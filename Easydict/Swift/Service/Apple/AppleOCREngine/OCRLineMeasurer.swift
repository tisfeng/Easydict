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

/// Provides unified line measurement for OCR text processing
/// Consolidates all line length related judgments in one place
class OCRLineMeasurer {
    // MARK: Lifecycle

    /// Initialize with OCR metrics
    /// - Parameter metrics: OCR metrics containing necessary data for line measurement
    init(metrics: OCRMetrics) {
        self.metrics = metrics
        self.languageManager = EZLanguageManager.shared()
    }

    // MARK: Internal

    /// Check if a line observation is considered "long" based on remaining character space
    /// This method calculates how many characters could still fit on the line and compares against a threshold
    /// - Parameters:
    ///   - observation: The text observation to check
    ///   - minimumRemainingCharacters: The minimum characters that should remain (if nil, uses smart default)
    /// - Returns: True if the line is considered long (few characters remaining) for text merging purposes
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
