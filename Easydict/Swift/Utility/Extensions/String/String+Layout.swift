//
//  String+Layout.swift
//  Easydict
//
//  Created by Easydict on 2025/11/25.
//  Copyright © 2025 izual. All rights reserved.
//

import AppKit

// MARK: - String Layout Extension

extension String {
    /// Calculate the width of the string with a given font.
    ///
    /// - Parameter font: Font to use for calculation
    /// - Returns: Width required to display the string
    ///
    /// - Example:
    /// ```swift
    /// let text = "Hello, World!"
    /// let width = text.width(with: .systemFont(ofSize: 14))
    /// ```
    func width(with font: NSFont) -> CGFloat {
        width(with: font, constrainedToHeight: .greatestFiniteMagnitude)
    }

    /// Calculate the width of the string with a given font, constrained to a maximum height.
    ///
    /// - Parameters:
    ///   - font: Font to use for calculation
    ///   - height: Maximum height constraint
    /// - Returns: Width required to display the string
    ///
    /// - Example:
    /// ```swift
    /// let width = text.width(with: font, constrainedToHeight: 100)
    /// ```
    func width(with font: NSFont, constrainedToHeight height: CGFloat) -> CGFloat {
        size(
            with: font,
            constrainedToSize: CGSize(width: .greatestFiniteMagnitude, height: height)
        ).width
    }

    /// Calculate the height of the string with a given font.
    ///
    /// - Parameter font: Font to use for calculation
    /// - Returns: Height required to display the string
    ///
    /// - Example:
    /// ```swift
    /// let height = text.height(with: .systemFont(ofSize: 14))
    /// ```
    func height(with font: NSFont) -> CGFloat {
        height(with: font, constrainedToWidth: .greatestFiniteMagnitude)
    }

    /// Calculate the height of the string with a given font, constrained to a maximum width.
    ///
    /// - Parameters:
    ///   - font: Font to use for calculation
    ///   - width: Maximum width constraint
    /// - Returns: Height required to display the string
    ///
    /// - Example:
    /// ```swift
    /// let height = text.height(with: font, constrainedToWidth: 300)
    /// ```
    func height(with font: NSFont, constrainedToWidth width: CGFloat) -> CGFloat {
        size(
            with: font,
            constrainedToSize: CGSize(width: width, height: .greatestFiniteMagnitude)
        ).height
    }

    /// Calculate the size of the string with a given font.
    ///
    /// - Parameter font: Font to use for calculation
    /// - Returns: Size required to display the string
    ///
    /// - Example:
    /// ```swift
    /// let size = text.size(with: .systemFont(ofSize: 14))
    /// ```
    func size(with font: NSFont) -> CGSize {
        size(
            with: font,
            constrainedToSize: CGSize(
                width: CGFloat.greatestFiniteMagnitude,
                height: CGFloat.greatestFiniteMagnitude
            )
        )
    }

    /// Calculate the size of the string with a given font, constrained to a maximum size.
    ///
    /// - Parameters:
    ///   - font: Font to use for calculation
    ///   - size: Maximum size constraint
    /// - Returns: Size required to display the string
    ///
    /// - Example:
    /// ```swift
    /// let size = text.size(with: font, constrainedToSize: CGSize(width: 300, height: 200))
    /// ```
    func size(with font: NSFont, constrainedToSize size: CGSize) -> CGSize {
        self.size(with: [.font: font], constrainedToSize: size)
    }

    /// Calculate the size of the string with given text attributes, constrained to a maximum size.
    ///
    /// - Parameters:
    ///   - attributes: Text attributes (font, color, etc.)
    ///   - size: Maximum size constraint
    /// - Returns: Size required to display the string
    ///
    /// - Example:
    /// ```swift
    /// let attributes: [NSAttributedString.Key: Any] = [
    ///     .font: NSFont.systemFont(ofSize: 14),
    ///     .foregroundColor: NSColor.red
    /// ]
    /// let size = text.size(with: attributes, constrainedToSize: CGSize(width: 300, height: 200))
    /// ```
    func size(
        with attributes: [NSAttributedString.Key: Any],
        constrainedToSize size: CGSize
    )
        -> CGSize {
        (self as NSString).boundingRect(
            with: size,
            options: .usesLineFragmentOrigin,
            attributes: attributes,
            context: nil
        ).size
    }
}

// MARK: - NSString Layout Extension (Objective-C Compatibility)

@objc
extension NSString {
    /// Calculate the width of the string with a given font (modern API).
    ///
    /// - Parameter font: Font to use for calculation
    /// - Returns: Width required to display the string
    @objc(widthWithFont:)
    func width(with font: NSFont) -> CGFloat {
        (self as String).width(with: font)
    }

    /// Calculate the width of the string with a given font (legacy mm_ API).
    ///
    /// - Parameter font: Font to use for calculation
    /// - Returns: Width required to display the string
    @objc(mm_widthWithFont:)
    func mm_width(with font: NSFont) -> CGFloat {
        width(with: font)
    }

