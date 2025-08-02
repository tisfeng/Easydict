//
//  UtilityFunctionsTests.swift
//  EasydictSwiftTests
//
//  Created by AI Assistant on 2025/7/3.
//  Copyright © 2024 izual. All rights reserved.
//

import RegexBuilder
import Testing

@testable import Easydict

/// Tests for utility functions and helper methods
@Suite("Utility Functions", .tags(.utilities, .unit))
struct UtilityFunctionsTests {
    @Test("AES Encryption and Decryption", .tags(.utilities))
    func testAES() {
        let text = "123"
        let encryptedText = text.encryptAES()
        let decryptedText = encryptedText.decryptAES()
        #expect(decryptedText == text)
    }

    @Test("Filter Think Tags", .tags(.utilities))
    func testFilterThinkTags() {
        let testCases: [(input: String, expected: String)] = [
            ("<think>hello", ""),
            ("<think></think>hello", "hello"),
            ("<think>hello</think>world", "world"),
            ("hello<think>world</think>", "hello<think>world</think>"),
            ("no tags here", "no tags here"),
            ("", ""),
        ]

        for (index, testCase) in testCases.enumerated() {
            let result = testCase.input.filterThinkTagContent()
            print("Test Case \(index + 1): \(result)")
            #expect(result == testCase.expected)
        }
    }

    // MARK: - String+Detect Tests

    @Test("Chinese Text Detection", .tags(.utilities))
    func testChineseTextDetection() {
        // Test Chinese character detection
        #expect("你好".isChineseTextByRegex == true)
        #expect("世界".isChineseTextByRegex == true)
        #expect("開門".isChineseTextByRegex == true)
        #expect("hello".isChineseTextByRegex == false)
        #expect("123".isChineseTextByRegex == false)
        #expect("你好world".isChineseTextByRegex == false) // Mixed content
        #expect("".isChineseTextByRegex == false)
    }

    @Test("Simplified Chinese Detection", .tags(.utilities))
    func testSimplifiedChineseDetection() {
        // Test simplified Chinese detection
        #expect("你好世界".isSimplifiedChinese == true)
        #expect("你好world".isSimplifiedChinese == true) // Mixed content, Chinese words > English words
        #expect("开门".isSimplifiedChinese == true)
        #expect("開門".isSimplifiedChinese == false) // Traditional
        #expect("hello".isSimplifiedChinese == false)
        #expect("".isSimplifiedChinese == false)
    }

    @Test("English Alphabet Detection", .tags(.utilities))
    func testEnglishAlphabetDetection() {
        // Test single character English detection
        #expect("a".isEnglishAlphabet == true)
        #expect("Z".isEnglishAlphabet == true)
        #expect("1".isEnglishAlphabet == false)
        #expect("你".isEnglishAlphabet == false)
        #expect("à".isEnglishAlphabet == false) // Accented character
        #expect("ab".isEnglishAlphabet == false) // Multiple characters
        #expect("".isEnglishAlphabet == false)

        // Test English text detection
        #expect("hello".isEnglishText == true)
        #expect("World".isEnglishText == true)
        #expect("HelloWorld".isEnglishText == true)
        #expect("hello123".isEnglishText == false) // Contains numbers
        #expect("hello你好".isEnglishText == false) // Mixed scripts
        #expect("café".isEnglishText == false) // Contains accented characters
        #expect("".isEnglishText == false)
    }

    @Test("Latin Alphabet Detection", .tags(.utilities))
    func testLatinAlphabetDetection() {
        // Test single character Latin detection
        #expect("a".isLatinAlphabet == true)
        #expect("Z".isLatinAlphabet == true)
        #expect("à".isLatinAlphabet == true) // Accented character
        #expect("ñ".isLatinAlphabet == true) // Spanish character
        #expect("ü".isLatinAlphabet == true) // German character
        #expect("你".isLatinAlphabet == false)
        #expect("1".isLatinAlphabet == false)
        #expect("ab".isLatinAlphabet == false) // Multiple characters
        #expect("".isLatinAlphabet == false)

        // Test Latin text detection
        #expect("hello".isLatinText == true)
        #expect("café".isLatinText == true)
        #expect("naïve".isLatinText == true)
        #expect("español".isLatinText == true)
        #expect("hello123".isLatinText == false) // Contains numbers
        #expect("hello你好".isLatinText == false) // Mixed scripts
        #expect("".isLatinText == false)
    }

