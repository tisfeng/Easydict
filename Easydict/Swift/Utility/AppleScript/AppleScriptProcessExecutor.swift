//
//  AppleScriptProcessExecutor.swift
//  Easydict
//
//  Created by tisfeng on 2026/4/12.
//

import Darwin
import Foundation

// MARK: - AppleScriptProcessExecutor

/// Executes one cancellable script. The lock synchronizes cancellation with process launch.
final class AppleScriptProcessExecutor: @unchecked Sendable {
    // MARK: Lifecycle

    init(script: String) {
        self.script = script
    }

    // MARK: Internal

    @discardableResult
    func run() async throws -> String? {
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                Self.queue.addOperation {
                    continuation.resume(with: Result { try self.execute() })
                }
            }
        } onCancel: {
            self.cancel()
        }
    }

    func cancel() {
        lock.withLock {
            guard !cancelled else { return }
            cancelled = true
            if task.isRunning {
                task.terminate()
            }
        }
    }

    // MARK: Private

    // Selection and tab URL requests can run together. Each operation keeps its
    // slot until the process exits, even if its caller has already timed out.
    private static let queue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 2
        queue.qualityOfService = .userInitiated
        return queue
    }()

    private let script: String
    private let task = Process()
    private let lock = NSLock()
    private var cancelled = false

    /// Preserve the text-or-nil behavior of the previous Apple event descriptor.
    private var textResultScript: String {
        let source = script.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        return """
        set scriptResult to run script "\(source)"
        try
            if scriptResult is missing value then return
            if class of scriptResult is list or class of scriptResult is record then return
            return scriptResult as text
        on error
            return
        end try
        """
    }

    private func execute() throws -> String? {
        try lock.withLock {
            if cancelled { throw CancellationError() }
        }

        let input = try temporaryHandle()
        let output = try temporaryHandle()
        let errors = try temporaryHandle()

        try input.write(contentsOf: Data(textResultScript.utf8))
        try input.seek(toOffset: 0)

        try lock.withLock {
            if cancelled { throw CancellationError() }
            task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            task.arguments = ["-"]
            task.standardInput = input
            task.standardOutput = output
            task.standardError = errors
            try task.run()
        }

        task.waitUntilExit()
        try lock.withLock {
            if cancelled { throw CancellationError() }
        }

        if task.terminationStatus != 0 {
            throw QueryError(
                type: .appleScript,
                message: try readOutput(errors) ?? "Run AppleScript error",
                errorDataMessage: script
            )
        }
        return try readOutput(output)
    }

    /// Anonymous files keep scripts out of process arguments and let the child write without
    /// waiting for the app to drain a pipe. Closing the handles releases the files.
    private func temporaryHandle() throws -> FileHandle {
        var path = FileManager.default.temporaryDirectory
            .appendingPathComponent("easydict-applescript.XXXXXX").path.utf8CString
        let descriptor = path.withUnsafeMutableBufferPointer {
            mkostemp($0.baseAddress!, O_CLOEXEC)
        }
        guard descriptor >= 0 else {
            throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
        }
        let handle = FileHandle(fileDescriptor: descriptor, closeOnDealloc: true)
        guard path.withUnsafeBufferPointer({ unlink($0.baseAddress!) }) == 0 else {
            throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
        }
        return handle
    }

    private func readOutput(_ handle: FileHandle) throws -> String? {
        try handle.seek(toOffset: 0)
        guard var data = try handle.readToEnd(), !data.isEmpty else { return nil }
        // osascript adds one newline to its output. Preserve newlines in the result itself.
        if data.last == 0x0A { data.removeLast() }
        return String(decoding: data, as: UTF8.self)
    }
}