    /// Calculate the width of the string with a given font, constrained to a maximum height (modern API).
    ///
    /// - Parameters:
    ///   - font: Font to use for calculation
    ///   - height: Maximum height constraint
    /// - Returns: Width required to display the string
    @objc(widthWithFont:constrainedToHeight:)
    func width(with font: NSFont, constrainedToHeight height: CGFloat) -> CGFloat {
        (self as String).width(with: font, constrainedToHeight: height)
    }

    /// Calculate the width of the string with a given font, constrained to a maximum height (legacy mm_ API).
    ///
    /// - Parameters:
    ///   - font: Font to use for calculation
    ///   - height: Maximum height constraint
    /// - Returns: Width required to display the string
    @objc(mm_widthWithFont:constrainedToHeight:)
    func mm_width(with font: NSFont, constrainedToHeight height: CGFloat) -> CGFloat {
        width(with: font, constrainedToHeight: height)
    }

    /// Calculate the height of the string with a given font (modern API).
    ///
    /// - Parameter font: Font to use for calculation
    /// - Returns: Height required to display the string
    @objc(heightWithFont:)
    func height(with font: NSFont) -> CGFloat {
        (self as String).height(with: font)
    }

    /// Calculate the height of the string with a given font (legacy mm_ API).
    ///
    /// - Parameter font: Font to use for calculation
    /// - Returns: Height required to display the string
    @objc(mm_heightWithFont:)
    func mm_height(with font: NSFont) -> CGFloat {
        height(with: font)
    }

    /// Calculate the height of the string with a given font, constrained to a maximum width (modern API).
    ///
    /// - Parameters:
    ///   - font: Font to use for calculation
    ///   - width: Maximum width constraint
    /// - Returns: Height required to display the string
    @objc(heightWithFont:constrainedToWidth:)
    func height(with font: NSFont, constrainedToWidth width: CGFloat) -> CGFloat {
        (self as String).height(with: font, constrainedToWidth: width)
    }

    /// Calculate the height of the string with a given font, constrained to a maximum width (legacy mm_ API).
    ///
    /// - Parameters:
    ///   - font: Font to use for calculation
    ///   - width: Maximum width constraint
    /// - Returns: Height required to display the string
    @objc(mm_heightWithFont:constrainedToWidth:)
    func mm_height(with font: NSFont, constrainedToWidth width: CGFloat) -> CGFloat {
        height(with: font, constrainedToWidth: width)
    }

    /// Calculate the size of the string with a given font (modern API).
    ///
    /// - Parameter font: Font to use for calculation
    /// - Returns: Size required to display the string
    @objc(sizeWithFont:)
    func size(with font: NSFont) -> CGSize {
        (self as String).size(with: font)
    }

    /// Calculate the size of the string with a given font (legacy mm_ API).
    ///
    /// - Parameter font: Font to use for calculation
    /// - Returns: Size required to display the string
    @objc(mm_sizeWithFont:)
    func mm_size(with font: NSFont) -> CGSize {
        size(with: font)
    }

    /// Calculate the size of the string with a given font, constrained to a maximum size (modern API).
    ///
    /// - Parameters:
    ///   - font: Font to use for calculation
    ///   - size: Maximum size constraint
    /// - Returns: Size required to display the string
    @objc(sizeWithFont:constrainedToSize:)
    func size(with font: NSFont, constrainedToSize size: CGSize) -> CGSize {
        (self as String).size(with: font, constrainedToSize: size)
    }

    /// Calculate the size of the string with a given font, constrained to a maximum size (legacy mm_ API).
    ///
    /// - Parameters:
    ///   - font: Font to use for calculation
    ///   - size: Maximum size constraint
    /// - Returns: Size required to display the string
    @objc(mm_sizeWithFont:constrainedToSize:)
    func mm_size(with font: NSFont, constrainedToSize size: CGSize) -> CGSize {
        self.size(with: font, constrainedToSize: size)
    }

    /// Calculate the size of the string with given text attributes, constrained to a maximum size (modern API).
    ///
    /// - Parameters:
    ///   - attributes: Text attributes (font, color, etc.)
    ///   - size: Maximum size constraint
    /// - Returns: Size required to display the string
    @objc(sizeWithAttributes:constrainedToSize:)
    func size(
        with attributes: [NSAttributedString.Key: Any],
        constrainedToSize size: CGSize
    )
        -> CGSize {
        (self as String).size(with: attributes, constrainedToSize: size)
    }

    /// Calculate the size of the string with given text attributes, constrained to a maximum size (legacy mm_ API).
    ///
    /// - Parameters:
    ///   - attributes: Text attributes (font, color, etc.)
    ///   - size: Maximum size constraint
    /// - Returns: Size required to display the string
    @objc(mm_sizetWithAttributes:constrainedToSize:)
    func mm_sizet(
        with attributes: [NSAttributedString.Key: Any],
        constrainedToSize size: CGSize
    )
        -> CGSize {
        self.size(with: attributes, constrainedToSize: size)
    }
}
