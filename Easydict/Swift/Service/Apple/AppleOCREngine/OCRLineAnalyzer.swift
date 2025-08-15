//
//  OCRLineAnalyzer.swift
//  Easydict
//
//  Created by tisfeng on 2025/6/26.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation
import Vision

// MARK: - OCRLineAnalyzer

/// A class dedicated to analyzing the spatial and layout relationships between lines of OCR text.
///
/// `OCRLineAnalyzer` provides a suite of methods to determine how text observations are
/// positioned relative to one another. It is a key component in the text merging process,
/// responsible for identifying indentation, line breaks, font size changes, and other
/// layout features that guide formatting decisions.
class OCRLineAnalyzer {
    // MARK: Lifecycle

    /// Initializes the line analyzer with the provided OCR metrics.
    /// - Parameter metrics: The OCR metrics containing document-wide analysis data.
    init(metrics: OCRSection) {
        self.metrics = metrics
        self.lineMeasurer = OCRLineMeasurer(metrics: metrics)
    }

    // MARK: Internal

    /// Checks if a text observation has indentation relative to a reference observation.
    ///
    /// - Parameters:
    ///   - observation: The text observation to analyze for indentation.
    ///   - compared: The reference observation to compare against (optional, defaults to `metrics.minXLineTextObservation`).
    ///   - confidence: The detection confidence level affecting threshold strictness (default: `.medium`).
    ///   - indentationType: The type of indentation to check for (default: `.positive`).
    ///   - xComparison: The type of X position comparison to perform (default: `.minX`).
    /// - Returns: `true` if the observation has the specified type of indentation, `false` otherwise.
    func hasIndentation(
        observation: VNRecognizedTextObservation,
        compared comparedObservation: VNRecognizedTextObservation? = nil,
        confidence: ConfidenceLevel = .medium,
        indentationType: IndentationType = .positive,
        xComparison: XComparisonType = .minX
    )
        -> Bool {
        // Use provided comparedObservation or fall back to metrics default
        guard let comparedObservation = comparedObservation ?? metrics.minXObservation else {
            return false
        }

        let indentationInfo = analyzeIndentationInfo(
            observation: observation,
            compared: comparedObservation,
            confidence: confidence,
            xComparison: xComparison
        )

        let hasRequestedIndentation = indentationInfo.matches(indentationType)

        if hasRequestedIndentation {
            print("\nIndentation detected: \(indentationInfo)")
            print("\nCurrent observation: \(observation)")
            print("Compared against: \(comparedObservation)\n")
        }

        return hasRequestedIndentation
    }

    /// Convenience method to check for positive indentation.
    func hasPositiveIndentation(
        observation: VNRecognizedTextObservation,
        comparedObservation: VNRecognizedTextObservation? = nil,
        confidence: ConfidenceLevel = .medium,
        xComparison: XComparisonType = .minX
    )
        -> Bool {
        hasIndentation(
            observation: observation,
            compared: comparedObservation,
            confidence: confidence,
            indentationType: .positive,
            xComparison: xComparison
        )
    }

    /// Convenience method to check for negative indentation.
    func hasNegativeIndentation(
        observation: VNRecognizedTextObservation,
        comparedObservation: VNRecognizedTextObservation? = nil,
        confidence: ConfidenceLevel = .medium,
        xComparison: XComparisonType = .minX
    )
        -> Bool {
        hasIndentation(
            observation: observation,
            compared: comparedObservation,
            confidence: confidence,
            indentationType: .negative,
            xComparison: xComparison
        )
    }

    /// Convenience method to check for no indentation (aligned).
    func hasNoIndentation(
        observation: VNRecognizedTextObservation,
        compared: VNRecognizedTextObservation? = nil,
        confidence: ConfidenceLevel = .medium,
        xComparison: XComparisonType = .minX
    )
        -> Bool {
        hasIndentation(
            observation: observation,
            compared: compared,
            confidence: confidence,
            indentationType: .none,
            xComparison: xComparison
        )
    }

