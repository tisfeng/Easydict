//
//  OCRLineMeasurer.swift
//  Easydict
//
//  Created by tisfeng on 2025/7/1.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation
import Vision

// MARK: - OCRLineMeasurer

/// Specialized measurement system for analyzing text line characteristics in OCR processing
///
/// This centralized measurement system provides comprehensive analysis of text line properties,
/// serving as the authoritative source for all line-length-related decisions in the OCR pipeline.
/// It consolidates complex measurement logic and provides consistent metrics across all components.
///
/// **Core Measurements:**
/// - **Line Length Analysis**: Determines if lines are "long" or "short" relative to available space
/// - **Remaining Space Calculation**: Measures how much space is left on each line
/// - **Character Capacity**: Estimates how many more characters could fit on a line
/// - **Relative Length Comparison**: Compares lines against maximum observed lengths
/// - **Language-specific Metrics**: Applies different measurement rules for different languages
///
/// **Use Cases:**
/// - Poetry detection (short lines often indicate poetic structure)
/// - Text merging decisions (long lines may need different treatment)
/// - Layout analysis (understanding document structure)
/// - Quality assessment (very short lines may indicate OCR issues)
///
/// **Measurement Approach:**
/// - Uses character width calculations for precise space estimation
/// - Considers document-wide patterns for relative measurements
/// - Applies language-specific thresholds and rules
/// - Provides both absolute and relative measurement metrics
///
/// Essential for making intelligent decisions about text layout and formatting preservation.
class OCRLineMeasurer {
    // MARK: Lifecycle

    /// Initialize with OCR metrics
    /// - Parameter metrics: OCR metrics containing necessary data for line measurement
    init(metrics: OCRMetrics) {
        self.metrics = metrics
        self.languageManager = EZLanguageManager.shared()
    }

    // MARK: Internal

    /// Determine if a text line is considered "long" based on remaining character space analysis
    ///
    /// This sophisticated measurement method analyzes how much space remains at the end of a text line
    /// to determine if it should be considered "long" for text merging purposes. A "long" line typically
    /// indicates the text continues naturally to the next line, while a "short" line may indicate
    /// intentional breaks (poetry, lists, paragraphs).
    ///
    /// **Measurement Strategy:**
    /// - Calculates actual remaining horizontal space in the line
    /// - Converts space to character count using average character width
    /// - For space-separated languages: Compares with next line's first word length
    /// - For character-based languages: Uses character-based threshold calculations
    /// - Uses document-wide patterns for context-aware decisions
    ///
    /// **Context-Aware Threshold:**
    /// - Space-separated languages (English): Uses next line's first word length if available
    /// - Character-based languages (Chinese): Uses character-based calculations
    /// - Fallback to smart threshold when next observation is not available
    ///
    /// **Use Cases:**
    /// - Text merging decisions (should lines be joined?)
    /// - Poetry detection (short lines often indicate intentional breaks)
    /// - List formatting (preserving list structure)
    /// - Paragraph boundary detection
    ///
    /// - Parameters:
    ///   - observation: The text observation to analyze for line length
    ///   - nextObservation: The next text observation for context-aware analysis (optional)
    ///   - comparedObservation: The reference observation to compare against for remaining space (optional)
    /// - Returns: true if line is considered "long" (little space remaining), false if "short"
    func isLongLine(
        observation: VNRecognizedTextObservation,
        nextObservation: VNRecognizedTextObservation? = nil,
        comparedObservation: VNRecognizedTextObservation? = nil
    )
        -> Bool {
        let threshold = smartMinimumCharactersThreshold(
            observation: observation,
            nextObservation: nextObservation
        )

        let actualRemainingCharacters = charactersRemainingToReferenceLine(
            observation: observation,
            comparedObservation: comparedObservation
        )

        // Line is considered "long" if remaining space is less than required minimum
        let isLongLine = actualRemainingCharacters < threshold

        let debugText = observation.firstText.prefix20
        let refText = comparedObservation?.firstText.prefix20 ?? "Default"

        if !isLongLine {
            print(
                "Short line detected: '\(debugText)...' -> Remaining: \(String(format: "%.1f", actualRemainingCharacters)), Threshold: \(String(format: "%.1f", threshold)), Ref: '\(refText)...'"
            )
        }

        return isLongLine
    }

