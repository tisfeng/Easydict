//
//  String+Tests.swift
//  EasydictTests
//
//  Created by Claude on 2025/1/29.
//  Copyright © 2025 izual. All rights reserved.
//

import Testing

@testable import Easydict

/// Tests for String extension methods
@Suite("String Extensions")
struct StringHandleInputTextTests {
    // MARK: - Split Code Text Tests

    @Test("Split camel case text")
    func splitCamelCaseText() {
        let testCases = [
            ("anchoredDraggableState", "anchored Draggable State"),
            ("AnchoredDraggableState", "Anchored Draggable State"),
            ("GetHTTP", "Get HTTP"),
            ("GetHTTPCode", "Get HTTP Code"),
            ("simpleWord", "simpleWord"),
            ("", ""),
            ("XMLHttpRequest", "XML Http Request"),
        ]

        for (input, expected) in testCases {
            #expect(input.splitCamelCaseText() == expected, "Failed for input: \(input)")
        }
    }

    @Test("Split snake case text")
    func splitSnakeCaseText() {
        let testCases = [
            ("anchored_draggable_state", "anchored draggable state"),
            ("simple_word", "simple word"),
            ("already spaced", "already spaced"),
            ("", ""),
            ("snake_case", "snake case"),
            ("multiple___underscores", "multiple   underscores"),
        ]

        for (input, expected) in testCases {
            #expect(input.splitSnakeCaseText() == expected, "Failed for input: \(input)")
        }
    }

    @Test("Split code text")
    func splitCodeText() {
        let testCases = [
            ("anchored_draggable_state", "anchored draggable state"),
            ("GetHTTPCode", "Get HTTP Code"),
            ("anchoredDraggableState", "anchored Draggable State"),
            ("simple_test_case", "simple test case"),
            ("XMLHttpRequest", "XML Http Request"),
            ("", ""),
            ("a_b_c", "a b c"),
        ]

        for (input, expected) in testCases {
            #expect(input.splitCodeText() == expected, "Failed for input: \(input)")
        }
    }

    // MARK: - Comment Handling Tests

    @Test("All lines start with comment symbol")
    func allLineStartsWithCommentSymbol() {
        let testCases = [
            ("# This is a comment\n// Another comment", true),
            ("# Comment\nNot a comment", false),
            ("/* Block comment */\n* Another", true),
            ("Normal text\n// Comment", false),
            ("// Only comments\n# More comments\n* And more", true),
            ("", false),
            ("   # Indented comment", true),
        ]

        for (input, expected) in testCases {
            #expect(input.allLineStartsWithCommentSymbol() == expected, "Failed for input: \(input)")
        }
    }

    @Test("Remove comment block symbols")
    func removeCommentBlockSymbols() {
        let input = """
        // This is a comment
        // with multiple lines
        """

        let result = input.removingCommentBlockSymbols()
        #expect(result.contains("This is a comment"))
        #expect(result.contains("with multiple lines"))
        #expect(!result.contains("//"))
    }

    @Test("Remove comment symbol prefix")
    func removeCommentSymbolPrefix() {
        let testCases = [
            ("// Comment", "Comment"),
            ("# Hash comment", "Hash comment"),
            ("* Asterisk comment", "Asterisk comment"),
            ("    // Indented comment", "Indented comment"),
            ("Normal text", "Normal text"),
        ]

        for (input, expected) in testCases {
            #expect(input.removeCommentSymbolPrefix() == expected, "Failed for input: \(input)")
        }
    }

    @Test("Remove comment symbols")
    func removeCommentSymbols() {
        let testCases = [
            ("// Comment at start", "Comment at start"),
            ("Comment at end //", "Comment at end"),
            ("Comment // in // middle", "Comment in middle"),
            ("# Hash comment", "Hash comment"),
            ("Normal text", "Normal text"),
        ]

        for (input, expected) in testCases {
            #expect(input.removeCommentSymbols() == expected, "Failed for input: \(input)")
        }
    }

    // MARK: - Word Segmentation Tests

    @Test("Segment words")
    func segmentWords() {
        let testCases = [
            ("key_value", "key value"),
            ("LaTeX", "LaTeX"),
            ("'UIKit'", "UIKit"),
            ("simpleWord", "simpleWord"),
            ("", ""),
            ("test_case", "test case"),
        ]

        for (input, expected) in testCases {
            #expect(input.segmentWords() == expected, "Failed for input: \(input)")
        }
    }

    // MARK: - Quote Handling Tests

    @Test("Has quotes pair")
    func hasQuotesPair() {
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
            #expect(input.hasQuotesPair() == expected, "Failed for input: \(input)")
        }
    }

    @Test("Try to remove quotes")
    func tryToRemoveQuotes() {
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

    // MARK: - End Punctuation Tests

    @Test("Has end punctuation suffix")
    func hasEndPunctuationSuffix() {
        let testCases: [(String, Bool)] = [
            ("text.", true),
            ("text!", true),
            ("text?", true),
            ("text。", true),
            ("text…", true),
            ("text", false),
            ("text..", false),
            ("text,", false),
            ("", false),
        ]

        for (input, expected) in testCases {
            #expect(input.hasEndPunctuationSuffix == expected, "Failed for input: \(input)")
        }
    }

    // MARK: - Newline Replacement Tests

    @Test("Replacing newlines with whitespace")
    func replacingNewlinesWithWhitespace() {
        let testCases = [
            ("line1\nline2", "line1 line2"),
            ("line1\n\nline2", "line1  line2"),
            ("line1   \n   line2", "line1 line2"),
            ("single line", "single line"),
            ("", ""),
            ("\nleading newline", " leading newline"),
        ]

        for (input, expected) in testCases {
            #expect(input.replacingNewlinesWithWhitespace() == expected, "Failed for input: \(input)")
        }
    }

    // MARK: - Integration Tests

    @Test("Handle input text integration")
    func handleInputTextIntegration() {
        // Test complete input handling with various configurations
        let testInput = """
        // This is a comment
        key_value
        testWord
        """

        let result = testInput.handlingInputText()
        #expect(!result.contains("//"))
        #expect(result.contains("key value"))
        #expect(result.contains("testWord"))
        #expect(result.splitCodeText().contains("key value"))
    }

    @Test("Complex code splitting")
    func complexCodeSplitting() {
        let testCases = [
            ("XMLHttpRequest", "XML Http Request"),
            ("getUserID", "get User ID"),
            ("parseJSONResponse", "parse JSON Response"),
            ("initializeComponents", "initialize Components"),
        ]

        for (input, expected) in testCases {
            #expect(input.splitCodeText() == expected, "Failed for input: \(input)")
        }
    }
}
