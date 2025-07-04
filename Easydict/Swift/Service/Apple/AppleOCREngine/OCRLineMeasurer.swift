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
    /// - Compares against intelligent threshold based on content analysis
    /// - Uses document-wide patterns for context-aware decisions
    ///
    /// **Threshold Calculation:**
    /// - Default threshold varies by language and content type
    /// - Space-separated languages (English): Uses word boundary analysis
    /// - Character-based languages (Chinese): Uses character-based calculations
    /// - Poetry/special content: Applies different thresholds
    ///
    /// **Use Cases:**
    /// - Text merging decisions (should lines be joined?)
    /// - Poetry detection (short lines often indicate intentional breaks)
    /// - List formatting (preserving list structure)
    /// - Paragraph boundary detection
    ///
    /// - Parameters:
    ///   - observation: The text observation to analyze for line length
    ///   - minimumRemainingCharacters: Custom threshold for remaining characters (uses smart default if nil)
    /// - Returns: true if line is considered "long" (little space remaining), false if "short"
    func isLongLine(
        _ observation: VNRecognizedTextObservation,
        minimumRemainingCharacters: Double? = nil
    )
        -> Bool {
        let threshold = minimumRemainingCharacters ?? smartMinimumCharactersThreshold(observation)
        let actualRemainingCharacters = charactersRemainingInLine(observation)

        // Line is considered "long" if remaining space is less than required minimum
        return actualRemainingCharacters < threshold
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

    /// Calculate how many characters can still fit in the line compared to the maximum line length
    /// - Parameter observation: The text observation to analyze
    /// - Returns: Number of characters that could still fit on the right side of the line
    private func charactersRemainingInLine(_ observation: VNRecognizedTextObservation) -> Double {
        guard let maxObservation = metrics.maxLongLineTextObservation else {
            return 0.0
        }

        let scaleFactor = NSScreen.main?.backingScaleFactor ?? 1.0

        // Calculate the horizontal distance between current line end and maximum line end
        let horizontalGap = maxObservation.boundingBox.maxX - observation.boundingBox.maxX

        // Convert the gap from normalized coordinates to actual pixel distance
        let actualLineWidth = metrics.ocrImage.size.width * metrics.maxLineLength / scaleFactor
        let actualGapWidth = actualLineWidth * horizontalGap

        // Convert pixel distance to character count using average character width
        let remainingCharacters = actualGapWidth / metrics.averageCharacterWidth

        return remainingCharacters
    }

    /// Calculate the minimum character threshold for considering a line as "long"
    /// Returns the minimum number of characters that should remain for a line to be considered "not long"
    /// - Parameters:
    ///   - observation: The text observation to analyze
    /// - Returns: Character count threshold (dynamically calculated based on detected text)
    private func smartMinimumCharactersThreshold(_ observation: VNRecognizedTextObservation)
        -> Double {
        let isEnglishTypeLanguage = languageManager.isLanguageWordsNeedSpace(metrics.language)

        if isEnglishTypeLanguage {
            // For space-separated languages, use detected maximum word length as base
            if metrics.maxWordLength > 0 {
                // Use actual max word length + buffer for punctuation and spacing
                return Double(metrics.maxWordLength) + 3.0
            } else {
                // Fallback to default if no words detected yet
                return 15.0
            }
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
