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
        let trimmedText = trimmingCharacters(in: .whitespaces)
        guard !trimmedText.isEmpty else { return false }

        // Use regex to match various list patterns
        let patterns = [
            "^\\d+\\.", // 1. 2. 3. etc.
            "^\\d+\\)", // 1) 2) 3) etc.
            "^[a-z]\\.", // a. b. c. etc.
            "^[A-Z]\\.", // A. B. C. etc.
            "^[a-z]\\)", // a) b) c) etc.
            "^[A-Z]\\)", // A) B) C) etc.
            "^[ivxlcdm]+\\.", // i. ii. iii. iv. v. etc. (Roman numerals)
            "^[IVXLCDM]+\\.", // I. II. III. IV. V. etc. (Roman numerals)
            "^•", // Bullet point
            "^-", // Dash
            "^\\*", // Asterisk
            "^§", // Section symbol
            "^¶", // Paragraph symbol
            "^►", // Arrow bullet
            "^▪", // Square bullet
            "^▫", // Hollow square bullet
            "^○", // Circle bullet
            "^●", // Filled circle bullet
            "^◦", // Small circle bullet
            "^◾", // Black medium small square
            "^◽", // White medium small square
        ]

        for pattern in patterns {
            do {
                let regex = try NSRegularExpression(pattern: pattern, options: [])
                let range = NSRange(location: 0, length: trimmedText.utf16.count)
                if regex.firstMatch(in: trimmedText, options: [], range: range) != nil {
                    return true
                }
            } catch {
                // If regex compilation fails, continue to next pattern
                continue
            }
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
