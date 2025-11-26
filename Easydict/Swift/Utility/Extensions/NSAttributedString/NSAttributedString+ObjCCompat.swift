//
//  NSAttributedString+ObjCCompat.swift
//  Easydict
//
//  Created by tisfeng on 2025/11/26.
//  Copyright © 2025 izual. All rights reserved.
//

import AppKit

extension NSAttributedString {
    /// Creates an attributed string with the specified text and font.
    ///
    /// - Parameters:
    ///   - text: The text content.
    ///   - font: The font to apply.
    /// - Returns: An attributed string with the specified attributes.
    @objc(mm_attributedStringWithString:font:)
    static func attributedString(withText text: String, font: NSFont) -> NSAttributedString? {
        guard !text.isEmpty else { return nil }
        return NSAttributedString(string: text, attributes: [.font: font])
    }

    /// Creates an attributed string with the specified text, font, and color.
    ///
    /// - Parameters:
    ///   - text: The text content.
    ///   - font: The font to apply.
    ///   - color: The text color.
    /// - Returns: An attributed string with the specified attributes.
    @objc(mm_attributedStringWithString:font:color:)
    static func attributedString(
        withText text: String,
        font: NSFont,
        color: NSColor
    )
        -> NSAttributedString? {
        guard !text.isEmpty else { return nil }
        return NSAttributedString(
            string: text,
            attributes: [
                .font: font,
                .foregroundColor: color,
            ]
        )
    }

    /// Calculates the width of the attributed string.
    @objc(mm_getTextWidth)
    var width: CGFloat {
        size.width
    }

    /// Calculates the height of the attributed string for a given width.
    ///
    /// - Parameter width: The maximum width available.
    /// - Returns: The calculated height.
    @objc(mm_getTextHeightWithWidth:)
    func height(forWidth width: CGFloat) -> CGFloat {
        size(constrainedTo: CGSize(width: width, height: .greatestFiniteMagnitude)).height
    }

    /// Calculates the size of the attributed string for a given constraint.
    ///
    /// - Parameter size: The maximum size constraint.
    /// - Returns: The calculated size.
    @objc(mm_getTextSize:)
    func size(constrainedTo size: CGSize) -> CGSize {
        guard size.width > 0, size.height > 0 else { return .zero }

        let textStorage = NSTextStorage(attributedString: self)
        let textContainer = NSTextContainer(containerSize: size)
        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        layoutManager.glyphRange(for: textContainer)
        return layoutManager.usedRect(for: textContainer).size
    }

    /// Calculates the size of the attributed string with no constraints.
    @objc(mm_getTextSize)
    var size: CGSize {
        size(constrainedTo: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
    }
}
