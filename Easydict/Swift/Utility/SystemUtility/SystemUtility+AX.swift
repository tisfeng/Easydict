//
//  SystemUtility+AX.swift
//  Easydict
//
//  Created by tisfeng on 2025/9/2.
//  Copyright © 2025 izual. All rights reserved.
//

import AXSwift
import Foundation
import SelectedTextKit

extension SystemUtility {
    /// Replace text in current focused text field with optional range support
    /// - Parameters:
    ///   - text: The replacement text
    func insertTextByAX(_ text: String) {
        do {
            guard let element = try focusedTextFieldElement() else {
                return
            }

            try element.setAttribute(.selectedText, value: text)
        } catch {
            logError("Failed to insert text by AX: \(error.localizedDescription)")
        }
    }

    /// Select all text in current focused text field by Accessibility API
    func selectAllByAX() {
        logInfo("Select all text using AX")

        do {
            guard let element = try focusedTextFieldElement(),
                  let fullText = try element.value() else {
                return
            }

            let selectedTextRange = CFRange(location: 0, length: fullText.count)
            try element.setAttribute(.selectedTextRange, value: selectedTextRange)
        } catch {
            logError("Failed to select all by AX: \(error.localizedDescription)")
        }
    }

    /// Check if the currently focused element is a text field that supports Accessibility API
    var isSupportedAX: Bool {
        guard let element = try? focusedTextFieldElement(),
              let value = try? element.value() else {
            return false
        }

        // If value is non-empty string, consider it as supported text field.
        return !value.isEmpty
    }

    /// Get the currently focused text field element, use AXSwift API
    func focusedTextFieldElement() throws -> UIElement? {
        do {
            guard let focusedUIElement = try frontmostAppElement?.focusedUIElement() else {
                logInfo("No focused UI element found")
                return nil
            }

            guard let roleValue = try focusedUIElement.roleValue() else {
                logInfo("Focused UI element has no role attribute")
                return nil
            }

            if textFieldRoles.contains(roleValue) {
                return focusedUIElement
            }
            logInfo("Focused UI element not a text field role: \(roleValue)")
            return nil
        } catch {
            logError("Error accessing focused UI element: \(error)")
            return nil
        }
    }

    /// A `UIElement` for frontmost application.
    var frontmostAppElement: UIElement? {
        let frontmostApp = NSWorkspace.shared.frontmostApplication
        guard let frontmostApp else {
            return nil
        }
        return Application(frontmostApp)
    }

    // MARK: Private

    /// Roles that are considered text fields
    private var textFieldRoles: Set<String> {
        [
            kAXTextFieldRole,
            kAXTextAreaRole,
            kAXTextAreaRole,
            kAXComboBoxRole, // Safari: Google search field
            kAXSearchFieldSubrole,
            kAXPopUpButtonRole,
            kAXMenuRole,
        ]
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

        if textFieldRoles.contains(roleValue) {
            return focusedElement
        } else {
            return nil
        }
    }

    // MARK: - Objective-C AX Wrappers

    @objc
    func hasCopyMenuItem() -> Bool {
        AXManager.shared.findCopyMenuItem() != nil
    }

    /// Check if there is a focused text field element
    @objc
    func isFocusedTextField() -> Bool {
        (try? focusedTextFieldElement()) != nil
    }
}
