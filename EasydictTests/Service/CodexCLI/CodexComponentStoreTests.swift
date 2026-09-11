//
//  CodexComponentStoreTests.swift
//  EasydictTests
//
//  Created by Alfred on 2026/09/07.
//

import CryptoKit
import Defaults
@testable import Easydict
import Foundation
import Testing

// MARK: - CodexComponentStoreTests

/// Exercises pinned package download, validation and transactional installation.
/// Each download is served by a disposable loopback-only Python fixture, never
/// from the official package URL or a real Codex account.
@Suite("Codex component store", .serialized)
struct CodexComponentStoreTests {
    @Test("installs a verified package atomically and preserves a valid cache")
    func installsAndReusesVerifiedPackage() async throws {
        let fixture = try ComponentFixture()
        let archive = try fixture.makeArchive()
        let server = try fixture.server(archive: archive, behavior: .normal)
        let store = fixture.store(archive: archive, downloadURL: server.url)

        let first = try await store.install { _ in }
        let executable = first.appendingPathComponent("bin/codex")
        let firstInode = try #require(fileInode(executable))
        let second = try await store.install { _ in }

        let executableContents = try String(contentsOf: executable, encoding: .utf8)

        #expect(first == store.installedDirectory)
        #expect(second == first)
        #expect(executableContents == ComponentFixture.executableContents)
        #expect(fileInode(executable) == firstInode)
        #expect(server.requestCount == 2)
    }

