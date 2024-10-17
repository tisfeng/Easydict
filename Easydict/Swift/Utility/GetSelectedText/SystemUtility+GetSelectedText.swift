//
//  GetSelectedText.swift
//  Easydict
//
//  Created by tisfeng on 2024/10/3.
//  Copyright © 2024 izual. All rights reserved.
//

import AXSwift
import Cocoa

extension SystemUtility {
    // MARK: Internal

    /// 1. Get selected text, try to get text by AXUI first.
    /// 2. If failed, try to get text by menu action copy.
    /// 3. if failed, try to get text by shortcut copy.
    static func getSelectedText() -> String? {
        logInfo("Attempting to get selected text")

        // Try AXUI method first
        switch getSelectedTextByAXUI() {
        case let .success(text):
            logInfo("Successfully got text via AXUI")
            return text
        case let .failure(error):
            logError("Failed to get text via AXUI: \(error)")

            // If AXUI fails, try menu action copy
            if let menuCopyText = getSelectedTextByMenuBarActionCopy() {
                logInfo("Successfully got text via menu action copy")
                return menuCopyText
            }

            logError("Failed to get text via menu action copy")

            // If menu action copy fails, try shortcut copy
            if let shortcutCopyText = getSelectedTextByShortcutCopy() {
                logInfo("Successfully got text via shortcut copy")
                return shortcutCopyText
            }

            logError("Failed to get text via shortcut copy")
        }

        logError("All methods to get selected text have failed")
        return nil
    }

    /// Get selected text by AXUI
    static func getSelectedTextByAXUI() -> Result<String, AXError> {
        logInfo("Getting selected text via AXUI")

        let systemWideElement = AXUIElementCreateSystemWide()
        var focusedElementRef: CFTypeRef?

        // Get the currently focused element
        let focusedElementResult = AXUIElementCopyAttributeValue(
            systemWideElement,
            kAXFocusedUIElementAttribute as CFString,
            &focusedElementRef
        )

        guard focusedElementResult == .success,
              let focusedElement = focusedElementRef as! AXUIElement?
        else {
            logError("Failed to get focused element")
            return .failure(focusedElementResult)
        }

        var selectedTextValue: CFTypeRef?

        // Get the selected text
        let selectedTextResult = AXUIElementCopyAttributeValue(
            focusedElement,
            kAXSelectedTextAttribute as CFString,
            &selectedTextValue
        )

        guard selectedTextResult == .success else {
            logError("Failed to get selected text")
            return .failure(selectedTextResult)
        }

        guard let selectedText = selectedTextValue as? String else {
            logError("Selected text is not a string")
            return .failure(.noValue)
        }

        logInfo("Selected text via AXUI: \(selectedText)")
        return .success(selectedText)
    }

    /// Get selected text by menu bar action copy.
    ///
    /// Refer to Copi  https://github.com/s1ntoneli/Copi/blob/531a12fdc2da66c809951926ce88af02593e0723/Copi/Utilities/SystemUtilities.swift#L257
    static func getSelectedTextByMenuBarActionCopy() -> String? {
        logInfo("Getting selected text by menu bar action copy")

        guard let copyItem = findEnabledCopyItemInFrontmostApp() else {
            return nil
        }

        let selectedText = getSelectedTextWithAction {
            try copyItem.performAction(.press)
        }

        logInfo("Menu bar action copy got selected text: \(selectedText ?? "nil")")

        return selectedText
    }

    /// Get selected text by shortcut copy.
    static func getSelectedTextByShortcutCopy() -> String? {
        logInfo("Getting selected text by shortcut copy")

        let selectedText = getSelectedTextWithAction {
            postCopyEvent()
        }

        logInfo("Shortcut copy got selected text: \(selectedText ?? "nil")")

        return selectedText
    }

    static func getSelectedTextWithAction(
        action: @escaping () throws -> ()
    )
        -> String? {
        var selectedText: String?
        monitorPasteboardContentChange(
            triggerAction: {
                try action()
            },
            onPasteboardChange: { copiedText in
                selectedText = copiedText
            }
        )
        return selectedText
    }

    /// Monitor pasteboard content change.
    ///
    /// - Parameters:
    ///   - triggerAction: The action to trigger the pasteboard change.
    ///   - onPasteboardChange: The callback when the pasteboard content changes.
    static func monitorPasteboardContentChange(
        triggerAction: @escaping () throws -> (),
        onPasteboardChange: @escaping (String?) -> ()
    ) {
        logInfo("Monitoring pasteboard content change")

        let pasteboard = NSPasteboard.general
        let initialChangeCount = pasteboard.changeCount

        pasteboard.performTemporaryTask {
            do {
                logInfo("Executing trigger action")
                try triggerAction()
            } catch {
                logError("Failed to execute trigger action: \(error)")
                onPasteboardChange(nil)
                return
            }

            pollTask {
                if pasteboard.changeCount != initialChangeCount {
                    let result = pasteboard.string()
                    logInfo("Pasteboard changed content: \(result ?? "nil")")
                    onPasteboardChange(result)
                    return true
                }
                return false
            }
        }
    }
}
