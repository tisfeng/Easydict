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
            of: Constants.easydictTranslateShortcutName, parameters: parameters
        )
        return try await runAppleScript(appleScript)
    }

    @discardableResult
    static func runAppleScript(_ appleScript: String, timeout: TimeInterval = 10) async throws -> String? {
        try await Task { () -> String? in
            try runAppleScript(appleScript, timeout: timeout)
        }.value
    }

    /// Run AppleScript with timeout control
    /// - Parameters:
    ///   - appleScript: The AppleScript to execute
    ///   - timeout: Maximum execution time in seconds, defaults to 10
    /// - Returns: Optional string result from the AppleScript execution
    /// - Throws: QueryError if execution fails or times out
    @discardableResult
    static func runAppleScript(_ appleScript: String, timeout: TimeInterval = 10) throws -> String? {
        func makeError(_ message: String) -> QueryError {
            .init(type: .appleScript, message: message, errorDataMessage: appleScript)
        }

        guard let script = NSAppleScript(source: appleScript) else {
            throw makeError("Failed to create AppleScript instance")
        }

        var errorInfo: NSDictionary?

        // Create semaphore for timeout control
        let semaphore = DispatchSemaphore(value: 0)
        var result: String?
        var executionError: Error?

        // Execute AppleScript in background queue
        DispatchQueue.global().async {
            let output = script.executeAndReturnError(&errorInfo)
            if let errorInfo {
                let message = errorInfo[NSAppleScript.errorMessage] as? String ?? "Run AppleScript error"
                executionError = makeError(message)
            } else {
                result = output.stringValue
            }
            semaphore.signal()
        }

        // Wait for completion or timeout
        let timeoutResult = semaphore.wait(timeout: .now() + timeout)
        if timeoutResult == .timedOut {
            throw makeError("AppleScript execution timed out after \(timeout) seconds")
        }

        if let error = executionError {
            throw error
        }

        return result
    }

    /// Run AppleScript with `NSAppleScript`, faster than `Process`, but requires AppleEvent permission.
    @discardableResult
    static func runAppleScriptWithDescriptor(_ appleScript: String) async throws
        -> NSAppleEventDescriptor {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global().async {
                let appleScript = NSAppleScript(source: appleScript)
                var errorInfo: NSDictionary?
                let output = appleScript?.executeAndReturnError(&errorInfo)

                guard let output, errorInfo == nil else {
                    let errorMessage =
                        errorInfo?[NSAppleScript.errorMessage] as? String ?? "Run AppleScript error"
                    continuation.resume(
                        throwing: QueryError(type: .appleScript, message: errorMessage)
                    )
                    return
                }
                continuation.resume(returning: output)
            }
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
}

// MARK: - AppleScriptError

// enum AppleScriptError: Error {
//    case executionError(message: String, code: Int = 1)
// }

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
