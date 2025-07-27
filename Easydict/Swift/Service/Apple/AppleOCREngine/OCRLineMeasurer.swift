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

/**
 * A class responsible for measuring line length and determining if a line is "long" or "short".
 *
 * This class encapsulates the logic for one of the most critical parts of the text merging
 * process: deciding whether a line of text is long enough to be considered part of a
 * continuous paragraph. A "long" line suggests that the next line is likely a continuation,
 * while a "short" line might indicate the end of a paragraph, a heading, or a list item.
 *
 * ### Key Responsibilities:
 * - **Long Line Detection**: The primary method, `isLongLine`, determines if a line has
 *   enough text to be considered "long".
 * - **Context-Aware Thresholds**: It calculates a `smartMinimumCharactersThreshold` that adapts
 *   based on the content of the *next* line, making the detection more robust.
 * - **Remaining Space Calculation**: It computes how many characters could still fit on a line,
 *   which is the core metric for the long-line decision.
 */
class OCRLineMeasurer {
    // MARK: Lifecycle

    /// Initialize with OCR metrics
    /// - Parameter metrics: OCR metrics containing necessary data for line measurement
    init(metrics: OCRMetrics) {
        self.metrics = metrics
        self.languageManager = EZLanguageManager.shared()
    }

    // MARK: Internal

    /// Determines if a text line is considered "long" based on remaining character space analysis.
    ///
    /// - Parameters:
    ///   - observation: The text observation to analyze for line length.
    ///   - nextObservation: The next text observation for context-aware analysis (optional).
    ///   - comparedObservation: The reference observation to compare against for remaining space (optional).
    ///   - confidenceLevel: Detection confidence level affecting threshold strictness (default: `.medium`).
    /// - Returns: `true` if the line is considered "long" (little space remaining), `false` if "short".
    func isLongLine(
        observation: VNRecognizedTextObservation,
        nextObservation: VNRecognizedTextObservation? = nil,
        comparedObservation: VNRecognizedTextObservation? = nil,
        confidenceLevel: OCRConfidenceLevel = .medium
    )
        -> Bool {
        let baseThreshold = smartMinimumCharactersThreshold(
            observation: observation,
            nextObservation: nextObservation
        )

        let finalThreshold = baseThreshold / confidenceLevel.multiplier

        let actualRemainingCharacters = charactersRemainingToReferenceLine(
            observation: observation,
            comparedObservation: comparedObservation
        )

        // Line is considered "long" if remaining space is less than required minimum
        let isLongLine = actualRemainingCharacters < finalThreshold

        let debugText = observation.firstText.prefix20
        let refText = comparedObservation?.firstText.prefix20 ?? "Default"

        if !isLongLine {
            print(
                "Short line detected (confidence: \(confidenceLevel)): '\(debugText)...' -> Remaining: \(String(format: "%.1f", actualRemainingCharacters)), Threshold: \(String(format: "%.1f", finalThreshold)) (base: \(String(format: "%.1f", baseThreshold)) × \(confidenceLevel.multiplier)), Ref: '\(refText)...'"
            )
        }

        return isLongLine
    }

    // MARK: Private

    private let metrics: OCRMetrics
    private let languageManager: EZLanguageManager

    // MARK: - Strategy Implementations

    // MARK: - Helper Methods

    /// Calculates how many characters can still fit in the line compared to a reference line length.
    /// - Parameters:
    ///   - observation: The text observation to analyze.
    ///   - comparedObservation: The reference observation to compare against (optional, defaults to `metrics.maxXLineTextObservation`).
    /// - Returns: The number of characters that could still fit on the right side of the line.
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

    /// Calculates the minimum character threshold for considering a line as "long".
    ///
    /// - Parameters:
    ///   - observation: The current text observation to analyze.
    ///   - nextObservation: The next text observation for context-aware analysis (optional).
    /// - Returns: The character count threshold (context-aware calculation based on the next line).
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

                    // Count the first word length
                    let firstWord = nextText.wordComponents.first ?? nextText
                    let firstWordLength = firstWord.count.double
                    // Add buffer for punctuation and spacing
                    threshold = firstWordLength + 3.0 // Special case > 2.8

                    return threshold
                }
            }

            // Fallback when no next observation or empty text
            return 12.0 // Conservative default for English
        } else {
            // For non-space languages (Chinese, Japanese, etc.), use character-based threshold
            var minimumCharacters = 1.6

            // Apply language-specific adjustments for Chinese
            if languageManager.isChineseLanguage(metrics.language) {
                let text = observation.firstText
                let hasEndPunctuation = text.hasEndPunctuationSuffix

                // Chinese text without ending punctuation may need slightly more tolerance
                // to avoid over-aggressive line merging
                if !hasEndPunctuation {
                    minimumCharacters += 0.7
                }

                /**
                 易成本，限制了最小实际交易额度从而杜绝了日常小额交易的可能性，而且由于不支持不
                 可撤销支付，对不可撤销服务进行支付将需要更大的成本。由于存在交易被撤销的可能
                 性，对于信任的需求将更广泛。商家必须警惕他们的客户，麻烦他们提供更多他本不需要
                 */

                if let nextObservation {
                    let nextText = nextObservation.firstText
                    let secondCharIsPunctuation = nextText.dropFirst().first?.isPunctuation ?? false

                    // If next text second character is punctuation, increase threshold
                    if !nextText.hasPunctuationPrefix, secondCharIsPunctuation {
                        minimumCharacters += 0.8 // Increase threshold for Chinese with punctuation
                    }
                }
            }

            return minimumCharacters
        }
    }
}
