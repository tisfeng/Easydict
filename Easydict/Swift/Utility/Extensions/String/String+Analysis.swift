//
//  String+Analysis.swift
//  Easydict
//
//  Created by Claude on 2025/1/30.
//  Copyright © 2025 izual. All rights reserved.
//

import AppKit
import Foundation
import NaturalLanguage

// MARK: - Language Detection

extension String {
    /// Detect the dominant language of the text

    func detectLanguage() -> NLLanguage? {
        let tagger = NLTagger(tagSchemes: [.language])
        tagger.string = self
        return tagger.dominantLanguage
    }
}

// MARK: - Query Type Analysis

extension String {
    /// Determine query type based on language and word count constraints

    func queryType(language: Language, maxWordCount: Int) -> QueryTextType {
        if shouldQueryDictionary(withLanguage: language, maxWordCount: maxWordCount) {
            return .dictionary
        }

        if shouldQuerySentence(withLanguage: language), language == .english {
            return .sentence
        }

        return .translation
    }

    /// Check if text should be queried as dictionary entry

    func shouldQueryDictionary(withLanguage language: Language, maxWordCount: Int) -> Bool {
        guard count <= Self.englishWordMaxLength else { return false }

        // Check if language is Chinese based
        let chineseLanguages: Set<Language> = [
            .simplifiedChinese, .traditionalChinese, .classicalChinese,
        ]

        if chineseLanguages.contains(language) {
            return isChineseWord || isChinesePhrase
        }

        if language == .english {
            return isEnglishWord || isEnglishPhrase
        }

        return false
    }

    /// Check if text should be queried as sentence

    func shouldQuerySentence(withLanguage language: Language) -> Bool {
        guard !shouldQueryDictionary(withLanguage: language, maxWordCount: 1) else { return false }
        return isSentence
    }
}

// MARK: - Spelling Check

extension String {
    /// Check if word is spelled correctly

    var isSpelledCorrectly: Bool {
        isSpelledCorrectly(language: nil)
    }

    /// Check if word is spelled correctly with specified language

    func isSpelledCorrectly(language: String?) -> Bool {
        let spellChecker = NSSpellChecker.shared
        let checkLanguage = language ?? spellChecker.language()

        let misspelledRange = spellChecker.checkSpelling(
            of: self,
            startingAt: 0,
            language: checkLanguage,
            wrap: false,
            inSpellDocumentWithTag: 0,
            wordCount: nil
        )

        return misspelledRange.location == NSNotFound
    }

    /// Get suggested corrections for misspelled words

    var guessedWords: [String]? {
        guessedWords(language: nil)
    }

    /// Get suggested corrections for misspelled words with specified language

    func guessedWords(language: String?) -> [String]? {
        let spellChecker = NSSpellChecker.shared
        let checkLanguage = language ?? spellChecker.language()

        let wordRange = NSRange(location: 0, length: count)

        return spellChecker.guesses(
            forWordRange: wordRange,
            in: self,
            language: checkLanguage,
            inSpellDocumentWithTag: 0
        )
    }
}

// MARK: - Advanced Text Analysis

extension String {
    /// Get lexical tags for words in text
    var taggedWordsInText: [NLTag] {
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = self

        let range = startIndex ..< endIndex
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace]

        return tagger.tags(in: range, unit: .word, scheme: .lexicalClass, options: options)
            .compactMap { $0.0 }
    }
}

// MARK: - NSString Bridges

@objc
extension NSString {
    @objc(queryTypeWithLanguage:maxWordCount:)
    func queryType(withLanguage language: Language, maxWordCount: Int) -> EZQueryTextType {
        (self as String).queryType(language: language, maxWordCount: maxWordCount)
    }

    func shouldQueryDictionary(withLanguage language: Language, maxWordCount: Int) -> Bool {
        (self as String).shouldQueryDictionary(withLanguage: language, maxWordCount: maxWordCount)
    }

    func shouldQuerySentence(withLanguage language: Language) -> Bool {
        (self as String).shouldQuerySentence(withLanguage: language)
    }

    func isSpelledCorrectly() -> Bool {
        (self as String).isSpelledCorrectly
    }

    @objc(isSpelledCorrectlyWithLanguage:)
    func isSpelledCorrectly(language: String?) -> Bool {
        (self as String).isSpelledCorrectly(language: language)
    }

    func isEnglishWord() -> Bool {
        (self as String).isEnglishWord
    }

    func isEnglishWordWithMaxWordLength(_ maxLength: Int) -> Bool {
        (self as String).isEnglishWordWithMaxLength(maxLength)
    }

    @objc(isEnglishWordWithLanguage:)
    func isEnglishWord(withLanguage language: Language) -> Bool {
        (self as String).isEnglishWord(withLanguage: language)
    }

    func wordCount() -> Int {
        (self as String).wordCount
    }

    func firstWord() -> String { (self as String).firstWord }

    func lastWord() -> String { (self as String).lastWord }

    @objc(wordAtIndex:)
    func wordAtIndex(_ characterIndex: Int) -> String? {
        (self as String).word(at: characterIndex)
    }
}

// MARK: - Language-Specific Analysis

// extension String {
//    /// Check if text is an English word with specific language
//
//    func isEnglishWord(withLanguage language: Language) -> Bool {
//        guard language == "en" else { return false }
//        return isEnglishWord
//    }
//
//    /// Check if text is a Chinese word (length <= 4)
//    var isChineseWord: Bool {
//        let text = tryRemovingQuotes()
//        guard text.count <= 4 else { return false }
//        return isChineseText
//    }
//
//    /// Check if text is a Chinese phrase (length <= 5)
//    var isChinesePhrase: Bool {
//        let text = tryRemovingQuotes()
//        guard text.count <= 5 else { return false }
//        return isChineseText
//    }
// }
