//
//  StringTextCleaningTests.swift
//  EasydictTests
//
//  Created by Claude on 2025/1/30.
//  Copyright © 2025 izual. All rights reserved.
//

@testable import Easydict
import Testing

/// Tests for String text cleaning extensions
@Suite("String Text Cleaning", .tags(.utilities, .unit))
struct StringTextCleaningTests {
    // MARK: - Non-Normal Characters Removal

    @Test("Remove all non-normal characters")
    func removeNonNormalCharacters() {
        let complexText = "Hello, 世界! 123 café@#$%"
        let cleaned = complexText.removingNonNormalCharacters()

        #expect(cleaned.contains("Hello"), "Should keep English letters")
        #expect(cleaned.contains("世界"), "Should keep Chinese characters")
        #expect(cleaned.contains("café"), "Should keep accented characters")
        #expect(!cleaned.contains(","), "Should remove punctuation")
        #expect(!cleaned.contains("!"), "Should remove punctuation")
        #expect(!cleaned.contains("123"), "Should remove numbers")
        #expect(!cleaned.contains("@"), "Should remove symbols")
        #expect(!cleaned.contains("#"), "Should remove symbols")
        #expect(!cleaned.contains("$"), "Should remove symbols")
        #expect(!cleaned.contains("%"), "Should remove symbols")
    }

    // MARK: - Whitespace Removal

    @Test("Remove whitespace and newlines")
    func removeWhitespaceAndNewlines() {
        let textWithWhitespace = "  hello \n world \t test  \n\n  "
        let cleaned = textWithWhitespace.removingWhitespaceAndNewlineCharacters()

        #expect(cleaned == "helloworldtest", "Should remove all whitespace and newlines")
        #expect(cleaned.contains(" "), "Should not contain spaces")
        #expect(cleaned.contains("\n"), "Should not contain newlines")
        #expect(cleaned.contains("\t"), "Should not contain tabs")
    }

    // MARK: - Punctuation Removal

    @Test("Remove punctuation characters")
    func removePunctuationCharacters() {
        let textWithPunctuation = "Hello, world! How are you? Good; fine."
        let cleaned = textWithPunctuation.removingPunctuationCharacters()

        #expect(cleaned == "Hello world How are you Good fine", "Should remove all punctuation")
        #expect(!cleaned.contains(","), "Should remove commas")
        #expect(!cleaned.contains("!"), "Should remove exclamation marks")
        #expect(!cleaned.contains("?"), "Should remove question marks")
        #expect(!cleaned.contains(";"), "Should remove semicolons")
        #expect(!cleaned.contains("."), "Should remove periods")
    }

    @Test("Remove enhanced Chinese punctuation")
    func removeEnhancedChinesePunctuation() {
        let textWithChinesePunctuation = "你好，世界！你好吗？"
        let cleaned = textWithChinesePunctuation.removingPunctuationCharacters2()

        #expect(cleaned == "你好世界你好吗", "Should remove Chinese punctuation marks")
        #expect(!cleaned.contains("，"), "Should remove Chinese comma")
        #expect(!cleaned.contains("！"), "Should remove Chinese exclamation")
        #expect(!cleaned.contains("？"), "Should remove Chinese question mark")
    }

    // MARK: - Number Removal

    @Test("Remove numbers")
    func removeNumbers() {
        let textWithNumbers = "Hello123world456test789"
        let cleaned = textWithNumbers.removingNumbers()

        #expect(cleaned == "Helloworldtest", "Should remove all numbers")
        #expect(!cleaned.contains("1"), "Should not contain digits")
        #expect(!cleaned.contains("2"), "Should not contain digits")
        #expect(!cleaned.contains("3"), "Should not contain digits")
    }

    @Test("Remove Arabic-Indic numbers")
    func removeArabicIndicNumbers() {
        let textWithArabicNumbers = "Test٠١٢٣numbers"
        let cleaned = textWithArabicNumbers.removingNumbers()

        #expect(cleaned == "Testnumbers", "Should remove Arabic-Indic digits")
    }

    @Test("Remove Persian numbers")
    func removePersianNumbers() {
        let textWithPersianNumbers = "Test۱۲۳۴۵۶۷۸۹numbers"
        let cleaned = textWithPersianNumbers.removingNumbers()

        #expect(cleaned == "Testnumbers", "Should remove Persian digits")
    }