    @Test("Numeric Character Detection", .tags(.utilities))
    func testNumericCharacterDetection() {
        // Test single number detection
        #expect("0".isNumeric == true)
        #expect("9".isNumeric == true)
        #expect("5".isNumeric == true)
        #expect("a".isNumeric == false)
        #expect("你".isNumeric == false)
        #expect("12".isNumeric == true)
        #expect("".isNumeric == false)

        // Test numeric text detection
        #expect("123".isNumeric == true)
        #expect("0".isNumeric == true)
        #expect("999".isNumeric == true)
        #expect("12a".isNumeric == false) // Contains letters
        #expect("1 2".isNumeric == false) // Contains spaces
        #expect("".isNumeric == false)
    }

    @Test("Numeric Heavy Detection", .tags(.utilities))
    func testNumericHeavyDetection() {
        #expect("12345".isNumericHeavy == true) // 100% numbers
        #expect("123a".isNumericHeavy == true) // 75% numbers
        #expect("12ab".isNumericHeavy == false) // 50% numbers
        #expect("1abc".isNumericHeavy == false) // 25% numbers
        #expect("hello".isNumericHeavy == false) // 0% numbers
        #expect("".isNumericHeavy == false)
    }

    // MARK: - String+ToChinese Tests

    @Test("Traditional to Simplified Chinese Conversion", .tags(.utilities))
    func testTraditionalToSimplifiedConversion() {
        // Test traditional to simplified conversion
        #expect("開門".toSimplifiedChinese() == "开门")
        #expect("門".toSimplifiedChinese() == "门")
        #expect("車".toSimplifiedChinese() == "车")
        #expect("書".toSimplifiedChinese() == "书")
        #expect("學習".toSimplifiedChinese() == "学习")
        #expect("電腦".toSimplifiedChinese() == "电脑")
        #expect("現在".toSimplifiedChinese() == "现在")

        // Test already simplified characters (should remain unchanged)
        #expect("开门".toSimplifiedChinese() == "开门")
        #expect("你好".toSimplifiedChinese() == "你好")

        // Test non-Chinese text (should remain unchanged)
        #expect("hello".toSimplifiedChinese() == "hello")
        #expect("123".toSimplifiedChinese() == "123")
        #expect("".toSimplifiedChinese() == "")
    }

    @Test("Simplified to Traditional Chinese Conversion", .tags(.utilities))
    func testSimplifiedToTraditionalConversion() {
        // Test simplified to traditional conversion
        #expect("开门".toTraditionalChinese() == "開門")
        #expect("门".toTraditionalChinese() == "門")
        #expect("车".toTraditionalChinese() == "車")
        #expect("书".toTraditionalChinese() == "書")
        #expect("学习".toTraditionalChinese() == "學習")
        #expect("电脑".toTraditionalChinese() == "電腦")
        #expect("现在".toTraditionalChinese() == "現在")

        // Test already traditional characters (should remain unchanged)
        #expect("開門".toTraditionalChinese() == "開門")

        // Test characters that are the same in both variants
        #expect("你好".toTraditionalChinese() == "你好")
        #expect("中文".toTraditionalChinese() == "中文")

        // Test non-Chinese text (should remain unchanged)
        #expect("hello".toTraditionalChinese() == "hello")
        #expect("123".toTraditionalChinese() == "123")
        #expect("".toTraditionalChinese() == "")
    }

