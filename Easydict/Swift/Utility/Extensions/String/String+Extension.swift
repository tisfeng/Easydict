//
//  String+Extension.swift
//  Easydict
//
//  Created by tisfeng on 2024/4/29.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation

extension String {
    /// Truncate string max lenght to 200.
    func truncated(_ maxLength: Int = 200) -> String {
        String(prefix(maxLength))
    }

    /// Trim whitespaces and newlines.
    func trim() -> String {
        trimmingCharacters(in: .whitespacesAndNewlines)
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

    /// Replace all newlines with whitespaces.
    /// For line breaks, currently macOS is `\n`, previously used `\n`, Windows is `\r\n`.
    func replacingNewlinesWithWhitespace() -> NSString {
        let newlines = ["\r\n", "\n", "\r"]
        var newString = self
        for newline in newlines {
            newString = replacingOccurrences(of: newline, with: " ") as NSString
        }
        return newString
    }
}
