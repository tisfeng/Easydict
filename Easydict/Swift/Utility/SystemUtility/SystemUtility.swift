//
//  SystemUtility.swift
//  Easydict
//
//  Created by tisfeng on 2025/8/30.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation
import SelectedTextKit

// MARK: - SystemUtility

@objc(EZSystemUtility)
class SystemUtility: NSObject {
    @objc static let shared = SystemUtility()

    let axManager = AXManager.shared
    let pasteboardManager = PasteboardManager.shared
    let selectedTextManager = SelectedTextManager.shared

    /// Get selected text from current focused application
    /// Just a wrapper of EZEventMonitor method
    func getSelectedText() async -> String? {
        await EZEventMonitor.shared().getSelectedText()
    }

    /// Select all text using the specified operation set.
    func selectAll(using operationSet: TextStrategySet) async {
        logInfo("Select all using operation set: \(operationSet)")

        func selectAllInNonBrowser() async {
            if operationSet.contains(.menuAction) {
                await selectAllByMenuAction()
            } else if operationSet.contains(.shortcut) {
                await selectAllByShortcut()
            } else if operationSet.contains(.accessibility) {
                selectAllByAX()
            }
        }

        if operationSet.contains(.appleScript) {
            do {
                try await selectAllByAppleScript()
            } catch {
                logError("Select all by AppleScript failed: \(error), fallback to other methods")
                await selectAllInNonBrowser()
            }
        } else {
            await selectAllInNonBrowser()
        }
    }

    /// Insert text using the specified operation set.
    ///
    /// - Parameters:
    ///   - text: The text to insert
    ///   - operationSet: The set of available operation types, will use the highest priority one
    ///
    /// - Important: This function may be called many times in streaming mode,
    ///              so we pass the operation set as parameter to avoid repeated checks.
    func insertText(_ text: String, using operationSet: TextStrategySet) async {
        func insertTextInNonBrowser() async {
            if operationSet.contains(.menuAction) {
                await insertTextByMenuAction(text)
            } else if operationSet.contains(.shortcut) {
                await insertTextByShortcut(text)
            } else if operationSet.contains(.accessibility) {
                insertTextByAX(text)
            }
        }

        if operationSet.contains(.appleScript) {
            do {
                try await insertTextByAppleScript(text)
            } catch {
                logError("Insert text by AppleScript failed: \(error), fallback to other methods")
                await insertTextInNonBrowser()
            }
        } else {
            await insertTextInNonBrowser()
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

    /// Get text strategy set based on current application context
    func textStrategySet(
        shouldUseAppleScript: Bool,
        enableCompatibilityMode: Bool,
        isSupportedAX: Bool
    )
        -> TextStrategySet {
        var operationSet: TextStrategySet = []
        if isSupportedAX {
            operationSet.insert(.accessibility)
        }
        if enableCompatibilityMode {
            operationSet.insert(.menuAction)
            operationSet.insert(.shortcut)
        }
        if shouldUseAppleScript {
            operationSet.insert(.appleScript)
        }
        return operationSet
    }
}
