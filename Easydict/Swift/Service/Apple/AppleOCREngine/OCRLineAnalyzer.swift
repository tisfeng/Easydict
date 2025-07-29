//
//  OCRLineAnalyzer.swift
//  Easydict
//
//  Created by tisfeng on 2025/6/26.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation
import Vision

// MARK: - OCRConfidenceLevel

/**
 * Defines various confidence levels for OCR analysis thresholds.
 *
 * These levels adjust detection thresholds to provide more or less strict analysis
 * depending on the reliability of the OCR data and specific use cases.
 */
enum OCRConfidenceLevel {
    /// High confidence level, applies a 1.5x multiplier to thresholds (more strict).
    case high
    /// Medium confidence level, applies a 1.0x multiplier to thresholds (default).
    case medium
    /// Low confidence level, applies a 0.7x multiplier to thresholds (more lenient).
    case low
    /// Custom confidence level, allows a user-defined multiplier.
    case custom(Double)

    // MARK: Lifecycle

    /// Initializes a custom confidence level with a specific multiplier value.
    /// - Parameter multiplier: The exact threshold multiplier value to use.
    init(multiplier: Double) {
        self = .custom(multiplier)
    }

    // MARK: Internal

    /// The numerical multiplier associated with the confidence level.
    var multiplier: Double {
        switch self {
        case .high: return 1.5
        case .medium: return 1.0
        case .low: return 0.7
        case let .custom(multiplier): return multiplier
        }
    }
}

// MARK: - XComparisonType

/// Represents the type of X position comparison for text observations.
enum XComparisonType {
    case minX
    case maxX
}

// MARK: - OCRLineAnalyzer

/**
 * A class dedicated to analyzing the spatial and layout relationships between lines of OCR text.
 *
 * `OCRLineAnalyzer` provides a suite of methods to determine how text observations are
 * positioned relative to one another. It is a key component in the text merging process,
 * responsible for identifying indentation, line breaks, font size changes, and other
 * layout features that guide formatting decisions.
 *
 * ### Key Analysis Capabilities:
 * - **Indentation Detection**: Determines if a line is indented relative to a reference line.
 * - **Line Spacing Analysis**: Checks for large vertical gaps that may indicate paragraph breaks.
 * - **Font Size Comparison**: Identifies changes in font size between lines.
 * - **Alignment Checks**: Verifies if lines share the same starting (`isEqualX`) or ending (`isEqualMaxX`) horizontal positions.
 * - **Line Length Analysis**: Classifies lines as "long" or "short" based on their width relative to the document's maximum line length.
 *
 * The analyzer uses `OCRMetrics` to access document-wide statistics, ensuring that its
 * decisions are context-aware and consistent.
 */
class OCRLineAnalyzer {
    // MARK: Lifecycle

    /// Initializes the line analyzer with the provided OCR metrics.
    /// - Parameter metrics: The OCR metrics containing document-wide analysis data.
    init(metrics: OCRMetrics) {
        self.metrics = metrics
        self.lineMeasurer = OCRLineMeasurer(metrics: metrics)
    }

    // MARK: Internal

    /// Checks if a text observation has indentation relative to a reference observation.
    ///
    /// - Parameters:
    ///   - observation: The text observation to analyze for indentation.
    ///   - comparedObservation: The reference observation to compare against (optional, defaults to `metrics.minXLineTextObservation`).
    ///   - confidence: The detection confidence level affecting threshold strictness (default: `.medium`).
    /// - Returns: `true` if the observation is indented, `false` if aligned with the left margin.
    func hasIndentation(
        observation: VNRecognizedTextObservation,
        comparedObservation: VNRecognizedTextObservation? = nil,
        confidence: OCRConfidenceLevel = .medium
    )
        -> Bool {
        // Use provided comparedObservation or fall back to metrics default
        let referenceObservation = comparedObservation ?? metrics.minXLineTextObservation
        guard let referenceObservation = referenceObservation else { return false }

        let textObservationPair = OCRTextObservationPair(
            current: observation,
            previous: referenceObservation
        )

        let characterDifference = characterDifferenceInXPosition(pair: textObservationPair)
        let baseThreshold = OCRConstants.indentationCharacterCount
        let finalThreshold = baseThreshold * confidence.multiplier
        let isIndented = characterDifference > finalThreshold

        if isIndented {
            let refText = referenceObservation.firstText.prefix20
            print(
                "\nIndentation detected (confidence: \(confidence)): \(characterDifference.oneDecimalString) > \(finalThreshold.oneDecimalString) (base: \(baseThreshold) × \(confidence.multiplier)) characters"
            )
            print("Current observation: \(observation)")
            print("Compared against: '\(refText)...'\n")
        }

        return isIndented
    }

