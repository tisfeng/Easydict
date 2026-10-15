//
//  GitHubCopilotCatalogClient.swift
//  Easydict
//
//  Created by tisfeng on 2026/09/27.
//

import Darwin
import Foundation

/// A bounded, cancellable, single-use JSON-RPC client for model metadata.
/// Blocking pipe I/O runs on a dispatch worker, never the UI or a cooperative executor.
final class GitHubCopilotCatalogClient: @unchecked Sendable {
    // MARK: Internal

    func models(
        binary: String,
        workingDirectory: URL,
        logDirectory: URL,
        environment: [String: String]
    ) async throws
        -> [GitHubCopilotModel] {
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                DispatchQueue.global(qos: .userInitiated).async {
                    do {
                        let result = try self.readModels(
                            binary: binary, workingDirectory: workingDirectory,
                            logDirectory: logDirectory, environment: environment
                        )
                        continuation.resume(returning: result)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        } onCancel: {
            self.lock.withLock { self.cancelled = true }
        }
    }

    // MARK: Private

    private struct Reply: Decodable {
        struct Payload: Decodable {
            let ok: Bool?
            let protocolVersion: Int?
            let models: [GitHubCopilotModel]?
        }

        struct Failure: Decodable {
            let message: String
        }

        let id: Int?
        let result: Payload?
        let error: Failure?
    }

    private let lock = NSLock()
    private var cancelled = false
    private let maximumMessageSize = 4 * 1024 * 1024

    private func readModels(
        binary: String,
        workingDirectory: URL,
        logDirectory: URL,
        environment: [String: String]
    ) throws
        -> [GitHubCopilotModel] {
        let process = Process()
        let input = Pipe()
        let output = Pipe()
        let errors = Pipe()
        process.executableURL = URL(fileURLWithPath: binary)
        process.arguments = [
            "--server", "--stdio", "--no-auto-update", "--no-custom-instructions",
            "--disable-builtin-mcps", "--no-remote", "--no-remote-export",
            "--log-dir", logDirectory.path,
        ]
        process.currentDirectoryURL = workingDirectory
        process.environment = environment
        process.standardInput = input
        process.standardOutput = output
        process.standardError = errors
        let exited = DispatchSemaphore(value: 0)
        process.terminationHandler = { _ in exited.signal() }
        try checkCancellation()
        try process.run()
        defer {
            try? input.fileHandleForWriting.close()
            if process.isRunning { process.terminate() }
            if exited.wait(timeout: .now() + 2) == .timedOut, process.isRunning {
                kill(process.processIdentifier, SIGKILL)
                process.waitUntilExit()
            }
            try? output.fileHandleForReading.close()
            try? errors.fileHandleForReading.close()
        }

        try send(id: 1, method: "connect", to: input.fileHandleForWriting)
        var buffer = Data()
        var stderr = Data()
        let deadline = ProcessInfo.processInfo.systemUptime + 30
        var descriptors = [
            pollfd(fd: output.fileHandleForReading.fileDescriptor, events: Int16(POLLIN), revents: 0),
            pollfd(fd: errors.fileHandleForReading.fileDescriptor, events: Int16(POLLIN), revents: 0),
        ]
        var bytes = [UInt8](repeating: 0, count: 65536)
        var connected = false
        while ProcessInfo.processInfo.systemUptime < deadline {
            try checkCancellation()
            let ready = poll(&descriptors, nfds_t(descriptors.count), 100)
            if ready < 0 {
                if errno == EINTR { continue }
                throw GitHubCopilotError.catalogUnavailable
            }
            for index in descriptors.indices where descriptors[index].revents != 0 {
                let count = Darwin.read(descriptors[index].fd, &bytes, bytes.count)
                if count < 0, errno == EINTR { continue }
                guard count > 0 else {
                    descriptors[index].fd = -1
                    continue
                }
                if index == 1 {
                    stderr.append(contentsOf: bytes.prefix(count))
                    stderr = Data(stderr.suffix(65536))
                    continue
                }
                buffer.append(contentsOf: bytes.prefix(count))
                guard buffer.count <= maximumMessageSize else { throw GitHubCopilotError.catalogUnavailable }
                while let message = try nextMessage(in: &buffer) {
                    let reply = try JSONDecoder().decode(Reply.self, from: message)
                    guard reply.id == 1 || reply.id == 2 else { continue }
                    if let error = reply.error {
                        throw parseGitHubCopilotError(fromStdout: "", stderr: error.message)
                    }
                    if reply.id == 1, !connected {
                        guard reply.result?.ok == true, reply.result?.protocolVersion == 3 else {
                            throw GitHubCopilotError.catalogUnavailable
                        }
                        connected = true
                        try send(id: 2, method: "models.list", to: input.fileHandleForWriting)
                    } else if reply.id == 2, connected, let models = reply.result?.models {
                        var seen = Set<String>()
                        let uniqueModels = models.filter { !$0.id.isEmpty && seen.insert($0.id).inserted }
                        guard !uniqueModels.isEmpty else { throw GitHubCopilotError.catalogUnavailable }
                        return uniqueModels
                    }
                }
            }
            if descriptors[0].fd == -1 {
                throw parseGitHubCopilotError(fromStdout: "", stderr: String(data: stderr, encoding: .utf8) ?? "")
            }
        }
        throw GitHubCopilotError.catalogUnavailable
    }

    private func checkCancellation() throws {
        if lock.withLock({ cancelled }) { throw CancellationError() }
    }

    private func send(id: Int, method: String, to handle: FileHandle) throws {
        let body = try JSONSerialization.data(withJSONObject: [
            "jsonrpc": "2.0", "id": id, "method": method, "params": [:],
        ])
        var frame = Data("Content-Length: \(body.count)\r\n\r\n".utf8)
        frame.append(body)
        try handle.write(contentsOf: frame)
    }

    /// Handles both fragmented headers/bodies and multiple frames in one read.
    private func nextMessage(in buffer: inout Data) throws -> Data? {
        guard let separator = buffer.range(of: Data("\r\n\r\n".utf8)) else { return nil }
        guard let header = String(data: buffer[..<separator.lowerBound], encoding: .utf8) else {
            throw GitHubCopilotError.catalogUnavailable
        }
        let length = header.components(separatedBy: "\r\n").compactMap { line -> Int? in
            let parts = line.split(separator: ":", maxSplits: 1)
            guard parts.count == 2, parts[0].lowercased() == "content-length" else { return nil }
            return Int(parts[1].trimmingCharacters(in: .whitespaces))
        }.first
        guard let length, length > 0, length <= maximumMessageSize else {
            throw GitHubCopilotError.catalogUnavailable
        }
        let end = separator.upperBound + length
        guard buffer.count >= end else { return nil }
        let message = Data(buffer[separator.upperBound ..< end])
        buffer = Data(buffer[end...])
        return message
    }
}
