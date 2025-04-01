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

    func hasHighClassicalLinguisticFeatureRatio(_ threshold: Double = 0.15) -> Bool {
        let ratio = calculateLinguisticFeatureRatio(for: ClassicalMarker.Prose.particles)
        print("Classical linguistic feature ratio: \(String(format: "%.2f", ratio))")
        return ratio > threshold
    }

    func hasHighModernLinguisticFeatureRatio(_ threshold: Double = 0.2) -> Bool {
        let ratio = calculateLinguisticFeatureRatio(for: ClassicalMarker.Modern.particles)
        print("Modern linguistic feature ratio: \(String(format: "%.2f", ratio))")
        return ratio > threshold
    }

    func calculateLinguisticFeatureRatio(for features: [String]) -> Double {
        let cleanText = removeAllPunctuation().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanText.isEmpty else { return 0.0 }

        var featureCount = 0
        let totalChars = cleanText.count

        // Count features
        for char in cleanText where features.contains(String(char)) {
            featureCount += 1
        }

        // Calculate ratio
        return Double(featureCount) / Double(totalChars)
    }

    /// Find matched count for given pattern list
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