    /// Determines if a text observation represents a long line of text.
    ///
    /// - Parameters:
    ///   - observation: The text observation to analyze for line length characteristics.
    ///   - nextObservation: The next text observation for enhanced context analysis (optional).
    ///   - comparedObservation: The reference observation to compare against (optional).
    ///   - confidence: The detection confidence level affecting threshold strictness (default: `.medium`).
    /// - Returns: `true` if the line is considered "long", `false` if "short".
    func isLongText(
        observation: VNRecognizedTextObservation,
        nextObservation: VNRecognizedTextObservation? = nil,
        comparedObservation: VNRecognizedTextObservation? = nil,
        confidence: OCRConfidenceLevel = .medium
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
        pair: OCRTextObservationPair,
        lineSpacingThreshold: Double? = nil,
        confidence: OCRConfidenceLevel = .medium
    )
        -> Bool {
        // Use provided threshold or fall back to metrics default big line spacing threshold
        let threshold = lineSpacingThreshold ?? metrics.bigLineSpacingThreshold
        let gapRatio = pair.verticalGap / threshold
        let isBigSpacing = gapRatio > confidence.multiplier

        if isBigSpacing {
            print(
                "\nBig line spacing detected (confidence: \(confidence)), gap = \(pair.verticalGap.threeDecimalString), threshold = \(threshold.threeDecimalString), gapRatio = \(gapRatio.threeDecimalString) > \(confidence.multiplier)"
            )
            print("Current: \(pair.current)\n")
        }

        return isBigSpacing
    }

    /// Calculates the absolute font size difference between two text observations.
    /// - Parameter pair: The text observation pair containing current and previous observations.
    /// - Returns: The absolute difference between the font sizes of the two observations.
    func fontSizeDifference(pair: OCRTextObservationPair) -> Double {
        let currentFontSize = fontSize(pair.current)
        let prevFontSize = fontSize(pair.previous)
        return abs(currentFontSize - prevFontSize)
    }

    /// Analyzes and compares font sizes between two text observations.
    ///
    /// - Parameters:
    ///   - pair: The text observation pair containing current and previous observations.
    ///   - fontSizeThreshold: Optional font size difference threshold; if `nil`, uses language-specific default.
    ///   - confidence: The detection confidence level affecting threshold strictness (default: `.medium`).
    /// - Returns: `true` if font sizes are considered different beyond the threshold, `false` if they are similar.
    func isDifferentFontSize(
        pair: OCRTextObservationPair,
        fontSizeThreshold: Double? = nil,
        confidence: OCRConfidenceLevel = .medium
    )
        -> Bool {
        let differentFontSize = fontSizeDifference(pair: pair)
        let baseThreshold = fontSizeThreshold ?? self.fontSizeThreshold(metrics.language)
        let finalThreshold = baseThreshold * confidence.multiplier
        let isDifferent = differentFontSize >= finalThreshold

        if isDifferent {
            print(
                "\nDifferent font detected (confidence: \(confidence)): diff = \(differentFontSize), threshold = \(finalThreshold) (base: \(baseThreshold) × \(confidence.multiplier))"
            )
            print("Pair: \(pair)\n")
        }
        return isDifferent
    }

    /// Returns the font size threshold based on the specified language.
    /// - Parameter language: The language to determine the threshold for.
    /// - Returns: The font size difference threshold for the given language.
    func fontSizeThreshold(_ language: Language) -> Double {
        languageManager.isChineseLanguage(language)
            ? OCRConstants.chineseDifferenceFontThreshold
            : OCRConstants.englishDifferenceFontThreshold
    }

