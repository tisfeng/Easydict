//
//  Regex+Common.swift
//  Easydict
//
//  Created by tisfeng on 2025/7/6.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation
import RegexBuilder

// MARK: - Common Character Classes for Regex Patterns

extension CharacterClass {
    /// - Important: Default `CharacterClass(.word)` includes CJK characters, so it is not suitable for some cases.
    ///
    /// ASCII letters (a-z, A-Z)
    /// Uses range-based syntax for better performance and clarity
    static let asciiLetters = CharacterClass("a" ... "z", "A" ... "Z")

    /// ASCII digits (0-9)
    /// Uses range-based syntax for better performance and clarity
    static let asciiDigits = CharacterClass("0" ... "9")

    /// Underscore character
    /// Separated for modularity and reusability
    static let underscore = CharacterClass.anyOf("_")

    /// ASCII word characters (a-z, A-Z, 0-9, _)
    /// Combines ASCII letters, digits, and underscore - equivalent to \w but restricted to ASCII
    static let asciiWords = CharacterClass(.asciiLetters, .asciiDigits, .underscore)

    /// ASCII letters and digits (a-z, A-Z, 0-9) - equivalent to \w without underscore
    /// Useful for identifiers where underscore is not allowed
    static let asciiAlphanumeric = CharacterClass(.asciiLetters, .asciiDigits)

    /// CJK characters (Chinese, Japanese, Korean)
    /// Covers CJK Unified Ideographs (U+4E00-U+9FFF) - primarily Chinese characters
    /// Note: Does not include all CJK ranges (Hiragana, Katakana, Hangul, etc.)
    static let cjkChars = CharacterClass("\u{4E00}" ... "\u{9FFF}")

    /// Identifier characters (letters, digits, underscore) - equivalent to ASCII \w
    /// Uses ASCII-only characters to avoid CJK inclusion issues
    static let identifier = CharacterClass(.asciiWords)

    /// Identifier start characters (letters, underscore)
    /// Characters that can start an identifier in most programming languages
    static let identifierStart = CharacterClass(.asciiLetters, .underscore)

    /// Domain name characters (letters, digits, hyphen)
    /// RFC-compliant domain name character set (ASCII only)
    static let domainChars = CharacterClass(.asciiLetters, .asciiDigits, .anyOf("-"))

    /// Email local part characters (letters, digits, special chars)
    /// Common characters allowed in email local part (before @)
    static let emailLocalChars = CharacterClass(.asciiWords, .anyOf(".+-"))

    /// Email domain characters (letters, digits, dot, hyphen)
    /// Characters allowed in email domain part (after @)
    static let emailDomainChars = CharacterClass(.asciiLetters, .asciiDigits, .anyOf(".-"))

    /// Characters to exclude from URLs/paths for OCR text processing
    /// Includes whitespace, CJK characters, and common punctuation that might end sentences
    static let urlExcludedChars = CharacterClass(.whitespace, .cjkChars, .anyOf(",.;:!?"))

    /// Common sentence ending punctuation
    /// Used for text normalization and punctuation handling
    static let sentenceEnding = CharacterClass.anyOf(",.;:!?")

    /// Horizontal whitespace (space and tab)
    /// Excludes newlines and other vertical whitespace
    static let horizontalWhitespace = CharacterClass.anyOf(" \t")

    /// Extended sentence ending punctuation (includes more symbols)
    /// Broader set of punctuation marks that can end sentences
    static let extendedSentenceEnding = CharacterClass.anyOf(".,:;!?")
}

// MARK: - Protection Patterns for OCR Text Processing

extension Regex where Output == Substring {
    //    static let chineseTextRegex = try! Regex(#"\p{Han}+"#) // Matches Chinese characters

    // MARK: - General Text Patterns

    /// Matches Chinese-like text (CJK characters)
    ///
    /// Example:
    /// ```swift
    /// let match = text.wholeMatch(of: .chineseText)
    /// ```
    ///
    /// - Note: \p{Han} is more wider than \u{4E00}-\u{9FFF}
    ///
    /// - SeeAlso: [\p{Script=Han}](https://www.unicode.org/reports/tr18/#General_Category_Property)
    /// - SeeAlso: [4E00..9FFF](https://www.unicode.org/Public/UCD/latest/ucd/Scripts.txt)
    /// - SeeAlso: [\p{L} Unicode Regex Expression](https://www.regular-expressions.info/unicode.html)
    static var chineseText: Self {
        /\p{Han}+/ // /[\u{4E00}-\u{9FFF}]+/
    }

    // MARK: - URL and Network Patterns