    @Test("rejects a bad hash, a truncated archive and an HTTP failure", arguments: DownloadFault.allCases)
    func rejectsInvalidDownloads(fault: DownloadFault) async throws {
        let fixture = try ComponentFixture()
        let archive = try fixture.makeArchive()
        let server = try fixture.server(archive: archive, behavior: fault.serverBehavior)
        let store = fixture.store(
            archive: archive,
            downloadURL: server.url,
            archiveSHA256: fault == .wrongHash ? String(repeating: "0", count: 64) : nil
        )

        await #expect(throws: CodexManagedError.componentInvalid) {
            try await store.install { _ in }
        }
        #expect(!FileManager.default.fileExists(atPath: store.installedDirectory.path))
    }

    @Test("a late download cancellation never becomes an installation")
    func cancellationLateInDownloadDoesNotInstall() async throws {
        let fixture = try ComponentFixture()
        let archive = try fixture.makeArchive(extraFiles: ["data/payload": pseudoRandomData(count: 1_048_576)])
        let server = try fixture.server(archive: archive, behavior: .slow)
        let store = fixture.store(archive: archive, downloadURL: server.url)
        let installation = Task {
            try await store.install { _ in }
        }
        try await waitForRequest(server)
        try await Task.sleep(for: .milliseconds(750))

        installation.cancel()
        do {
            _ = try await installation.value
            Issue.record("A cancelled download unexpectedly installed a component.")
        } catch {
            let cancellationCode = (error as NSError).code
            #expect(error is CancellationError || cancellationCode == NSURLErrorCancelled)
        }
        #expect(!FileManager.default.fileExists(atPath: store.installedDirectory.path))
    }

    @Test("rejects unsafe paths and links before archive extraction")
    func rejectsUnsafeArchiveEntriesBeforeExtraction() throws {
        let fixture = try ComponentFixture()
        let archive = try fixture.makeArchive()
        let store = fixture.store(archive: archive, downloadURL: URL(string: "http://127.0.0.1:9/package")!)

        #expect(throws: CodexManagedError.componentInvalid) {
            try store.validateArchiveEntries(
                names: "./bin/codex\n../outside\n",
                details: "-rwxr-xr-x bin/codex\n-rw-r--r-- ../outside\n"
            )
        }
        #expect(throws: CodexManagedError.componentInvalid) {
            try store.validateArchiveEntries(
                names: "./bin/codex\n/absolute\n",
                details: "-rwxr-xr-x bin/codex\n-rw-r--r-- /absolute\n"
            )
        }
        #expect(throws: CodexManagedError.componentInvalid) {
            try store.validateArchiveEntries(
                names: "./bin/codex\nhashmanifest\n",
                details: "lrwxr-xr-x bin/codex -> /outside\n-rw-r--r-- hashmanifest\n"
            )
        }
    }

    @Test("rejects an installed package after a pinned file changes")
    func rejectsChangedInstalledFile() async throws {
        let fixture = try ComponentFixture()
        let archive = try fixture.makeArchive()
        let server = try fixture.server(archive: archive, behavior: .normal)
        let store = fixture.store(archive: archive, downloadURL: server.url)
        let installed = try await store.install { _ in }
        let executable = installed.appendingPathComponent("bin/codex")
        try "#!/bin/sh\necho tampered\n".write(to: executable, atomically: true, encoding: .utf8)

        await #expect(throws: CodexManagedError.componentInvalid) {
            try await store.verifyInstalled()
        }
    }

    @Test("replaces a damaged cached package with a verified staged package")
    func replacesDamagedCachedPackage() async throws {
        let fixture = try ComponentFixture()
        let archive = try fixture.makeArchive()
        let server = try fixture.server(archive: archive, behavior: .normal)
        let store = fixture.store(archive: archive, downloadURL: server.url)
        let installed = try await store.install { _ in }
        let executable = installed.appendingPathComponent("bin/codex")
        try "#!/bin/sh\necho tampered\n".write(to: executable, atomically: true, encoding: .utf8)

        let repaired = try await store.install { _ in }
        let executableContents = try String(contentsOf: executable, encoding: .utf8)
        let verified = try await store.verifyInstalled()

        #expect(repaired == installed)
        #expect(executableContents == ComponentFixture.executableContents)
        #expect(verified == installed)
    }

    @Test("a missing component check exposes recovery without downloading or touching an account")
    @MainActor
    func missingComponentCheckStopsAtDownloadRecovery() async throws {
        let fixture = try ComponentFixture()
        let archive = try fixture.makeArchive()
        let server = try fixture.server(archive: archive, behavior: .normal)
        let store = fixture.store(archive: archive, downloadURL: server.url)
        let account = CodexManagedAccount(
            runtimeFactory: { throw ComponentManagerFixtureError.unexpectedAccountRuntimeAccess },
            coordinator: CodexRequestCoordinator()
        )
        let manager = CodexComponentManager(storeFactory: { store }, account: account)

        manager.refresh()
        try await waitForComponentManager { !manager.isBusy }

        #expect(componentManagerIsMissing(manager))
        #expect(server.requestCount == 0)
        #expect(!account.isBusy)
        #expect(account.errorMessage == nil)
    }

    @Test("a component that becomes invalid clears verification without claiming the account signed out")
    @MainActor
    func invalidComponentClearsVerificationAndKeepsAuthentication() async throws {
        try await withAccountFixture(initiallySignedIn: true, release: .current) { runtimeFixture in
            let uuid = UUID().uuidString
            installManagedConfiguration(uuid: uuid, model: "gpt-5.5", effort: .high)
            defer { resetManagedConfiguration(uuid: uuid) }
            let configuration = CodexServiceConfiguration(uuid: uuid)
            let fixture = try ComponentFixture()
            let archive = try fixture.makeArchive()
            let server = try fixture.server(archive: archive, behavior: .normal)
            let store = fixture.store(archive: archive, downloadURL: server.url)
            let installed = try await store.install { _ in }
            let account = runtimeFixture.account()
            let manager = CodexComponentManager(storeFactory: { store }, account: account)

            manager.refresh()
            try await waitForComponentManager { !manager.isBusy && manager.isReady }
            try await waitForAccount { !account.isBusy && account.isSignedIn }
            account.validate(configuration: configuration)
            try await waitForAccount { !account.isBusy && account.isValidated(configuration: configuration) }
            try "#!/bin/sh\necho tampered\n".write(
                to: installed.appendingPathComponent("bin/codex"),
                atomically: true,
                encoding: .utf8
            )

            manager.refresh()
            try await waitForComponentManager { !manager.isBusy }

            #expect(componentManagerIsMissing(manager))
            #expect(!account.isValidated(configuration: configuration))
            #expect(account.isSignedIn)
            #expect(account.errorMessage == nil)
            #expect(server.requestCount == 1)
        }
    }

    @Test("a successful component refresh updates a stale signed-in account to login recovery")
    @MainActor
    func successfulComponentRefreshUpdatesStaleAccountStatus() async throws {
        try await withAccountFixture(initiallySignedIn: true, release: .current) { runtimeFixture in
            let uuid = UUID().uuidString
            installManagedConfiguration(uuid: uuid, model: "gpt-5.5", effort: .high)
            defer { resetManagedConfiguration(uuid: uuid) }
            let configuration = CodexServiceConfiguration(uuid: uuid)
            let fixture = try ComponentFixture()
            let archive = try fixture.makeArchive()
            let server = try fixture.server(archive: archive, behavior: .normal)
            let store = fixture.store(archive: archive, downloadURL: server.url)
            _ = try await store.install { _ in }
            let account = runtimeFixture.account()
            let manager = CodexComponentManager(storeFactory: { store }, account: account)

            manager.refresh()
            try await waitForComponentManager { !manager.isBusy }
            try await waitForAccount { !account.isBusy && account.isSignedIn }
            account.validate(configuration: configuration)
            try await waitForAccount { !account.isBusy && account.isValidated(configuration: configuration) }
            let execBeforeLoss = runtimeFixture.invocationCount("exec")
            let statusBeforeLoss = runtimeFixture.invocationCount("status")

            try runtimeFixture.setSignedIn(false)
            let translation = CodexManagedTranslation()
            await #expect(throws: CodexManagedError.loginRequired) {
                try await translation.run(
                    prompt: "Translate Hello into Simplified Chinese.",
                    model: CodexRuntimeRelease.current.defaultModel,
                    effort: "high",
                    runtime: runtimeFixture.runtime()
                )
            }
            #expect(account.isSignedIn)
            #expect(account.isValidated(configuration: configuration))

            manager.refresh()
            try await waitForComponentManager { !manager.isBusy }
            try await waitForAccount { !account.isBusy && accountIsSignedOut(account) }

            #expect(!account.isValidated(configuration: configuration))
            #expect(runtimeFixture.invocationCount("exec") == execBeforeLoss)
            #expect(runtimeFixture.invocationCount("login") == 0)
            #expect(runtimeFixture.invocationCount("status") == statusBeforeLoss + 2)
            #expect(server.requestCount == 1)
        }
    }

    @Test("overlapping settings refreshes reuse the same component check")
    @MainActor
    func overlappingRefreshesReuseOneCheck() async throws {
        let fixture = try ComponentFixture()
        let archive = try fixture.makeArchive()
        let server = try fixture.server(archive: archive, behavior: .normal)
        let store = fixture.store(archive: archive, downloadURL: server.url)
        let gate = ComponentStoreFactoryGate()
        let calls = ComponentStoreFactoryCounter()
        let account = CodexManagedAccount(
            runtimeFactory: { throw ComponentManagerFixtureError.unexpectedAccountRuntimeAccess },
            coordinator: CodexRequestCoordinator()
        )
        let manager = CodexComponentManager(
            storeFactory: {
                await calls.record()
                await gate.wait()
                return store
            },
            account: account
        )

        manager.refresh()
        manager.refresh()
        try await waitForComponentStoreFactory(gate)
        #expect(await calls.count == 1)

        await gate.release()
        try await waitForComponentManager { !manager.isBusy }

        #expect(componentManagerIsMissing(manager))
        #expect(server.requestCount == 0)
        #expect(account.errorMessage == nil)
    }

    @Test("canceling a read-only component check preserves availability and does not restart it")
    @MainActor
    func cancellingComponentCheckDoesNotRestart() async throws {
        let fixture = try ComponentFixture()
        let archive = try fixture.makeArchive()
        let server = try fixture.server(archive: archive, behavior: .normal)
        let store = fixture.store(archive: archive, downloadURL: server.url)
        let gate = ComponentStoreFactoryGate()
        let calls = ComponentStoreFactoryCounter()
        let account = CodexManagedAccount(
            runtimeFactory: { throw ComponentManagerFixtureError.unexpectedAccountRuntimeAccess },
            coordinator: CodexRequestCoordinator()
        )
        let manager = CodexComponentManager(
            storeFactory: {
                await calls.record()
                if await calls.count == 2 { await gate.wait() }
                return store
            },
            account: account
        )

        manager.refresh()
        try await waitForComponentManager { !manager.isBusy }
        #expect(componentManagerIsMissing(manager))

        manager.refresh()
        try await waitForComponentStoreFactory(gate)
        manager.cancel()
        await gate.release()
        try await waitForComponentManager { !manager.isBusy }

        #expect(await calls.count == 2)
        #expect(componentManagerIsMissing(manager))
        #expect(server.requestCount == 0)
        #expect(account.errorMessage == nil)
    }

    @Test("canceling an installation rechecks the actual component result")
    @MainActor
    func cancellingInstallRechecksActualComponent() async throws {
        let fixture = try ComponentFixture()
        let archive = try fixture.makeArchive(extraFiles: ["data/payload": pseudoRandomData(count: 1_048_576)])
        let server = try fixture.server(archive: archive, behavior: .slow)
        let store = fixture.store(archive: archive, downloadURL: server.url)
        let calls = ComponentStoreFactoryCounter()
        let account = CodexManagedAccount(
            runtimeFactory: { throw ComponentManagerFixtureError.unexpectedAccountRuntimeAccess },
            coordinator: CodexRequestCoordinator()
        )
        let manager = CodexComponentManager(
            storeFactory: {
                await calls.record()
                return store
            },
            account: account
        )

        manager.download(origin: "first-window")
        try await waitForRequest(server)
        try await Task.sleep(for: .milliseconds(750))
        manager.cancel()
        try await waitForComponentManager { !manager.isBusy }

        #expect(await calls.count == 2)
        #expect(componentManagerIsMissing(manager))
        #expect(server.requestCount == 1)
        #expect(!account.isBusy)
        #expect(account.errorMessage == nil)
    }

    @Test("canceling a component check does not interrupt an independent managed translation")
    @MainActor
    func cancellingComponentCheckDoesNotCancelTranslation() async throws {
        try await withAccountFixture(initiallySignedIn: true, validationDelay: 2, release: .current) { runtimeFixture in
            let fixture = try ComponentFixture()
            let archive = try fixture.makeArchive()
            let server = try fixture.server(archive: archive, behavior: .normal)
            let store = fixture.store(archive: archive, downloadURL: server.url)
            let gate = ComponentStoreFactoryGate()
            let manager = CodexComponentManager(
                storeFactory: {
                    await gate.wait()
                    return store
                },
                account: runtimeFixture.account()
            )
            let translation = CodexManagedTranslation()
            let translationTask = Task {
                try await translation.run(
                    prompt: "Translate Hello into Simplified Chinese.",
                    model: CodexRuntimeRelease.current.defaultModel,
                    effort: "high",
                    runtime: runtimeFixture.runtime()
                )
            }
            try await waitForAccount { runtimeFixture.invocationCount("exec") == 1 }

            manager.refresh()
            try await waitForComponentStoreFactory(gate)
            manager.cancel()
            await gate.release()
            try await waitForComponentManager { !manager.isBusy }
            let result = try await translationTask.value

            #expect(result.text == "你好")
            #expect(server.requestCount == 0)
        }
    }

    @Test("a component refresh does not preempt an existing account operation")
    @MainActor
    func refreshDoesNotPreemptBusyAccount() async throws {
        try await withAccountFixture(firstStatusDelayedAndSignedIn: true, release: .current) { fixture in
            let calls = ComponentStoreFactoryCounter()
            let account = fixture.account()
            let manager = CodexComponentManager(
                storeFactory: {
                    await calls.record()
                    throw ComponentManagerFixtureError.unexpectedComponentStoreAccess
                },
                account: account
            )

            account.refresh()
            try await waitForAccount { fixture.invocationCount("status") == 1 }
            manager.refresh()
            try await Task.sleep(for: .milliseconds(100))

            let callCount = await calls.count
            #expect(callCount == 0)
            #expect(!manager.isBusy)
            #expect(componentManagerIsUnknown(manager))

            account.cancelCurrentOperation()
            try await waitForAccount { !account.isBusy }
        }
    }
}