    /// Checks if two observations are considered equal Chinese text.
    func isEqualChinesePair(_ pair: OCRTextObservationPair) -> Bool {
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
            print("\nEqual Chinese text detected: similarity = \(similarity.threeDecimalString)\n")
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
        let referenceObservation = comparedObservation ?? metrics.maxLineLengthObservation
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
    func isNewLine(pair: OCRTextObservationPair) -> Bool {
        let verticalGap = pair.verticalGap

        // Calculate adaptive threshold based on actual text heights
        let currentHeight = pair.current.boundingBox.size.height
        let previousHeight = pair.previous.boundingBox.size.height
        let smallerHeight = min(currentHeight, previousHeight)

        // Use a fraction of the smaller text height as threshold
        // This is more adaptive than using global minimum line height
        let adaptiveThreshold = smallerHeight

        // Also consider a minimum threshold to avoid being too strict with very small text
        let minimumThreshold = metrics.averageLineHeight

        // Use the larger of the two thresholds for better accuracy
        let threshold = max(adaptiveThreshold, minimumThreshold) * 0.4

        // If vertical gap is positive (spacing) or very small negative (slight overlap),
        // consider it as a new line.
        let isNewLine = verticalGap > 0 || abs(verticalGap) <= threshold

        if !isNewLine {
            print(
                "\nVertical gap: \(verticalGap.threeDecimalString), Threshold: \(threshold.threeDecimalString)"
            )
            print("Same line detected: \(pair)")
        }

        return isNewLine
    }

    // MARK: - Helper Methods

    /// Determines if two text observations have equal alignment (both minX and maxX coordinates).
    func isEqualAlignment(pair: OCRTextObservationPair, confidence: OCRConfidenceLevel = .medium) -> Bool {
        let isEqualMinX = isEqualX(pair: pair, comparison: .minX, confidence: confidence)
        let isEqualMaxX = isEqualX(pair: pair, comparison: .maxX, confidence: confidence)
        return isEqualMinX && isEqualMaxX
    }

    /// Calculates the horizontal difference between two text observations in character units.
    ///
    /// - Parameters:
    ///   - pair: The pair of text observations to compare.
    ///   - comparison: The X position comparison type (minX or maxX). Default is .minX.
    /// - Returns: The horizontal difference in character units (can be positive, negative, or zero).
    func characterDifferenceInXPosition(pair: OCRTextObservationPair, comparison: XComparisonType = .minX) -> Double {
        guard let ocrImage = metrics.ocrImage else {
            return 0.0
        }

        let currentX: CGFloat
        let previousX: CGFloat
        switch comparison {
        case .minX:
            currentX = pair.current.boundingBox.minX
            previousX = pair.previous.boundingBox.minX
        case .maxX:
            currentX = pair.current.boundingBox.maxX
            previousX = pair.previous.boundingBox.maxX
        }
        let dx = currentX - previousX

        // Vision framework provides normalized coordinates (0-1), multiply by image width to get logical distance
        let imageWidth = ocrImage.size.width
        let logicalDifference = imageWidth * dx

        // Convert logical difference to character units using average character width
        let characterDifference = logicalDifference / metrics.averageCharacterWidth

        return characterDifference
    }

    /// Determines if two text observations have equivalent horizontal positioning (X coordinates).
    ///
    /// - Parameters:
    ///   - pair: The pair of text observations to compare for X alignment.
    ///   - confidence: The detection confidence level affecting threshold strictness (default: `.medium`).
    /// - Returns: `true` if observations are horizontally aligned within tolerance, `false` otherwise.
    func isEqualX(
        pair: OCRTextObservationPair,
        comparison: XComparisonType = .minX,
        confidence: OCRConfidenceLevel = .medium
    )
        -> Bool {
        let characterDifference = characterDifferenceInXPosition(pair: pair, comparison: comparison)

        // Consider positions "equal" if difference is less than indentation threshold
        let baseTolerance = OCRConstants.indentationCharacterCount * 0.9
        let finalTolerance = baseTolerance / confidence.multiplier
        let isEqual = abs(characterDifference) < finalTolerance

        if !isEqual {
            print(
                "\nNot equalX text (confidence: \(confidence), comparison: \(comparison): difference = \(characterDifference.oneDecimalString) >= tolerance \(finalTolerance.oneDecimalString) (base: \(baseTolerance.oneDecimalString) × \(confidence.multiplier))"
            )
            print("Current: \(pair.current)\n")
        }

        return isEqual
    }

    /// Determines if `value1` is greater than `value2` by a given `ratio`.
    /// - Parameters:
    ///   - ratio: The minimum similarity ratio (0.0-1.0).
    ///   - value1: The first value to compare.
    ///   - value2: The second value to compare.
    /// - Returns: `true` if `value1` is greater than `value2` by the ratio, `false` otherwise.
    func isRatioGreaterThan(_ ratio: Double, value1: Double, value2: Double) -> Bool {
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
    func isEqualMaxX(pair: OCRTextObservationPair, ratio: Double = 0.95) -> Bool {
        let lineMaxX = pair.current.boundingBox.maxX
        let prevLineMaxX = pair.previous.boundingBox.maxX

        return isRatioGreaterThan(ratio, value1: lineMaxX, value2: prevLineMaxX)
    }

    // MARK: Private

    private let metrics: OCRMetrics
    private let lineMeasurer: OCRLineMeasurer
    private var languageManager = EZLanguageManager.shared()

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

    /// Calculates the font size of a text string given its width.
    /// - Parameters:
    ///   - text: The text string.
    ///   - textWidth: The width of the text.
    /// - Returns: The calculated font size.
    private func fontSize(_ text: String, width textWidth: Double) -> Double {
        let systemFontSize = NSFont.systemFontSize
        let font = NSFont.boldSystemFont(ofSize: systemFontSize)

        let width = text.size(withAttributes: [.font: font]).width

        /**
         systemFontSize / width = fontSize / textWidth
         fontSize = textWidth * (systemFontSize / width)
         */
        let fontSize = textWidth * (systemFontSize / width)

        return fontSize
    }
}
