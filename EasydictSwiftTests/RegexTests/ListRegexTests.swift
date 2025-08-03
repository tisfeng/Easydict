//
//  ListRegexTests.swift
//  EasydictSwiftTests
//
//  Created by tisfeng on 2025/8/3.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation
import RegexBuilder
import Testing

@testable import Easydict

/// Unit tests for list-related regex patterns defined in Regex+List.swift
@Suite("List Regex Patterns Tests", .tags(.utilities, .unit))
struct ListRegexTests {
    @Test("List With Dot Pattern")
    func listWithDotPattern() {
        let regex = Regex.listWithDotPattern

        // Valid cases - should match
        let validCases = [
            // Numeric lists with dots
            "1. First item",
            "  2. Second item", // with leading whitespace
            "123. Number item",
            "\t3. Tab indented",
            "10. Double digit",
            "1.保持版本控制", // Chinese list without space
            "2.检查代码质量", // Chinese list without space
            "  3.添加测试用例", // Chinese list with indent

            // Letter lists with dots (a-g, A-G only)
            "a. Letter list",
            "A. Capital letter list",
            "d. Last letter",
            "  b. Indented letter",
            "\tc. Tab indented letter",

            // Letter lists with parentheses (a-g, A-G only) - also supported!
            "a) Letter with parentheses",
            "B) Capital letter with parentheses",
            "c） Letter with Chinese parentheses",

            // Roman numeral lists with dots
            "i. Roman numeral list",
            "IV. Roman numeral list",
            "ii. Second roman",
            "x. Roman ten",
            "  v. Indented roman",

            // Edge cases that match due to negative lookahead implementation
            "1.No space after dot", // matches "1." because 'N' is not a digit
            "2.Text", // matches "2." because 'T' is not a digit
            "a.Something", // matches "a." because 'S' is not a digit
        ]

        for input in validCases {
            #expect(input.contains(regex), "Should match: '\(input)'")
        }

        // Invalid cases - should NOT match
        let invalidCases = [
            // Decimal numbers (digit after dot)
            "1.5 Not a list",
            "3.14159",
            "1.2.3",

            // Letters outside a-g, A-G range
            "h. Letter outside range",
            "M. Letter outside range",
            "z. Letter outside range",
            "h) Letter outside range",
            "M) Letter outside range",
            "z) Letter outside range",

            // Multiple letters before dot
            "ab. Multiple letters",
            "Mr. Smith",

            // Numeric parentheses (not supported by dot pattern - only by marker pattern)
            "1) Parentheses list",
            "2） Chinese parentheses",

            // Symbol-based (not supported by dot pattern)
            "• Bullet point",
            "- Dash bullet",
            "* Asterisk bullet",
            "[1] Bracketed number",

            // Missing components
            "1", // no dot
            ". No prefix",
            "  . Just dot",

            // Empty
            "",
            "  ",
        ]

        for input in invalidCases {
            #expect(!input.contains(regex), "Should NOT match: '\(input)'")
        }
    }

    @Test("List Marker Pattern")
    func listMarkerPattern() {
        let regex = Regex.listMarkerPattern

        // Valid cases - should match
        let validCases = [
            // Numeric lists with dots
            "1. First item",
            "  2. Second item",
            "123. Number item",
            "1.保持版本控制",
            "1.No space after dot", // matches due to negative lookahead

            // Numeric lists with parentheses
            "1) First item",
            "  2) Second item",
            "123) Number item",
            "1） Chinese parenthesis",
            "  2） Indented Chinese parenthesis",

            // Letter lists (a-g, A-G only)
            "a. Letter list",
            "A. Capital letter list",
            "d. Last letter",
            "a) Letter with parenthesis",
            "B) Capital letter with parenthesis",
            "c） Letter with Chinese parenthesis",
            "a.Something", // matches due to negative lookahead

            // Roman numeral lists
            "i. Roman numeral list",
            "IV. Roman numeral list",
            "ii. Second roman",
            "x. Roman ten",

            // Bullet symbols (require space after)
            "• Bullet point",
            "- Dash bullet",
            "* Asterisk bullet",
            "§ Section symbol",
            "¶ Paragraph symbol",
            "► Arrow bullet",
            "▪ Square bullet",
            "▫ Hollow square bullet",
            "○ Circle bullet",
            "● Filled circle bullet",
            "◦ Small circle bullet",
            "◾ Black medium small square",
            "◽ White medium small square",
            "  • Indented bullet",
            "\t- Tab indented bullet",

            // Bracketed numbers (require space after)
            "[1] Bracketed number",
            "[42] Multi-digit bracketed",
            "[123] Long number bracketed",
            "  [5] Indented bracketed",
            "\t[7] Tab indented bracketed",
        ]

        for input in validCases {
            #expect(input.contains(regex), "Should match: '\(input)'")
        }

        // Invalid cases - should NOT match
        let invalidCases = [
            // Decimal numbers (digit after dot)
            "1.5 Not a list",
            "3.14159",
            "1.2.3",

            // Letters outside a-g, A-G range
            "h. Letter outside range",
            "M. Letter outside range",
            "z. Letter outside range",

            // Multiple letters before dot
            "ab. Multiple letters",
            "Mr. Smith",

            // Symbols without required space
            "•no space after bullet",
            "-no space after dash",
            "*no space after asterisk",
            "[1]no space after bracket",

            // Missing components
            "1", // no marker symbol
            ". No prefix",
            "  . Just dot",

            // Empty
            "",
            "  ",
        ]

        for input in invalidCases {
            #expect(!input.contains(regex), "Should NOT match: '\(input)'")
        }
    }
}
