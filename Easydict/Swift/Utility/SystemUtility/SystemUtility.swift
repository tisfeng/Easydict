//
//  SystemUtility.swift
//  Easydict
//
//  Created by tisfeng on 2025/8/30.
//  Copyright © 2025 izual. All rights reserved.
//

import AXSwift
import Foundation

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

    /// Get text from current focused text field
    ///
    /// This method intelligently determines what text to return from focused text field:
    /// 1. If not a text field or error → returns nil
    /// 2. If there is selected text → returns selected text
    /// 3. If no text is selected → returns all text in the field
    func getFocusedTextFieldText() async -> String? {
        // 1. Ensure focused element is a text field
        guard let element = focusedTextFiledElement() else {
            logInfo("Current focused element is not a text field")
            return nil
        }

        // 2. Try to get selected text first
        // Since `element.selectedText` may not work for some apps, e.g. VSCode
        // So we use `getSelectedText` to get selected text.
        if let selectedText = await getSelectedText(), !selectedText.isEmpty {
            return selectedText
        }

        // 3. If no selected text, get all text
        return element.value
    }

    /// Replace text in current focused text field, use AXSwift API
    func replaceFocusedTextFieldText(with text: String) {
        guard let element = focusedTextFiledElement() else {
            logInfo("Current focused element is not a text field")
            return
        }

        do {
            try element.setAttribute(.value, value: text)
        } catch {
            logError("Failed to replace text field text: \(error)")
        }
    }

    // MARK: Private

    /// Get the currently focused text field element, use AXSwift API
    private func focusedTextFiledElement() -> UIElement? {
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
    private func focusedTextFiledElement2() -> AXUIElement? {
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

    var selectedRange: NSRange? {
        if let cfRange: CFRange = try? attribute(.selectedTextRange) {
            return NSRange(cfRange)
        }
        return nil
    }
}

extension NSRange {
    init(_ cfRange: CFRange) {
        self.init(location: cfRange.location, length: cfRange.length)
    }
}
