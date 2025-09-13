//
//  TextFieldInfo.swift
//  Easydict
//
//  Created by tisfeng on 2025/8/31.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

/// Result type for focused text field information
struct TextFieldInfo: CustomStringConvertible {
    /// Full text in the focused text field, empty string if element not supported, e.g. VSCode
    let fullText: String

    /// Selected text range, length is 0 if element not supported AX though has selected text
    var selectedRange: CFRange?

    /// Selected text in the focused text field.
    /// If user has selected text, `selectedText` should have a value by forced selection.
    ///
    /// - Note: Sometimes has selected text, but selectedRange is nil
    let selectedText: String?

    /// Role value of the focused element, e.g. kAXTextFieldRole, AXTextAreaRole,
    let roleValue: String

    /// Focused text, prefer selectedText if available, otherwise use full text
    var focusedText: String {
        if let selectedText, !selectedText.isEmpty {
            return selectedText
        } else {
            return fullText
        }
    }

    /// Whether the focused element is a supported text input element
    var isSupportedAXElement: Bool {
        !fullText.isEmpty
    }

    // - MARK: CustomStringConvertible

    var description: String {
        let rangeDesc = selectedRange.map { "(\($0.location), \($0.length))" } ?? ""
        let selectedDesc = selectedText ?? ""

        return """
        TextFieldInfo(
            text: \"\(fullText.prefix200)\",
            selectedRange: \(rangeDesc),
            selectedText: \(selectedDesc),
            roleValue: \(roleValue)
        )
        """
    }
}