    /// Matches URLs with protocol (http://, https://, ftp://, etc.).
    /// Excludes whitespace, CJK characters, and trailing punctuation for OCR text processing
    ///
    /// **Examples:**
    /// - `https://example.com` ✓
    /// - `http://subdomain.example.co.uk/path` ✓
    /// - `https://example.com,` → matches `https://example.com` (excludes comma)
    /// - `https://中文域名.测试` ✗ (excludes CJK characters)
    ///
    /// **Note:** CJK characters are excluded to prevent interference with OCR text processing
    /// **Original regex:** `https?:\/\/[^\s\u4e00-\u9fff,.;:!?]+`
    /// - Note: This regex is designed to match URLs that do not contain CJK characters.
    static var url: Self {
        Regex {
            "http"
            Optionally("s")
            "://"
            OneOrMore {
                CharacterClass(
                    .whitespace,
                    CharacterClass(.cjkChars),
                    .anyOf(",;:!?")
                ).inverted
            }
        }
    }

    /// Matches domain names without protocol (e.g., example.com, subdomain.example.co.uk)
    /// Supports multiple levels of subdomains
    ///
    /// **Examples:**
    /// - `easydict.app` ✓
    /// - `translate.google.com` ✓
    /// - `example.co.uk` ✓
    /// - `sub.domain.example.org` ✓
    /// - `google.com.` → matches `google.com` (excludes period)
    ///
    /// **Original regex:** `[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*\.[a-zA-Z]{2,}`
    static var domain: Self {
        Regex {
            Anchor.wordBoundary
            // First subdomain part
            OneOrMore {
                CharacterClass.domainChars
            }
            // Additional subdomain parts (optional, can repeat)
            ZeroOrMore {
                "."
                OneOrMore {
                    CharacterClass.domainChars
                }
            }
            // Final TLD part - must be at least 2 letters
            "."
            Repeat(2...) {
                CharacterClass.asciiLetters
            }
            Anchor.wordBoundary
        }
    }

    /// Matches email addresses
    /// Excludes trailing punctuation that might be sentence endings
    ///
    /// **Examples:**
    /// - `user@example.com` ✓
    /// - `test.email+tag@subdomain.example.co.uk` ✓
    /// - `user@domain.com.` → matches `user@domain.com` (excludes period)
    ///
    /// **Original regex:** `[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}`
    static var email: Self {
        Regex {
            Anchor.wordBoundary
            OneOrMore {
                CharacterClass.emailLocalChars
            }
            "@"
            OneOrMore {
                CharacterClass.emailDomainChars
            }
            "."
            Repeat(2...) {
                CharacterClass.asciiLetters
            }
            Anchor.wordBoundary
        }
    }

    // MARK: - File System Patterns

    /// Matches Windows-style file paths and Unix paths with drive letters
    /// Excludes trailing punctuation that might be sentence endings
    ///
    /// **Examples:**
    /// - `C:\Users\file.txt` ✓
    /// - `D:/Documents/image.png` ✓
    /// - `/home/user/document.pdf` (won't match - no drive letter)
    ///
    /// **Original regex:** `[a-zA-Z]:[\\\/][^\s\u4e00-\u9fff,.;:!?]+`
    static var filePath: Self {
        Regex {
            One(.word) // Single letter for drive
            ":"
            CharacterClass.anyOf("\\/")
            OneOrMore {
                CharacterClass.urlExcludedChars.inverted
            }
        }
    }

    // MARK: - Programming Code Patterns

    /// Matches programming code patterns (object.property, variable.method)
    ///
    /// **Examples:**
    /// - `array.length` ✓
    /// - `user.getName` ✓
    /// - `document.getElementById` ✓
    ///
    /// **Original regex:** `[a-zA-Z_][a-zA-Z0-9_]*\.[a-zA-Z_][a-zA-Z0-9_]*`
    static var codePattern: Self {
        Regex {
            Anchor.wordBoundary
            CharacterClass.identifierStart
            ZeroOrMore {
                CharacterClass.identifier
            }
            "."
            CharacterClass.identifierStart
            ZeroOrMore {
                CharacterClass.identifier
            }
            Anchor.wordBoundary
        }
    }

    /// Matches function call patterns (object.method(), array.map())
    ///
    /// **Examples:**
    /// - `array.map()` ✓
    /// - `obj.toString()` ✓
    /// - `document.querySelector()` ✓
    ///
    /// **Original regex:** `[a-zA-Z_][a-zA-Z0-9_]*\.[a-zA-Z_][a-zA-Z0-9_]*\(\)`
    static var functionCall: Self {
        Regex {
            CharacterClass.identifierStart
            ZeroOrMore {
                CharacterClass.identifier
            }
            "."
            CharacterClass.identifierStart
            ZeroOrMore {
                CharacterClass.identifier
            }
            "()"
        }
    }