// MARK: - DownloadFault

/// Defines a fixture response that cannot satisfy a pinned component descriptor.
enum DownloadFault: CaseIterable, Sendable {
    case wrongHash
    case truncated
    case httpFailure

    // MARK: Internal

    var serverBehavior: HTTPBehavior {
        switch self {
        case .wrongHash: .normal
        case .truncated: .truncated
        case .httpFailure: .failure
        }
    }
}

// MARK: - HTTPBehavior

/// Configures the loopback fixture's response without accessing external network resources.
enum HTTPBehavior: String, Sendable {
    case normal
    case truncated
    case failure
    case slow
}

// MARK: - ComponentFixture

/// Builds a compact executable package and matching descriptor inside one private directory.
private final class ComponentFixture {
    // MARK: Lifecycle

    init() throws {
        // ComponentStore rejects roots below a symbolic-link ancestor. macOS exposes
        // NSTemporaryDirectory through /var, which links to /private/var.
        let temporaryDirectory = FileManager.default.temporaryDirectory.path
        let physicalTemporaryDirectory = temporaryDirectory.hasPrefix("/var/")
            ? "/private" + temporaryDirectory
            : temporaryDirectory
        self.directory = URL(fileURLWithPath: physicalTemporaryDirectory, isDirectory: true)
            .appendingPathComponent("Easydict-CodexComponentTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    deinit {
        try? FileManager.default.removeItem(at: directory)
    }

    // MARK: Internal

    static let executableContents = "#!/bin/sh\necho fixture-codex\n"

    let directory: URL

    func makeArchive(extraFiles: [String: Data] = [:]) throws -> FixtureArchive {
        let payload = directory.appendingPathComponent("payload-\(UUID().uuidString)", isDirectory: true)
        var contents = [
            "bin/codex": Data(Self.executableContents.utf8),
            "hashmanifest": Data("fixture-manifest\n".utf8),
        ]
        contents.merge(extraFiles) { _, extra in extra }
        for (path, data) in contents {
            let file = payload.appendingPathComponent(path)
            try FileManager.default.createDirectory(
                at: file.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try data.write(to: file)
        }
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o755],
            ofItemAtPath: payload.appendingPathComponent("bin/codex").path
        )

        let archive = directory.appendingPathComponent("package-\(UUID().uuidString).tar.gz")
        let entries = Set(contents.keys.compactMap { $0.split(separator: "/").first.map(String.init) }).sorted()
        try runProcess(executable: "/usr/bin/tar", arguments: ["-czf", archive.path, "-C", payload.path] + entries)
        var hashes = [String: String]()
        for path in contents.keys {
            hashes[path] = sha256(try Data(contentsOf: payload.appendingPathComponent(path)))
        }
        let directories = Set(contents.keys.compactMap { path -> String? in
            let parent = (path as NSString).deletingLastPathComponent
            return parent.isEmpty ? nil : parent
        }).sorted()
        return FixtureArchive(url: archive, files: hashes, directories: directories)
    }

