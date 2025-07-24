//
//  RegexTests.swift
//  EasydictSwiftTests
//
//  Created by tisfeng on 2025/7/6.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation
import RegexBuilder
import Testing

@testable import Easydict

/// Unit tests for common regex patterns defined in Regex+Common.swift
@Suite("Regex Common Patterns Tests", .tags(.utilities, .unit))
struct RegexTests {
    // MARK: - URL and Network Pattern Tests

    @Test("URL Pattern Matching")
    func urlPattern() {
        let regex = Regex.url

        // Valid URLs
        #expect("https://example.com".contains(regex))
        #expect("http://subdomain.example.co.uk/path".contains(regex))
        #expect("https://google.com/search?q=test".contains(regex))
        #expect("http://localhost:8080".contains(regex))

        // URLs with trailing punctuation (should match without punctuation)
        let textWithComma = "Visit https://example.com, it's great!"
        if let match = textWithComma.firstMatch(of: regex) {
            #expect(String(match.output) == "https://example.com")
        } else {
            Issue.record("Should match URL without trailing comma")
        }

        // Invalid URLs
        #expect(!"example.com".contains(regex)) // No protocol
        #expect(!"ftp://example.com".contains(regex)) // Wrong protocol

        // URLs with invalid Chinese characters
        #expect(!"https://中文域名.测试".contains(regex))
    }

    @Test("Domain Pattern Matching")
    func domainPattern() {
        let regex = Regex.domain

        // Valid domains
        #expect("easydict.app".contains(regex))
        #expect("translate.google.com".contains(regex))
        #expect("example.co.uk".contains(regex))
        #expect("sub.domain.example.org".contains(regex))

        // Domains with trailing punctuation (should match without punctuation)
        let textWithPeriod = "Visit google.com."
        if let match = textWithPeriod.firstMatch(of: regex) {
            #expect(String(match.output) == "google.com")
        } else {
            Issue.record("Should match domain without trailing period")
        }

        // Invalid domains
        #expect(!"localhost".contains(regex)) // No TLD
        #expect(!"example".contains(regex)) // No TLD
        #expect(!"a.b".contains(regex)) // TLD too short

        // Domains with invalid Chinese characters
        #expect(!"中文.域名.测试".contains(regex)) // Non-ASCII characters
    }

    @Test("Email Pattern Matching")
    func emailPattern() {
        let regex = Regex.email

        // Valid emails
        #expect("user@example.com".contains(regex))
        #expect("test.email+tag@subdomain.example.co.uk".contains(regex))
        #expect("user123@domain.org".contains(regex))
        #expect("first.last@company.net".contains(regex))

        // Email with trailing punctuation (should match without punctuation)
        let textWithComma = "Contact user@domain.com, thanks"
        if let match = textWithComma.firstMatch(of: regex) {
            #expect(String(match.output) == "user@domain.com")
        } else {
            Issue.record("Should match email without trailing comma")
        }

        // Invalid emails
        #expect(!"invalid.email".contains(regex)) // No @
        #expect(!"@domain.com".contains(regex)) // No local part
        #expect(!"user@".contains(regex)) // No domain

        // Emails with invalid Chinese characters
        #expect(!"用户@域名.测试".contains(regex)) // Non-ASCII characters
    }

    // MARK: - File System Pattern Tests

    @Test("File Path Pattern Matching")
    func filePathPattern() {
        let regex = Regex.filePath

        // Valid Windows paths
        #expect("C:\\Users\\file.txt".contains(regex))
        #expect("D:/Documents/image.png".contains(regex))
        #expect("E:\\Program Files\\app.exe".contains(regex))

        // Invalid paths
        #expect(!"/home/user/document.pdf".contains(regex)) // No drive letter
        #expect(!"~/Documents/file.txt".contains(regex)) // No drive letter
        #expect(!"file.txt".contains(regex)) // Relative path
    }

