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

    /// Bundle identifiers of apps that should use the "Paste menu item enabled" heuristic
    /// when the focused text field element cannot be reliably determined via Accessibility APIs.
    var bundleIDAllowListForPasteMenuCheck: Set<String> = [AppBundleIDs.weChat]

    /// Get selected text from current focused application.
    ///
    /// - Note: Just a wrapper of EZEventMonitor's getSelectedText method.
    func getSelectedText() async -> String? {
        await EventMonitor.shared.getSelectedText()
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

    /// Get text strategies for current focused element
    func textStrategies(enableSelectAll: Bool = false) async -> [TextStrategy] {
        let elementInfo = await focusedElementInfo(enableSelectAll: enableSelectAll)
        return textStrategies(for: elementInfo)
    }

    /// Determine the appropriate text strategy set based on the focused element info and user settings
    func textStrategies(for elementInfo: FocusedElementInfo) -> [TextStrategy] {
        let isSupportedAX = elementInfo.isSupportedAXElement
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

    // MARK: - Focused Element Info

    func focusedElementInfo(enableSelectAll: Bool = false) async -> FocusedElementInfo {
        var elementInfo = await fetchFocusedElementInfo()
        logInfo("Focused Element Info: \(elementInfo)")

        let selectedText = elementInfo.selectedText ?? ""

        // Only auto-select all text option when enabled and no selected text
        if enableSelectAll, selectedText.isEmpty {
            elementInfo = await processAutoAllTextSelection(for: elementInfo)
            logInfo("Element Info after Auto-Selection: \(elementInfo)")
        }
        return elementInfo
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

    /// Fetch comprehensive information from current focused element
    ///
    /// - Returns: FocusedElementInfo containing text, range, and selected text. Returns empty info when unavailable.
    private func fetchFocusedElementInfo() async -> FocusedElementInfo {
        do {
            guard let element = try frontmostAppElement?.focusedUIElement() else {
                logInfo("No focused UI element found: \(String(describing: frontmostAppElement))")
                return .empty
            }

            let roleValue = try? element.roleValue()
            let fullText: String? = try? element.value()
            let selectedRange: CFRange? = try? element.selectedTextRange()
            let selectedText = await getSelectedText()

            return FocusedElementInfo(
                fullText: fullText,
                selectedRange: selectedRange,
                selectedText: selectedText,
                roleValue: roleValue
            )
        } catch {
            logError("Error getting focused UI element info: \(error)")
            return .empty
        }
    }

    /// Process automatic all text selection based on user settings and return updated element info
    ///
    /// - Parameter elementInfo: Information about the current focused element
    /// - Returns: Updated FocusedElementInfo after processing auto-selection.
    private func processAutoAllTextSelection(for elementInfo: FocusedElementInfo) async
        -> FocusedElementInfo {
        guard elementInfo.isTextField else {
            return elementInfo
        }

        let textStrategy = textStrategies(for: elementInfo)
        await selectAll(using: textStrategy)

        logInfo("Auto-selected all text content in field")

        return await fetchFocusedElementInfo()
    }
}
