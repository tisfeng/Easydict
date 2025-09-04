//
//  SystemUtility+AppleScript.swift
//  Easydict
//
//  Created by tisfeng on 2025/9/2.
//  Copyright © 2025 izual. All rights reserved.
//

import Defaults

/// Frontmost application bundle identifier
var frontmostAppBundleID: String {
    NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? ""
}

extension SystemUtility {
    /// Select all text using AppleScript in browser
    func selectAllByAppleScript() async throws {
        logInfo("Select all text using AppleScript")

        // Try to select all text
        let success = try await AppleScriptTask.selectAllInputTextInBrowser(frontmostAppBundleID)
        if !success {
            throw QueryError(type: .appleScript, message: "Failed to select all text using AppleScript")
        }
    }

    /// Insert text using AppleScript in browser
    func insertTextByAppleScript(_ text: String) async throws {
        let success = try await AppleScriptTask.insertTextInBrowser(text, bundleID: frontmostAppBundleID)
        if !success {
            throw QueryError(type: .appleScript, message: "Failed to insert text using AppleScript")
        }
    }
}
