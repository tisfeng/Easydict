//
//  AppleScriptTask+Browser.swift
//  Easydict
//
//  Created by tisfeng on 2024/9/11.
//  Copyright © 2024 izual. All rights reserved.
//

extension AppleScriptTask {
    // MARK: Internal

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
        if isSafari(bundleID) {
            try await getSelectedTextFromSafari()
        } else if isChromeKernelBrowser(bundleID) {
            try await getSelectedTextFromChromeBrowser(bundleID: bundleID)
        } else {
            nil
        }
    }

    class func getSelectedTextFromSafari() async throws -> String? {
        let script = """
        tell application id "com.apple.Safari"
            tell front window
                set selection_text to do JavaScript "window.getSelection().toString();" in current tab
            end tell
        end tell
        """

        let result = try await runAppleScript(script, timeout: 0.2)
        logInfo("Safari selected text: \(result ?? "")")
        return result
    }

    class func getSelectedTextFromChromeBrowser(bundleID: String) async throws -> String? {
        let script = """
        tell application id "\(bundleID)"
           tell active tab of front window
               set selection_text to execute javascript "window.getSelection().toString();"
           end tell
        end tell
        """

        // Generally, AppleScript cost < 0.2s to get the selected text.
        let result = try await runAppleScript(script, timeout: 0.2)
        logInfo("Chrome Browser selected text: \(result ?? "")")
        return result
    }

    class func getCurrentTabURLFromBrowser(_ bundleID: String) async throws -> String? {
        if isSafari(bundleID) {
            try await getCurrentTabURLFromSafari(bundleID: bundleID)
        } else if isChromeKernelBrowser(bundleID) {
            try await getCurrentTabURLFromChromeBrowser(bundleID: bundleID)
        } else {
            nil
        }
    }

    class func getCurrentTabURLFromChromeBrowser(bundleID: String) async throws -> String? {
        let script = """
        tell application id "\(bundleID)"
           set theUrl to URL of active tab of front window
        end tell
        """

        let result = try await runAppleScript(script)
        logInfo("Chrome current tab URL: \(result ?? "")")
        return result
    }

    class func getCurrentTabURLFromSafari(bundleID: String) async throws -> String? {
        let script = """
        tell application id "\(bundleID)"
           set theUrl to URL of front document
        end tell
        """

        let result = try await runAppleScript(script)
        logInfo("Safari current tab URL: \(result ?? "")")
        return result
    }

    class func replaceSelectedTextInBrowser(_ replacementString: String, bundleID: String) async throws -> String? {
        if isSafari(bundleID) {
            try await replaceSelectedTextInSafari(replacementString, bundleID: bundleID)
        } else if isChromeKernelBrowser(bundleID) {
            try await replaceSelectedTextInChromeBrowser(replacementString, bundleID: bundleID)
        } else {
            nil
        }
    }

    class func replaceSelectedTextInSafari(_ selectedText: String, bundleID: String) async throws -> String? {
        let script = """
        tell application id "\(bundleID)"
             do JavaScript "document.execCommand('insertText', false, '\(selectedText)')" in document 1
        end tell
        """

        let result = try await runAppleScript(script)
        logInfo("Safari replace selected text result: \(result ?? "")")
        return result
    }

    class func replaceSelectedTextInChromeBrowser(_ selectedText: String, bundleID: String) async throws -> String? {
        let script = """
        tell application id "\(bundleID)"
           tell active tab of front window
               execute javascript "document.execCommand('insertText', false, '\(selectedText)')"
           end tell
        end tell
        """

        let result = try await runAppleScript(script)
        logInfo("Chrome replace selected text result: \(result ?? "")")
        return result
    }

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
