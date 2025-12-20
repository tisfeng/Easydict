//
//  StringCommentHandlingTests.swift
//  EasydictTests
//
//  Created by Claude on 2025/1/29.
//  Copyright © 2025 izual. All rights reserved.
//

import Testing

@testable import Easydict

/// Tests for String comment handling extensions
@Suite("String Comment Handling", .tags(.utilities, .unit))
struct StringCommentHandlingTests {
    // MARK: - Comment Symbol Detection

    @Test("Comment symbol detection")
    func commentSymbolDetection() {
        let testCases = [
            ("# This is a comment\n// Another comment", true),
            ("# Comment\nNot a comment", false),
            ("/* Block comment */\n* Another", false),
            ("Normal text\n// Comment", false),
            ("// Only comments\n# More comments\n* And more", true),
            ("", false),
            ("   # Indented comment", true),
        ]

        for (input, expected) in testCases {
            #expect(input.allLineStartsWithCommentSymbol() == expected, "Failed for input: \(input)")
        }
    }

    // MARK: - Comment Block Removal

    @Test("Comment block removal")
    func commentBlockRemoval() {
        let input = """
        // This is a comment
        // with multiple lines
        """

        let result = input.removingCommentBlockSymbols()
        #expect(result.contains("This is a comment"))
        #expect(result.contains("with multiple lines"))
        #expect(!result.contains("//"))
    }

    // MARK: - Comment Prefix Removal

    @Test("Comment prefix removal")
    func commentPrefixRemoval() {
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

    // MARK: - Inline Comment Removal

    @Test("Inline comment removal")
    func inlineCommentRemoval() {
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
}
