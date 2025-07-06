//
//  Regex+Common.swift
//  Easydict
//
//  Created by tisfeng on 2025/7/6.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation
import RegexBuilder

// MARK: - Protection Patterns for OCR Text Processing

extension Regex where Output == Substring {
    static let chineseTextRegex = try! Regex(#"\p{Han}+"#) // Matches Chinese characters

    // MARK: - General Text Patterns

    /// Precompiled regex that matches one or more Chinese Han characters.
    /// Usage: `let match = text.wholeMatch(of: .chineseText)`
    static var chineseText: Self {
        // Literals are compile‑time, `try!` can't actually fail here.
        try! Regex(#"\p{Han}+"#)
    }

    // MARK: - URL and Network Patterns

    /// Matches URLs with protocol (http://, https://, ftp://, etc.)
    /// Excludes trailing punctuation that might be sentence endings
    ///
    /// **Examples:**
    /// - `https://example.com` ✓
    /// - `http://subdomain.example.co.uk/path` ✓
    /// - `https://example.com,` → matches `https://example.com` (excludes comma)
    ///
    /// **Original regex:** `https?:\/\/[^\s\u4e00-\u9fff,.;:!?]+`
    static var url: Self {
        Regex {
            "http"
            Optionally("s")
            "://"
            OneOrMore {
                CharacterClass.anyOf(" \t\n\r\u{4e00}-\u{9fff},.;:!?").inverted
            }
        }
    }

    /// Matches domain names without protocol (e.g., example.com, subdomain.example.co.uk)
    /// Excludes trailing punctuation that might be sentence endings
    ///
    /// **Examples:**
    /// - `easydict.app` ✓
    /// - `translate.google.com` ✓
    /// - `example.co.uk` ✓
    /// - `google.com.` → matches `google.com` (excludes period)
    ///
    /// **Original regex:** `[a-zA-Z0-9-]+\.[a-zA-Z]{2,}(?:\.[a-zA-Z]{2,})?(?![,.;:!?])`
    static var domain: Self {
        Regex {
            OneOrMore {
                CharacterClass(
                    .anyOf("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-")
                )
            }
            "."
            Repeat(2...) {
                CharacterClass(.word)
            }
            Optionally {
                "."
                Repeat(2...) {
                    CharacterClass(.word)
                }
            }
            NegativeLookahead {
                CharacterClass.anyOf(",.;:!?")
            }
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
    /// **Original regex:** `[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}(?![,.;:!?])`
    static var email: Self {
        Regex {
            OneOrMore {
                CharacterClass(
                    .anyOf("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._%+-")
                )
            }
            "@"
            OneOrMore {
                CharacterClass(
                    .anyOf("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.-")
                )
            }
            "."
            Repeat(2...) {
                CharacterClass(.word)
            }
            NegativeLookahead {
                CharacterClass.anyOf(",.;:!?")
            }
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
            CharacterClass(.word)
            ":"
            CharacterClass.anyOf("\\/")
            OneOrMore {
                CharacterClass.anyOf(" \t\n\r\u{4e00}-\u{9fff},.;:!?").inverted
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
            CharacterClass(.anyOf("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_"))
            ZeroOrMore {
                CharacterClass(
                    .anyOf("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_")
                )
            }
            "."
            CharacterClass(.anyOf("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_"))
            ZeroOrMore {
                CharacterClass(
                    .anyOf("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_")
                )
            }
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
            CharacterClass(.anyOf("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_"))
            ZeroOrMore {
                CharacterClass(
                    .anyOf("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_")
                )
            }
            "."
            CharacterClass(.anyOf("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_"))
            ZeroOrMore {
                CharacterClass(
                    .anyOf("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_")
                )
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
            CharacterClass(.anyOf("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"))
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
}
