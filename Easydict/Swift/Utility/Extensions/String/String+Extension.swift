//
//  String+Extension.swift
//  Easydict
//
//  Created by tisfeng on 2024/4/29.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation

extension String {
    var boolValue: Bool {
        (self as NSString).boolValue
    }

    /// Truncate string max lenght to 200.
    func truncated(_ maxLength: Int = 200) -> String {
        String(prefix(maxLength)) + (count > maxLength ? "..." : "")
    }

    /// Trim whitespaces and newlines.
    func trim() -> String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Replace all newlines with whitespaces.
    /// For line breaks, currently macOS is `\n`, previously used `\r`, Windows is `\r\n`.
    func replacingNewlinesWithWhitespace() -> String {
        (self as NSString).replacingNewlinesWithWhitespace() as String
    }

    /// Remove prefix string
    func removePrefix(_ prefix: String) -> String {
        guard hasPrefix(prefix) else { return self }
        return String(dropFirst(prefix.count))
    }

    /// Copy to clipboard
    func copyToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(self, forType: .string)
    }
}

@objc
extension NSString {
    func truncated() -> NSString {
        truncated(200)
    }

    func truncated(_ maxLength: Int) -> NSString {
        if length > maxLength {
            return substring(to: maxLength) as NSString
        }
        return self
    }

    func replacingNewlinesWithWhitespace() -> NSString {
        let newlines = ["\r\n", "\n", "\r"]
        var newString = self
        for newline in newlines {
            newString = newString.replacingOccurrences(of: newline, with: " ") as NSString
        }
        return newString
    }
}
