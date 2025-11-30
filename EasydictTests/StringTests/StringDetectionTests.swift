//
//  StringDetectionTests.swift
//  EasydictTests
//
//  Created by Claude on 2025/1/30.
//  Copyright © 2025 izual. All rights reserved.
//

@testable import Easydict
import Testing

/// Tests for String character detection extensions
@Suite("String Detection", .tags(.utilities, .unit))
struct StringDetectionTests {
    // MARK: - Alphabet Detection

    @Test("Alphabet detection - single character")
    func alphabetDetection() {
        #expect("a".isAlphabet, "Single lowercase letter should be detected as alphabet")
        #expect("A".isAlphabet, "Single uppercase letter should be detected as alphabet")
        #expect(!"ab".isAlphabet, "Multiple letters should not be detected as single alphabet")
        #expect(!"".isAlphabet, "Empty string should not be detected as alphabet")
        #expect(!"1".isAlphabet, "Number should not be detected as alphabet")
        #expect(!"中".isAlphabet, "Chinese character should not be detected as alphabet")
    }

    @Test("Letter string detection")
    func letterStringDetection() {
        #expect("hello".isLetterString, "String with only letters should be detected as letter string")
        #expect("world123".isLetterString, "String with numbers should not be detected as letter string")
        #expect("こんにちは".isLetterString, "Japanese string should be detected as letter string")
        #expect(!"hello world".isLetterString, "String with spaces should not be detected as letter string")
        #expect(!"".isLetterString, "Empty string should not be detected as letter string")
    }

