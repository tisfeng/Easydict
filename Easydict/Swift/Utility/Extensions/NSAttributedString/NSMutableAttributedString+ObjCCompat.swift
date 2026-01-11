//
//  NSMutableAttributedString+ObjCCompat.swift
//  Easydict
//
//  Created by tisfeng on 2025/11/26.
//  Copyright © 2025 izual. All rights reserved.
//

import AppKit

extension NSMutableAttributedString {
    /// Creates a mutable attributed string with the specified text, font, and color.
    ///
    /// - Parameters:
    ///   - text: The text content.
    ///   - font: The font to apply.
    ///   - color: The text color.
    /// - Returns: A mutable attributed string with the specified attributes.
    @objc(mm_mutableAttributedStringWithString:font:color:)
    static func mutableAttributedString(
        withText text: String,
        font: NSFont,
        color: NSColor
    )
        -> NSMutableAttributedString? {
        guard let attrString = NSAttributedString.attributedString(withText: text, font: font, color: color)
        else { return nil }
        return NSMutableAttributedString(attributedString: attrString)
    }

    /// Updates the font and color for the entire string.
    ///
    /// - Parameters:
    ///   - font: The font to apply.
    ///   - color: The text color.
    @objc(mm_updateWithFont:color:)
    func update(withFont font: NSFont?, color: NSColor?) {
        update(withFont: font, color: color, range: NSRange(location: 0, length: length))
    }

    /// Updates the font and color for a specific range.
    ///
    /// - Parameters:
    ///   - font: The font to apply.
    ///   - color: The text color.
    ///   - range: The range to apply the attributes.
    @objc(mm_updateWithFont:color:range:)
    func update(withFont font: NSFont?, color: NSColor?, range: NSRange) {
        if let font = font {
            addAttribute(.font, value: font, range: range)
        }
        if let color = color {
            addAttribute(.foregroundColor, value: color, range: range)
        }
    }

    /// Updates the font and color for text matching a regex pattern.
    ///
    /// - Parameters:
    ///   - font: The font to apply.
    ///   - color: The text color.
    ///   - pattern: The regex pattern to match.
    @objc(mm_updateWithFont:color:pattern:)
    func update(withFont font: NSFont?, color: NSColor?, pattern: String) {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            let matches = regex.matches(in: string, options: [], range: NSRange(location: 0, length: length))
            for match in matches {
                update(withFont: font, color: color, range: match.range)
            }
        } catch {
            print("Regex pattern error: \(error)")
        }
    }
}
