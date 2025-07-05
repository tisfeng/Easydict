//
//  String+Detect.swift
//  Easydict
//
//  Created by tisfeng on 2025/7/5.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

extension String {
    /// Check if the string is Simplified Chinese.
    /// Characters in the text must be all Simplified Chinese characters, otherwise it will return false.
    var isSimplifiedChinese: Bool {
        let pureText = removingNonNormalCharacters()
        if !pureText.isChineseTextByRegex {
            return false
        }

        let simplifiedChinese = pureText.toSimplifiedChineseText()
        return simplifiedChinese == pureText
    }

    /// Check if the string is Chinese text by regex unicode range.
    var isChineseTextByRegex: Bool {
        // Regular expression to match Chinese characters
        let regex = try? NSRegularExpression(pattern: "[\\u4e00-\\u9fa5]+", options: [])
        let range = NSRange(location: 0, length: utf16.count)

        // Check if the entire string matches the regex
        return regex?.firstMatch(in: self, options: [], range: range) != nil
    }

    /// Check if character is English alphabet (basic Latin only)
    var isEnglishAlphabet: Bool {
        range(of: "^[a-zA-Z]$", options: .regularExpression) != nil
    }

    /// Check if string contains only English alphabet characters
    var isEnglishText: Bool {
        range(of: "^[a-zA-Z]+$", options: .regularExpression) != nil
    }

    /// Check if character is Latin alphabet (used by English, French, Spanish, etc.)
    var isLatinAlphabet: Bool {
        range(of: "^[a-zA-ZÀ-ÿ]$", options: .regularExpression) != nil
    }

    /// Check if string contains only alphabetic characters
    var isLatinText: Bool {
        range(of: "^[a-zA-ZÀ-ÿ]+$", options: .regularExpression) != nil
    }

    /// Check if character is whitespace or punctuation
    var isWhitespaceOrPunctuation: Bool {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || range(of: "^[\\p{P}\\p{S}]$", options: .regularExpression) != nil
    }

    /// Check if string contains only a single numeric character (0-9)
    var isNumber: Bool {
        range(of: "^[0-9]$", options: .regularExpression) != nil
    }

    /// Check if string contains only numeric characters
    var isNumericText: Bool {
        range(of: "^[0-9]+$", options: .regularExpression) != nil
    }

    /// Check if string is numeric-heavy (>70% numbers)
    var isNumericHeavy: Bool {
        let digitCount = filter { $0.isNumber }.count
        return Double(digitCount) / Double(count) > 0.7
    }

    /// Check if string contains mixed scripts (different writing systems)
    var hasMixedScripts: Bool {
        var hasLatin = false
        var hasChinese = false
        var hasOther = false

        for char in self {
            let charString = String(char)
            if charString.isLatinAlphabet {
                hasLatin = true
            } else if charString.isChineseTextByRegex {
                hasChinese = true
            } else if !charString.isWhitespaceOrPunctuation {
                hasOther = true
            }
        }

        // Mixed if we have at least 2 different script types
        let scriptCount = [hasLatin, hasChinese, hasOther].filter { $0 }.count
        return scriptCount >= 2
    }
}

extension String {
    /// Remove non-normal characters from the string.
    func removingNonNormalCharacters() -> String {
        var text = self
        text = text.removingWhitespaceAndNewlines()
        text = text.removingPunctuationCharacters()
        text = text.removingSymbols()
        text = text.removingNumbers()
        text = text.removingNonBaseCharacterSet()
        return text
    }

    /// Remove whitespace and newline characters from the string.
    func removingWhitespaceAndNewlines() -> String {
        components(separatedBy: .whitespacesAndNewlines).joined()
    }

    /// Remove punctuation characters from the string.
    func removingPunctuationCharacters() -> String {
        components(separatedBy: .punctuationCharacters).joined()
    }

    /// Remove symbol characters from the string.
    func removingSymbols() -> String {
        components(separatedBy: .symbols).joined()
    }

    /// Remove numbers from the string.
    func removingNumbers() -> String {
        components(separatedBy: .decimalDigits).joined()
    }

    /// Remove non-base characters from the string.
    func removingNonBaseCharacterSet() -> String {
        // Base characters are letters and digits, so we remove everything else.
        components(separatedBy: .alphanumerics.inverted).joined()
    }
}
