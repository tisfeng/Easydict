//
//  AppleScriptTask.swift
//  Easydict
//
//  Created by tisfeng on 2024/9/8.
//

import Foundation

// MARK: - AppleScriptTask

/// Provides the app-facing AppleScript facade used by browser automation, system integrations,
/// and Apple Translation fallback. Business code depends on this type instead of selecting an
/// execution backend directly, so the preferred `NSAppleScript` path stays centralized while still
/// avoiding UI-thread blocking. The same facade is also bridged into Objective-C through Swift async
/// completion-handler generation.
@objcMembers
class AppleScriptTask: NSObject {
    /// Runs the Apple Translation shortcut through the unified `NSAppleScript` backend.
    ///
    /// The script template targets `Shortcuts Events`, but execution still goes through the
    /// shared business runner so Objective-C and Swift callers observe the same timeout and
    /// error behavior.
    ///
    /// - Parameter parameters: Shortcut input parameters encoded as key-value pairs.
    /// - Returns: The translated text returned by the shortcut, if any.
    /// - Throws: `QueryError` when script execution fails.
    static func runTranslateShortcut(parameters: [String: String]) async throws -> String? {
        let appleScript = appleScript(
            of: SharedConstants.easydictTranslateShortcutName, parameters: parameters
        )
        return try await runAppleScript(appleScript)
    }

    /// Run AppleScript with timeout control
    /// - Parameters:
    ///   - appleScript: The AppleScript to execute
    ///   - timeout: Maximum execution time in seconds, defaults to 10
    /// - Returns: Optional string result from the AppleScript execution
    /// - Throws: QueryError if execution fails or times out
    /// - Note: Execution is dispatched to a background queue so AppleScript work does not occupy the
    ///   UI thread. Timeout is best-effort only and cannot forcibly interrupt a running script.
    @discardableResult
    static func runAppleScript(_ appleScript: String, timeout: TimeInterval = 10) async throws
        -> String? {
        try await AppleScriptExecutor().run(appleScript, timeout: timeout)
    }
}

/// Builds the `Shortcuts Events` AppleScript used to run a shortcut with plain-text input.
///
/// - Parameters:
///   - shortcutName: The shortcut name exposed by the Shortcuts app.
///   - inputText: The raw text passed into the shortcut.
/// - Returns: A complete AppleScript source string for `Shortcuts Events`.
func appleScript(of shortcutName: String, inputText: String) -> String {
    // inputText may contain ", we need to escape it
    let escapedInputText = inputText.replacingOccurrences(of: "\"", with: "\\\"")

    let appleScript = """
    tell application "Shortcuts Events"
        run the shortcut named "\(shortcutName)" with input "\(escapedInputText)"
    end tell
    """

    return appleScript
}

/// Builds the `Shortcuts Events` AppleScript used to run a shortcut from query parameters.
///
/// - Parameters:
///   - shortcutName: The shortcut name exposed by the Shortcuts app.
///   - parameters: Shortcut input values that will be encoded into the query string format.
/// - Returns: A complete AppleScript source string for `Shortcuts Events`.
func appleScript(of shortcutName: String, parameters: [String: Any]) -> String {
    let queryString = parameters.queryString
    return appleScript(of: shortcutName, inputText: queryString)
}
