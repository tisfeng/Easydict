//
//  FocusedElementInfo.swift
//  Easydict
//
//  Created by tisfeng on 2025/8/31.
//  Copyright © 2025 izual. All rights reserved.
//

import AXSwift
import Foundation

/// Result type for focused UI element information
struct FocusedElementInfo: CustomStringConvertible {
    /// Default empty info used when no element data can be retrieved
    static let empty = FocusedElementInfo(
        fullText: nil,
        selectedRange: nil,
        selectedText: nil,
        roleValue: nil
    )

    // MARK: - Role Helpers

    /// Roles that are considered text input elements
    static let textInputRoles: Set<String> = [
        kAXTextFieldRole,
        kAXTextAreaRole,
        kAXComboBoxRole, // Safari: Google search field
        kAXSearchFieldSubrole,
        kAXPopUpButtonRole,
        kAXMenuRole,
    ]

    /// Full text in the focused text field, if available
    let fullText: String?

    /// Selected text range, length is 0 if element not supported AX though has selected text
    var selectedRange: CFRange?

    /// Selected text in the focused text field.
    /// If user has selected text, `selectedText` should have a value by forced selection.
    ///
    /// - Note: Sometimes has selected text, but selectedRange is nil
    let selectedText: String?

    /// Role value of the focused element, e.g. kAXTextFieldRole, AXTextAreaRole,
    let roleValue: String?

    /// Whether the focused element is a text input element
    var isTextField: Bool {
        guard let roleValue else {
            return false
        }
        return Self.textInputRoles.contains(roleValue)
    }

    /// Focused text, prefer selectedText if available, otherwise use full text
    var focusedText: String? {
        if let selectedText, !selectedText.isEmpty {
            return selectedText
        }
        if let fullText, !fullText.isEmpty {
            return fullText
        }
        return nil
    }

    /// Whether the focused element is a supported text input element
    var isSupportedAXElement: Bool {
        fullText?.isEmpty == false
    }

    // - MARK: CustomStringConvertible

    var description: String {
        let rangeDesc = selectedRange.map { "(\($0.location), \($0.length))" } ?? ""
        let selectedDesc = selectedText ?? "nil"
        let roleDesc = roleValue ?? "nil"
        let fullTextDesc = fullText?.prefix200 ?? "nil"

        return """
        FocusedElementInfo(
            text: \"\(fullTextDesc)\",
            selectedRange: \(rangeDesc),
            selectedText: \(selectedDesc),
            roleValue: \(roleDesc)
        )
        """
    }
}
