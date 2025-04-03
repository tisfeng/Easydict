//
//  String+Utils.swift
//  Easydict
//
//  Created by tisfeng on 2025/3/31.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

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

    /// Alternative punctuation removal using regex pattern.
    /// More flexible but potentially slower than removeAllPunctuation().
    /// - Returns: String with punctuation removed
    func removePunctuation2() -> String {
        let pattern = "[\\p{P}]"
        let regex = try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        return regex.stringByReplacingMatches(
            in: self,
            options: [],
            range: NSRange(location: 0, length: count),
            withTemplate: ""
        )
    }

    // MARK: - Feature Detection Methods

    /// Calculate the ratio of classical Chinese characters in text
    func calculateClassicalChineseMarkerRatio() -> Double {
        calculateLinguisticFeatureRatio(for: ClassicalMarker.Prose.particles)
    }

    /// Calculate the ratio of modern Chinese characters in text
    func calculateModernChineseMarkerRatio() -> Double {
        calculateLinguisticFeatureRatio(for: ClassicalMarker.Modern.particles)
    }

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

    func hasClassicalCiSpecificMarkers() -> Bool {
        let matches = findMatchedPatterns(in: ClassicalMarker.LyricPoetry.commonPhrases)
        if !matches.isEmpty {
            print("Found Ci markers: \(matches.joined(separator: ", "))")
        }
        // Require at least 2 markers
        return matches.count >= 2
    }

    /// Check if text contains classical poetry markers or patterns
    func hasClassicalPoetrySpecificMarkers() -> Bool {
        // Check common phrases
        let phraseMatches = findMatchedPatterns(in: ClassicalMarker.Poetry.commonPhrases)
        let hasCommonPhrases = phraseMatches.count >= 2

        if !phraseMatches.isEmpty {
            print("Found common phrases: \(phraseMatches.joined(separator: ", "))")
        }

        return hasCommonPhrases
    }

    /// Calculate the ratio of punctuation marks in text
    func calculatePunctuationRatio() -> Double {
        let text = trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return 0.0 }

        var punctuationCount = 0
        for char in text
            where
            ClassicalMarker.Common.punctuationCharacters.contains(String(char)) {
            punctuationCount += 1
        }

        return Double(punctuationCount) / Double(text.count)
    }
}
