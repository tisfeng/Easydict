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
            let errorMessage = "Failed to select all text using AppleScript in app: \(frontmostAppBundleID)"
            logError(errorMessage)
            throw QueryError(type: .appleScript, message: errorMessage)
        }
    }

    /// Insert text using AppleScript in the browser captured when the action began.
    func insertTextByAppleScript(
        _ text: String,
        bundleID: String,
        expectedTabURL: String
    ) async throws {
        let result = try await AppleScriptTask.insertTextInBrowser(
            text,
            bundleID: bundleID,
            expectedTabURL: expectedTabURL
        )
        switch result {
        case .inserted:
            return
        case .contextChanged:
            throw TextInsertionError.targetChanged
        case .rejected:
            let errorMessage = "Failed to insert text using AppleScript in app: \(bundleID)"
            logError("Text insertion failed strategy=apple_script category=api_rejected")
            throw QueryError(type: .appleScript, message: errorMessage)
        }
    }
}
