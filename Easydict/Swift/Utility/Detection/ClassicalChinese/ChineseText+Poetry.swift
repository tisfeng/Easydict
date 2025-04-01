//
//  ChineseText+Poetry.swift
//  Easydict
//
//  Created by tisfeng on 2025/4/2.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

extension ChineseText {
    /// Analyze if the text follows classical poetry (格律诗) patterns
    /// - Returns: True if text matches classical poetry patterns
    func isClassicalPoetry() -> Bool {
        print("\n----- Classical Poetry Detection -----")
        guard content.count >= 8 else { return false }

        // Split content into lines with punctuation separators
        let contentLines = content.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard contentLines.count >= 2 else { return false }

        print("Content lines count: \(contentLines.count)")
        print("Characters count: \(content.filter { !$0.isWhitespace }.count)")

        // Check poetry format and structure
        let (standardLineRatio, parallelRatio) = checkPoetryFormat(contentLines)
        let hasStrongFormat = standardLineRatio > 0.7 || parallelRatio > 0.5

        print("Poetry format check:")
        print("- Standard line ratio: \(String(format: "%.2f", standardLineRatio))")
        print("- Parallel ratio: \(String(format: "%.2f", parallelRatio))")

        // Check markers and title format as auxiliary features
        let hasPoetryMarkers = originalText.hasClassicalPoetrySpecificMarkers()
        let hasTitleFormat = title != nil

        print("Additional features:")
        print("- Poetry markers: \(hasPoetryMarkers ? "✅" : "❌")")
        print("- Title format: \(hasTitleFormat ? "✅" : "❌")")

        // Final decision based on multiple factors
        let isPoetry =
            hasStrongFormat
                && (
                    standardLineRatio > 0.8 // Very strong format signal
                        || (standardLineRatio > 0.6 && hasPoetryMarkers) // Good format with markers
                        || (standardLineRatio > 0.5 && hasPoetryMarkers && hasTitleFormat) // Multiple weak signals
                )

        print("Poetry detection result: \(isPoetry ? "✅" : "❌")")
        return isPoetry
    }

    // MARK: - Helper Methods

    /// Check poetry format and return format ratios
    func checkPoetryFormat(_ lines: [String]) -> (
        standardLineRatio: Double, parallelRatio: Double
    ) {
        var standardCount = 0
        var parallelCount = 0

        for (index, line) in lines.enumerated() {
            // Check standard length (5/7)
            if line.count == 5 || line.count == 7 {
                standardCount += 1
            }

            // Check parallel structure
            if index < lines.count - 1 {
                let nextLine = lines[index + 1]
                if line.count == nextLine.count {
                    parallelCount += 1
                }
            }
        }

        return (
            Double(standardCount) / Double(lines.count),
            Double(parallelCount) / Double(max(1, lines.count - 1))
        )
    }
}
