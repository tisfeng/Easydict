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
    ///   - nextObservation: The next text observation for context-aware analysis.
    ///   - comparedObservation: The reference observation to compare against for remaining space (optional).
    ///   - confidence: Detection confidence level affecting threshold strictness (default: `.medium`).
    /// - Returns: `true` if the line is considered "long" (little space remaining), `false` if "short".
    func isLongLine(
        observation: VNRecognizedTextObservation,
        nextObservation: VNRecognizedTextObservation,
        comparedObservation: VNRecognizedTextObservation? = nil,
        confidence: ConfidenceLevel = .medium
    )
        -> Bool {
        let baseThreshold = smartMinimumCharactersThreshold(
            observation: observation,
            nextObservation: nextObservation
        )

        let finalThreshold = baseThreshold / confidence.multiplier

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
                "Short line detected (confidence: \(confidence)): '\(debugText)...' -> Remaining: \(actualRemainingCharacters.string1f)), Threshold: \(finalThreshold.string1f) (base: \(baseThreshold)) × \(confidence.multiplier)), Ref: '\(refText)...'"
            )
        }

        return isLongLine
    }

    /// Computes the average character width based on a given pair observation.
    ///
    /// - TODO: If pair observations font is different, we should only use the current observation.
    func computeAverageCharWidth(
        currentObservation: VNRecognizedTextObservation,
        anotherObservation: VNRecognizedTextObservation,
        ocrImage: NSImage? = nil,
        allowDifferentFontSize: Bool = false
    )
        -> Double {
        let currentAverageCharWidth = computeAverageCharWidth(
            observation: currentObservation,
            ocrImage: ocrImage
        )

        let pair = OCRTextObservationPair(current: currentObservation, previous: anotherObservation)
        let differentFontSize = fontSizeDifference(pair: pair)
        // If font sizes are significantly different, use the current observation only
        if !allowDifferentFontSize, differentFontSize > 1.5 {
            return currentAverageCharWidth
        }

        let anotherAverageCharWidth = computeAverageCharWidth(
            observation: anotherObservation,
            ocrImage: ocrImage
        )

        // Average the widths of both observations
        let averageCharWidth = (currentAverageCharWidth + anotherAverageCharWidth) / 2.0
        return averageCharWidth
    }

    /// Calculates the horizontal difference between two text observations in character units. currentX - previousX
    ///
    /// - Parameters:
    ///   - pair: The pair of text observations to compare.
    ///   - comparison: The X position comparison type (minX or maxX). Default is .minX.
    /// - Returns: The horizontal difference in character units (can be positive, negative, or zero).
    func characterDifferenceInXPosition(
        pair: OCRTextObservationPair,
        xComparison: XComparisonType = .minX
    )
        -> Double {
        guard let ocrImage = metrics.ocrImage else {
            return 0.0
        }

        let current = pair.current
        let previous = pair.previous

        let currentX: CGFloat
        let previousX: CGFloat
        switch xComparison {
        case .minX:
            currentX = current.boundingBox.minX
            previousX = previous.boundingBox.minX
        case .maxX:
            currentX = current.boundingBox.maxX
            previousX = previous.boundingBox.maxX
        case .centerX:
            currentX = current.boundingBox.midX
            previousX = previous.boundingBox.midX
        }
        let dx = currentX - previousX

        // Vision framework provides normalized coordinates (0-1), multiply by image width to get logical distance
        let imageWidth = ocrImage.size.width
        let logicalDifference = imageWidth * dx

        // For checking X position difference, do not need to check font size
        let averageCharacterWidth = computeAverageCharWidth(
            currentObservation: current,
            anotherObservation: previous,
            allowDifferentFontSize: true
        )

        // Convert logical difference to character units using average character width
        let characterDifference = logicalDifference / averageCharacterWidth

        return characterDifference
    }

    /// Calculates the absolute font size difference between two text observations.
    /// - Parameter pair: The text observation pair containing current and previous observations.
    /// - Returns: The absolute difference between the font sizes of the two observations.
    func fontSizeDifference(pair: OCRTextObservationPair) -> Double {
        let currentFontSize = fontSize(pair.current)
        let prevFontSize = fontSize(pair.previous)
        return abs(currentFontSize - prevFontSize)
    }

    /// Returns the font size threshold based on the specified language.
    /// - Parameter language: The language to determine the threshold for.
    /// - Returns: The font size difference threshold for the given language.
    func fontSizeThreshold(_ language: Language) -> Double {
        languageManager.isChineseLanguage(language)
            ? OCRConstants.chineseDifferenceFontThreshold
            : OCRConstants.englishDifferenceFontThreshold
    }

    // MARK: Private

    private let metrics: OCRMetrics
    private let languageManager: EZLanguageManager

    /// Computes the average character width based on a given text observation.
    private func computeAverageCharWidth(
        observation: VNRecognizedTextObservation,
        ocrImage: NSImage? = nil
    )
        -> Double {
        let ocrImage = ocrImage ?? metrics.ocrImage!

        // Vision framework provides normalized coordinates (0-1), so we multiply by image size
        // No need for scaleFactor since NSImage.size already gives us the logical size in points
        let textWidth = observation.boundingBox.size.width * ocrImage.size.width
        var charCount = observation.firstText.count.double

        // If text last char is punctuation, only count 0.5 char
        if let lastChar = observation.firstText.last,
           lastChar.isPunctuation {
            charCount -= 0.5
        }

        charCount = max(1, charCount) // Avoid negative

        return textWidth / charCount
    }

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
        let referenceObservation = comparedObservation ?? metrics.maxXObservation
        guard let referenceObservation = referenceObservation else {
            return 0.0
        }

        // Calculate the horizontal distance between current line end and reference line end
        let horizontalGap = referenceObservation.boundingBox.maxX - observation.boundingBox.maxX

        // Convert the gap from normalized coordinates to logical distance
        let referenceLineLength = referenceObservation.boundingBox.size.width
        let logicalLineWidth = ocrImage.size.width * referenceLineLength
        let logicalGapWidth = logicalLineWidth * horizontalGap

        let averageCharacterWidth = computeAverageCharWidth(
            currentObservation: observation,
            anotherObservation: referenceObservation,
        )

        // Convert logical distance to character count using average character width
        let remainingCharacters = logicalGapWidth / averageCharacterWidth

        return remainingCharacters
    }

    /// Calculates the minimum character threshold for considering a line as "long".
    ///
    /// - Parameters:
    ///   - observation: The current text observation to analyze.
    ///   - nextObservation: The next text observation for context-aware analysis.
    /// - Returns: The character count threshold (context-aware calculation based on the next line).
    private func smartMinimumCharactersThreshold(
        observation: VNRecognizedTextObservation,
        nextObservation: VNRecognizedTextObservation
    )
        -> Double {
        let isEnglishTypeLanguage = languageManager.isLanguageWordsNeedSpace(metrics.language)

        if isEnglishTypeLanguage {
            // For space-separated languages, use next line's first word length if available
            let nextText = nextObservation.firstText.trim()
            if !nextText.isEmpty {
                var threshold = 3.0 // Minimum threshold for English

                // Count the first word length
                let firstWord = nextText.wordComponents.first ?? nextText
                let firstWordLength = firstWord.count.double
                // Add buffer for punctuation and spacing
                threshold = firstWordLength + 3.0 // Special case > 2.8

                return threshold
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

                let nextText = nextObservation.firstText
                let secondCharIsPunctuation = nextText.dropFirst().first?.isPunctuation ?? false

                // If next text second character is punctuation, increase threshold
                if !nextText.hasPunctuationPrefix, secondCharIsPunctuation {
                    minimumCharacters += 0.8 // Increase threshold for Chinese with punctuation
                }
            }

            return minimumCharacters
        }
    }

    /// Calculates the font size of a given text observation.
    /// - Parameter observation: The text observation.
    /// - Returns: The calculated font size.
    private func fontSize(_ observation: VNRecognizedTextObservation) -> Double {
        guard let ocrImage = metrics.ocrImage else {
            return NSFont.systemFontSize
        }

        // Vision framework provides normalized coordinates, multiply by image size to get logical width
        let textWidth = observation.boundingBox.size.width * ocrImage.size.width
        return fontSize(observation.firstText, width: textWidth)
    }

    /// Estimates the font size of a string based on its actual width and system font proportions.
    /// - Parameters:
    ///   - text: The text string to measure.
    ///   - textWidth: The width of the text (in points).
    /// - Returns: An estimated font size that would fit the given width.
    private func fontSize(_ text: String, width textWidth: Double) -> Double {
        let systemFontSize = NSFont.systemFontSize
        guard !text.isEmpty else { return systemFontSize }

        let font = NSFont.systemFont(ofSize: systemFontSize)
        let renderedWidth = text.size(withAttributes: [.font: font]).width
        guard renderedWidth > 0 else { return systemFontSize }

        /**
         Use proportional scaling to estimate the actual font size:

         systemFontSize / renderedWidth = fontSize / textWidth
         fontSize = textWidth * (systemFontSize / renderedWidth)
         */

        let fontSize = textWidth * (systemFontSize / renderedWidth)
        return fontSize
    }
}
