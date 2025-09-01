//
//  SystemUtility.swift
//  Easydict
//
//  Created by tisfeng on 2025/8/30.
//  Copyright © 2025 izual. All rights reserved.
//

import AXSwift
import Foundation
import KeySender

// MARK: - SystemUtility

class SystemUtility {
    // MARK: Internal

    static let shared = SystemUtility()

    /// A `UIElement` for frontmost application.
    var frontmostAppElement: UIElement? {
        let frontmostApp = NSWorkspace.shared.frontmostApplication
        guard let frontmostApp else {
            return nil
        }
        return Application(frontmostApp)
    }

    /// Check if current focused element is a text field
    var isFocusedTextField: Bool {
        let focusedUIElement = frontmostAppElement?.focusedUIElement
        if let roleValue = focusedUIElement?.roleValue {
            return textFieldRoles.contains(roleValue)
        }
        return false
    }

    /// Roles that are considered text fields
    var textFieldRoles: Set<String> {
        [
            kAXTextFieldRole,
            kAXTextAreaRole,
            kAXComboBoxRole,
            kAXSearchFieldSubrole,
            kAXPopUpButtonRole,
            kAXMenuRole,
        ]
    }

    func getSelectedText() async -> String? {
        await EZEventMonitor.shared().getSelectedText()
    }

    /// Post Command + A to select all text in current focused text field
    func selectAll() {
        let sender = KeySender(key: .a, modifiers: .command)
        sender.sendGlobally()
    }

    /// Get comprehensive information from current focused text field
    ///
    /// - Returns: TextFieldInfo containing text, range, and selected text
    func getFocusedTextFieldInfo() async -> TextFieldInfo? {
        // 1. Ensure focused element is a text field
        guard let element = focusedTextFieldElement() else {
            logInfo("Current focused element is not a text field")
            return nil
        }

        // 2. Get full text from the text field
        guard let fullText = element.value else {
            logInfo("Failed to get text from focused element")
            return nil
        }

        // 3. Try to get selected text and range
        let selectedText = await getSelectedText()
        let selectedRange = element.selectedRange

        return TextFieldInfo(
            text: fullText,
            selectedRange: selectedRange,
            selectedText: selectedText?.isEmpty == false ? selectedText : nil
        )
    }

    /// Replace text in current focused text field, use AXSwift API
    func replaceFocusedTextFieldText(with text: String) {
        replaceFocusedTextFieldText(with: text, range: nil)
    }

    /// Replace text in current focused text field with optional range support
    /// - Parameters:
    ///   - text: The replacement text
    ///   - range: Optional CFRange for partial replacement. If nil, replaces entire content
    func replaceFocusedTextFieldText(with text: String, range: CFRange?) {
        guard let element = focusedTextFieldElement() else {
            logInfo("Current focused element is not a text field")
            return
        }

        do {
            if range != nil {
                // Partial replacement using selectedTextRange
//                try element.setAttribute(.selectedTextRange, value: range)
                try element.setAttribute(.selectedText, value: text)
            } else {
                // Full replacement
                try element.setAttribute(.value, value: text)
            }
        } catch {
            logError("Failed to replace text field text: \(error)")
        }
    }

    /// Get the current selected range in the focused text field
    func getFocusedTextFieldSelectedRange() -> CFRange? {
        guard let element = focusedTextFieldElement() else {
            logInfo("Current focused element is not a text field")
            return nil
        }

        return element.selectedRange
    }

    /// Replace selected text in the focused text field
    func replaceSelectedText(with text: String) {
        guard let element = focusedTextFieldElement() else {
            logInfo("Current focused element is not a text field")
            return
        }

        do {
            try element.setAttribute(.selectedText, value: text)
        } catch {
            logError("Failed to replace selected text: \(error)")
        }
    }

    // MARK: Private

    /// Get the currently focused text field element, use AXSwift API
    private func focusedTextFieldElement() -> UIElement? {
        guard let focusedUIElement = frontmostAppElement?.focusedUIElement else {
            logInfo("No focused UI element found")
            return nil
        }

        guard let roleValue = focusedUIElement.roleValue else {
            logInfo("Focused UI element has no role attribute")
            return nil
        }

        logInfo("Focused UI Element Role: \(roleValue)")

        if textFieldRoles.contains(roleValue) {
            return focusedUIElement
        } else {
            return nil
        }
    }

    /// Get the currently focused text field element, use system AXUIElement API
    private func focusedTextFieldElement2() -> AXUIElement? {
        let systemWideElement = AXUIElementCreateSystemWide()
        var focusedElementRef: CFTypeRef?

        let error = AXUIElementCopyAttributeValue(
            systemWideElement,
            kAXFocusedUIElementAttribute as CFString,
            &focusedElementRef
        )

        guard error == .success, let focusedElement = focusedElementRef as! AXUIElement? else {
            logError("Failed to get focused element, error: \(error)")
            return nil
        }

        var roleValueRef: CFTypeRef?
        let roleError = AXUIElementCopyAttributeValue(
            focusedElement,
            kAXRoleAttribute as CFString,
            &roleValueRef
        )
        guard roleError == .success, let roleValue = roleValueRef as? String else {
            logError("Failed to get role attribute, error: \(roleError)")
            return nil
        }

        logInfo("Focused UI Element Role: \(roleValue)")

        if textFieldRoles.contains(roleValue) {
            return focusedElement
        } else {
            return nil
        }
    }
}

extension UIElement {
    var focusedUIElement: UIElement? {
        try? attribute(.focusedUIElement)
    }

    var roleValue: String? {
        try? attribute(.role)
    }

    var value: String? {
        try? attribute(.value)
    }

    var selectedText: String? {
        try? attribute(.selectedText)
    }

    var selectedRange: CFRange? {
        try? attribute(.selectedTextRange)
    }
}