    // MARK: - Symbol Removal

    @Test("Remove symbols")
    func removeSymbols() {
        let textWithSymbols = "Hello@world#$test%café"
        let cleaned = textWithSymbols.removingSymbolCharacterSet()

        #expect(cleaned.contains("Hello"), "Should keep letters")
        #expect(cleaned.contains("world"), "Should keep letters")
        #expect(cleaned.contains("test"), "Should keep letters")
        #expect(cleaned.contains("café"), "Should keep accented characters")
        #expect(!cleaned.contains("@"), "Should remove at symbol")
        #expect(!cleaned.contains("#"), "Should remove hash symbol")
        #expect(!cleaned.contains("$"), "Should remove dollar symbol")
        #expect(!cleaned.contains("%"), "Should remove percent symbol")
    }

    @Test("Remove math symbols")
    func removeMathSymbols() {
        let textWithMath = "2+2=4√5×6=7∑8π"
        let cleaned = textWithMath.removingSymbolCharacterSet()

        #expect(cleaned.contains("2"), "Should keep numbers")
        #expect(cleaned.contains("4"), "Should keep numbers")
        #expect(cleaned.contains("5"), "Should keep numbers")
        #expect(cleaned.contains("6"), "Should keep numbers")
        #expect(cleaned.contains("7"), "Should keep numbers")
        #expect(cleaned.contains("8"), "Should keep numbers")
        #expect(!cleaned.contains("+"), "Should remove plus sign")
        #expect(!cleaned.contains("="), "Should remove equals sign")
        #expect(!cleaned.contains("√"), "Should remove square root symbol")
        #expect(!cleaned.contains("×"), "Should remove multiplication sign")
        #expect(!cleaned.contains("∑"), "Should remove summation symbol")
        #expect(!cleaned.contains("π"), "Should remove pi symbol")
    }

    // MARK: - Alphabet Removal

    @Test("Remove alphabet characters")
    func removeAlphabet() {
        let textWithAlphabet = "Hello123world456test"
        let cleaned = textWithAlphabet.removingAlphabet()

        #expect(cleaned == "123456", "Should keep only numbers")
        #expect(!cleaned.contains("H"), "Should remove uppercase letters")
        #expect(!cleaned.contains("e"), "Should remove lowercase letters")
        #expect(!cleaned.contains("l"), "Should remove lowercase letters")
        #expect(!cleaned.contains("o"), "Should remove lowercase letters")
    }

    @Test("Remove alphabet using regex")
    func removeAlphabetWithRegex() {
        let textWithAlphabet = "Hello_world-123.Test"
        let cleaned = textWithAlphabet.removingAlphabet2()

        #expect(cleaned == "123.", "Should remove all letters using regex")
    }

    // MARK: - Combined Operations

    @Test("Remove letters and numbers")
    func removeLettersAndNumbers() {
        let textWithAlphanumerics = "Hello_world123!"
        let cleaned = textWithAlphanumerics.removingAlphabetAndNumbers()

        #expect(cleaned.isEmpty, "Should remove all letters and numbers")
    }

    @Test("Complex text cleaning pipeline")
    func complexTextCleaning() {
        let complexText = "  Hello，世界！123 café@#$  \n\n  "
        let cleaned = complexText.removingNonNormalCharacters()

        #expect(cleaned.contains("Hello"), "Should keep English letters")
        #expect(cleaned.contains("世界"), "Should keep Chinese characters")
        #expect(cleaned.contains("café"), "Should keep accented characters")
        #expect(!cleaned.contains("，"), "Should remove Chinese punctuation")
        #expect(!cleaned.contains("！"), "Should remove Chinese punctuation")
        #expect(!cleaned.contains("123"), "Should remove numbers")
        #expect(!cleaned.contains("@"), "Should remove symbols")
        #expect(!cleaned.contains("#"), "Should remove symbols")
        #expect(!cleaned.contains("$"), "Should remove symbols")
        #expect(!cleaned.contains("%"), "Should remove symbols")
        #expect(!cleaned.contains(" "), "Should remove extra whitespace")
        #expect(!cleaned.contains("\n"), "Should remove newlines")
    }
}
