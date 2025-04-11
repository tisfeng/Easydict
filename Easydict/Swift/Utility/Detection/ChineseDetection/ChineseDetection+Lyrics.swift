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
    func isClassicalLyrics(_ analysis: ChineseAnalysis) -> Bool {
        logInfo("\n----- Classical Lyrics Detection -----")

        if analysis.textCharCount < 10, analysis.phraseAnalysis.phrases.count < 2 {
            logInfo("Text is too short to be considered classical lyrics.")
            return false
        }

        // Check if we have a valid tune pattern from title
        if let title = analysis.metadata.title,
           let pattern = hasCiTunePattern(in: title) {
            logInfo("Found Ci tune pattern: \(pattern.pattern)")

            if matchesCiTuneCharacterCounts(analysis, tunePattern: pattern) {
                logInfo("✅ Lyrics, character count matches tune pattern")
                return true
            }
        }

        let hasCiFormat =
            analysis.parallelStructureRatio > 0.8 && analysis.phraseAnalysis.averageLength < 7
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
              let pattern = ChinseseMarker.LyricPoetry.tunePatterns.first(where: {
                  title.contains($0.key)
              })
        else { return nil }

        return (pattern.key, pattern.value)
    }

    /// Check if content matches expected character count for ci tune pattern
    /// - Parameters:
    ///   - analysis: ChineseAnalysis object containing analysis results
    ///   - tunePattern: Tuple containing the tune pattern and expected count
    /// - Returns: True if character count matches within tolerance
    func matchesCiTuneCharacterCounts(
        _ analysis: ChineseAnalysis,
        tunePattern: (pattern: String, count: [Int])
    )
        -> Bool {
        let (pattern, expectedCounts) = tunePattern
        let charCount = analysis.textCharCount

        logInfo("Tune pattern '\(pattern)' expects \(expectedCounts) chars")
        logInfo("Content has \(charCount) chars")

        let matchesCount = expectedCounts.contains(charCount)
        logInfo("Character count matches: \(matchesCount ? "✅" : "❌")")

        // Currently, classical ci content lines should no more than 2 lines
        if analysis.lines.count > 2 {
            logInfo("Warning: Content lino es count exceeds 2, may not be a valid ci.")
            return false
        }

        return matchesCount
    }
}