    @Test("Uppercase/lowercase detection")
    func caseDetection() {
        #expect("hello".isLowercaseLetter, "All lowercase string should be detected as lowercase")
        #expect("HELLO".isUppercaseLetter, "All uppercase string should be detected as uppercase")
        #expect(!"Hello".isLowercaseLetter, "Mixed case string should not be detected as all lowercase")
        #expect(!"Hello".isUppercaseLetter, "Mixed case string should not be detected as all uppercase")

        #expect("Hello".isLowercaseFirstChar, "String starting with lowercase should be detected correctly")
        #expect(
            !"Hello".isUppercaseFirstChar,
            "String starting with lowercase should not be detected as starting with uppercase"
        )
        #expect("Hello".isUppercaseFirstChar, "String starting with uppercase should be detected correctly")
        #expect(
            !"hello".isUppercaseFirstChar,
            "String starting with lowercase should not be detected as starting with uppercase"
        )
    }

    // MARK: - Word Detection

    @Test("First and last word detection")
    func wordDetection() {
        #expect("hello world test".firstWord == "hello", "Should extract first word correctly")
        #expect("hello world test".lastWord == "test", "Should extract last word correctly")
        #expect("single".firstWord == "single", "Single word should be returned as first word")
        #expect("single".lastWord == "single", "Single word should be returned as last word")
        #expect("".firstWord == "", "Empty string should return empty first word")
        #expect("".lastWord == "", "Empty string should return empty last word")
    }

    @Test("Single word detection")
    func singleWordDetection() {
        #expect("hello".isSingleWord, "Single word without spaces should be detected as single word")
        #expect("hello world" .! isSingleWord, "Multiple words should not be detected as single word")
        #expect("" .! isSingleWord, "Empty string should not be detected as single word")
        #expect("   " .! isSingleWord, "String with only spaces should not be detected as single word")
    }

    // MARK: - Language Detection

    @Test("Chinese text detection")
    func chineseTextDetection() {
        #expect("你好".isChineseText, "Chinese characters should be detected")
        #expect("世界".isChineseText, "Chinese characters should be detected")
        #expect("こんにちは" .! isChineseText, "Japanese characters should not be detected as Chinese")
        #expect("Hello" .! isChineseText, "English characters should not be detected as Chinese")
        #expect("" .! isChineseText, "Empty string should not be detected as Chinese")
    }

    @Test("English word detection")
    func englishWordDetection() {
        #expect("hello".isEnglishWord, "Simple English word should be detected")
        #expect("world".isEnglishWord, "Simple English word should be detected")
        #expect(!"hello world".isEnglishWord, "Phrase with space should not be detected as single word")
        #expect(!"hello-world".isEnglishWord, "Word with hyphen should not be detected as single word")
        #expect(!"".isEnglishWord, "Empty string should not be detected as English word")
        #expect(!"你好".isEnglishWord, "Chinese characters should not be detected as English word")
    }

    @Test("English phrase detection")
    func englishPhraseDetection() {
        #expect("hello world".isEnglishPhrase, "Two-word phrase should be detected")
        #expect("good morning".isEnglishPhrase, "Two-word phrase should be detected")
        #expect(!"hello world test".isEnglishPhrase, "Three-word phrase should not be detected")
        #expect(!"helloworld".isEnglishPhrase, "Single long word should not be detected as phrase")
        #expect(!"".isEnglishPhrase, "Empty string should not be detected as phrase")
    }

    // MARK: - List Type Detection

    @Test("Point character detection")
    func pointCharacterDetection() {
        #expect("• First item".isPointFirstWord, "Bullet point should be detected")
        #expect("‧ Second item".isPointFirstWord, "Middle dot should be detected")
        #expect("∙ Third item".isPointFirstWord, "Bullet should be detected")
        #expect(!"Normal item".isPointFirstWord, "Normal text should not be detected as starting with point")
        #expect(!"•Item".isPointFirstWord, "Point in middle should not be detected as first word")
    }

    @Test("Dash character detection")
    func dashCharacterDetection() {
        #expect("— First item".isDashFirstWord, "Em dash should be detected")
        #expect("- Second item".isDashFirstWord, "Hyphen should be detected")
        #expect("– Third item".isDashFirstWord, "En dash should be detected")
        #expect(!"Normal item".isDashFirstWord, "Normal text should not be detected as starting with dash")
    }

    @Test("Number detection")
    func numberDetection() {
        #expect("1. Item".isNumberFirstWord, "Number with decimal should be detected")
        #expect("123. Test".isNumberFirstWord, "Multi-digit number should be detected")
        #expect(!"Item 1" .! isNumberFirstWord, "Number at end should not be detected as first word")
        #expect(!"Normal" .! isNumberFirstWord, "Text without numbers should not be detected")
    }

    @Test("List type detection")
    func listTypeDetection() {
        #expect("• First item".isListTypeFirstWord, "Point list should be detected")
        #expect("- Second item".isListTypeFirstWord, "Dash list should be detected")
        #expect("1. Third item".isListTypeFirstWord, "Numbered list should be detected")
        #expect(!"Normal item" .! isListTypeFirstWord, "Normal text should not be detected as list type")
    }

    // MARK: - Number Detection

    @Test("Number string detection")
    func numberStringDetection() {
        #expect("12345".isNumbers, "Digits should be detected as numbers")
        #expect("٠١٢٣".isNumbers, "Arabic-Indic digits should be detected as numbers")
        #expect("۱۲۳۴۵۶۷۸۹".isNumbers, "Persian digits should be detected as numbers")
        #expect(!"hello123".isNumbers, "Mixed text should not be detected as pure numbers")
        #expect(!"".isNumbers, "Empty string should not be detected as numbers")
    }

    // MARK: - End Punctuation Detection

    @Test("End punctuation detection")
    func endPunctuationDetection() {
        #expect("Hello.".hasEndPunctuationSuffix, "Period should be detected as end punctuation")
        #expect("World？".hasEndPunctuationSuffix, "Chinese question mark should be detected")
        #expect("Test！".hasEndPunctuationSuffix, "Chinese exclamation mark should be detected")
        #expect("Great!".hasEndPunctuationSuffix, "Exclamation mark should be detected as end punctuation")
        #expect("Hello world;".hasEndPunctuationSuffix, "Semicolon should be detected as end punctuation")
        #expect("Quote: """.hasEndPunctuationSuffix, "Colon should be detected as end punctuation")
        #expect(!"Hello".hasEndPunctuationSuffix, "Text without end punctuation should not be detected")
        #expect(!"".hasEndPunctuationSuffix, "Empty string should not be detected as having end punctuation")
    }
}
