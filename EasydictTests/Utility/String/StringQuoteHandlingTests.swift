//
//  StringQuoteHandlingTests.swift
//  EasydictTests
//
//  Created by Claude on 2025/1/29.
//  Copyright © 2025 izual. All rights reserved.
//

import Testing

@testable import Easydict

/// Tests for String quote handling extensions
@Suite("String Quote Handling", .tags(.utilities, .unit))
struct StringQuoteHandlingTests {
    // MARK: - Quote Pair Detection

    @Test("Quote pair detection")
    func quotePairDetection() {
        // Use Unicode escapes for curly quotes to avoid syntax issues
        let leftDoubleQuote = "\u{201C}" // "
        let rightDoubleQuote = "\u{201D}" // "

        let testCases: [(String, Bool)] = [
            ("'text'", true),
            ("\"text\"", true),
            ("\(leftDoubleQuote)text\(rightDoubleQuote)", true),
            ("\(leftDoubleQuote)text\(rightDoubleQuote)", true),
            ("\(leftDoubleQuote)text\(rightDoubleQuote)", true),
            ("text", false),
            ("'text", false),
            ("text'", false),
        ]

        for (input, expected) in testCases {
            #expect(input.hasQuotesPair == expected, "Failed for input: \(input)")
        }
    }

    // MARK: - Quote Removal

    @Test("Quote removal")
    func quoteRemoval() {
        // Use Unicode escapes for curly quotes to avoid syntax issues
        let leftDoubleQuote = "\u{201C}" // "
        let rightDoubleQuote = "\u{201D}" // "

        let testCases: [(String, String)] = [
            ("'text'", "text"),
            ("\"text\"", "text"),
            ("\(leftDoubleQuote)text\(rightDoubleQuote)", "text"),
            ("\(leftDoubleQuote)text\(rightDoubleQuote)", "text"),
            ("\(leftDoubleQuote)text\(rightDoubleQuote)", "text"),
            ("text", "text"),
            ("'text", "'text"),
            ("text'", "text'"),
        ]

        for (input, expected) in testCases {
            #expect(input.tryToRemoveQuotes() == expected, "Failed for input: \(input)")
        }
    }
}
