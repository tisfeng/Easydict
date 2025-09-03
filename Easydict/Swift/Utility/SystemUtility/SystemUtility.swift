//
//  SystemUtility.swift
//  Easydict
//
//  Created by tisfeng on 2025/8/30.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

// MARK: - SystemUtility

@objc(EZSystemUtility)
class SystemUtility: NSObject {
    @objc static let shared = SystemUtility()

    func getSelectedText() async -> String? {
        await EZEventMonitor.shared().getSelectedText()
    }

    /// Select all text in the currently focused text field.
    func selectAll() async {
        if shouldUseAppleScript {
            await selectAllByAppleScript()
        } else if isSupportedAX {
            selectAllByAX()
        } else {
            // Fallback to hotkey
            await selectAllByShortcut()
        }
    }

    /// Insert text into the currently focused text field.
    ///
    /// - Important: This function may be called many times in streaming mode,
    /// check `shouldUseAppleScript` and `isSupportedAX` cost time, so we pass it as parameter.
    ///
    /// - Note: This function checks if the current application is a supported browser and uses AppleScript if so.
    ///         If not, it checks if the Accessibility API can be used.
    ///         If neither method is available, it falls back to using hotkeys and clipboard.
    func insertText(
        _ text: String,
        shouldUseAppleScript: Bool,
        isSupportedAX: Bool
    ) async {
        if shouldUseAppleScript {
            // Use browser-specific AppleScript
            await insertTextByAppleScript(text)
        } else if isSupportedAX {
            // Use Accessibility API
            insertTextByAX(text)
        } else {
            // We protect the clipboard content manually before and after streaming insert text
            // because the insertTextByHotkey may be called many times in streaming mode.
            await insertTextByShortcut(text, preservePasteboard: false)
        }
    }

    /// Get comprehensive information from current focused text field
    ///
    /// - Returns: TextFieldInfo containing text, range, and selected text
    func getFocusedTextFieldInfo() async -> TextFieldInfo? {
        do {
            // 1. Ensure focused element is a text field
            guard let element = try focusedTextFieldElement() else {
                logInfo("Current focused element is not a text field")
                return nil
            }

            // 2. Get full text from the text field
            guard let fullText = try element.value() else {
                logInfo("Failed to get text from focused element")
                return nil
            }

            // 3. Try to get selected text and range
            let selectedRange = try element.selectedRange()
            let selectedText = await getSelectedText()
            let roleValue = try element.roleValue() ?? "unknown"

            return TextFieldInfo(
                fullText: fullText,
                selectedRange: selectedRange,
                selectedText: selectedText,
                roleValue: roleValue
            )
        } catch {
            logError("Error getting focused text field info: \(error)")
            return nil
        }
    }
}
