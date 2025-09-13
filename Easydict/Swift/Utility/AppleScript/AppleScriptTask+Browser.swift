//
//  AppleScriptTask+Browser.swift
//  Easydict
//
//  Created by tisfeng on 2024/9/11.
//  Copyright © 2024 izual. All rights reserved.
//

extension AppleScriptTask {
    // MARK: Internal

    /// Browser action types for better abstraction
    enum BrowserAction {
        case getCurrentTabURL
        case getSelectedText
        case getTextFieldText
        case insertText(String)
        case selectAllText
    }

    class func isBrowserSupportingAppleScript(_ bundleID: String) -> Bool {
        browsersSupportingAppleScript.contains(bundleID)
    }

    class func isSafari(_ bundleID: String) -> Bool {
        bundleID == "com.apple.Safari"
    }

    class func isChromeKernelBrowser(_ bundleID: String) -> Bool {
        chromeKernelBrowsers.contains(bundleID)
    }

    class func getSelectedTextFromBrowser(_ bundleID: String) async throws -> String? {
        try await executeBrowserAction(.getSelectedText, bundleID: bundleID)
    }

    class func getCurrentTabURLFromBrowser(_ bundleID: String) async throws -> String? {
        try await executeBrowserAction(.getCurrentTabURL, bundleID: bundleID)
    }

    class func insertTextInBrowser(_ text: String, bundleID: String) async throws -> Bool {
        do {
            let result = try await executeBrowserAction(.insertText(text), bundleID: bundleID) ?? ""
            return result.boolValue
        } catch {
            logInfo("Failed to insert text in browser: \(error)")
            return false
        }
    }

    class func selectAllInputTextInBrowser(_ bundleID: String) async throws -> Bool {
        do {
            let result = try await executeBrowserAction(.selectAllText, bundleID: bundleID) ?? ""
            return result.boolValue
        } catch {
            logInfo("Failed to select all text in browser: \(error)")
            return false
        }
    }

    // MARK: Private

    /// Generic browser action executor that handles Safari and Chrome differences
    private class func executeBrowserAction(_ action: BrowserAction, bundleID: String) async throws
        -> String? {
        guard isBrowserSupportingAppleScript(bundleID) else { return nil }

        let script: String
        let timeout: TimeInterval?
        let logMessage: String

        if isSafari(bundleID) {
            (script, timeout, logMessage) = safariScriptFor(action: action, bundleID: bundleID)
        } else if isChromeKernelBrowser(bundleID) {
            (script, timeout, logMessage) = chromeScriptFor(action: action, bundleID: bundleID)
        } else {
            return nil
        }

        let result = try await asyncRunAppleScript(script, timeout: timeout ?? 5.0)
        logInfo("\(logMessage): \(result ?? "")")
        return result
    }

    // MARK: - Chrome AppleScript

    /// Generate Chrome-specific AppleScript for different actions
    private class func chromeScriptFor(action: BrowserAction, bundleID: String) -> (
        script: String, timeout: TimeInterval?, logMessage: String
    ) {
        switch action {
        case .getCurrentTabURL:
            let script = """
            tell application id "\(bundleID)"
               set theUrl to URL of active tab of front window
            end tell
            """
            return (script, nil, "Chrome current tab URL")

        case .getSelectedText:
            let script = """
            tell application id "\(bundleID)"
               tell active tab of front window
                   set selection_text to execute javascript "window.getSelection().toString();"
               end tell
            end tell
            """
            return (script, 0.2, "Chrome Browser selected text")

        case .getTextFieldText:
            let script = """
            tell application id "\(bundleID)"
                tell active tab of front window
                    set inputText to execute javascript "
                        \(getTextFieldTextScript())
                    "
                end tell
            end tell
            """
            return (script, 0.2, "Chrome Browser text field text")

        case let .insertText(text):
            let script = """
            tell application id "\(bundleID)"
               tell active tab of front window
                    execute javascript "document.execCommand('insertText', false, '\(text)')"
               end tell
            end tell
            """
            return (script, nil, "Chrome insert text result")

        case .selectAllText:
            let script = """
            tell application id "\(bundleID)"
               tell active tab of front window
                   execute javascript "
                       \(getSelectAllInputTextScript())
                   "
               end tell
            end tell
            """
            return (script, nil, "Chrome select all text result")
        }
    }

    // MARK: - Safari AppleScript

    /// Generate Safari-specific AppleScript for different actions
    private class func safariScriptFor(action: BrowserAction, bundleID: String) -> (
        script: String, timeout: TimeInterval?, logMessage: String
    ) {
        switch action {
        case .getCurrentTabURL:
            let script = """
            tell application id "\(bundleID)"
               set theUrl to URL of front document
            end tell
            """
            return (script, nil, "Safari current tab URL")

        case .getSelectedText:
            let script = """
            tell application id "\(bundleID)"
                tell front window
                    set selection_text to do JavaScript "window.getSelection().toString();" in current tab
                end tell
            end tell
            """
            return (script, 0.2, "Safari selected text")

        case .getTextFieldText:
            let script = """
            tell application id "\(bundleID)"
                do JavaScript "
                    \(getTextFieldTextScript())
                " in document 1
            end tell
            """
            return (script, 0.2, "Safari text field text")

        case let .insertText(text):
            let script = """
            tell application id "\(bundleID)"
                do JavaScript "document.execCommand('insertText', false, '\(text)')" in document 1
            end tell
            """
            return (script, nil, "Safari insert text result")

        case .selectAllText:
            let script = """
            tell application id "\(bundleID)"
                do JavaScript "
                    \(getSelectAllInputTextScript())
                " in document 1
            end tell
            """
            return (script, nil, "Safari select all text result")
        }
    }

    private class func getTextFieldTextScript() -> String {
        """
        (function() {
            var el = document.activeElement;
            if (!el) return '';
            if (el.tagName === 'INPUT' || el.tagName === 'TEXTAREA') {
                return el.value;
            }
            if (el.isContentEditable) {
                return el.innerText || el.textContent || '';
            }
            return '';
        })();
        """
    }

    /// Modern implementation for selecting all text in the focused element
    private class func getSelectAllInputTextScript() -> String {
        """
        (function() {
            const activeElement = document.activeElement;

            if (!activeElement) {
                console.log('No active element found');
                return false;
            }

            // For input and textarea elements
            if (activeElement.tagName === 'INPUT' || activeElement.tagName === 'TEXTAREA') {
                activeElement.select();
                return true;
            }

            // For contentEditable elements
            if (activeElement.isContentEditable) {
                const range = document.createRange();
                range.selectNodeContents(activeElement);

                const selection = window.getSelection();
                selection.removeAllRanges();
                selection.addRange(range);

                return true;
            }

            console.log('Active element is neither input, textarea, nor contentEditable');
            return false;
        })();
        """
    }

    // MARK: - Static Data

    private static let chromeKernelBrowsers = [
        "com.google.Chrome",
        "com.microsoft.edgemac",
    ]

    static let browsersSupportingAppleScript = [
        "com.apple.Safari",
        "com.google.Chrome",
        "com.microsoft.edgemac",
    ]
}
