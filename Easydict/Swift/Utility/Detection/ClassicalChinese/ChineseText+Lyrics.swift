//
//  ChineseText+Lyrics.swift
//  Easydict
//
//  Created by tisfeng on 2025/4/2.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

extension ChineseText {
    /// Detect if the text is Chinese classical Ci (词)
    func isClassicalCi() -> Bool {
        print("\n----- Classical Ci Detection -----")
        guard content.count >= 12 else { return false }

        // Check if we have a valid tune pattern from title
        if let title = title,
           let pattern = hasCiTunePattern(in: title) {
            print("Found Ci tune pattern: \(pattern.pattern)")

            // Get content lines without metadata
            let contentLines = content.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }

            // Check structure and other features
            let (variableRatio, structureRatio) = analyzeCiStructure(contentLines)
            let hasCiFormat = structureRatio > 0.4 || (variableRatio > 0.3 && structureRatio > 0.3)

            // Check additional Ci features
            let hasCiMarkers = originalText.hasClassicalCiSpecificMarkers()

            print("\nCi Feature Check:")
            print("- Variable length ratio: \(String(format: "%.2f", variableRatio))")
            print("- Structure similarity ratio: \(String(format: "%.2f", structureRatio))")
            print("- Ci format: \(hasCiFormat ? "✅" : "❌")")
            print("- Ci markers: \(hasCiMarkers ? "✅" : "❌")")

            // If character count matches the tune pattern, it's a strong signal
            if matchesCiTuneCharacterCounts(contentLines, tunePattern: pattern) {
                print("✅ Character count matches tune pattern")
                return true
            }

            // Weaker signals: format and markers with tune pattern
            if hasCiFormat, structureRatio > 0.3 {
                print("✅ Has Ci format with tune pattern")
                return true
            }
        }

        // Even without a tune pattern, check if it has strong Ci characteristics
        let contentLines = content.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let (variableRatio, structureRatio) = analyzeCiStructure(contentLines)
        let hasCiFormat = structureRatio > 0.4 || (variableRatio > 0.3 && structureRatio > 0.3)
        let hasCiMarkers = originalText.hasClassicalCiSpecificMarkers()

        let isCi =
            hasCiFormat
                && (
                    (hasCiMarkers && structureRatio > 0.4) // Has markers and good structure
                        || (variableRatio > 0.4 && structureRatio > 0.5) // Very strong structural features
                )

        print("Ci detection result: \(isCi ? "✅" : "❌")")
        return isCi
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

    /// Extract ci tune title from a line
    /// For example:
    /// - 《定风波·莫听穿林打叶声》-> 定风波
    /// - 定风波 · 莫听穿林打叶声 -> 定风波
    /// - 定风波令·莫听穿林打叶声 -> 定风波
    /// - 定风波：莫听穿林打叶声 -> 定风波
    func extractCiTuneTitle(from line: String) -> String? {
        // Remove 《》if present and get potential title part
        let titlePart = line.replacingOccurrences(of: "《", with: "")
            .replacingOccurrences(of: "》", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Split by common separators
        let components = titlePart.components(separatedBy: CharacterSet(charactersIn: "·。："))
            .map { $0.replacingOccurrences(of: "令", with: "") } // Remove common suffix "令"
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        // Check if any component is a valid tune pattern
        return components.first { component in
            ClassicalMarker.LyricPoetry.tunePatterns.keys.contains(component)
        }
    }

    /// Check if content matches expected character count for ci tune pattern
    /// - Parameters:
    ///   - contentLines: Lines of content without metadata
    ///   - tunePattern: Tuple containing the tune pattern and expected count
    /// - Returns: True if character count matches within tolerance
    func matchesCiTuneCharacterCounts(
        _ contentLines: [String],
        tunePattern: (pattern: String, count: [Int])
    )
        -> Bool {
        let (pattern, expectedCounts) = tunePattern
        let contentText = contentLines.joined()
            .removeAllPunctuation()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let charCount = contentText.count

        print("Tune pattern '\(pattern)' expects \(expectedCounts) chars")
        print("Content has \(charCount) chars")

        let matchesCount = expectedCounts.contains(expectedCounts)
        print("Character count matches: \(matchesCount ? "✅" : "❌")")

        // Currently, classical ci content lines should no more than 2 lines
        if contentLines.count > 2 {
            print("Warning: Content lines count exceeds 2, may not be a valid ci.")
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
        print("\n-- Analyzing Ci Structure --")

        let minLinesToCheck = 2
        guard lines.count >= minLinesToCheck else {
            return (0.0, 0.0)
        }

        // Split each line into phrases and print
        let allPhrases = lines.map { splitIntoShortPhrases($0) }
        print("Split phrases result:")
        for (index, phrases) in allPhrases.enumerated() {
            print("Line \(index + 1): \(phrases.joined(separator: " | "))")
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
            print("\nComparing line \(i + 1) with line \(i + 2):")
            print("- Line 1: \(line1)")
            print("- Line 2: \(line2)")

            let similarity = compareStructuralPatterns(line1, line2)
            print("- Structural similarity: \(String(format: "%.2f", similarity))")

            if similarity > 0.6 {
                structureMatchCount += 1
                print("✅ Found matching structure pattern")
            }
        }

        // Calculate final ratios
        let linePairs = Double(lines.count - 1)
        let variableRatio = Double(variableCount) / linePairs
        let structureRatio = Double(structureMatchCount) / linePairs

        print("Format analysis:")
        print("- Variable length ratio: \(String(format: "%.2f", variableRatio))")
        print("- Structure similarity ratio: \(String(format: "%.2f", structureRatio))")

        return (variableRatio, structureRatio)
    }
}