    func server(archive: FixtureArchive, behavior: HTTPBehavior) throws -> ComponentHTTPServer {
        try ComponentHTTPServer(directory: directory, archiveURL: archive.url, behavior: behavior)
    }

    func store(
        archive: FixtureArchive,
        downloadURL: URL,
        archiveSHA256: String? = nil
    )
        -> CodexComponentStore {
        let archiveData = try! Data(contentsOf: archive.url)
        let archiveSize = Int64(try! archive.url.resourceValues(forKeys: [.fileSizeKey]).fileSize!)
        let package = CodexRuntimeDescriptor.Package(
            target: "aarch64-apple-darwin",
            archiveSHA256: archiveSHA256 ?? sha256(archiveData),
            archiveSize: archiveSize,
            files: archive.files,
            directories: archive.directories,
            signatureRequirements: [:]
        )
        let descriptor = CodexRuntimeDescriptor(
            release: .legacy,
            architecture: .appleSilicon,
            package: package,
            catalogURL: runtimeCatalogURL(),
            downloadURL: downloadURL
        )
        return CodexComponentStore(descriptor: descriptor, root: directory.appendingPathComponent("components"))
    }

    // MARK: Private

    private func runtimeCatalogURL() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("scripts/codex-runtime/0.134.0/translation-models.json")
    }
}

