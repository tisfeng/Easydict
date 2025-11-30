//
//  String+Detection.swift
//  Easydict
//
//  Created by Claude on 2025/1/30.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation
import NaturalLanguage

// MARK: - Character Detection

extension String {
    /// Check if it is a single letter of the alphabet, like 'a', 'A'
    var isAlphabet: Bool {
        count == 1 && range(of: "[a-zA-Z]", options: .regularExpression) != nil
    }

    /// Check if the string contains only letters
    var isLetterString: Bool {
        guard !isEmpty else { return false }
        let letterSet = CharacterSet.letters
        return unicodeScalars.allSatisfy { letterSet.contains($0) }
    }

    /// Check if the string is all lowercase letters
    var isLowercaseLetter: Bool {
        let lowercaseSet = CharacterSet.lowercaseLetters
        return unicodeScalars.allSatisfy { lowercaseSet.contains($0) }
    }

    /// Check if the first character is lowercase
    var isLowercaseFirstChar: Bool {
        guard let firstChar = first else { return false }
        return String(firstChar).isLowercaseLetter
    }

    /// Check if the string is all uppercase letters
    var isUppercaseLetter: Bool {
        let uppercaseSet = CharacterSet.uppercaseLetters
        return unicodeScalars.allSatisfy { uppercaseSet.contains($0) }
    }

    /// Check if the first character is uppercase
    var isUppercaseFirstChar: Bool {
        guard let firstChar = first else { return false }
        return firstChar.isUppercase
    }

    /// Get the first word of the string
    var firstWord: String {
        components(separatedBy: " ").first ?? ""
    }

    /// Get the last word of the string
    var lastWord: String {
        components(separatedBy: " ").last ?? ""
    }

    /// Check if text ends with a punctuation mark
    var hasEndPunctuationSuffix: Bool {
        guard let lastChar = last else { return false }
        return Self.endPunctuationMarks.contains(String(lastChar))
    }

    /// Get the first character of the string
    var firstChar: Character? {
        first
    }

    /// Get the last character of the string
    var lastChar: Character? {
        last
    }

    /// Check if the first word is a point character
    var isPointFirstWord: Bool {
        let firstWord = firstWord
        return Self.pointCharacters.contains(firstWord)
    }

    /// Check if the first character is a point character
    var isPointFirstChar: Bool {
        guard let firstChar = firstChar else { return false }
        return Self.pointCharacters.contains(String(firstChar))
    }

    /// Check if the first word is a dash character
    var isDashFirstWord: Bool {
        let firstWord = firstWord
        return Self.dashCharacters.contains(firstWord)
    }

    /// Check if the first character is a dash character
    var isDashFirstChar: Bool {
        guard let firstChar = firstChar else { return false }
        return Self.dashCharacters.contains(String(firstChar))
    }

    /// Check if the first word represents a number
    var isNumberFirstWord: Bool {
        let firstWord = firstWord

        // Check if the first word contains a dot
        if firstWord.contains(".") {
            let number = firstWord.components(separatedBy: ".").first ?? ""
            return number.isNumbers
        }

        return false
    }

    /// Check if the first word indicates a list type (point, dash, or number)
    var isListTypeFirstWord: Bool {
        isPointFirstWord || isDashFirstWord || isNumberFirstWord
    }
}

// MARK: - Text Type Detection

extension String {
    /// Check if the text is English word
    var isEnglishWord: Bool {
        isEnglishWordWithMaxLength(Self.englishWordMaxLength)
    }

    /// Check if the text should be treated as an English word for the given language context
    func isEnglishWord(withLanguage language: Language) -> Bool {
        guard language == .english else { return false }
        return isEnglishWord
    }

    /// Check if the text is English word with maximum length constraint
    func isEnglishWordWithMaxLength(_ maxLength: Int) -> Bool {
        let text = tryToRemoveQuotes()
        guard text.count <= maxLength else { return false }

        let pattern = "^[a-zA-Z]+$"
        return range(of: pattern, options: .regularExpression) != nil
    }

    /// Check if the text is English phrase
    var isEnglishPhrase: Bool {
        let text = replacingOccurrences(of: " ", with: "")
        let isEnglishPhraseLength = text.isEnglishWordWithMaxLength(Self.englishWordMaxLength * 2)
        let isPhraseWordCount = wordCount == 2
        return isEnglishPhraseLength && isPhraseWordCount
    }