    /// Returns the full indentation analysis result for detailed inspection.
    ///
    /// - Parameters:
    ///   - observation: The text observation to analyze for indentation.
    ///   - comparedObservation: The reference observation to compare against (optional, defaults to `metrics.minXObservation`).
    ///   - confidence: The detection confidence level affecting threshold strictness (default: `.medium`).
    ///   - xComparison: The type of X position comparison to perform (default: `.minX`).
    /// - Returns: An `IndentationInfo` containing all analysis details, or `nil` if no comparison observation is available.
    func getIndentationAnalysis(
        observation: VNRecognizedTextObservation,
        comparedObservation: VNRecognizedTextObservation? = nil,
        confidence: ConfidenceLevel = .medium,
        xComparison: XComparisonType = .minX
    )
        -> IndentationInfo? {
        guard let comparedObservation = comparedObservation ?? metrics.minXObservation else {
            return nil
        }

        return analyzeIndentationInfo(
            observation: observation,
            compared: comparedObservation,
            confidence: confidence,
            xComparison: xComparison
        )
    }

    /// Determines if two text observations have equivalent horizontal positioning (X coordinates).
    ///
    /// - Parameters:
    ///   - pair: The pair of text observations to compare for X alignment.
    ///   - comparison: The type of X position comparison to perform (default: `.minX`).
    ///   - confidence: The detection confidence level affecting threshold strictness (default: `.medium`).
    /// - Returns: `true` if observations are horizontally aligned within tolerance, `false` otherwise.
    func isEqualX(
        pair: OCRObservationPair,
        xComparison: XComparisonType = .minX,
        confidence: ConfidenceLevel = .medium
    )
        -> Bool {
        // Use hasNoIndentation to check if there's no significant difference
        // If there's no indentation, then the X positions are considered equal
        hasNoIndentation(
            observation: pair.current,
            compared: pair.previous,
            confidence: confidence,
            xComparison: xComparison
        )
    }

    /// Checks if two text observations have equivalent center X positions.
    func isEqualCenterX(
        pair: OCRObservationPair,
        confidence: ConfidenceLevel = .medium
    )
        -> Bool {
        // Compare minX and maxX positions to determine center alignment
        let isEqualCenterX = isEqualX(pair: pair, xComparison: .centerX, confidence: confidence)
        return isEqualCenterX
    }

    /// Determines if a text observation represents a long line of text.
    func isLongText(
        observation: VNRecognizedTextObservation,
        nextObservation: VNRecognizedTextObservation,
        comparedObservation: VNRecognizedTextObservation? = nil,
        confidence: ConfidenceLevel = .medium
    )
        -> Bool {
        lineMeasurer.isLongLine(
            observation: observation,
            nextObservation: nextObservation,
            comparedObservation: comparedObservation,
            confidence: confidence
        )
    }

    /// Analyzes if there is significant line spacing between two text observations.
    ///
    /// - Parameters:
    ///   - pair: The text observation pair containing current and previous observations.
    ///   - lineSpacingThreshold: Optional absolute height threshold; if `nil`, calculates an adaptive threshold.
    ///   - confidence: The detection confidence level affecting threshold strictness (default: `.medium`).
    /// - Returns: `true` if the vertical gap exceeds the threshold, `false` otherwise.
    func isBigLineSpacing(
        pair: OCRObservationPair,
        lineSpacingThreshold: Double? = nil,
        confidence: ConfidenceLevel = .medium
    )
        -> Bool {
        // Use provided threshold or fall back to metrics default big line spacing threshold
        let threshold = lineSpacingThreshold ?? metrics.bigLineSpacingThreshold
        let gapRatio = pair.verticalGap / threshold
        let isBigSpacing = gapRatio > confidence.multiplier

        if isBigSpacing {
            print(
                "\nBig line spacing detected (confidence: \(confidence)), gap = \(pair.verticalGap.string3f), threshold = \(threshold.string3f), gapRatio = \(gapRatio.string3f) > \(confidence.multiplier)"
            )
            print("Current: \(pair.current)\n")
        }

        return isBigSpacing
    }

    /// Analyzes and compares font sizes between two text observations.
    ///
    /// - Parameters:
    ///   - pair: The text observation pair containing current and previous observations.
    ///   - fontSizeThreshold: Optional font size difference threshold; if `nil`, uses language-specific default.
    ///   - confidence: The detection confidence level affecting threshold strictness (default: `.medium`).
    /// - Returns: `true` if font sizes are considered different beyond the threshold, `false` if they are similar.
    func hasDifferentFontSize(
        pair: OCRObservationPair,
        fontSizeThreshold: Double? = nil,
        confidence: ConfidenceLevel = .medium,
        checkTextLength: Bool = true
    )
        -> Bool {
        // If text is too short, font size may be inaccurate.
        if checkTextLength, !hasEnoughTextLength(pair: pair) {
            return false
        }

        let differentFontSize = lineMeasurer.fontSizeDifference(pair: pair)
        let baseThreshold = fontSizeThreshold ?? lineMeasurer.fontSizeThreshold(metrics.language)
        let finalThreshold = baseThreshold * confidence.multiplier
        let isDifferent = differentFontSize >= finalThreshold

        if isDifferent {
            print(
                "\nDifferent font detected (confidence: \(confidence)): diff = \(differentFontSize.string1f), threshold = \(finalThreshold) (base: \(baseThreshold) × \(confidence.multiplier))"
            )
            print("Pair: \(pair)\n")
        }
        return isDifferent
    }