// MARK: - FixtureArchive

/// Holds the archive and exact contents used to form one test-only package descriptor.
private struct FixtureArchive {
    let url: URL
    let files: [String: String]
    let directories: [String]
}

// MARK: - ComponentHTTPServer

/// Runs a disposable loopback server whose responses are restricted to one generated archive.
private final class ComponentHTTPServer {
    // MARK: Lifecycle

    init(directory: URL, archiveURL: URL, behavior: HTTPBehavior) throws {
        let scriptURL = directory.appendingPathComponent("server-\(UUID().uuidString).py")
        let portURL = directory.appendingPathComponent("port-\(UUID().uuidString)")
        self.requestsURL = directory.appendingPathComponent("requests-\(UUID().uuidString)")
        try Self.script.write(to: scriptURL, atomically: true, encoding: .utf8)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        process.arguments = ["-u", scriptURL.path, archiveURL.path, behavior.rawValue, portURL.path, requestsURL.path]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try process.run()
        self.process = process
        do {
            try waitForFile(portURL)
            guard let port = Int(try String(contentsOf: portURL, encoding: .utf8)
                .trimmingCharacters(in: .whitespacesAndNewlines)) else {
                throw ComponentFixtureError.invalidServerPort
            }
            self.url = URL(string: "http://127.0.0.1:\(port)/package")!
        } catch {
            process.terminate()
            throw error
        }
    }

