//
//  String+OCR.swift
//  Easydict
//
//  Created by tisfeng on 2025/6/24.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

extension String {
    /// Check if the string starts with a capital letter
    var isFirstLetterUpperCase: Bool {
        guard let firstCharacter = first else {
            return false
        }
        return firstCharacter.isUppercase && firstCharacter.isLetter
    }

    /// Check if text ends with end punctuation marks
    var hasEndPunctuationSuffix: Bool {
        let endPunctuationMarks = CharacterSet(charactersIn: "。！？.!?;:")
        guard let lastChar = last else { return false }
        return String(lastChar).unicodeScalars.allSatisfy { endPunctuationMarks.contains($0) }
    }

    /// Check if a single character string is a punctuation mark
    var isPunctuationCharacter: Bool {
        guard count == 1, let scalar = unicodeScalars.first else { return false }
        return CharacterSet.punctuationCharacters.contains(scalar)
    }

    var hasPunctuationSuffix: Bool {
        guard let lastChar = last else { return false }
        return String(lastChar).isPunctuationCharacter
    }

    /// Check if text starts with lowercase character
    var isLowercaseFirstChar: Bool {
        guard let firstChar = first else { return false }
        return firstChar.isLowercase && firstChar.isLetter
    }

    /// Count the number of words in the text string
    var wordCount: Int {
        let words = components(separatedBy: .whitespacesAndNewlines)
        return words.filter { !$0.isEmpty }.count
    }

    /// Check if text represents a list item based on common list markers
    var isListTypeFirstWord: Bool {
        let listPatterns = [
            "1.", "2.", "3.", "4.", "5.", "6.", "7.", "8.", "9.", "•", "-", "*", "a.", "b.", "c.",
        ]
        let trimmedText = trimmingCharacters(in: .whitespaces)

        for pattern in listPatterns where trimmedText.hasPrefix(pattern) {
            return true
        }

        return false
    }

    /// Count punctuation marks in text, excluding poetry-specific characters
    func countPunctuationMarks(excludingPoetryCharacters: Bool = true) -> Int {
        let allowedCharacters = excludingPoetryCharacters ? ["《", "》", "〔", "〕"] : [] // Poetry-specific characters
        var count = 0

        for char in self {
            let charString = String(char)
            if !allowedCharacters.contains(charString), charString.isPunctuationCharacter {
                count += 1
            }
        }

        return count
    }
}