    /// Matches parentheses that are adjacent to alphanumeric characters
    /// Used to protect function calls and method invocations
    ///
    /// **Examples:**
    /// - `func(param)` ✓
    /// - `method(arg1, arg2)` ✓
    /// - `calculate(10, 20)` ✓
    ///
    /// **Original regex:** `[a-zA-Z0-9]\([^)]*\)`
    static var adjacentParentheses: Self {
        Regex {
            CharacterClass.asciiAlphanumeric
            "("
            ZeroOrMore {
                CharacterClass.anyOf(")").inverted
            }
            ")"
        }
    }

    // MARK: - Number and Symbol Patterns

    /// Matches decimal numbers (floating point numbers)
    ///
    /// **Examples:**
    /// - `10.99` ✓
    /// - `3.14159` ✓
    /// - `0.5` ✓
    ///
    /// **Original regex:** `\d+\.\d+`
    static var decimal: Self {
        Regex {
            OneOrMore(.digit)
            "."
            OneOrMore(.digit)
        }
    }

    /// Matches number-like patterns including decimals, version numbers, and other dot-separated numeric sequences
    ///
    /// **Examples:**
    /// - `10.99` ✓ (decimal)
    /// - `3.14159` ✓ (decimal)
    /// - `1.2.3` ✓ (version number)
    /// - `1.2.3.4` ✓ (IP address, version)
    /// - `2.1.0.beta1` ✓ (complex version)
    /// - `10.5.7.129` ✓ (IP address)
    /// - `1.0` ✓ (simple version)
    /// - `123.456.789.012` ✓ (any dot-separated numbers)
    ///
    /// **Pattern Logic:**
    /// - Must start with one or more digits (not letters)
    /// - Followed by one or more groups of: dot + alphanumeric segments
    /// - Supports mixed alphanumeric segments (for beta versions, etc.)
    /// - Uses word boundaries to ensure complete matches
    ///
    /// **Original regex equivalent:** `\b\d+(?:\.[a-zA-Z0-9]+)+\b`
    static var numberLikePattern: Self {
        Regex {
            Anchor.wordBoundary
            // Must start with digits (not letters)
            OneOrMore(.digit)
            // Followed by one or more dot-separated alphanumeric segments
            OneOrMore {
                "."
                OneOrMore {
                    CharacterClass(.asciiAlphanumeric)
                }
            }
            Anchor.wordBoundary
        }
    }

    /// Matches ellipsis (three consecutive dots)
    ///
    /// **Examples:**
    /// - `...` ✓
    /// - `待续...` (contains ellipsis) ✓
    ///
    /// **Original regex:** `\.\.\.`
    static var ellipsis: Self {
        Regex {
            "..."
        }
    }

    // MARK: - Spacing and Formatting Patterns

    /// Matches multiple consecutive horizontal whitespace (2 or more spaces/tabs)
    /// Used for normalizing excessive spacing while preserving line breaks
    ///
    /// **Examples:**
    /// - `"Hello    world"` → matches `"    "` (4 spaces)
    /// - `"text  \t  more"` → matches `"  \t  "` (mixed spaces/tabs)
    ///
    /// **Original regex:** `[ \t]{2,}`
    static var multipleHorizontalWhitespace: Self {
        Regex {
            Repeat(2...) {
                CharacterClass.horizontalWhitespace
            }
        }
    }

    /// Matches whitespace around decimal points for normalization
    /// Captures the digits before and after the decimal point
    ///
    /// **Examples:**
    /// - `"10 . 99"` → captures "10" and "99"
    /// - `"3.14"` → captures "3" and "14"
    /// - `"0 .5"` → captures "0" and "5"
    ///
    /// **Original regex:** `(\d+)[ \t]*\.[ \t]*(\d+)`
    static var decimalWithSpacing: Regex<(Substring, Substring, Substring)> {
        Regex<(Substring, Substring, Substring)> {
            Capture {
                OneOrMore(.digit)
            }
            ZeroOrMore {
                CharacterClass.horizontalWhitespace
            }
            "."
            ZeroOrMore {
                CharacterClass.horizontalWhitespace
            }
            Capture {
                OneOrMore(.digit)
            }
        }
    }

