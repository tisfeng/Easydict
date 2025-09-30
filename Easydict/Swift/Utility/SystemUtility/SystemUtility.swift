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
    func selectAll(using strategies: [TextStrategy]) async {
        logInfo("Select all using operation set: \(strategies)")

        func selectAllInNonBrowser() async {
            if strategies.contains(.menuAction) {
                await selectAllByMenuAction()
            } else if strategies.contains(.shortcut) {
                await selectAllByShortcut()
            } else if strategies.contains(.accessibility) {
                selectAllByAX()
            }
        }

        if strategies.contains(.appleScript) {
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
    ///   - strategies: The text strategies to use, in order of preference
    ///
    /// - Important: This function may be called many times in streaming mode,
    ///              so we pass the strategies array each time to avoid recomputation.
    func insertText(_ text: String, using strategies: [TextStrategy]) async {
        func insertTextInNonBrowser() async {
            if strategies.contains(.menuAction) {
                await insertTextByMenuAction(text)
            } else if strategies.contains(.shortcut) {
                await insertTextByShortcut(text)
            } else if strategies.contains(.accessibility) {
                insertTextByAX(text)
            }
        }

        if strategies.contains(.appleScript) {
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
            let selectedRange = try element.selectedTextRange()
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

    /// Get text strategies based on user preferences and system capabilities
    func textStrategies(
        shouldUseAppleScript: Bool,
        enableCompatibilityMode: Bool,
        isSupportedAX: Bool
    )
        -> [TextStrategy] {
        var strategies: [TextStrategy] = []
        if shouldUseAppleScript {
            strategies.append(.appleScript)
        }
        if isSupportedAX {
            strategies.append(.accessibility)
        }
        if enableCompatibilityMode {
            strategies.append(.menuAction)
            strategies.append(.shortcut)
        }
        return strategies
    }
}
