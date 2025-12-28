//
//  StringCodeSplittingTests.swift
//  EasydictTests
//
//  Created by Claude on 2025/1/29.
//  Copyright © 2025 izual. All rights reserved.
//

import Testing

@testable import Easydict

/// Tests for String code text splitting extensions
@Suite("String Code Splitting", .tags(.utilities, .unit))
struct StringCodeSplittingTests {
    // MARK: - Camel Case Text Splitting

    @Test("Camel case text splitting")
    func camelCaseTextSplitting() {
        let testCases = [
            ("anchoredDraggableState", "anchored Draggable State"),
            ("AnchoredDraggableState", "Anchored Draggable State"),
            ("GetHTTP", "Get HTTP"),
            ("GetHTTPCode", "Get HTTP Code"),
            ("simpleWord", "simple Word"),
            ("", ""),
            ("XMLHttpRequest", "XML Http Request"),
        ]

        for (input, expected) in testCases {
            #expect(input.splitCamelCaseText() == expected, "Failed for input: \(input)")
        }
    }

    // MARK: - Snake Case Text Splitting

    @Test("Snake case text splitting")
    func snakeCaseTextSplitting() {
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

    // MARK: - Generic Code Text Splitting

    @Test("Generic code text splitting")
    func codeTextSplitting() {
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

    // MARK: - Complex Code Splitting Patterns

    @Test("Complex code splitting patterns")
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