    deinit {
        if process.isRunning {
            process.terminate()
        }
    }

    // MARK: Internal

    let url: URL

    var requestCount: Int {
        guard let content = try? String(contentsOf: requestsURL, encoding: .utf8) else { return 0 }
        return content.split(separator: "\n").count
    }

    // MARK: Private

    private static let script = """
    import http.server
    import os
    import pathlib
    import sys
    import time

    archive, behavior, port_path, requests_path = sys.argv[1:]

    class Handler(http.server.BaseHTTPRequestHandler):
        def do_GET(self):
            pathlib.Path(requests_path).open("a").write("request\\n")
            if behavior == "failure":
                self.send_response(500)
                self.end_headers()
                return
            body = pathlib.Path(archive).read_bytes()
            if behavior == "truncated":
                body = body[:max(1, len(body) // 2)]
            self.send_response(200)
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            if behavior == "slow":
                for offset in range(0, len(body), 16384):
                    self.wfile.write(body[offset:offset + 16384])
                    self.wfile.flush()
                    time.sleep(0.015)
            else:
                self.wfile.write(body)

        def log_message(self, format, *args):
            pass

    server = http.server.HTTPServer(("127.0.0.1", 0), Handler)
    pending_port_path = port_path + ".pending"
    pathlib.Path(pending_port_path).write_text(str(server.server_port))
    os.replace(pending_port_path, port_path)
    server.serve_forever()
    """