    /// Matches whitespace around dots in number-like patterns (decimals, versions, IPs)
    /// Normalizes spacing between numeric segments
    ///
    /// **Examples:**
    /// - `"1 . 2 . 3"` → normalizes to "1.2.3"
    /// - `"10 . 99"` → normalizes to "10.99"
    /// - `"1 .2. 3 . 4"` → normalizes to "1.2.3.4"
    /// - `"192 . 168.1. 1"` → normalizes to "192.168.1.1"
    ///
    /// **Pattern Logic:**
    /// - Must start with digits (not letters)
    /// - Followed by one or more: optional whitespace + dot + optional whitespace + alphanumeric segment
    /// - Supports mixed alphanumeric segments for versions like "1.2.beta"
    /// - Uses word boundaries for precise matching
    ///
    /// **Original regex equivalent:** `\b\d+(?:[ \t]*\.[ \t]*[a-zA-Z0-9]+)+\b`
    static var numberPatternWithSpacing: Self {
        Regex {
            Anchor.wordBoundary
            // Must start with digits (not letters)
            OneOrMore(.digit)
            // One or more dot-separated segments with optional spacing
            OneOrMore {
                ZeroOrMore {
                    CharacterClass.horizontalWhitespace
                }
                "."
                ZeroOrMore {
                    CharacterClass.horizontalWhitespace
                }
                OneOrMore {
                    CharacterClass(.asciiAlphanumeric)
                }
            }
            Anchor.wordBoundary
        }
    }

    /// Matches whitespace before punctuation marks
    /// Captures the punctuation for replacement
    ///
    /// **Examples:**
    /// - `"Hello , world"` → captures ","
    /// - `"Test   !"` → captures "!"
    ///
    /// **Original regex:** `[ \t]+([,.;:!?])`
    static var whitespaceBeforePunctuation: Regex<(Substring, Substring)> {
        Regex<(Substring, Substring)> {
            OneOrMore {
                CharacterClass.horizontalWhitespace
            }
            Capture {
                CharacterClass.sentenceEnding
            }
        }
    }

    /// Matches punctuation followed by non-whitespace (missing space)
    /// Captures both the punctuation and the following character
    ///
    /// **Examples:**
    /// - `"Hello,world"` → captures "," and "w"
    /// - `"Test!Now"` → captures "!" and "N"
    ///
    /// **Original regex:** `([,.;:!?])([^\s])`
    static var punctuationWithoutSpace: Regex<(Substring, Substring, Substring)> {
        Regex<(Substring, Substring, Substring)> {
            Capture {
                CharacterClass.sentenceEnding
            }
            Capture {
                CharacterClass(.whitespace).inverted
            }
        }
    }

    /// Matches three or more consecutive newlines
    /// Used to normalize excessive line breaks
    ///
    /// **Examples:**
    /// - `"Line1\n\n\n\nLine2"` → matches `"\n\n\n\n"`
    /// - `"Text\n\n\nMore"` → matches `"\n\n\n"`
    ///
    /// **Original regex:** `\n{3,}`
    static var excessiveNewlines: Self {
        Regex {
            Repeat(3...) {
                "\n"
            }
        }
    }

    /// Matches horizontal whitespace after newlines
    /// Used to clean up indentation artifacts from OCR
    ///
    /// **Examples:**
    /// - `"Line1\n   Line2"` → matches `"\n   "`
    /// - `"Text\n\t\tMore"` → matches `"\n\t\t"`
    ///
    /// **Original regex:** `\n[ \t]+`
    static var whitespaceAfterNewline: Self {
        Regex {
            "\n"
            OneOrMore {
                CharacterClass.horizontalWhitespace
            }
        }
    }

    /// Matches horizontal whitespace before newlines
    /// Used to clean up trailing whitespace
    ///
    /// **Examples:**
    /// - `"Line1   \nLine2"` → matches `"   \n"`
    /// - `"Text\t\t\nMore"` → matches `"\t\t\n"`
    ///
    /// **Original regex:** `[ \t]+\n`
    static var whitespaceBeforeNewline: Self {
        Regex {
            OneOrMore {
                CharacterClass.horizontalWhitespace
            }
            "\n"
        }
    }

    // MARK: - OCR Error Patterns

    /// Matches lowercase 'l' at word boundaries that should be 'I'
    /// Common OCR error where 'I' is misread as 'l'
    ///
    /// **Examples:**
    /// - `"l think"` → matches the 'l' before " think"
    /// - `"l am"` → matches the 'l' before " am"
    /// - `"l."` → matches the 'l' before "."
    /// - `"l've"` → matches the 'l' before "'ve"
    /// - `"l'll"` → matches the 'l' before "'ll"
    /// - `"l'm"` → matches the 'l' before "'m"
    /// - `"l'd"` → matches the 'l' before "'d"
    ///
    /// **Original regex:** `\bl(?=[ \t]|$|[.,:;!?]|'(?:ve|ll|m|d))`
    static var lowercaseLAsI: Self {
        Regex {
            Anchor.wordBoundary
            "l"
            Lookahead {
                ChoiceOf {
                    CharacterClass.horizontalWhitespace
                    Anchor.endOfSubject
                    CharacterClass.extendedSentenceEnding
                    // Match specific contractions: 've, 'll, 'm, 'd
                    Regex {
                        "'"
                        ChoiceOf {
                            "ve"
                            "ll"
                            "m"
                            "d"
                        }
                    }
                }
            }
        }
    }
}
