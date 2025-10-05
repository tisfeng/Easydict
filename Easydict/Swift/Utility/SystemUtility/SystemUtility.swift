//
//  SystemUtility.swift
//  Easydict
//
//  Created by tisfeng on 2025/8/30.
//  Copyright © 2025 izual. All rights reserved.
//

import Defaults
import Foundation
import SelectedTextKit

// MARK: - SystemUtility

@objc(EZSystemUtility)
class SystemUtility: NSObject {
    // MARK: Internal

    @objc static let shared = SystemUtility()

    let axManager = AXManager.shared
    let pasteboardManager = PasteboardManager.shared
    let selectedTextManager = SelectedTextManager.shared

    /// Get selected text from current focused application.
    ///
    /// - Note: Just a wrapper of EZEventMonitor's getSelectedText method.
    func getSelectedText() async -> String? {
        await EZEventMonitor.shared().getSelectedText()
    }

    /// Select all text using the specified operation set.
    ///
    /// TODO: Refactor the nested function to avoid code duplication with insertText
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

    /// Insert text into the currently focused text field.
    ///
    /// - Note: This method determines the best strategy to use based on the current context
    ///         and user preferences. It may use AppleScript, Accessibility APIs, menu actions,
    ///         or keyboard shortcuts as needed.
    @objc
    func insertText(_ text: String) async {
        let strategies = await textStrategies()
        await insertText(text, using: strategies)
    }

    // MARK: - Text Strategies

    /// Get text strategies for current focused TextField element
    func textStrategies(enableSelectAll: Bool = false) async -> [TextStrategy] {
        guard let textFieldInfo = await focusedTextFieldInfo(enableSelectAll: enableSelectAll) else {
            return []
        }

        return textStrategies(for: textFieldInfo)
    }

    /// Determine the appropriate text strategy set based on the text field info and user settings
    func textStrategies(for textFieldInfo: TextFieldInfo) -> [TextStrategy] {
        let isSupportedAX = textFieldInfo.isSupportedAXElement
        let enableCompatibilityMode = Defaults[.enableCompatibilityReplace]

        let isBrowser = AppleScriptTask.isBrowserSupportingAppleScript(frontmostAppBundleID)
        let preferAppleScriptAPI = Defaults[.preferAppleScriptAPI]
        let shouldUseAppleScript = isBrowser && preferAppleScriptAPI

        return textStrategies(
            shouldUseAppleScript: shouldUseAppleScript,
            enableCompatibilityMode: enableCompatibilityMode,
            isSupportedAX: isSupportedAX
        )
    }

    // MARK: - Focused Text Field Info

    func focusedTextFieldInfo(enableSelectAll: Bool = false) async -> TextFieldInfo? {
        guard var textFieldInfo = await fetchFocusedTextFieldInfo() else {
            return nil
        }
        logInfo("Focused Text Field Info: \(textFieldInfo)")

        if enableSelectAll {
            // Process auto-selection and get updated text field info
            guard let newInfo = await processAutoAllTextSelection(for: textFieldInfo) else {
                return nil
            }
            textFieldInfo = newInfo
            logInfo("Text Field Info after Auto-Selection: \(textFieldInfo)")
        }
        return textFieldInfo
    }

    // MARK: Private

    /// Get text strategies based on user preferences and system capabilities
    private func textStrategies(
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

    /// Fetch comprehensive information from current focused text field
    ///
    /// - Returns: TextFieldInfo containing text, range, and selected text
    private func fetchFocusedTextFieldInfo() async -> TextFieldInfo? {
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

    /// Process automatic all text selection based on user settings and return updated text field info
    ///
    /// - Parameter textFieldInfo: Information about the current text field
    /// - Returns: Updated TextFieldInfo after processing auto-selection, or nil if processing fails
    private func processAutoAllTextSelection(for textFieldInfo: TextFieldInfo) async -> TextFieldInfo? {
        let autoSelectEnabled = Defaults[.autoSelectAllTextFieldText]
        let selectedText = textFieldInfo.selectedText?.trim() ?? ""

        guard autoSelectEnabled, selectedText.isEmpty else {
            return textFieldInfo
        }

        let textStrategy = textStrategies(for: textFieldInfo)
        await selectAll(using: textStrategy)

        logInfo("Auto-selected all text content in field")

        return await fetchFocusedTextFieldInfo()
    }
}
