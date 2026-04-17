//
//  AppleScriptProcessExecutor.swift
//  Easydict
//
//  Created by tisfeng on 2026/4/12.
//

import Foundation

// MARK: - AppleScriptProcessExecutor

/// Executes AppleScript by spawning `/usr/bin/osascript` and waiting for the subprocess result. The
/// runner is retained as an internal compatibility backend for cases where a process-based path is
/// still useful, while keeping `Process`, pipe management, and stderr mapping out of the primary
/// `NSAppleScript` business flow. Production callers should continue to prefer `AppleScriptExecutor`.
final class AppleScriptProcessExecutor {
    // MARK: Lifecycle

    /// Creates a subprocess-backed AppleScript executor for one script invocation.
    ///
    /// - Parameter script: The AppleScript source string to execute with `osascript`.
    init(script: String) {
        self.script = script
        self.task = Process()
        self.outputPipe = Pipe()
        self.errorPipe = Pipe()

        task.standardOutput = outputPipe
        task.standardError = errorPipe
        task.arguments = ["-e", script]
        task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
    }

    // MARK: Internal

    /// Runs the configured AppleScript in a subprocess and returns the captured stdout.
    ///
    /// - Returns: The optional string output emitted by `osascript`.
    /// - Throws: `QueryError` when the process reports a script error or I/O capture fails.
    @discardableResult
    func run() async throws -> String? {
        try task.run()

        return try await withCheckedThrowingContinuation { continuation in
            task.terminationHandler = { _ in
                do {
                    let outputData = try self.outputPipe.fileHandleForReading.readToEnd()
                    let errorData = try self.errorPipe.fileHandleForReading.readToEnd()

                    if let error = errorData?.stringValue, !error.isEmpty {
                        continuation.resume(
                            throwing: QueryError(
                                type: .appleScript,
                                message: error,
                                errorDataMessage: self.script
                            )
                        )
                    } else {
                        continuation.resume(returning: outputData?.stringValue)
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Terminates the underlying `osascript` process if it is still running.
    func terminate() {
        task.terminate()
    }

    // MARK: Private

    private let script: String
    private let task: Process
    private let outputPipe: Pipe
    private let errorPipe: Pipe
}
