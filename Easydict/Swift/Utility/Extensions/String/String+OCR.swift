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

    /// Count the number of words in the text string, splitting by whitespace and punctuation
    var wordCount: Int {
        wordComponents.count
    }

    /// Count the number of English words in the text string.
    var englishWordCount: Int {
        let englishWords = wordComponents.filter { $0.isEnglishText }
        return englishWords.count
    }

    /// Check if text represents a list item based on common list markers
    var isListTypeFirstWord: Bool {
        let trimmedText = trimmingCharacters(in: .whitespaces)
        guard !trimmedText.isEmpty else { return false }

        // Use regex to match various list patterns
        let patterns = [
            "^\\d+\\.", // 1. 2. 3. etc.
            "^\\d+\\)", // 1) 2) 3) etc.
            "^\\d+\\）", // 1） 2） 3） etc. (Chinese parentheses)
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
                if let match = regex.firstMatch(in: trimmedText, options: [], range: range) {
                    // Found a list marker, now check what follows
                    let markerEndIndex = match.range.upperBound

                    // Check if there's content after the marker
                    guard markerEndIndex < trimmedText.utf16.count else { return false }

                    // Get the substring after the marker
                    let afterMarkerIndex = trimmedText.index(
                        trimmedText.startIndex, offsetBy: markerEndIndex
                    )
                    let remainingText = String(trimmedText[afterMarkerIndex...])

                    // Find the first non-whitespace character after the marker
                    let firstNonSpaceChar = remainingText.first { !$0.isWhitespace }

                    // The first non-whitespace character should not be a punctuation mark
                    if let char = firstNonSpaceChar {
                        return !String(char).isPunctuationCharacter
                    }

                    // If no non-whitespace character found after marker, it's not a valid list item
                    return false
                }
            } catch {
                // If regex compilation fails, continue to next pattern
                continue
            }
        }

        return false
    }

    /// Get the first word in the string, splitting by whitespace and punctuation
    var firstWord: String {
        wordComponents.first ?? ""
    }

    /// Get the last word in the string, splitting by whitespace and punctuation
    var lastWord: String {
        wordComponents.last ?? ""
    }

    /// Split text into word components, separating by whitespace and punctuation
    var wordComponents: [String] {
        // Create a character set that includes whitespace, newlines, and punctuation
        var separatorSet = CharacterSet.whitespacesAndNewlines
        separatorSet.formUnion(.punctuationCharacters)

        // Split the string and filter out empty components
        let components = components(separatedBy: separatorSet)
        return components.filter { !$0.isEmpty }
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
