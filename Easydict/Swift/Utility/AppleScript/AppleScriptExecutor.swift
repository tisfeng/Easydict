//
//  AppleScriptExecutor.swift
//  Easydict
//
//  Created by tisfeng on 2026/4/12.
//

import Foundation

// MARK: - AppleScriptExecutor

/// Executes business AppleScript through `NSAppleScript` and keeps that backend isolated from the
/// facade type. It centralizes timeout control, main-thread execution, and `QueryError` mapping so
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
                try await MainActor.run {
                    try executeOnMainActor(appleScript)
                }
            }
        } catch is TaskTimeoutError {
            throw makeAppleScriptError(
                "AppleScript execution timed out after \(timeout) seconds",
                appleScript: appleScript
            )
        }
    }

    // MARK: Private

    /// Executes `NSAppleScript` on the main actor and returns the script string result.
    ///
    /// Apple lists `NSAppleScript` under Foundation classes that must be used only from the main
    /// thread. This helper keeps the main-thread requirement local to the `NSAppleScript` backend.
    ///
    /// - Parameter appleScript: The AppleScript source string to execute.
    /// - Returns: The script's optional string result.
    /// - Throws: `QueryError` when script creation or execution fails.
    @discardableResult
    @MainActor
    private func executeOnMainActor(_ appleScript: String) throws -> String? {
        guard let script = NSAppleScript(source: appleScript) else {
            throw makeAppleScriptError(
                "Failed to create AppleScript instance",
                appleScript: appleScript
            )
        }

        var errorInfo: NSDictionary?
        let output = script.executeAndReturnError(&errorInfo)

        guard errorInfo == nil else {
            let errorMessage =
                errorInfo?[NSAppleScript.errorMessage] as? String ?? "Run AppleScript error"
            throw makeAppleScriptError(errorMessage, appleScript: appleScript)
        }

        return output.stringValue
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