    /// Check if the text is a single word
    var isWord: Bool {
        let text = tryToRemoveQuotes()
        guard text.count <= Self.englishWordMaxLength else { return false }
        return wordCount == 1
    }

    /// Check if the text is a single word (simple version)
    var isSingleWord: Bool {
        !isEmpty && components(separatedBy: " ").count == 1
    }

    /// Check if the text is Chinese word
    var isChineseWord: Bool {
        let text = tryToRemoveQuotes()
        guard text.count <= 4 else { return false }
        return isChineseText
    }

    /// Check if the text is Chinese phrase
    var isChinesePhrase: Bool {
        let text = tryToRemoveQuotes()
        guard text.count <= 5 else { return false }
        return isChineseText
    }

    /// Check if the text contains only Chinese characters
    var isChineseText: Bool {
        let pattern = "^[\\u4e00-\\u9fa5]+$"
        return range(of: pattern, options: .regularExpression) != nil
    }

    /// Check if the text contains only Chinese characters (alternative method)
    var isChineseText2: Bool {
        let pattern = "^[\\u4e00-\\u9fa5]+$"
        let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let range = NSRange(location: 0, length: utf16.count)
        let matches = regex?.numberOfMatches(in: self, options: [], range: range)
        return matches ?? 0 > 0
    }

    /// Check if the text contains only numbers
    var isNumbers: Bool {
        guard !isEmpty else { return false }
        return unicodeScalars.allSatisfy { CharacterSet.decimalDigits.contains($0) }
    }

    /// Check if the text is a sentence
    var isSentence: Bool {
        sentenceCount == 1
    }
}

// MARK: - Word and Sentence Count

extension String {
    /// Count the number of words in the text using NLTokenizer
    var wordCount: Int {
        guard !isEmpty else { return 0 }

        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = self

        // Set language for better tokenization
        if isChineseText {
            tokenizer.setLanguage(.simplifiedChinese)
        }

        var count = 0
        tokenizer.enumerateTokens(in: startIndex ..< endIndex) { tokenRange, _ in
            let token = String(self[tokenRange])
            // Skip whitespace and punctuation
            if !token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
               token.rangeOfCharacter(from: .punctuationCharacters) == nil {
                count += 1
            }
            return true
        }
        return count
    }

    /// Count the number of sentences in the text using NLTokenizer
    var sentenceCount: Int {
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = self
        var count = 0
        tokenizer.enumerateTokens(in: startIndex ..< endIndex) { _, _ in
            count += 1
            return true
        }
        return count
    }

    /// Get an array of words in the text using NLTokenizer
    var wordsInText: [String] {
        guard !isEmpty else { return [] }
        let trimmedText = trimmingCharacters(in: .whitespacesAndNewlines)

        // For Chinese text, use word tokenizer which handles Chinese better
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = trimmedText
        // Set language for better Chinese word segmentation
        if isChineseText {
            tokenizer.setLanguage(.simplifiedChinese)
        }

        var words: [String] = []
        tokenizer.enumerateTokens(in: trimmedText.startIndex ..< trimmedText.endIndex) { tokenRange, _ in
            let token = String(trimmedText[tokenRange])
            // Filter out punctuation-only tokens
            if !token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
               token.rangeOfCharacter(from: .punctuationCharacters) == nil {
                words.append(token)
            }
            return true
        }

        return words
    }

    /// Get the word at the specified character index using NLTokenizer
    func word(at characterIndex: Int) -> String? {
        guard !isEmpty else { return nil }
        guard characterIndex >= 0, characterIndex < count else { return nil }

        let stringIndex = index(startIndex, offsetBy: characterIndex)
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = self

        let tokenRange = tokenizer.tokenRange(at: stringIndex)
        guard tokenRange.lowerBound < tokenRange.upperBound else { return nil }

        let word = String(self[tokenRange])
        // Skip if it's just punctuation or whitespace
        let trimmed = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.rangeOfCharacter(from: .punctuationCharacters) == nil else {
            return nil
        }

        return word
    }
}
