//
//  AppleScriptExecutor.swift
//  Easydict
//
//  Created by tisfeng on 2026/4/12.
//

import Foundation

// MARK: - AppleScriptExecutor

/// Executes business AppleScript through `NSAppleScript` and keeps that backend isolated from the
/// facade type. It centralizes timeout control, background execution, and `QueryError` mapping so
/// browser automation, system integrations, and Apple Translation fallback all share one runtime
/// behavior. This is the preferred AppleScript backend for production Easydict features.
struct AppleScriptExecutor {
    // MARK: Internal

    /// Runs an AppleScript string through the `NSAppleScript` backend.
    ///
    /// - Parameters:
    ///   - appleScript: The AppleScript source string to execute.
    ///   - timeout: Maximum execution time in seconds.
    /// - Returns: The script's optional string result.
    /// - Throws: `QueryError` when script creation, execution, or timeout handling fails.
    @discardableResult
    func run(_ appleScript: String, timeout: TimeInterval = 10) async throws -> String? {
        do {
            return try await Task.withTimeout(seconds: timeout) {
                try await executeOnBackgroundQueue(appleScript)
            }
        } catch is TaskTimeoutError {
            throw makeAppleScriptError(
                "AppleScript execution timed out after \(timeout) seconds",
                appleScript: appleScript
            )
        }
    }

    // MARK: Private

    /// Executes `NSAppleScript` on a background queue and returns the script string result.
    ///
    /// This backend intentionally runs work off the main thread to avoid blocking UI-sensitive
    /// AppleScript call sites such as browser text insertion and selection. Timeout remains
    /// best-effort only, because a running script cannot be interrupted once started.
    ///
    /// - Parameter appleScript: The AppleScript source string to execute.
    /// - Returns: The script's optional string result.
    /// - Throws: `QueryError` when script creation or execution fails.
    @discardableResult
    private func executeOnBackgroundQueue(_ appleScript: String) async throws -> String? {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global().async {
                guard let script = NSAppleScript(source: appleScript) else {
                    continuation.resume(
                        throwing: makeAppleScriptError(
                            "Failed to create AppleScript instance",
                            appleScript: appleScript
                        )
                    )
                    return
                }

                var errorInfo: NSDictionary?
                let output = script.executeAndReturnError(&errorInfo)

                if let errorInfo {
                    let errorMessage =
                        errorInfo[NSAppleScript.errorMessage] as? String ?? "Run AppleScript error"
                    continuation.resume(
                        throwing: makeAppleScriptError(errorMessage, appleScript: appleScript)
                    )
                    return
                }

                continuation.resume(returning: output.stringValue)
            }
        }
    }

    /// Creates a standardized AppleScript query error with the script content attached.
    ///
    /// - Parameters:
    ///   - message: The high-level failure reason.
    ///   - appleScript: The AppleScript source string that triggered the error.
    /// - Returns: A `QueryError` configured for AppleScript failures.
    private func makeAppleScriptError(_ message: String, appleScript: String) -> QueryError {
        .init(type: .appleScript, message: message, errorDataMessage: appleScript)
    }
}
