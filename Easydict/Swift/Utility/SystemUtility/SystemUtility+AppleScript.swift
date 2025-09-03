//
//  SystemUtility+AppleScript.swift
//  Easydict
//
//  Created by tisfeng on 2025/9/2.
//  Copyright © 2025 izual. All rights reserved.
//

import Defaults
import Foundation

extension SystemUtility {
    var frontmostAppBundleID: String {
        NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? ""
    }

    var shouldUseAppleScript: Bool {
        let isBrowser = AppleScriptTask.isBrowserSupportingAppleScript(frontmostAppBundleID)
        return isBrowser && Defaults[.preferAppleScriptAPI]
    }

    /// Select all text using AppleScript in browser
    func selectAllByAppleScript() async {
        logInfo("Select all text using AppleScript")

        do {
            // Try to select all text
            let success = try await AppleScriptTask.selectAllInputTextInBrowser(frontmostAppBundleID)
            if !success {
                logInfo("Failed to select all text using AppleScript")
            }
        } catch {
            logError("Error selecting all text using AppleScript: \(error)")
        }
    }

    /// Insert text using AppleScript in browser
    func insertTextByAppleScript(_ text: String) async {
        do {
            let success = try await AppleScriptTask.insertTextInBrowser(text, bundleID: frontmostAppBundleID)
            if !success {
                logInfo("Failed to insert text using AppleScript")
            }
        } catch {
            logError("Error inserting text using AppleScript: \(error)")
        }
    }
}