    // MARK: - Programming Code Pattern Tests

    @Test("Code Pattern Matching")
    func codePattern() {
        let regex = Regex.codePattern // Valid code patterns
        #expect("array.length".contains(regex))
        #expect("user.getName".contains(regex))
        #expect("document.getElementById".contains(regex))
        #expect("obj.property".contains(regex))
        #expect("_private.method".contains(regex))

        // Invalid patterns
        #expect(!"123.invalid".contains(regex)) // Starts with digit
        #expect(!"obj.".contains(regex)) // No property
        #expect(!".method".contains(regex)) // No object
    }

    @Test("Function Call Pattern Matching")
    func functionCallPattern() {
        let regex = Regex.functionCall

        // Valid function calls
        #expect("array.map()".contains(regex))
        #expect("obj.toString()".contains(regex))
        #expect("document.querySelector()".contains(regex))
        #expect("_helper.process()".contains(regex))

        // Invalid patterns
        #expect(!"array.map".contains(regex)) // No parentheses
        #expect(!"function()".contains(regex)) // No object
        #expect(!"obj.method(arg)".contains(regex)) // Has arguments
        #expect(!"func (param)".contains(regex)) // Space between function name and parentheses
    }

    @Test("Adjacent Parentheses Pattern Matching")
    func adjacentParenthesesPattern() {
        let regex = Regex.adjacentParentheses

        // Valid patterns - alphanumeric character directly followed by parentheses
        #expect("func(param)".contains(regex))
        #expect("method(arg1, arg2)".contains(regex))
        #expect("calculate(10, 20)".contains(regex))
        #expect("test()".contains(regex))
        #expect("a()".contains(regex))
        #expect("1(value)".contains(regex))

        // Invalid patterns - strings that should not contain the pattern
        #expect(!"func (param)".contains(regex)) // Space between func and parentheses
        #expect(!"(standalone)".contains(regex)) // No preceding alphanumeric
        #expect(!"only text".contains(regex)) // No parentheses at all
    }

    // MARK: - Number and Symbol Pattern Tests

    @Test("Decimal Pattern Matching")
    func decimalPattern() {
        let regex = Regex.decimal

        // Valid decimals
        #expect("10.99".contains(regex))
        #expect("3.14159".contains(regex))
        #expect("0.5".contains(regex))
        #expect("123.456".contains(regex))

        // Invalid patterns
        #expect(!"10".contains(regex)) // No decimal point
        #expect(!".5".contains(regex)) // No digits before decimal
        #expect(!"10.".contains(regex)) // No digits after decimal
    }

    @Test("Number-like Pattern Matching")
    func numberLikePattern() {
        let regex = Regex.numberLikePattern

        // Valid number patterns (digits only)
        #expect("10.99".contains(regex)) // Decimal
        #expect("3.14159".contains(regex)) // Decimal
        #expect("1.2.3".contains(regex)) // Version number
        #expect("1.2.3.4".contains(regex)) // IP address or version
        #expect("10.5.7.129".contains(regex)) // IP address
        #expect("1.0".contains(regex)) // Simple version
        #expect("123.456.789.012".contains(regex)) // Multi-segment

        // Invalid patterns
        #expect(!"10".contains(regex)) // No dots
        #expect(!".5".contains(regex)) // No digits before first dot
        #expect(!"10.".contains(regex)) // No content after last dot
        #expect(!"1..3".contains(regex)) // Empty segment
        #expect(!"".contains(regex)) // Empty string
        #expect(!"a.b".contains(regex)) // Starts with letter (not digit)
        #expect(!"just.letters".contains(regex)) // Only letters, no digits
        #expect(!"2.1.0.beta1".contains(regex)) // Contains letters - excluded
        #expect(!"5.1.2.RELEASE".contains(regex)) // Contains letters - excluded
        #expect(!"1.2.alpha".contains(regex)) // Contains letters - excluded
    }