    // MARK: Private

    private let metrics: OCRMetrics
    private let languageManager: EZLanguageManager

    /// Check if a line observation is considered "long" based on simple length ratio
    /// This is a simplified version for basic length checking
    /// - Parameters:
    ///   - observation: The text observation to check
    ///   - threshold: The threshold ratio (0.0 to 1.0), defaults to 0.9
    /// - Returns: True if the line is considered long according to the threshold
    private func isLongLine(_ observation: VNRecognizedTextObservation, threshold: Double) -> Bool {
        let lineLength = observation.boundingBox.maxX
        return lineLength >= metrics.maxLineLength * threshold
    }

    // MARK: - Strategy Implementations

    // MARK: - Helper Methods

    /// Calculate how many characters can still fit in the line compared to a reference line length
    /// - Parameters:
    ///   - observation: The text observation to analyze
    ///   - comparedObservation: The reference observation to compare against (optional, defaults to metrics.maxXLineTextObservation)
    /// - Returns: Number of characters that could still fit on the right side of the line
    private func charactersRemainingToReferenceLine(
        observation: VNRecognizedTextObservation,
        comparedObservation: VNRecognizedTextObservation? = nil
    )
        -> Double {
        guard let ocrImage = metrics.ocrImage else {
            return 0.0
        }

        // Use provided comparedObservation or fall back to metrics default
        let referenceObservation = comparedObservation ?? metrics.maxXLineTextObservation
        guard let referenceObservation = referenceObservation else {
            return 0.0
        }

        // Calculate the horizontal distance between current line end and reference line end
        let horizontalGap = referenceObservation.boundingBox.maxX - observation.boundingBox.maxX

        // Convert the gap from normalized coordinates to logical distance
        let referenceLineLength = referenceObservation.boundingBox.size.width
        let logicalLineWidth = ocrImage.size.width * referenceLineLength
        let logicalGapWidth = logicalLineWidth * horizontalGap

        // Convert logical distance to character count using average character width
        let remainingCharacters = logicalGapWidth / metrics.averageCharacterWidth

        return remainingCharacters
    }

    /// Calculate the minimum character threshold for considering a line as "long"
    /// Returns the minimum number of characters that should remain for a line to be considered "not long"
    /// - Parameters:
    ///   - observation: The current text observation to analyze
    ///   - nextObservation: The next text observation for context-aware analysis (optional)
    /// - Returns: Character count threshold (context-aware calculation based on next line)
    private func smartMinimumCharactersThreshold(
        observation: VNRecognizedTextObservation,
        nextObservation: VNRecognizedTextObservation? = nil
    )
        -> Double {
        let isEnglishTypeLanguage = languageManager.isLanguageWordsNeedSpace(metrics.language)

        if isEnglishTypeLanguage {
            // For space-separated languages, use next line's first word length if available
            if let nextObservation {
                let nextText = nextObservation.firstText.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                if !nextText.isEmpty {
                    var threshold = 3.0 // Minimum threshold for English

                    // Count the first word length if next first character is not punctuation
                    if !nextText.hasPunctuationPrefix {
                        let firstWord = nextText.wordComponents.first ?? nextText
                        let firstWordLength = firstWord.count.double
                        // Add buffer for punctuation and spacing
                        threshold = firstWordLength + 3.0 // Special case > 2.8
                    }

                    return threshold
                }
            }

            // Fallback when no next observation or empty text
            return 10.0 // Conservative default for English
        } else {
            // For non-space languages (Chinese, Japanese, etc.), use character-based threshold
            var minimumCharacters = 1.5

            // Apply language-specific adjustments for Chinese
            if languageManager.isChineseLanguage(metrics.language) {
                let text = observation.firstText
                let hasEndPunctuation = text.hasEndPunctuationSuffix

                // Chinese text without ending punctuation may need slightly more tolerance
                // to avoid over-aggressive line merging
                if !hasEndPunctuation {
                    minimumCharacters += 0.8
                }
            }

            return minimumCharacters
        }
    }
}