    /// Calculates the font size difference between two text observations.
    func fontSizeDifference(
        pair: OCRObservationPair,
        checkTextLength: Bool = true
    )
        -> Double {
        // If text is too short, font size may be inaccurate.
        if checkTextLength, !hasEnoughTextLength(pair: pair) {
            return 0.0
        }

        return lineMeasurer.fontSizeDifference(pair: pair)
    }

    /// Checks if two observations are considered equal Chinese text.
    func isEqualChinesePair(_ pair: OCRObservationPair) -> Bool {
        // Only analyze if the language is Chinese
        guard languageManager.isChineseLanguage(metrics.language) else {
            return false
        }

        let line1 = pair.previous.firstText
        let line2 = pair.current.firstText
        let similarity = line1.structuralSimilarityScore(to: line2)
        let equalCharCount = line1.count == line2.count

        let equalStructure = similarity >= 0.9 || (similarity >= 0.7 && equalCharCount)
        let equalAlignment = isEqualAlignment(pair: pair)
        let hasEndPunctuationSuffix = line1.hasEndPunctuationSuffix && line2.hasEndPunctuationSuffix

        let isEqualChinese = equalStructure && equalAlignment && hasEndPunctuationSuffix
        if isEqualChinese {
            print("\nEqual Chinese text detected: similarity = \(similarity.string2f)\n")
        }

        return isEqualChinese
    }

    /// Checks if a text observation is a short line of text.
    ///
    /// - Parameters:
    ///  - observation: The text observation to analyze for line length characteristics.
    ///  - comparedObservation: Optional reference observation to compare against (defaults to `metrics.maxLineLengthObservation`).
    ///  - lessRateOfMaxLength: Optional rate of maximum line length to consider as "short" (default: 0.5).
    /// - Returns: `true` if the line is considered short, `false` otherwise.
    func isShortLine(
        observation: VNRecognizedTextObservation,
        comparedObservation: VNRecognizedTextObservation? = nil,
        lessRateOfMaxLength: Double = 0.5
    )
        -> Bool {
        // Use provided comparedObservation or fall back to metrics default
        let referenceObservation = comparedObservation ?? metrics.maxLengthObservation
        guard let referenceObservation = referenceObservation else { return false }

        let lineWidth = observation.lineWidth
        let comparedLineWidth = referenceObservation.lineWidth
        let isShort = lineWidth < (comparedLineWidth * lessRateOfMaxLength)

        return isShort
    }

    /// Determines if two text observations represent a new line break.
    ///
    /// - Parameter pair: The pair of text observations to analyze for line separation.
    /// - Returns: `true` if observations represent a new line, `false` if on the same line.
    func isNewLine(pair: OCRObservationPair) -> Bool {
        let verticalGap = pair.verticalGap

        // Calculate adaptive threshold based on actual text heights
        let currentHeight = pair.current.boundingBox.size.height
        let previousHeight = pair.previous.boundingBox.size.height
        let averageHeight = (currentHeight + previousHeight) / 2

        // Use a fraction of the smaller text height as threshold
        // This is more adaptive than using global minimum line height
        let adaptiveThreshold = averageHeight

        // Also consider a minimum threshold to avoid being too strict with very small text
        let minimumThreshold = metrics.averageLineHeight

        // Use the larger of the two thresholds for better accuracy
        let threshold = max(adaptiveThreshold, minimumThreshold) * 0.4

        // If vertical gap is positive (spacing) or very small negative (slight overlap),
        // consider it as a new line.
        let isNewLine = verticalGap > 0 || abs(verticalGap) <= threshold

        if !isNewLine {
            print(
                "\nVertical gap: \(verticalGap.string2f), Threshold: \(threshold.string2f)"
            )
            print("Same line detected: \(pair)")
        }

        return isNewLine
    }