    @Test("Ellipsis Pattern Matching")
    func ellipsisPattern() {
        let regex = Regex.ellipsis

        // Valid ellipsis
        #expect("...".contains(regex))
        #expect("待续...".contains(regex))
        #expect("To be continued...".contains(regex))

        // Invalid patterns
        #expect(!"..".contains(regex)) // Only two dots
        // Note: "....." will match the first three dots, so this test should pass
        #expect("....".contains(regex)) // Four dots (matches first three)
    }

    // MARK: - Spacing and Formatting Pattern Tests

    @Test("Multiple Horizontal Whitespace Pattern Matching")
    func multipleHorizontalWhitespacePattern() {
        let regex = Regex.multipleHorizontalWhitespace

        // Valid patterns
        #expect("Hello    world".contains(regex)) // Multiple spaces
        #expect("text  \t  more".contains(regex)) // Mixed spaces and tabs
        #expect("word\t\t\ttab".contains(regex)) // Multiple tabs

        // Invalid patterns
        #expect(!"single space".contains(regex)) // Single space
        #expect(!"no spaces".contains(regex)) // No extra spaces
        #expect(!"line\nbreak".contains(regex)) // Newline, not horizontal space
    }

    @Test("Decimal With Spacing Pattern Matching")
    func decimalWithSpacingPattern() {
        let regex = Regex.decimalWithSpacing

        // Valid patterns with captures
        let testCases = [
            ("10 . 99", "10", "99"),
            ("3.14", "3", "14"),
            ("0 .5", "0", "5"),
            ("7\t.\t8", "7", "8"),
        ]

        for (input, expectedFirst, expectedSecond) in testCases {
            if let match = input.firstMatch(of: regex) {
                #expect(String(match.1) == expectedFirst, "First capture group for '\(input)'")
                #expect(String(match.2) == expectedSecond, "Second capture group for '\(input)'")
            } else {
                Issue.record("Should match decimal with spacing: '\(input)'")
            }
        }

        // Invalid patterns - should not match multiple decimals in sequence
        // Note: "10.99.1" will match "0.9" in the middle, so we test that it doesn't match the intended pattern
        let invalidInput = "10.99.1"
        if let match = invalidInput.firstMatch(of: regex) {
            // If it matches, it should not be the full intended number
            #expect(String(match.1) == "10")
            #expect(String(match.2) == "99")
        }
        #expect("abc.def".firstMatch(of: regex) == nil) // Non-digits
    }

