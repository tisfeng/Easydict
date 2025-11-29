//
//  String+HandleInputTextTests.swift
//  EasydictTests
//
//  Created by Claude on 2025/1/29.
//  Copyright © 2025 izual. All rights reserved.
//

@testable import Easydict
import XCTest

final class StringHandleInputTextTests: XCTestCase {
    // MARK: - Split Code Text Tests

    func testSplitCamelCaseText() {
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
            XCTAssertEqual(input.splitCamelCaseText(), expected, "Failed for input: \(input)")
        }
    }

    func testSplitSnakeCaseText() {
        let testCases = [
            ("anchored_draggable_state", "anchored draggable state"),
            ("simple_word", "simple word"),
            ("already spaced", "already spaced"),
            ("", ""),
            ("snake_case", "snake case"),
            ("multiple___underscores", "multiple   underscores"),
        ]

        for (input, expected) in testCases {
            XCTAssertEqual(input.splitSnakeCaseText(), expected, "Failed for input: \(input)")
        }
    }

    func testSplitCodeText() {
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
            XCTAssertEqual(input.splitCodeText(), expected, "Failed for input: \(input)")
        }
    }

    // MARK: - Comment Handling Tests

    func testAllLineStartsWithCommentSymbol() {
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
            XCTAssertEqual(input.allLineStartsWithCommentSymbol(), expected, "Failed for input: \(input)")
        }
    }

    func testRemoveCommentBlockSymbols() {
        let input = """
        // This is a comment
        // with multiple lines
        """

        let result = input.removingCommentBlockSymbols()
        XCTAssertTrue(result.contains("This is a comment"))
        XCTAssertTrue(result.contains("with multiple lines"))
        XCTAssertFalse(result.contains("//"))
    }

    func testRemoveCommentSymbolPrefix() {
        let testCases = [
            ("// Comment", "Comment"),
            ("# Hash comment", "Hash comment"),
            ("* Asterisk comment", "Asterisk comment"),
            ("    // Indented comment", "Indented comment"),
            ("Normal text", "Normal text"),
        ]

        for (input, expected) in testCases {
            XCTAssertEqual(input.removeCommentSymbolPrefix(), expected, "Failed for input: \(input)")
        }
    }

    func testRemoveCommentSymbols() {
        let testCases = [
            ("// Comment at start", "Comment at start"),
            ("Comment at end //", "Comment at end"),
            ("Comment // in // middle", "Comment in middle"),
            ("# Hash comment", "Hash comment"),
            ("Normal text", "Normal text"),
        ]

        for (input, expected) in testCases {
            XCTAssertEqual(input.removeCommentSymbols(), expected, "Failed for input: \(input)")
        }
    }

    // MARK: - Word Segmentation Tests

    func testSegmentWords() {
        let testCases = [
            ("key_value", "key value"),
            ("LaTeX", "LaTeX"),
            ("'UIKit'", "UIKit"),
            ("simpleWord", "simpleWord"),
            ("", ""),
            ("test_case", "test case"),
        ]

        for (input, expected) in testCases {
            XCTAssertEqual(input.segmentWords(), expected, "Failed for input: \(input)")
        }
    }

    // MARK: - Quote Handling Tests

    func testHasQuotesPair() {
        let testCases = [
            ("'text'", true),
            ("\"text\"", true),
            (""text"", true),
            (""text"", true),
            (""text"", true),
            ("text", false),
            ("'text", false),
            ("text'", false),
        ]

        for (input, expected) in testCases {
            XCTAssertEqual(input.hasQuotesPair(), expected, "Failed for input: \(input)")
        }
    }

    func testTryToRemoveQuotes() {
        let testCases = [
            ("'text'", "text"),
            ("\"text\"", "text"),
            (""text"", "text"),
            (""text"", "text"),
            (""text"", "text"),
            ("text", "text"),
            ("'text", "'text"),
            ("text'", "text'"),
        ]

        for (input, expected) in testCases {
            XCTAssertEqual(input.tryToRemoveQuotes(), expected, "Failed for input: \(input)")
        }
    }

    // MARK: - End Punctuation Tests

    func testHasEndPunctuationSuffix() {
        let testCases = [
            ("text.", true),
            ("text!", true),
            ("text?", true),
            ("text.", true),
            ("text…", true),
            ("text", false),
            ("text.", false),
            ("text,", false),
            ("", false),
        ]

        for (input, expected) in testCases {
            XCTAssertEqual(input.hasEndPunctuationSuffix, expected, "Failed for input: \(input)")
        }
    }

    // MARK: - Newline Replacement Tests

    func testReplacingNewlinesWithWhitespace() {
        let testCases = [
            ("line1\nline2", "line1 line2"),
            ("line1\n\nline2", "line1  line2"),
            ("line1   \n   line2", "line1 line2"),
            ("single line", "single line"),
            ("", ""),
            ("\nleading newline", " leading newline"),
        ]

        for (input, expected) in testCases {
            XCTAssertEqual(input.replacingNewlinesWithWhitespace(), expected, "Failed for input: \(input)")
        }
    }

    // MARK: - Integration Tests

    func testHandleInputTextIntegration() {
        // Test complete input handling with various configurations
        let testInput = """
        // This is a comment
        key_value
        testWord
        """

        let result = testInput.handlingInputText()
        XCTAssertFalse(result.contains("//"))
        XCTAssertTrue(result.contains("key value"))
        XCTAssertTrue(result.contains("testWord"))
        XCTAssertTrue(result.splitCodeText().contains("key value"))
    }

    func testComplexCodeSplitting() {
        let testCases = [
            ("XMLHttpRequest", "XML Http Request"),
            ("getUserID", "get User ID"),
            ("parseJSONResponse", "parse JSON Response"),
            ("initializeComponents", "initialize Components"),
        ]

        for (input, expected) in testCases {
            XCTAssertEqual(input.splitCodeText(), expected, "Failed for input: \(input)")
        }
    }

    // MARK: - Performance Tests

    func testPerformanceSplitCodeText() {
        let longString = "anchoredDraggableState" + String(repeating: "testWord", count: 1000)

        measure {
            _ = longString.splitCodeText()
        }
    }

    func testPerformanceRemoveCommentBlockSymbols() {
        var lines = [String]()
        for i in 0 ..< 1000 {
            lines.append("// This is comment number \(i)")
        }
        let longComment = lines.joined(separator: "\n")

        measure {
            _ = longComment.removingCommentBlockSymbols()
        }
    }
}