    @Test("Round-trip Chinese Conversion", .tags(.utilities))
    func testRoundTripChineseConversion() {
        // Test round-trip conversion: simplified -> traditional -> simplified
        let simplifiedTexts = ["开门", "学习", "电脑", "现在"]
        for text in simplifiedTexts {
            let traditional = text.toTraditionalChinese()
            let backToSimplified = traditional.toSimplifiedChinese()
            #expect(backToSimplified == text, "Round-trip failed for: \(text)")
        }

        // Test round-trip conversion: traditional -> simplified -> traditional
        let traditionalTexts = ["開門", "學習", "電腦", "現在"]
        for text in traditionalTexts {
            let simplified = text.toSimplifiedChinese()
            let backToTraditional = simplified.toTraditionalChinese()
            #expect(backToTraditional == text, "Round-trip failed for: \(text)")
        }
    }

    // MARK: - String Character Removal Tests

    @Test("Character Removal Functions", .tags(.utilities))
    func testCharacterRemovalFunctions() {
        let testText = "Hello, 世界! 123 café@#$"

        // Test whitespace and newline removal
        #expect("hello world\n\ttest".removingWhitespaceAndNewlines() == "helloworldtest")
        #expect("  spaced  ".removingWhitespaceAndNewlines() == "spaced")

        // Test punctuation removal
        #expect("hello, world!".removingPunctuationCharacters() == "hello world")
        #expect("test@#$%.txt".removingPunctuationCharacters() == "test$txt") // @ # $ % are symbols, not punctuation

        // Test symbol removal
        #expect("test+=$¥".removingSymbols() == "test")
        #expect("hello$world".removingSymbols() == "helloworld")

        // Test number removal
        #expect("hello123world".removingNumbers() == "helloworld")
        #expect("test456".removingNumbers() == "test")

        // Test non-base character removal
        #expect(!testText.removingNonLetters().isEmpty)

        // Test removing all non-letter characters
        let cleanText = testText.removingNonLetters()
        #expect(cleanText == "Hello世界café")
    }

    // MARK: - List Type Detection Tests

    @Test("List Type Detection", .tags(.utilities))
    func testListTypeFirstWord() {
        let trueInputs: [String] = [
            "1. item",
            "1) item",
            "1） item",
            "a. item",
            "A) item",
            "IV. item",
            "• item",
            "- item",
            "* item",
        ]
        let falseInputs: [String] = [
            "•item",
            "-item",
            "M. item",
            "item 1. item",
            "",
            "  ",
        ]
        for input in trueInputs {
            #expect(input.isListTypeFirstWord == true, "Failed for input: \(input)")
        }
        for input in falseInputs {
            #expect(input.isListTypeFirstWord == false, "Failed for input: \(input)")
        }
    }

    @Test("Word Components Extraction", .tags(.utilities))
    func testWordComponentsExtraction() {
        let testCases: [(input: String, expected: [String])] = [
            ("hello world", ["hello", "world"]),
            ("你好世界", ["你", "好", "世", "界"]),
            ("包括Google翻译、DeepL翻译等", ["包", "括", "Google", "翻", "译", "DeepL", "翻", "译", "等"]),
            ("hello你好world", ["hello", "你", "好", "world"]),
            ("123apple香蕉!", ["123apple", "香", "蕉"]),
            ("Mix中英文Text测试", ["Mix", "中", "英", "文", "Text", "测", "试"]),
            ("@tisfeng #Easydict", ["@tisfeng", "#Easydict"]),
            ("\"Hello\"!", ["\"Hello\""]),
            ("hi-hello, world", ["hi-hello", "world"]),
            ("scpl.example.com", ["scpl.example.com"]),
            ("mechanism/protocol", ["mechanism/protocol"]),
            ("   ,!?", []),
            ("", []),
        ]

        for (index, testCase) in testCases.enumerated() {
            let result = testCase.input.wordComponents
            #expect(
                result == testCase.expected,
                "Failed at case \(index + 1): got \(result), expected \(testCase.expected)"
            )
        }
    }
}
