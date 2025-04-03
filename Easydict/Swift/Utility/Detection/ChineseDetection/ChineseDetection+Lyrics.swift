//
//  ChineseDetection+Lyrics.swift
//  Easydict
//
//  Created by tisfeng on 2025/4/2.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

extension ChineseDetection {
    /// Detect if the text is Chinese classical Lyrics (词)
    func isClassicalLyrics(_ contentInfo: ContentInfo, title: String?) -> Bool {
        logInfo("\n----- Classical Lyrics Detection -----")

        if contentInfo.textCharCount < 10, contentInfo.phraseAnalysis.phrases.count < 2 {
            logInfo("Text is too short to be considered classical lyrics.")
            return false
        }

        // Check if we have a valid tune pattern from title
        if let title, let pattern = hasCiTunePattern(in: title) {
            logInfo("Found Ci tune pattern: \(pattern.pattern)")

            // If character count matches the tune pattern, it's a strong signal
            if matchesCiTuneCharacterCounts(
                contentInfo, tunePattern: pattern
            ) {
                logInfo("✅ Lyrics, character count matches tune pattern")
                return true
            }
        }

        // Even without a tune pattern, check if it has a valid ci structure
        let hasCiFormat =
            contentInfo.parallelStructureRatio > 0.8 && contentInfo.phraseAnalysis.averageLength < 7
        if hasCiFormat {
            logInfo("✅ Lyrics, has Ci format with parallel structure and average length < 7")
            return true
        }

        return false
    }

    /// Check if text contains Ci tune pattern in title
    /// - Parameter title: Optional title text to check
    /// - Returns: Tuple of (pattern, [expectedCount]) if found, nil otherwise
    func hasCiTunePattern(in title: String?) -> (pattern: String, count: [Int])? {
        guard let title = title,
              let pattern = ClassicalMarker.LyricPoetry.tunePatterns.first(where: {
                  title.contains($0.key)
              })
        else { return nil }

        return (pattern.key, pattern.value)
    }

    /// Check if content matches expected character count for ci tune pattern
    /// - Parameters:
    ///   - contentInfo: Content info containing text and structure analysis
    ///   - tunePattern: Tuple containing the tune pattern and expected count
    /// - Returns: True if character count matches within tolerance
    func matchesCiTuneCharacterCounts(
        _ contentInfo: ContentInfo,
        tunePattern: (pattern: String, count: [Int])
    )
        -> Bool {
        let (pattern, expectedCounts) = tunePattern
        let charCount = contentInfo.textCharCount

        logInfo("Tune pattern '\(pattern)' expects \(expectedCounts) chars")
        logInfo("Content has \(charCount) chars")

        let matchesCount = expectedCounts.contains(charCount)
        logInfo("Character count matches: \(matchesCount ? "✅" : "❌")")

        // Currently, classical ci content lines should no more than 2 lines
        if contentInfo.lines.count > 2 {
            logInfo("Warning: Content lino es count exceeds 2, may not be a valid ci.")
            return false
        }

        return matchesCount
    }

    /// Analyze structural patterns of ci by comparing adjacent lines.
    /// - Parameters:
    ///   - lines: Array of text lines with metadata removed
    /// - Returns: A tuple containing:
    ///   - variableRatio: Ratio of lines with significant length variation
    ///   - structureRatio: Ratio of lines with matching structural patterns
    func analyzeCiStructure(_ lines: [String]) -> (
        variableRatio: Double, structureRatio: Double
    ) {
        logInfo("\n-- Analyzing Ci Structure --")

        let minLinesToCheck = 2
        guard lines.count >= minLinesToCheck else {
            return (0.0, 0.0)
        }

        // Split each line into phrases and logInfo
        let allPhrases = lines.map { splitIntoShortPhrases($0) }
        logInfo("Split phrases result:")
        for (index, phrases) in allPhrases.enumerated() {
            logInfo("Line \(index + 1): \(phrases.joined(separator: " | "))")
        }

        var variableCount = 0
        var structureMatchCount = 0

        // Check adjacent line pairs
        for i in 0 ..< (lines.count - 1) {
            let line1 = lines[i]
            let line2 = lines[i + 1]

            // Check length variation
            let (len1, len2) = getCleanLengths(line1, line2)
            if abs(len1 - len2) >= 3 {
                variableCount += 1
            }

            // Compare whole line structure
            logInfo("\nComparing line \(i + 1) with line \(i + 2):")
            logInfo("- Line 1: \(line1)")
            logInfo("- Line 2: \(line2)")

            let similarity = compareStructuralPatterns(line1, line2)
            logInfo("- Structural similarity: \(String(format: "%.2f", similarity))")

            if similarity > 0.6 {
                structureMatchCount += 1
                logInfo("✅ Found matching structure pattern")
            }
        }

        // Calculate final ratios
        let linePairs = Double(lines.count - 1)
        let variableRatio = Double(variableCount) / linePairs
        let structureRatio = Double(structureMatchCount) / linePairs

        logInfo("Format analysis:")
        logInfo("- Variable length ratio: \(String(format: "%.2f", variableRatio))")
        logInfo("- Structure similarity ratio: \(String(format: "%.2f", structureRatio))")

        return (variableRatio, structureRatio)
    }
}