    private let process: Process
    private let requestsURL: URL
}

// MARK: - ComponentFixtureError

/// Identifies a test fixture startup condition that prevents a meaningful store assertion.
private enum ComponentFixtureError: Error {
    case invalidServerPort
    case waitTimedOut
}

private func runProcess(executable: String, arguments: [String]) throws {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: executable)
    process.arguments = arguments
    process.standardOutput = FileHandle.nullDevice
    process.standardError = FileHandle.nullDevice
    try process.run()
    process.waitUntilExit()
    guard process.terminationStatus == 0 else { throw ComponentFixtureError.waitTimedOut }
}

/// Produces incompressible fixture bytes so cancellation happens after material download progress.
private func pseudoRandomData(count: Int) -> Data {
    var state: UInt64 = 0xC0DEC0DE
    var data = Data()
    data.reserveCapacity(count)
    for _ in 0 ..< count {
        state = state &* 6_364_136_223_846_793_005 &+ 1
        data.append(UInt8(truncatingIfNeeded: state >> 24))
    }
    return data
}

private func sha256(_ data: Data) -> String {
    SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
}

private func fileInode(_ url: URL) -> UInt64? {
    guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
          let number = attributes[.systemFileNumber] as? NSNumber
    else { return nil }
    return number.uint64Value
}

private func waitForFile(_ url: URL, timeout: TimeInterval = 3) throws {
    let deadline = Date().addingTimeInterval(timeout)
    while !FileManager.default.fileExists(atPath: url.path) {
        guard Date() < deadline else { throw ComponentFixtureError.waitTimedOut }
        Thread.sleep(forTimeInterval: 0.01)
    }
}

private func waitForRequest(_ server: ComponentHTTPServer, timeout: TimeInterval = 3) async throws {
    let deadline = Date().addingTimeInterval(timeout)
    while server.requestCount == 0 {
        guard Date() < deadline else { throw ComponentFixtureError.waitTimedOut }
        try await Task.sleep(for: .milliseconds(10))
    }
}

@MainActor
private func waitForComponentManager(
    timeout: TimeInterval = 4,
    _ condition: @escaping @MainActor () -> Bool
) async throws {
    let deadline = Date().addingTimeInterval(timeout)
    while !condition() {
        guard Date() < deadline else { throw ComponentFixtureError.waitTimedOut }
        try await Task.sleep(for: .milliseconds(20))
    }
}

private func waitForComponentStoreFactory(
    _ gate: ComponentStoreFactoryGate,
    timeout: TimeInterval = 4
) async throws {
    let deadline = Date().addingTimeInterval(timeout)
    while !(await gate.isWaiting) {
        guard Date() < deadline else { throw ComponentFixtureError.waitTimedOut }
        try await Task.sleep(for: .milliseconds(20))
    }
}

@MainActor
private func componentManagerIsMissing(_ manager: CodexComponentManager) -> Bool {
    if case .missing = manager.state { return true }
    return false
}

@MainActor
private func componentManagerIsUnknown(_ manager: CodexComponentManager) -> Bool {
    if case .unknown = manager.state { return true }
    return false
}

// MARK: - ComponentManagerFixtureError

private enum ComponentManagerFixtureError: Error {
    case unexpectedAccountRuntimeAccess
    case unexpectedComponentStoreAccess
}

// MARK: - ComponentStoreFactoryCounter

private actor ComponentStoreFactoryCounter {
    // MARK: Internal

    var count: Int { value }

    func record() {
        value += 1
    }

    // MARK: Private

    private var value = 0
}

// MARK: - ComponentStoreFactoryGate

private actor ComponentStoreFactoryGate {
    // MARK: Internal

    var isWaiting: Bool { continuation != nil }

    func wait() async {
        await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
    }

    func release() {
        continuation?.resume()
        continuation = nil
    }

    // MARK: Private

    private var continuation: CheckedContinuation<(), Never>?
}
