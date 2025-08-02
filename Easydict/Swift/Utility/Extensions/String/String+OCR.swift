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
    var isFirstCharUppercase: Bool {
        guard let firstChar = first else {
            return false
        }
        return firstChar.isUppercase && firstChar.isLetter
    }

    /// Check if the string starts with a lowercase letter
    var isFirstCharLowercase: Bool {
        guard let firstChar = first else {
            return false
        }
        return firstChar.isLowercase && firstChar.isLetter
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

    var hasPunctuationPrefix: Bool {
        guard let firstChar = first else { return false }
        return String(firstChar).isPunctuationCharacter
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
            "^[a-g]\\.", // a. b. c. etc.
            "^[A-G]\\.", // A. B. C. etc.
            "^[a-g]\\)", // a) b) c) etc.
            "^[A-G]\\)", // A) B) C) etc.
            "^[ivx]+\\.", // i. ii. iii. iv. v. etc. (Roman numerals)
            "^[IVX]+\\.", // I. II. III. IV. V. etc. (Roman numerals)

            // Require whitespace after marker to treat as list
            "^•\\s+", // Bullet point
            "^-\\s+", // Dash
            "^\\*\\s+", // Asterisk
            "^§\\s+", // Section symbol
            "^¶\\s+", // Paragraph symbol
            "^►\\s+", // Arrow bullet
            "^▪\\s+", // Square bullet
            "^▫\\s+", // Hollow square bullet
            "^○\\s+", // Circle bullet
            "^●\\s+", // Filled circle bullet
            "^◦\\s+", // Small circle bullet
            "^◾\\s+", // Black medium small square
            "^◽\\s+", // White medium small square

            "^\\[\\d+\\]\\s+", // [1] [2] [3] with space after
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

    /// Splits the string into word components, preserving the original order of appearance.
    ///
    /// - Chinese characters are treated as individual words.
    /// - Non-Chinese characters (e.g., English words or numbers) are grouped together until a character of a different type or a separator is encountered.
    /// - Whitespace and most punctuation marks act as separators and are excluded from the result.
    ///
    /// - Returns: An array of word components in the order they appear in the original string.
    ///
    /// - Examples:
    ///   - `"Hello, world!"` → `["Hello", "world"]`
    ///   - `"scpl.example.com"` → `["scpl.example.com"]`
    ///   - `"包括Google翻译、DeepL翻译等"` → `["包", "括", "Google", "翻", "译", "DeepL", "翻", "译", "等"]`
    var wordComponents: [String] {
        // Create a character set that includes whitespace, newlines, and punctuation
        var separatorSet = CharacterSet.whitespacesAndNewlines
        separatorSet.formUnion(.punctuationCharacters)

        // Exclude specific characters that are considered as a part of the word
        separatorSet.remove(charactersIn: "@#/•\"-.")

        var components: [String] = []
        var currentWord = ""

        for char in self {
            let str = String(char)
            guard let scalar = str.unicodeScalars.first else { continue }

            // Check if the character is a separator
            if separatorSet.contains(scalar) {
                if !currentWord.isEmpty {
                    components.append(currentWord)
                    currentWord = ""
                }
                continue
            }

            // Determine if current character is Chinese
            let isChinese = str.isChineseTextByRegex

            if isChinese {
                // If we were building a non-Chinese word, flush it
                if !currentWord.isEmpty {
                    components.append(currentWord)
                    currentWord = ""
                }
                // Each Chinese character is a separate word
                components.append(str)
            } else {
                // If continuing non-Chinese word
                currentWord.append(char)
            }
        }

        if !currentWord.isEmpty {
            components.append(currentWord)
        }

        return components
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
