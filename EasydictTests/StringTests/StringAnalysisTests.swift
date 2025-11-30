//
//  StringAnalysisTests.swift
//  EasydictTests
//
//  Created by Claude on 2025/1/30.
//  Copyright © 2025 izual. All rights reserved.
//

import NaturalLanguage
import Testing

@testable import Easydict

/// Tests for String analysis extensions
@Suite("String Analysis", .tags(.utilities, .unit))
struct StringAnalysisTests {
    // MARK: - Language Detection

    @Test("Language detection")
    func languageDetection() {
        #expect("Hello".detectLanguage() == .english, "English text should be detected as English")
        #expect(
            "你好".detectLanguage() == .simplifiedChinese,
            "Chinese text should be detected as Chinese"
        )
        #expect(
            "こんにちは".detectLanguage() == .japanese, "Japanese text should be detected as Japanese"
        )
        #expect("Bonjour".detectLanguage() == .french, "French text should be detected as French")
        #expect("".detectLanguage() == nil, "Empty string should return nil")
    }

    // MARK: - Word Count

    @Test("Word count with NLTokenizer")
    func wordCount() {
        #expect("hello world".wordCount == 2, "Simple sentence should have correct word count")
        #expect(
            "The quick brown fox".wordCount == 4,
            "Sentence with multiple words should be counted correctly"
        )
        #expect("Hello, world!".wordCount == 2, "Punctuation should not affect word count")
        #expect("".wordCount == 0, "Empty string should have zero word count")
        #expect("こんにちは".wordCount == 1, "Japanese text should be counted correctly")
        #expect("你好世界".wordCount == 2, "Chinese text should be counted correctly")
    }

    @Test("Sentence count with NLTokenizer")
    func sentenceCount() {
        #expect(
            "Hello world. How are you?".sentenceCount == 2,
            "Multiple sentences should be counted correctly"
        )
        #expect(
            "This is sentence one. This is sentence two!".sentenceCount == 2,
            "Sentences with punctuation should be counted correctly"
        )
        #expect("Hello".sentenceCount == 1, "Single sentence should return 1")
        #expect("".sentenceCount == 0, "Empty string should return 0")
        #expect(
            "SingleSentence".sentenceCount == 1, "Single word without punctuation should return 1"
        )
    }

    // MARK: - Words in Text

    @Test("Words in text extraction")
    func wordsInText() {
        let englishWords = "Hello, world! This is a test.".wordsInText
        #expect(englishWords.count == 6, "Should extract correct number of English words")
        #expect(englishWords.contains("Hello"), "Should preserve all words")
        #expect(englishWords.contains("world"), "Should preserve all words")
        #expect(englishWords.contains("test"), "Should preserve all words")

        let chineseWords = "你好，世界！".wordsInText
        #expect(chineseWords.count == 2, "Should extract Chinese words correctly")
        #expect(chineseWords.contains("你好"), "Should preserve Chinese words")
        #expect(chineseWords.contains("世界"), "Should preserve Chinese words")
    }

    // MARK: - Word at Index

    @Test("Word at character index")
    func wordAtIndex() {
        let text = "Hello world test"
        #expect(text.word(at: 0) == "Hello", "Should return first word")
        #expect(text.word(at: 6) == "world", "Should return middle word")
        #expect(text.word(at: 11) == "test", "Should return last word")
        #expect(text.word(at: 5) == "world", "Should return word at space index")
        #expect(text.word(at: -1) == nil, "Negative index should return nil")
        #expect(text.word(at: 100) == nil, "Index out of bounds should return nil")
        #expect("".word(at: 0) == nil, "Empty string should return nil")
    }

    // MARK: - Query Type Analysis

    @Test("Dictionary query detection")
    func dictionaryQueryDetection() {
        let english: Language = .english
        let chinese: Language = .simplifiedChinese

        #expect(
            "hello".queryType(language: english, maxWordCount: 3).contains(.dictionary),
            "Single English word within limit should query dictionary"
        )
        #expect(
            "world".queryType(language: english, maxWordCount: 1).contains(.dictionary),
            "Single English word at limit should query dictionary"
        )
        #expect(
            "hel".queryType(language: english, maxWordCount: 2).contains(.dictionary),
            "Two-letter word within limit should query dictionary"
        )
        #expect(
            !"hello world".queryType(language: english, maxWordCount: 3).contains(.dictionary),
            "Multiple words should not query dictionary"
        )
        #expect(
            !"supercalifragilisticexpialidocious".queryType(language: english, maxWordCount: 20)
                .contains(.dictionary),
            "Word exceeding max length should not query dictionary"
        )

        #expect(
            "你好".queryType(language: chinese, maxWordCount: 5).contains(.dictionary),
            "Chinese word within limit should query dictionary"
        )
        #expect(
            "世界".queryType(language: chinese, maxWordCount: 4).contains(.dictionary),
            "Chinese word at limit should query dictionary"
        )
        #expect(
            !"你好世界".queryType(language: chinese, maxWordCount: 5).contains(.dictionary),
            "Chinese phrase exceeding limit should not query dictionary"
        )
    }

    @Test("Sentence query detection")
    func sentenceQueryDetection() {
        let english: Language = .english
        let chinese: Language = .simplifiedChinese

        #expect(
            "Hello world, how are you today?".queryType(language: english, maxWordCount: 1)
                .contains(.sentence),
            "English sentence should query sentence"
        )
        #expect(
            "This is a test".queryType(language: english, maxWordCount: 1).contains(.sentence),
            "Simple sentence should query sentence"
        )
        #expect(
            "SingleWord".queryType(language: english, maxWordCount: 1).contains(.sentence),
            "Single word without punctuation should not query sentence"
        )

        // Chinese text should not query sentence even if it's a sentence
        #expect(
            !"你好世界".queryType(language: chinese, maxWordCount: 1).contains(.sentence),
            "Chinese text should not query sentence"
        )
    }

    // MARK: - Spelling Check

    @Test("Spelling check")
    func spellingCheck() {
        #expect("hello".isSpelledCorrectly, "Common word should be spelled correctly")
        #expect("world".isSpelledCorrectly, "Common word should be spelled correctly")
        #expect(!"helo".isSpelledCorrectly, "Misspelled word should not be spelled correctly")
        #expect(!"wrold".isSpelledCorrectly, "Misspelled word should not be spelled correctly")
        #expect("".isSpelledCorrectly, "Empty string should be considered spelled correctly")
    }

    @Test("Spelling suggestions")
    func spellingSuggestions() {
        let suggestions = "helo".guessedWords
        #expect(suggestions != nil, "Misspelled word should return suggestions")
        #expect(suggestions?.contains("hello") == true, "Should suggest correct spelling")
        #expect(suggestions?.contains("hell") == true, "Should suggest alternative spellings")

        let correctSuggestions = "hello".guessedWords
        #expect(correctSuggestions == nil, "Correctly spelled word should return nil")
    }

    // MARK: - Tagged Words

    @Test("Tagged words in text")
    func taggedWordsInText() {
        let tags = "Hello world!".taggedWordsInText
        #expect(!tags.isEmpty, "Should return tags for words")

        // Check that we get valid NLTag objects
        for tag in tags {
            #expect(tag.rawValue != "", "Each tag should have a raw value")
        }
    }
}
