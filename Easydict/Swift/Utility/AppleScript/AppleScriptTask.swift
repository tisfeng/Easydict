//
//  AppleScriptTask.swift
//  Easydict
//
//  Created by tisfeng on 2024/9/8.
//

import Foundation

/// AppleScript to get all shortcuts, can be used to apply for automation permission.
let testShortcutScript = """
tell application "Shortcuts Events" to get the name of every shortcut
"""

// MARK: - AppleScriptTask

@objcMembers
class AppleScriptTask: NSObject {
    // MARK: Lifecycle

    init(script: String) {
        self.task = Process()
        self.outputPipe = Pipe()
        self.errorPipe = Pipe()

        task.standardOutput = outputPipe
        task.standardError = errorPipe
        task.arguments = ["-e", script]
        task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
    }

    // MARK: Internal

    let task: Process

    @discardableResult
    static func runShortcut(_ shortcutName: String, parameters: [String: String]) async throws
        -> String? {
        let appleScript = appleScript(of: shortcutName, parameters: parameters)
        return try await runAppleScriptWithProcess(appleScript)
    }

    @discardableResult
    static func runShortcut(_ shortcutName: String, inputText: String) async throws -> String? {
        let appleScript = appleScript(of: shortcutName, inputText: inputText)
        return try await runAppleScriptWithProcess(appleScript)
    }

    @discardableResult
    static func runAppleScriptWithProcess(_ appleScript: String) async throws -> String? {
        try await AppleScriptTask(script: appleScript).runAppleScriptWithProcess()
    }

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
    /// - Important: Apple documents `NSAppleScript` as a main-thread-only class, so execution is always
    ///   marshaled through `MainActor.run`. Reference:
    ///   https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Multithreading/ThreadSafetySummary/ThreadSafetySummary.html
    /// - Note: Timeout is best-effort only and cannot forcibly interrupt a running `NSAppleScript`.
    @discardableResult
    static func runAppleScript(_ appleScript: String, timeout: TimeInterval = 10) async throws
        -> String? {
        try await withThrowingTaskGroup(of: String?.self) { group in
            group.addTask {
                try await MainActor.run {
                    try runAppleScriptOnMainActor(appleScript)
                }
            }

            group.addTask {
                let timeoutInNanoseconds = UInt64(max(timeout, 0) * 1_000_000_000)
                try await Task.sleep(nanoseconds: timeoutInNanoseconds)
                throw makeAppleScriptError(
                    "AppleScript execution timed out after \(timeout) seconds",
                    appleScript: appleScript
                )
            }

            defer {
                group.cancelAll()
            }

            guard let result = try await group.next() else {
                throw makeAppleScriptError("AppleScript execution failed", appleScript: appleScript)
            }
            return result
        }
    }

    /// Run AppleScript with `Process`, slower than `NSAppleScript`
    func runAppleScriptWithProcess() async throws -> String? {
        try task.run()

        return try await withCheckedThrowingContinuation { continuation in
            task.terminationHandler = { _ in
                do {
                    let outputData = try self.outputPipe.fileHandleForReading.readToEnd()
                    let errorData = try self.errorPipe.fileHandleForReading.readToEnd()

                    if let error = errorData?.stringValue {
                        continuation.resume(
                            throwing: QueryError(type: .appleScript, message: error)
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

    func terminate() {
        task.terminate()
    }

    // MARK: Private

    private let outputPipe: Pipe
    private let errorPipe: Pipe

    /// Executes `NSAppleScript` on the main actor and returns the script string result.
    ///
    /// Apple lists `NSAppleScript` under Foundation classes that must be used only from the main thread.
    /// This helper centralizes that requirement for all `NSAppleScript` execution in the app.
    ///
    /// Reference:
    /// https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Multithreading/ThreadSafetySummary/ThreadSafetySummary.html
    @discardableResult
    @MainActor
    private static func runAppleScriptOnMainActor(_ appleScript: String) throws -> String? {
        guard let script = NSAppleScript(source: appleScript) else {
            throw makeAppleScriptError("Failed to create AppleScript instance", appleScript: appleScript)
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
    private static func makeAppleScriptError(_ message: String, appleScript: String) -> QueryError {
        .init(type: .appleScript, message: message, errorDataMessage: appleScript)
    }
}

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

func appleScript(of shortcutName: String, parameters: [String: Any]) -> String {
    let queryString = parameters.queryString
    return appleScript(of: shortcutName, inputText: queryString)
}
