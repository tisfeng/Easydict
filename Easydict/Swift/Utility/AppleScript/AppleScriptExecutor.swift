//
//  AppleScriptExecutor.swift
//  Easydict
//
//  Created by tisfeng on 2026/4/12.
//

import Foundation

// MARK: - AppleScriptExecutor

/// Applies the shared timeout and error behavior for Easydict's AppleScript calls.
struct AppleScriptExecutor {
    /// Runs a script in a subprocess. The timeout includes time spent in the execution queue.
    @discardableResult
    func run(_ appleScript: String, timeout: TimeInterval = 10) async throws -> String? {
        let executor = AppleScriptProcessExecutor(script: appleScript)
        do {
            return try await withTaskCancellationHandler {
                try await Task.withTimeout(seconds: timeout) {
                    try await executor.run()
                }
            } onCancel: {
                executor.cancel()
            }
        } catch is TaskTimeoutError {
            throw QueryError(
                type: .appleScript,
                message: "AppleScript execution timed out after \(timeout) seconds",
                errorDataMessage: appleScript
            )
        } catch let error as CancellationError {
            throw error
        } catch let error as QueryError {
            throw error
        } catch {
            throw QueryError(
                type: .appleScript,
                message: error.localizedDescription,
                errorDataMessage: appleScript
            )
        }
    }
}
