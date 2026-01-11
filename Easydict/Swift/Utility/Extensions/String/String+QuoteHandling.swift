//
//  String+QuoteHandling.swift
//  Easydict
//
//  Created by Claude on 2025/1/30.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

// MARK: - Quote Detection

extension String {
    /// Check if string has a prefix quote
    var hasPrefixQuote: Bool {
        !prefixQuote.isEmpty
    }

    /// Check if string has a suffix quote
    var hasSuffixQuote: Bool {
        !suffixQuote.isEmpty
    }

    /// Get prefix quote characters from the beginning of the string
    var prefixQuote: String {
        guard unicodeScalars.first != nil else { return "" }

        var quotes = ""
        for scalar in unicodeScalars {
            let char = String(scalar)
            if Self.quotePairs.keys.contains(char) {
                quotes.append(char)
            } else {
                break
            }
        }
        return quotes
    }

    /// Get suffix quote characters from the end of the string
    var suffixQuote: String {
        guard unicodeScalars.last != nil else { return "" }

        var quotes = ""
        for scalar in unicodeScalars.reversed() {
            let char = String(scalar)
            if Self.quotePairs.values.contains(char) {
                quotes.insert(contentsOf: char, at: quotes.startIndex)
            } else {
                break
            }
        }
        return String(quotes.reversed())
    }

    /// Remove prefix quote characters
    func tryRemovingPrefixQuote() -> String {
        let prefix = prefixQuote
        guard !prefix.isEmpty else { return self }
        return String(dropFirst(prefix.count))
    }

    /// Remove suffix quote characters
    func tryRemovingSuffixQuote() -> String {
        let suffix = suffixQuote
        guard !suffix.isEmpty else { return self }
        return String(dropLast(suffix.count))
    }

    /// Count total number of quote characters in text
    var countQuoteNumberInText: Int {
        let allQuotes = Array(Self.quotePairs.keys) + Array(Self.quotePairs.values)
        return unicodeScalars.map { String($0) }.compactMap { char in
            allQuotes.contains(char) ? 1 : 0
        }.reduce(0, +)
    }

    /// Check if string starts and ends with specified strings
    func isStartAndEnd(with start: String, end: String) -> Bool {
        guard count >= 2 else { return false }
        return hasPrefix(start) && hasSuffix(end)
    }

    /// Remove start and end strings if both present
    func removingStartAndEnd(with start: String, end: String) -> String {
        let substringLength = count - start.count - end.count
        guard isStartAndEnd(with: start, end: end), substringLength > 0 else { return self }

        let startIndex = index(startIndex, offsetBy: start.count)
        let endIndex = index(startIndex, offsetBy: substringLength)
        return String(self[startIndex ..< endIndex])
    }

    /// Remove matching quote pairs from both ends
    var tryRemovingQuotes: String {
        var text = self
        let prefixQuote = text.prefixQuote
        let suffixQuote = text.suffixQuote

        if prefixQuote.count == suffixQuote.count,
           let matchingSuffix = Self.quotePairs[prefixQuote],
           suffixQuote == matchingSuffix {
            text = text.removingStartAndEnd(with: prefixQuote, end: suffixQuote)
        }

        return text
    }

    /// Check if string has matching quote pairs
    var hasQuotesPair: Bool {
        !tryRemovingQuotes.isEmpty && tryRemovingQuotes != self
    }
}