    @Test("Number Pattern With Spacing Matching")
    func numberPatternWithSpacingPattern() {
        let regex = Regex.numberPatternWithSpacing

        // Valid patterns that should be normalized (digits only)
        let validInputs = [
            "1 . 2 . 3", // Version with spaces
            "10.99", // Decimal number
            "1 .2. 3 . 4", // Mixed spacing
            "192 . 168.1. 1", // IP with spaces
        ]

        for input in validInputs {
            #expect(input.contains(regex), "Should match number pattern: '\(input)'")
        }

        // Invalid patterns
        let invalidInputs = [
            "10", // No dots
            ".5", // No content before first dot
            "10.", // No content after last dot
            "1..3", // Empty segment
            "", // Empty string
            "a.b", // Starts with letter (not digit)
            "just.letters", // Only letters, no digits
            "2 .1.0.beta1", // Contains letters - excluded
            "5.1.2.RELEASE", // Contains letters - excluded
            "1 . 2 . alpha", // Contains letters - excluded
            "see version.2.1.0.beta1 for details", // Should not match as a whole
        ]

        for input in invalidInputs {
            #expect(!input.contains(regex), "Should not match: '\(input)'")
        }

        // Test embedded patterns (should match the number part)
        let embeddedTests = [
            ("version.1.2", "1.2"),
            ("app version 1.2.3 is here", "1.2.3"),
        ]

        for (input, expectedMatch) in embeddedTests {
            if let match = input.firstMatch(of: regex) {
                #expect(
                    String(match.output) == expectedMatch,
                    "Should match '\(expectedMatch)' in '\(input)'"
                )
            } else {
                Issue.record("Should find number pattern in: '\(input)'")
            }
        }
    }

    @Test("Whitespace Before Punctuation Pattern Matching")
    func whitespaceBeforePunctuationPattern() {
        let regex = Regex.whitespaceBeforePunctuation

        // Valid patterns with captures
        let testCases = [
            ("Hello , world", ","),
            ("Test   !", "!"),
            ("Question ?", "?"),
            ("End .", "."),
        ]

        for (input, expectedPunctuation) in testCases {
            if let match = input.firstMatch(of: regex) {
                #expect(
                    String(match.1) == expectedPunctuation, "Punctuation capture for '\(input)'"
                )
            } else {
                Issue.record("Should match whitespace before punctuation: '\(input)'")
            }
        }

        // Invalid patterns
        #expect("Hello,world".firstMatch(of: regex) == nil) // No space before punctuation
        #expect("Normal text".firstMatch(of: regex) == nil) // No punctuation
    }

    @Test("Punctuation Without Space Pattern Matching")
    func punctuationWithoutSpacePattern() {
        let regex = Regex.punctuationWithoutSpace

        // Valid patterns with captures
        let testCases = [
            ("Hello,world", ",", "w"),
            ("Test!Now", "!", "N"),
            ("Question?Answer", "?", "A"),
            ("End.Start", ".", "S"),
        ]

        for (input, expectedPunctuation, expectedChar) in testCases {
            if let match = input.firstMatch(of: regex) {
                #expect(
                    String(match.1) == expectedPunctuation, "Punctuation capture for '\(input)'"
                )
                #expect(
                    String(match.2) == expectedChar, "Following character capture for '\(input)'"
                )
            } else {
                Issue.record("Should match punctuation without space: '\(input)'")
            }
        }

        // Invalid patterns
        #expect("Hello, world".firstMatch(of: regex) == nil) // Has space after punctuation
        #expect("End.".firstMatch(of: regex) == nil) // Punctuation at end
    }

    @Test("Excessive Newlines Pattern Matching")
    func excessiveNewlinesPattern() {
        let regex = Regex.excessiveNewlines

        // Valid patterns
        #expect("Line1\n\n\n\nLine2".contains(regex)) // Four newlines
        #expect("Text\n\n\nMore".contains(regex)) // Three newlines
        #expect("Start\n\n\n\n\nEnd".contains(regex)) // Five newlines

        // Invalid patterns
        #expect(!"Line1\nLine2".contains(regex)) // Single newline
        #expect(!"Line1\n\nLine2".contains(regex)) // Double newline
    }

    @Test("Whitespace After Newline Pattern Matching")
    func whitespaceAfterNewlinePattern() {
        let regex = Regex.whitespaceAfterNewline

        // Valid patterns
        #expect("Line1\n   Line2".contains(regex)) // Spaces after newline
        #expect("Text\n\t\tMore".contains(regex)) // Tabs after newline
        #expect("Start\n \t End".contains(regex)) // Mixed spaces and tabs

        // Invalid patterns
        #expect(!"Line1\nLine2".contains(regex)) // No whitespace after newline
        #expect(!"Text\n\nMore".contains(regex)) // Another newline, not whitespace
    }

    @Test("Whitespace Before Newline Pattern Matching")
    func whitespaceBeforeNewlinePattern() {
        let regex = Regex.whitespaceBeforeNewline

        // Valid patterns
        #expect("Line1   \nLine2".contains(regex)) // Spaces before newline
        #expect("Text\t\t\nMore".contains(regex)) // Tabs before newline
        #expect("Start \t\nEnd".contains(regex)) // Mixed spaces and tabs

        // Invalid patterns
        #expect(!"Line1\nLine2".contains(regex)) // No whitespace before newline
        #expect(!"Text\n\nMore".contains(regex)) // Another newline, not whitespace
    }

    // MARK: - List Pattern Tests

    @Test("List With Dot Pattern Matching")
    func listWithDotPattern() {
        let regex = Regex.listWithDotPattern

        // Valid numeric list patterns
        let validNumericLists = [
            "1. First item",
            "  2. Second item", // with leading whitespace
            "123. Number item",
            "\t3. Tab indented",
            "10. Double digit",
            "1.保持版本控制", // Chinese list without space
            "2.检查代码质量", // Chinese list without space
            "  3.添加测试用例", // Chinese list with indent
            "4.修复错误", // Chinese list
        ]

        for input in validNumericLists {
            #expect(input.contains(regex), "Should match numeric list: '\(input)'")
        }

        // Valid letter list patterns
        let validLetterLists = [
            "a. Letter list",
            "A. Capital letter list",
            "z. Last letter",
            "  b. Indented letter",
            "\tc. Tab indented letter",
        ]

        for input in validLetterLists {
            #expect(input.contains(regex), "Should match letter list: '\(input)'")
        }

        // Valid Roman numeral list patterns
        let validRomanLists = [
            "i. Roman numeral list",
            "IV. Roman numeral list",
            "ii. Second roman",
            "x. Roman ten",
            "  v. Indented roman",
        ]

        for input in validRomanLists {
            #expect(input.contains(regex), "Should match roman numeral list: '\(input)'")
        }

        // Invalid patterns - not list items
        let invalidPatterns = [
            "1.5 Not a list", // decimal number (digit after dot)
            "1.2.3", // version number (digit after dot)
            "Mr. Smith", // abbreviation
            "3.14159", // mathematical constant
            "file.txt", // file extension
            "www.example.com", // domain
            "1.No space after dot", // no whitespace or CJK after dot (ASCII letter after dot)
            "ab. Multiple letters", // multiple letters before dot
            "1", // no dot
            ". No prefix", // no number/letter before dot
            "  . Just dot", // just dot with spaces
        ]

        for input in invalidPatterns {
            #expect(!input.contains(regex), "Should NOT match non-list pattern: '\(input)'")
        }

        // Edge cases
        let edgeCases = [
            ("Multi-line text\n2. Second line", true), // should match second line
            ("Not a list\n1. But this is", true), // should match second line
            ("1. First\n2. Second", true), // should match both lines
        ]

        for (input, shouldMatch) in edgeCases {
            if shouldMatch {
                #expect(input.contains(regex), "Should match edge case: '\(input)'")
            } else {
                #expect(!input.contains(regex), "Should NOT match edge case: '\(input)'")
            }
        }

        // Test specific matches to ensure we capture the right part
        let testInput = "1. First item"
        if let match = testInput.firstMatch(of: regex) {
            #expect(String(match.output) == "1. ", "Should match list marker with trailing space")
        } else {
            Issue.record("Should match list marker in: '\(testInput)'")
        }

        let testInputWithIndent = "  a. Letter item"
        if let match = testInputWithIndent.firstMatch(of: regex) {
            #expect(String(match.output) == "  a. ", "Should match indented list marker")
        } else {
            Issue.record("Should match indented list marker in: '\(testInputWithIndent)'")
        }

        // Test Chinese list format
        let chineseTestInput = "1.保持版本控制"
        if let match = chineseTestInput.firstMatch(of: regex) {
            #expect(
                String(match.output) == "1.保",
                "Should match Chinese list marker with first CJK character"
            )
        } else {
            Issue.record("Should match Chinese list marker in: '\(chineseTestInput)'")
        }

        let indentedChineseTestInput = "  3.添加测试用例"
        if let match = indentedChineseTestInput.firstMatch(of: regex) {
            #expect(String(match.output) == "  3.添", "Should match indented Chinese list marker")
        } else {
            Issue.record(
                "Should match indented Chinese list marker in: '\(indentedChineseTestInput)'"
            )
        }
    }

    // MARK: - OCR Error Pattern Tests

    @Test("Lowercase L as I Pattern Matching")
    func lowercaseLAsIPattern() {
        let regex = Regex.lowercaseLAsI

        // Valid patterns (lowercase 'l' that should be 'I')
        #expect("l think".contains(regex)) // 'l' before space
        #expect("l am".contains(regex)) // 'l' before space
        #expect("l.".contains(regex)) // 'l' before period
        #expect("l,".contains(regex)) // 'l' before comma
        #expect("l!".contains(regex)) // 'l' before exclamation

        let endOfStringTest = "Hello l"
        #expect(endOfStringTest.contains(regex)) // 'l' at end of string

        // Invalid patterns
        #expect(!"hello".contains(regex)) // 'l' not at word boundary
        #expect(!"la".contains(regex)) // 'l' followed by letter
        #expect(!"l1".contains(regex)) // 'l' followed by digit
    }

    // MARK: - Chinese Text Pattern Tests

    @Test("Chinese Text Pattern Matching")
    func chineseTextPattern() {
        let regex = Regex.chineseText

        // Valid Chinese text
        #expect("你好".contains(regex))
        #expect("中文测试".contains(regex))
        #expect("汉字".contains(regex))
        #expect("简体中文繁體中文".contains(regex))

        // Valid Japanese(Kanji) and Korean(Hanja) text
        #expect("日本語テスト".contains(regex)) // Japanese Kanji
        #expect("韓國".contains(regex)) // Korean Hanja

        // Invalid patterns
        #expect(!"Hello".contains(regex)) // English text
        #expect(!"123".contains(regex)) // Numbers
        #expect(!"こんにちは".contains(regex)) // Japanese (Hiragana)
        #expect(!"한글".contains(regex)) // Korean
    }

    // MARK: - Character Class Tests

    @Test("ASCII Character Classes")
    func asciiCharacterClasses() {
        // Test ASCII letters
        let asciiLetterRegex = Regex { CharacterClass.asciiLetters }
        #expect("a".wholeMatch(of: asciiLetterRegex) != nil)
        #expect("Z".wholeMatch(of: asciiLetterRegex) != nil)
        #expect("5".wholeMatch(of: asciiLetterRegex) == nil)
        #expect("_".wholeMatch(of: asciiLetterRegex) == nil)
        #expect("中".wholeMatch(of: asciiLetterRegex) == nil)

        // Test ASCII digits
        let asciiDigitRegex = Regex { CharacterClass.asciiDigits }
        #expect("5".wholeMatch(of: asciiDigitRegex) != nil)
        #expect("0".wholeMatch(of: asciiDigitRegex) != nil)
        #expect("9".wholeMatch(of: asciiDigitRegex) != nil)
        #expect("a".wholeMatch(of: asciiDigitRegex) == nil)
        #expect("_".wholeMatch(of: asciiDigitRegex) == nil)

        // Test ASCII alphanumeric
        let asciiAlphanumericRegex = Regex { CharacterClass.asciiAlphanumeric }
        #expect("a".wholeMatch(of: asciiAlphanumericRegex) != nil)
        #expect("Z".wholeMatch(of: asciiAlphanumericRegex) != nil)
        #expect("5".wholeMatch(of: asciiAlphanumericRegex) != nil)
        #expect("_".wholeMatch(of: asciiAlphanumericRegex) == nil) // Excludes underscore
        #expect("中".wholeMatch(of: asciiAlphanumericRegex) == nil) // Excludes CJK

        // Test ASCII words (includes underscore)
        let asciiWordsRegex = Regex { CharacterClass.asciiWords }
        #expect("a".wholeMatch(of: asciiWordsRegex) != nil)
        #expect("5".wholeMatch(of: asciiWordsRegex) != nil)
        #expect("_".wholeMatch(of: asciiWordsRegex) != nil) // Includes underscore
        #expect("中".wholeMatch(of: asciiWordsRegex) == nil) // Excludes CJK
    }

    @Test("CJK Character Class")
    func cjkCharacterClass() {
        let cjkRegex = Regex { CharacterClass.cjkChars }

        // Should match Chinese characters
        #expect("中".wholeMatch(of: cjkRegex) != nil)
        #expect("文".wholeMatch(of: cjkRegex) != nil)
        #expect("测".wholeMatch(of: cjkRegex) != nil)
        #expect("试".wholeMatch(of: cjkRegex) != nil)

        // Should NOT match non-CJK characters
        #expect("a".wholeMatch(of: cjkRegex) == nil)
        #expect("5".wholeMatch(of: cjkRegex) == nil)
        #expect("_".wholeMatch(of: cjkRegex) == nil)
        #expect(" ".wholeMatch(of: cjkRegex) == nil)

        // Note: Current range covers primarily Chinese characters
        // Japanese Hiragana/Katakana and Korean Hangul are in different Unicode ranges
        #expect("ひ".wholeMatch(of: cjkRegex) == nil) // Hiragana
        #expect("한".wholeMatch(of: cjkRegex) == nil) // Hangul
    }

    @Test("Domain and Email Character Classes")
    func domainEmailCharacterClasses() {
        // Test domain characters
        let domainRegex = Regex { CharacterClass.domainChars }
        #expect("a".wholeMatch(of: domainRegex) != nil)
        #expect("5".wholeMatch(of: domainRegex) != nil)
        #expect("-".wholeMatch(of: domainRegex) != nil)
        #expect("_".wholeMatch(of: domainRegex) == nil) // Not allowed in domains
        #expect(".".wholeMatch(of: domainRegex) == nil) // Handled separately

        // Test email local characters
        let emailLocalRegex = Regex { CharacterClass.emailLocalChars }
        #expect("a".wholeMatch(of: emailLocalRegex) != nil)
        #expect("5".wholeMatch(of: emailLocalRegex) != nil)
        #expect("_".wholeMatch(of: emailLocalRegex) != nil)
        #expect(".".wholeMatch(of: emailLocalRegex) != nil)
        #expect("+".wholeMatch(of: emailLocalRegex) != nil)
        #expect("-".wholeMatch(of: emailLocalRegex) != nil)

        // Test email domain characters
        let emailDomainRegex = Regex { CharacterClass.emailDomainChars }
        #expect("a".wholeMatch(of: emailDomainRegex) != nil)
        #expect("5".wholeMatch(of: emailDomainRegex) != nil)
        #expect(".".wholeMatch(of: emailDomainRegex) != nil)
        #expect("-".wholeMatch(of: emailDomainRegex) != nil)
        #expect("_".wholeMatch(of: emailDomainRegex) == nil) // Not allowed in domain
        #expect("+".wholeMatch(of: emailDomainRegex) == nil) // Not allowed in domain
    }

    @Test("Test NSRegularExpression Regex")
    func testNSRegularExpressionRegex() {
        let text = "Hello, 世界! 123 café@#$"

        // \w: Word characters are [\p{Ll}\p{Lu}\p{Lt}\p{Lo}\p{Nd}].
        // Docs: https://developer.apple.com/documentation/foundation/nsregularexpression
        let pattern = "\\w+"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: text.utf16.count)

        let matches = regex?.matches(in: text, options: [], range: range) ?? []
        let matchedStrings = matches.map { match in
            String(text[Range(match.range, in: text)!])
        }
        print("Matched strings: \(matchedStrings)") // ["Hello", "世界", "123", "café"]
        #expect(matchedStrings == ["Hello", "世界", "123", "café"])
    }
}