    // MARK: Private

    private let metrics: OCRSection
    private let lineMeasurer: OCRLineMeasurer
    private var languageManager = EZLanguageManager.shared()

    /// Determines if `value1` is greater than `value2` by a given `ratio`.
    /// - Parameters:
    ///   - ratio: The minimum similarity ratio (0.0-1.0).
    ///   - value1: The first value to compare.
    ///   - value2: The second value to compare.
    /// - Returns: `true` if `value1` is greater than `value2` by the ratio, `false` otherwise.
    private func isRatioGreaterThan(_ ratio: Double, value1: Double, value2: Double) -> Bool {
        let minValue = min(value1, value2)
        let maxValue = max(value1, value2)
        return (minValue / maxValue) > ratio
    }

    /// Checks if two text observations have similar maximum X coordinates (line endings).
    ///
    /// - Parameters:
    ///   - pair: The text observation pair to analyze.
    ///   - ratio: The similarity threshold ratio (default: 0.95).
    /// - Returns: `true` if maxX coordinates are similar within the ratio threshold, `false` otherwise.
    private func isEqualMaxX(pair: OCRObservationPair, ratio: Double = 0.95) -> Bool {
        let lineMaxX = pair.current.boundingBox.maxX
        let prevLineMaxX = pair.previous.boundingBox.maxX

        return isRatioGreaterThan(ratio, value1: lineMaxX, value2: prevLineMaxX)
    }

    /// Determines if two text observations have equal alignment (both minX and maxX coordinates).
    private func isEqualAlignment(
        pair: OCRObservationPair, confidence: ConfidenceLevel = .medium
    )
        -> Bool {
        let isEqualMinX = isEqualX(pair: pair, xComparison: .minX, confidence: confidence)
        let isEqualMaxX = isEqualX(pair: pair, xComparison: .maxX, confidence: confidence)
        return isEqualMinX && isEqualMaxX
    }

    /// Check if pair has enough text length excluding punctuation and symbols.
    private func hasEnoughTextLength(
        pair: OCRObservationPair,
        minLength: Int = 3
    )
        -> Bool {
        // If text is too short, font size may be inaccurate.
        // Punctuation marks may be also detected as different font size, so remove them.
        let text1 = pair.previous.firstText.removingNonLetters()
        let text2 = pair.current.firstText.removingNonLetters()
        return text1.count >= minLength && text2.count >= minLength
    }

    /// Check if observation has enough text length exluding punctuation and symbols.
    ///
    /// - Important: This is used to ensure that short text observations do not affect font size calculations.
    private func hasEnoughTextLength(
        observation: VNRecognizedTextObservation,
        minLength: Int = 3
    )
        -> Bool {
        // If text is too short, font size may be inaccurate.
        // Punctuation marks may be also detected as different font size, so remove them.
        let text = observation.firstText.removingPunctuationCharacters().removingSymbols().trim()
        return text.count >= minLength
    }

    /// Analyzes the indentation info between two text observations.
    ///
    /// - Parameters:
    ///   - observation: The text observation to analyze for indentation.
    ///   - compared: The reference observation to compare against.
    ///   - confidence: The detection confidence level affecting threshold strictness.
    ///   - xComparison: The type of X position comparison to perform.
    /// - Returns: An `IndentationInfo` containing the analysis results and intermediate values.
    private func analyzeIndentationInfo(
        observation: VNRecognizedTextObservation,
        compared comparedObservation: VNRecognizedTextObservation,
        confidence: ConfidenceLevel = .medium,
        xComparison: XComparisonType = .minX
    )
        -> IndentationInfo {
        let pair = OCRObservationPair(current: observation, previous: comparedObservation)
        let characterDifference = lineMeasurer.characterDifferenceInXPosition(
            pair: pair,
            xComparison: xComparison
        )
        let baseThreshold = OCRConstants.indentationCharacterCount
        let finalThreshold = baseThreshold * confidence.multiplier

        let indentationType: IndentationType
        if characterDifference > finalThreshold {
            indentationType = .positive
        } else if characterDifference < -finalThreshold {
            indentationType = .negative
        } else {
            indentationType = .none
        }

        return IndentationInfo(
            indentationType: indentationType,
            characterDifference: characterDifference,
            baseThreshold: baseThreshold,
            finalThreshold: finalThreshold,
            confidence: confidence,
            xComparison: xComparison
        )
    }
}
