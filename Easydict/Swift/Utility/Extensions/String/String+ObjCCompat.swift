//
//  String+ObjCCompat.swift
//  Easydict
//
//  Created by tisfeng on 2025/11/26.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

extension NSString {
    /// Returns a string by combining components with a separator.
    ///
    /// - Parameters:
    ///   - components: An array of strings to combine.
    ///   - separator: A string to insert between each component, or nil for no separator.
    /// - Returns: The combined string, or nil if components is empty.
    @objc(mm_stringByCombineComponents:separatedString:)
    static func combinedComponents(_ components: [String], separatedBy separator: String?) -> String? {
        guard !components.isEmpty else {
            return nil
        }

        var result = ""
        for (index, component) in components.enumerated() {
            result += component
            if let separator = separator, index != components.count - 1 {
                result += separator
            }
        }
        return result
    }

    /// Returns a URL-encoded version of the string.
    ///
    /// - Returns: The URL-encoded string.
    @objc(mm_urlencode)
    var urlEncodedString: String {
        (self as String).urlEncoded()
    }

    /// Trims the string and limits it to a maximum length.
    ///
    /// - Parameter maxLength: The maximum length of the resulting string.
    /// - Returns: A trimmed string limited to the specified length.
    @objc(mm_trimToMaxLength:)
    func trimmingToMaxLength(_ maxLength: Int) -> String {
        let trimmed = (self as String).trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count > maxLength {
            return String(trimmed.prefix(maxLength))
        }
        return trimmed
    }
}

extension String {
    /// Returns a string by combining components with a separator.
    ///
    /// - Parameters:
    ///   - components: An array of strings to combine.
    ///   - separator: A string to insert between each component, or nil for no separator.
    /// - Returns: The combined string, or nil if components is empty.
    static func combined(components: [String], separatedBy separator: String?) -> String? {
        guard !components.isEmpty else {
            return nil
        }

        var result = ""
        for (index, component) in components.enumerated() {
            result += component
            if let separator = separator, index != components.count - 1 {
                result += separator
            }
        }
        return result
    }

    /// Returns a URL-encoded version of the string.
    ///
    /// - Returns: The URL-encoded string.
    func urlEncoded() -> String {
        var output = ""

        for char in utf8 {
            if char == UInt8(ascii: " ") {
                output += "+"
            } else if char == UInt8(ascii: ".") ||
                char == UInt8(ascii: "-") ||
                char == UInt8(ascii: "_") ||
                char == UInt8(ascii: "~") ||
                (char >= UInt8(ascii: "a") && char <= UInt8(ascii: "z")) ||
                (char >= UInt8(ascii: "A") && char <= UInt8(ascii: "Z")) ||
                (char >= UInt8(ascii: "0") && char <= UInt8(ascii: "9")) {
                output += String(UnicodeScalar(char))
            } else {
                output += String(format: "%%%02X", char)
            }
        }

        return output
    }
}
