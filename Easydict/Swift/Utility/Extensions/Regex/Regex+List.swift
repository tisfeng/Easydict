//
//  Regex+List.swift
//  Easydict
//
//  Created by tisfeng on 2025/8/3.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation
import RegexBuilder

/// Regex extensions for matching list markers in text
extension Regex where Output == Substring {
    /// Matches list markers with dots at the beginning of lines
    /// Used to protect list items during OCR text normalization
    ///
    /// **Supported formats:**
    /// - Numbered lists with dots: `1.`, `2.`, `123.`
    /// - Letter lists with dots: `a.`, `B.`, `c.` (limited to a-g, A-G)
    /// - Roman numeral lists with dots: `i.`, `IV.`, `v.`
    ///
    /// **Examples:**
    /// - `"1. Item"` ✓, `"a. Item"` ✓, `"i. Item"` ✓
    /// - `"  2. Indented"` ✓, `"\tB. Tab indented"` ✓
    /// - `"3.14"` ✗ (decimal number - excluded by negative lookahead)
    /// - `"2) Item"` ✗ (parentheses - not included, use listMarkerPattern instead)
    ///
    /// **Note:** Excludes decimal numbers and parentheses-based lists
    static var listWithDotPattern: Self {
        Regex {
            Anchor.startOfLine
            ZeroOrMore(CharacterClass.horizontalWhitespace)
            dotBasedListMarkers
        }
    }

    /// Comprehensive list marker pattern that matches various list formats
    /// Used by `String.hasListPrefix` to detect list items
    ///
    /// **Supported formats:**
    /// - Numbered lists: `1.`, `2)`, `3）` (with Chinese parentheses)
    /// - Letter lists: `a.`, `B)`, `c.`, etc. (limited to a-g, A-G)
    /// - Roman numerals: `i.`, `IV.`, `v.`, etc.
    /// - Bullet points: `•`, `-`, `*`, `►`, `○`, etc. (requires space after)
    /// - Bracketed numbers: `[1]`, `[2]`, etc. (requires space after)
    ///
    /// **Examples:**
    /// - `"1. Item"` ✓, `"2) Item"` ✓, `"3） Item"` ✓
    /// - `"a. Item"` ✓, `"B) Item"` ✓
    /// - `"i. Item"` ✓, `"IV. Item"` ✓
    /// - `"• Item"` ✓, `"- Item"` ✓, `"* Item"` ✓
    /// - `"[1] Item"` ✓, `"[42] Item"` ✓
    ///
    /// **Note:** For symbol-based markers (bullets), whitespace after the marker is required
    /// to distinguish from regular text usage of these symbols.
    static var listMarkerPattern: Self {
        Regex {
            Anchor.startOfLine
            ZeroOrMore(CharacterClass.horizontalWhitespace)
            ChoiceOf {
                dotBasedListMarkers
                numberedListWithParentheses
                bulletSymbols
                bracketedNumbers
            }
        }
    }

    // MARK: - List Pattern Components (Private helpers)

    /// Common list marker components that use dots (number, letter, roman numeral lists)
    /// Used as building blocks for other list patterns
    private static var dotBasedListMarkers: Self {
        Regex {
            ChoiceOf {
                numberedListWithDot
                letterLists
                romanNumeralLists
            }
        }
    }

    /// Private helper: Matches numbered lists with dots (e.g., 1., 2., 3.)
    /// Excludes decimal numbers like 3.14 by using negative lookahead
    ///
    /// **Examples:**
    /// - `"1."` ✓ (list marker)
    /// - `"123."` ✓ (list marker)
    /// - `"3.14"` ✗ (decimal number - excluded)
    /// - `"1.5"` ✗ (decimal number - excluded)
    ///
    /// **Pattern Logic:**
    /// - Matches one or more digits followed by a dot
    /// - Uses negative lookahead to ensure no digit follows the dot
    /// - This prevents matching decimal numbers while allowing list markers
    private static var numberedListWithDot: Self {
        Regex {
            OneOrMore(.digit)
            "."
            // Negative lookahead: ensure it's not followed by another digit (to exclude decimals like 3.14)
            NegativeLookahead {
                One(.digit)
            }
        }
    }

    /// Private helper: Matches numbered lists with parentheses (e.g., 1), 2), 3）)
    private static var numberedListWithParentheses: Self {
        Regex {
            OneOrMore(.digit)
            ChoiceOf {
                ")" // Regular parenthesis: 1)
                "）" // Chinese parenthesis: 1）
            }
        }
    }

    /// Private helper: Matches letter lists (a-g, A-G only, e.g., a., B), c.)
    private static var letterLists: Self {
        Regex {
            One(CharacterClass("a" ... "g", "A" ... "G"))
            ChoiceOf {
                "." // Letter with dot: a.
                ")" // Letter with parenthesis: a)
                "）" // Letter with Chinese parenthesis: a）
            }
        }
    }

    /// Private helper: Matches Roman numeral lists (e.g., i., IV., xiii.)
    private static var romanNumeralLists: Self {
        Regex {
            OneOrMore(CharacterClass.anyOf("ivxIVX"))
            "."
        }
    }

    /// Private helper: Matches bullet symbols (requires whitespace after)
    private static var bulletSymbols: Self {
        Regex {
            ChoiceOf {
                "•" // Bullet point
                "-" // Dash
                "*" // Asterisk
                "§" // Section symbol
                "¶" // Paragraph symbol
                "►" // Arrow bullet
                "▪" // Square bullet
                "▫" // Hollow square bullet
                "○" // Circle bullet
                "●" // Filled circle bullet
                "◦" // Small circle bullet
                "◾" // Black medium small square
                "◽" // White medium small square
            }
            OneOrMore(CharacterClass.horizontalWhitespace)
        }
    }

    /// Private helper: Matches bracketed numbers (e.g., [1], [42])
    private static var bracketedNumbers: Self {
        Regex {
            "["
            OneOrMore(.digit)
            "]"
            OneOrMore(CharacterClass.horizontalWhitespace)
        }
    }
}
