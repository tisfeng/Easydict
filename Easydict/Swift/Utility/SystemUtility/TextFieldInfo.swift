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
    let text: String

    /// Selected text range, length is 0 if element not supported,
    var selectedRange: CFRange?

    /// - Note: Sometimes has selected text, but selectedRange is nil
    let selectedText: String?

    /// Focused text, prefer selectedText if available, otherwise use full text
    var focusedText: String {
        if let selectedText, !selectedText.isEmpty {
            return selectedText
        } else {
            return text
        }
    }

    /// Whether the focused element is a supported text input element
    var isSupportedAXElement: Bool {
        !text.isEmpty
    }

    // - MARK: CustomStringConvertible

    var description: String {
        let rangeDesc = selectedRange.map { "(\($0.location), \($0.length))" } ?? "nil"
        let selectedDesc = selectedText?.description ?? "nil"

        return
            "TextFieldInfo(text: \"\(text.prefix200)\", selectedRange: \(rangeDesc), selectedText: \(selectedDesc))"
    }
}
