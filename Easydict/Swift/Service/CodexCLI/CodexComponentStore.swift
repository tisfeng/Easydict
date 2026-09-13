//
//  CodexComponentStore.swift
//  Easydict
//
//  Created by Alfred on 2026/09/07.
//

import CryptoKit
import Foundation
import Security

// MARK: - CodexComponentStore

/// Installs a pinned package transactionally. Staging never counts as an installation.
struct CodexComponentStore: Sendable {
    // MARK: Internal

    let descriptor: CodexRuntimeDescriptor
    let root: URL

    var installedDirectory: URL {
        root.appendingPathComponent(descriptor.release.rawValue)
            .appendingPathComponent(descriptor.architecture.rawValue)
    }

    static func applicationStore(descriptor: CodexRuntimeDescriptor) throws -> Self {
        let support = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).resolvingSymlinksInPath()
        return Self(descriptor: descriptor, root: support.appendingPathComponent("Easydict/codex-managed/components"))
    }

    func verifyInstalled() async throws -> URL {
        try Task.checkCancellation()
        guard FileManager.default.fileExists(atPath: installedDirectory.path) else {
            throw CodexManagedError.componentMissing
        }
        try verifyPackage(at: installedDirectory)
        try Task.checkCancellation()
        return installedDirectory
    }

    func install(progress: @escaping @Sendable (Double?) -> ()) async throws -> URL {
        let manager = FileManager.default
        try createDirectory(root)
        let staging = root.appendingPathComponent(".install-\(UUID().uuidString)")
        try createDirectory(staging)
        defer { try? manager.removeItem(at: staging) }
        let delegate = CodexDownloadProgress(expectedSize: descriptor.package.archiveSize, progress: progress)
        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpShouldSetCookies = false
        configuration.timeoutIntervalForResource = 600
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }
        let downloaded: URL
        let response: URLResponse
        do {
            (downloaded, response) = try await session.download(from: descriptor.downloadURL, delegate: delegate)
        } catch {
            if delegate.exceededSize { throw CodexManagedError.componentInvalid }
            throw error
        }
        defer { try? manager.removeItem(at: downloaded) }
        try Task.checkCancellation()
        guard let http = response as? HTTPURLResponse, (200 ..< 300).contains(http.statusCode),
              try downloaded.resourceValues(forKeys: [.fileSizeKey]).fileSize == Int(descriptor.package.archiveSize),
              try Self.sha256(downloaded) == descriptor.package.archiveSHA256
        else { throw CodexManagedError.componentInvalid }
        progress(nil)
        let archive = staging.appendingPathComponent("package.tar.gz")
        try manager.moveItem(at: downloaded, to: archive)
        let unpacked = staging.appendingPathComponent("package")
        try createDirectory(unpacked)
        let environment = ["PATH": "/usr/bin:/bin", "LANG": "C"]
        let names = try await CodexManagedProcess().run(
            executable: URL(fileURLWithPath: "/usr/bin/tar"),
            arguments: ["-tzf", archive.path],
            environment: environment,
            workingDirectory: staging,
            timeout: 30
        )
        let kinds = try await CodexManagedProcess().run(
            executable: URL(fileURLWithPath: "/usr/bin/tar"),
            arguments: ["-tvzf", archive.path],
            environment: environment,
            workingDirectory: staging,
            timeout: 30
        )
        guard names.exitCode == 0, kinds.exitCode == 0 else { throw CodexManagedError.componentInvalid }
        try validateArchiveEntries(
            names: String(decoding: names.stdout, as: UTF8.self),
            details: String(decoding: kinds.stdout, as: UTF8.self)
        )
        try Task.checkCancellation()
        let extraction = try await CodexManagedProcess().run(
            executable: URL(fileURLWithPath: "/usr/bin/tar"),
            arguments: [
                "-xzf",
                archive.path,
                "-C",
                unpacked.path,
                "--no-same-owner",
            ],
            environment: environment,
            workingDirectory: staging,
            timeout: 60
        )
        guard extraction.exitCode == 0 else { throw CodexManagedError.componentInvalid }
        try verifyPackage(at: unpacked)
        try Task.checkCancellation()
        try createDirectory(installedDirectory.deletingLastPathComponent())
        if manager.fileExists(atPath: installedDirectory.path) {
            do {
                try verifyPackage(at: installedDirectory)
                return installedDirectory
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                // The replacement is fully verified. Keep the damaged copy until
                // promotion succeeds so a failed filesystem move is recoverable.
                let backup = staging.appendingPathComponent("previous")
                try manager.moveItem(at: installedDirectory, to: backup)
                do {
                    try manager.moveItem(at: unpacked, to: installedDirectory)
                } catch {
                    try manager.moveItem(at: backup, to: installedDirectory)
                    throw error
                }
                return installedDirectory
            }
        }
        try manager.moveItem(at: unpacked, to: installedDirectory)
        return installedDirectory
    }

    /// Check entry names and kinds before extraction, in addition to the pinned hash.
    func validateArchiveEntries(names: String, details: String) throws {
        let allowedFiles = Set(descriptor.package.files.keys)
        var allowedDirectories = Set(descriptor.package.directories + ["."])
        for file in allowedFiles {
            var parent = (file as NSString).deletingLastPathComponent
            while !parent.isEmpty {
                allowedDirectories.insert(parent)
                parent = (parent as NSString).deletingLastPathComponent
            }
        }
        var files = Set<String>()
        for raw in names.split(separator: "\n") {
            var name = String(raw)
            if name.hasPrefix("./") { name.removeFirst(2) }
            if name.hasSuffix("/") { name.removeLast() }
            guard !name.hasPrefix("/"), !name.split(separator: "/").contains(".."),
                  allowedFiles.contains(name) || allowedDirectories.contains(name)
            else { throw CodexManagedError.componentInvalid }
            if allowedFiles.contains(name), !files.insert(name).inserted {
                throw CodexManagedError.componentInvalid
            }
        }
        guard files == allowedFiles,
              details.split(separator: "\n").allSatisfy({ $0.first == "-" || $0.first == "d" })
        else { throw CodexManagedError.componentInvalid }
    }

    func verifyPackage(at directory: URL) throws {
        let manager = FileManager.default
        guard directory.resolvingSymlinksInPath() == directory.standardizedFileURL,
              let enumerator = manager.enumerator(
                  at: directory,
                  includingPropertiesForKeys: [.isRegularFileKey, .isSymbolicLinkKey]
              )
        else { throw CodexManagedError.componentInvalid }
        var files = Set<String>()
        for case let file as URL in enumerator {
            try Task.checkCancellation()
            let values = try file.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey])
            guard values.isSymbolicLink != true else { throw CodexManagedError.componentInvalid }
            if values.isRegularFile == true {
                let relative = String(file.path.dropFirst(directory.path.count + 1))
                guard let expected = descriptor.package.files[relative], try Self.sha256(file) == expected else {
                    throw CodexManagedError.componentInvalid
                }
                files.insert(relative)
            }
        }
        guard files == Set(descriptor.package.files.keys),
              manager.isExecutableFile(atPath: directory.appendingPathComponent("bin/codex").path)
        else { throw CodexManagedError.componentInvalid }
        for (path, expression) in descriptor.package.signatureRequirements {
            var code: SecStaticCode?
            var requirement: SecRequirement?
            guard SecStaticCodeCreateWithPath(directory.appendingPathComponent(path) as CFURL, [], &code) ==
                errSecSuccess,
                SecRequirementCreateWithString(expression as CFString, [], &requirement) == errSecSuccess,
                let code, let requirement,
                SecStaticCodeCheckValidity(code, SecCSFlags(rawValue: kSecCSStrictValidate), requirement) ==
                errSecSuccess
            else { throw CodexManagedError.componentInvalid }
        }
    }

    // MARK: Private

    private static func sha256(_ url: URL) throws -> String {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        var hash = SHA256()
        while let data = try handle.read(upToCount: 1024 * 1024), !data.isEmpty {
            try Task.checkCancellation()
            hash.update(data: data)
        }
        return hash.finalize().map { String(format: "%02x", $0) }.joined()
    }

    private func createDirectory(_ url: URL) throws {
        var ancestor = url
        while true {
            if (try? FileManager.default.destinationOfSymbolicLink(atPath: ancestor.path)) != nil {
                throw CodexManagedError.componentInvalid
            }
            if ancestor.path == "/" { break }
            ancestor.deleteLastPathComponent()
        }
        try FileManager.default.createDirectory(
            at: url,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700]
        )
        guard url.resolvingSymlinksInPath() == url.standardizedFileURL else {
            throw CodexManagedError.componentInvalid
        }
    }
}

// MARK: - CodexDownloadProgress

private final class CodexDownloadProgress: NSObject, URLSessionDownloadDelegate, @unchecked Sendable {
    // MARK: Lifecycle

    init(expectedSize: Int64, progress: @escaping @Sendable (Double?) -> ()) {
        self.expectedSize = expectedSize
        self.progress = progress
    }

    // MARK: Internal

    var exceededSize: Bool { lock.withLock { oversized } }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {}

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        if totalBytesWritten > expectedSize {
            lock.withLock { oversized = true }
            downloadTask.cancel()
        } else {
            progress(Double(totalBytesWritten) / Double(expectedSize))
        }
    }

    // MARK: Private

    private let expectedSize: Int64
    private let progress: @Sendable (Double?) -> ()
    private let lock = NSLock()
    private var oversized = false
}
