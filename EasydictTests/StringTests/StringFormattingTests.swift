//
//  StringFormattingTests.swift
//  EasydictTests
//
//  Created by Claude on 2025/1/29.
//  Copyright © 2025 izual. All rights reserved.
//

import Testing

@testable import Easydict

/// Tests for String formatting and text normalization extensions
@Suite("String Formatting", .tags(.utilities, .unit))
struct StringFormattingTests {
    // MARK: - Word Segmentation

    @Test("Word segmentation")
    func wordSegmentation() {
        let testCases = [
            ("key_value", "key value"),
            ("LaTeX", "LaTeX"),
            ("'UIKit'", "UIKit"),
            ("simpleWord", "simple Word"),
            ("", ""),
            ("test_case", "test case"),
        ]

        for (input, expected) in testCases {
            #expect(input.segmentWords() == expected, "Failed for input: \(input)")
        }
    }

    // MARK: - End Punctuation Detection

    @Test("End punctuation detection")
    func endPunctuationDetection() {
        let testCases: [(String, Bool)] = [
            ("text.", true),
            ("text!", true),
            ("text?", true),
            ("text。", true),
            ("text…", true),
            ("text", false),
            ("text..", true),
            ("text,", false),
            ("", false),
        ]

        for (input, expected) in testCases {
            #expect(input.hasEndPunctuationSuffix == expected, "Failed for input: \(input)")
        }
    }

    // MARK: - Newline Replacement

    @Test("Newline replacement with whitespace")
    func newlineReplacement() {
        let testCases = [
            ("line1\nline2", "line1 line2"),
            ("line1\n\nline2", "line1  line2"),
            ("line1   \n   line2", "line1       line2"),
            ("single line", "single line"),
            ("", ""),
            ("\nleading newline", " leading newline"),
        ]

        for (input, expected) in testCases {
            #expect(input.replacingNewlinesWithWhitespace() == expected, "Failed for input: \(input)")
        }
    }
}
