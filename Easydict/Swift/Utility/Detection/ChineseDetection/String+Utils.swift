//
//  String+Utils.swift
//  Easydict
//
//  Created by tisfeng on 2025/3/31.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

// MARK: - String with Punctuation

extension String {
    /// Remove specific punctuation marks from text.
    /// - Parameter punctuations: Array of punctuation strings to remove
    /// - Returns: String with specified punctuation removed
    func removePunctuations(_ punctuations: [String]) -> String {
        components(separatedBy: .init(charactersIn: punctuations.joined())).joined()
    }

    /// Remove all standard punctuation characters from text.
    /// Uses Foundation's punctuation character set.
    /// - Returns: String with all punctuation removed
    func removeAllPunctuation() -> String {
        components(separatedBy: .punctuationCharacters).joined()
    }

    // MARK: - Feature Detection Methods

    /// Calculate the ratio of classical Chinese characters in text
    func calculateClassicalChineseMarkerRatio() -> Double {
        calculateLinguisticFeatureRatio(for: ChinseseMarker.Prose.particles)
    }

    /// Calculate the ratio of modern Chinese characters in text
    func calculateModernChineseMarkerRatio() -> Double {
        calculateLinguisticFeatureRatio(for: ChinseseMarker.Modern.particles)
    }

    /// Calculate the ratio of specific linguistic features in text
    func calculateLinguisticFeatureRatio(for features: [String]) -> Double {
        let cleanText = removeAllPunctuation().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanText.isEmpty else { return 0.0 }

        let totalChars = cleanText.count
        let featureCount = countOccurrences(of: features)

        let matches = findMatchedPatterns(in: features)
        logInfo("Debug log, found linguistic features: \(matches)")

        // Calculate ratio
        return Double(featureCount) / Double(totalChars)
    }

    /// Calculate the count of occurrences in the text
    /// - Parameter elements: Array of elements to count occurrences
    /// - Returns: Total number of occurrences in the text. e.g. "这是一个的的的啊啊测试文本", ["的", "啊"] -> 5 (total occurrences)
    func countOccurrences(of elements: [String]) -> Int {
        elements.reduce(0) { count, element in
            count + components(separatedBy: element).count - 1
        }
    }

    /// Find matched elements in the given pattern list
    /// - Parameter patterns: Array of elements to check
    /// - Returns: Array of matched elements. e.g. "这是一个的的的啊啊测试文本", ["的", "啊"] -> ["的", "啊"]
    func findMatchedPatterns(in patterns: [String]) -> [String] {
        patterns.filter { contains($0) }
    }

    /// Calculate the ratio of punctuation marks in text
    func calculatePunctuationRatio() -> Double {
        let text = trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return 0.0 }

        var punctuationCount = 0
        for char in text where char.isPunctuation {
            punctuationCount += 1
        }

        return Double(punctuationCount) / Double(text.count)
    }
}

// MARK: - Split Text into Lines

// This extension provides functionality to split text into lines based on specified separators.

extension String {
    /// Split text into lines with separators.
    /// - Parameters:
    ///   - separators: Additional separators to split lines, default is "\n".
    ///   - omittingEmptySubsequences: Whether to omit empty subsequences, default is false.
    /// - Returns: Array of lines
    ///
    /// - Note:
    /// If the text contains only one line, split it with "。"
    func splitTextIntoLines(
        separators: [String] = ["\n"],
        omittingEmptySubsequences: Bool = false
    )
        -> [String] {
        let lines = splitIntoShortPhrases(separators: separators)

        // If only one line, try to split it with "。"
        if lines.count == 1, let singleLine = lines.first {
            return singleLine.splitIntoShortPhrases(separators: ["。"])
        }

        return lines
    }

    /// Split a string into phrases using specified separators.
    /// Used to analyze the internal structure of classical Chinese text.
    /// - Parameters:
    ///   - separators: Array of separator strings, defaults to classical Chinese punctuation
    ///   - omittingEmptySubsequences: Whether to omit empty subsequences, default is false.
    /// - Returns: Array of non-empty phrases with whitespace trimmed
    func splitIntoShortPhrases(
        separators: [String] = ChinseseMarker.Common.lineSeparators,
        omittingEmptySubsequences: Bool = false
    )
        -> [String] {
        var phrases = [self]
        for separator in separators {
            phrases = phrases.flatMap { $0.components(separatedBy: separator) }
        }

        phrases = phrases.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        if omittingEmptySubsequences {
            phrases = phrases.filter { !$0.isEmpty }
        }

        return phrases
    }
}
