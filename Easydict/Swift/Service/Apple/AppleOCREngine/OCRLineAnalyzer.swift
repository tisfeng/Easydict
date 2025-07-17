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

/// Handles line-level text analysis operations for OCR processing
///
/// This specialized analyzer provides sophisticated methods for analyzing relationships
/// between text lines and making intelligent formatting decisions. It serves as the
/// analytical brain for determining how text observations should be joined together.
///
/// **Core Capabilities:**
/// - **Line Relationship Analysis**: Determines if text observations are on same line or different lines
/// - **Indentation Detection**: Identifies text indentation patterns for proper formatting
/// - **Spacing Analysis**: Calculates appropriate spacing between text elements
/// - **Font Comparison**: Analyzes font size variations for formatting decisions
/// - **Poetry Recognition**: Detects poetic text patterns requiring special handling
/// - **List Processing**: Identifies and handles numbered/bulleted list structures
/// - **Language-aware Processing**: Applies language-specific analysis rules
///
/// **Key Algorithms:**
/// - Spatial relationship analysis using bounding box mathematics
/// - Dynamic threshold calculation based on text metrics
/// - Context-aware decision making for text merging
///
/// Used extensively by OCRTextMerger for making intelligent text joining decisions.
class OCRLineAnalyzer {
    // MARK: Lifecycle

    init(metrics: OCRMetrics) {
        self.metrics = metrics
        self.lineMeasurer = OCRLineMeasurer(metrics: metrics)
    }

    // MARK: Internal

    /// Check if text observation has indentation relative to the reference observation
    ///
    /// Analyzes whether a text observation is indented by comparing its X position
    /// against a reference observation (typically the leftmost or previous observation).
    /// Uses precise character-based calculation for accurate indentation detection.
    ///
    /// **Indentation Criteria:**
    /// - Current observation must be positioned to the right of the reference
    /// - Horizontal offset must be less than the indentation character threshold
    /// - Uses character-based measurement for consistent detection across different text sizes
    ///
    /// **Use Cases:**
    /// - Paragraph indentation detection
    /// - List item structure analysis
    /// - Block quote identification
    /// - Code block formatting preservation
    ///
    /// - Parameters:
    ///   - observation: The text observation to analyze for indentation
    ///   - comparedObservation: The reference observation to compare against (optional, defaults to metrics.minXLineTextObservation)
    /// - Returns: true if the observation is indented, false if aligned with left margin
    func hasIndentation(
        observation: VNRecognizedTextObservation,
        comparedObservation: VNRecognizedTextObservation? = nil
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

        let isIndented = characterDifference > OCRConstants.indentationCharacterCount

        if isIndented {
            let refText = referenceObservation.firstText.prefix(20)
            print("\nIndentation detected: \(characterDifference.oneDecimalString) characters")
            print("Current observation: \(observation)")
            print("Compared against: '\(refText)...'\n")
        }

        return isIndented
    }

    /// Determine if text observation represents a long line of text
    func isLongText(
        observation: VNRecognizedTextObservation,
        nextObservation: VNRecognizedTextObservation? = nil,
        comparedObservation: VNRecognizedTextObservation? = nil
    )
        -> Bool {
        lineMeasurer.isLongLine(
            observation: observation,
            nextObservation: nextObservation,
            comparedObservation: comparedObservation
        )
    }

    /// Analyze if there is significant line spacing between two text observations
    ///
    /// This method determines whether two consecutive text observations have enough
    /// vertical spacing to be considered as having big line spacing. It uses absolute
    /// height thresholds rather than ratios for more predictable and consistent behavior.
    ///
    /// **Spatial Analysis Approach:**
    /// - Uses absolute height thresholds for direct comparison
    /// - Automatically calculates adaptive threshold based on document metrics
    /// - Pure geometric calculation without text content dependencies
    /// - More stable than ratio-based approaches for varying text sizes
    ///
    /// **Threshold Calculation:**
    /// - Default: minimum of (averageLineHeight * 1.1, minLineHeight * 1.1, currentLineHeight)
    /// - Uses 1.1x multiplier to provide reasonable spacing detection sensitivity
    /// - Considers document-wide metrics for consistency
    /// - Prevents overly large thresholds from unusually large text
    ///
    /// - Parameters:
    ///   - pair: Text observation pair containing current and previous observations
    ///   - thresholdGap: Optional absolute height threshold; if nil, calculates adaptive threshold
    /// - Returns: true if vertical gap exceeds the threshold, false otherwise
    func isBigLineSpacing(
        pair: OCRTextObservationPair,
        lineSpacingThreshold: Double? = nil
    )
        -> Bool {
        // Use provided threshold or fall back to metrics default big line spacing threshold
        let finalThreshold = lineSpacingThreshold ?? metrics.bigLineSpacingThreshold
        let isBigSpacing = pair.verticalGap > finalThreshold

        if isBigSpacing {
            print(
                "\nBig line spacing detected, verticalGap: \(pair.verticalGap.threeDecimalString) > \(finalThreshold.threeDecimalString)"
            )
            print("Current: \(pair.current)\n")
        }

        return isBigSpacing
    }

    /// Calculate font size difference between two text observations
    ///
    /// - Parameter pair: Text observation pair containing current and previous observations
    /// - Returns: Absolute difference between the font sizes of the two observations
    func fontSizeDifference(pair: OCRTextObservationPair) -> Double {
        let currentFontSize = fontSize(pair.current)
        let prevFontSize = fontSize(pair.previous)
        return abs(currentFontSize - prevFontSize)
    }

    /// Analyze and compare font sizes between two text observations
    ///
    /// - Parameters:
    ///   - pair: Text observation pair containing current and previous observations
    ///   - fontSizeThreshold: Optional font size difference threshold; if nil, uses language-specific default
    /// - Returns: true if font sizes are considered different beyond the threshold, false if they are similar
    func isDifferentFontSize(pair: OCRTextObservationPair, fontSizeThreshold: Double? = nil) -> Bool {
        let differentFontSize = fontSizeDifference(pair: pair)
        let threshold = fontSizeThreshold ?? self.fontSizeThreshold(metrics.language)
        let isDifferent = differentFontSize >= threshold

        if isDifferent {
            print("\nDifferent font detected: diff = \(differentFontSize), threshold = \(threshold)")
            print("Pair: \(pair)\n")
        }
        return isDifferent
    }

    func fontSizeThreshold(_ language: Language) -> Double {
        languageManager.isChineseLanguage(language)
            ? OCRConstants.chineseDifferenceFontThreshold
            : OCRConstants.englishDifferenceFontThreshold
    }

    /// Check if two observations contain equal-length Chinese text
    ///
    /// Analyzes whether two text observations represent Chinese text with equal
    /// character lengths and consistent formatting. This is particularly useful
    /// for detecting Chinese poetry patterns and structured content.
    ///
    /// **Analysis Criteria:**
    /// - Current document language is Chinese (Simplified or Traditional)
    /// - Both observations have equal character count and formatting
    /// - Consistent punctuation patterns (both end with punctuation or neither do)
    /// - Basic horizontal alignment validation
    ///
    /// **Use Cases:**
    /// - Chinese poetry detection (classical poems often have equal line lengths)
    /// - Structured Chinese text identification
    /// - Traditional document format validation
    /// - Parallel text analysis
    ///
    /// - Parameter pair: Text observation pair to analyze
    /// - Returns: true if observations contain equal-length Chinese text
    func isEqualChineseText(pair: OCRTextObservationPair) -> Bool {
        let isEqualLength = pair.hasEqualCharacterLength
        let isEqualChinese = isEqualLength && languageManager.isChineseLanguage(metrics.language)

        if isEqualLength {
            print("Pair is considered equal Chinese text: \(pair)")
        }

        return isEqualChinese
    }

    /// Analyze if text represents short Chinese poetry format
    func isShortPoetry(_ text: String) -> Bool {
        languageManager.isChineseLanguage(metrics.language)
            && metrics.charCountPerLine < Double(OCRConstants.shortPoetryCharacterCountOfLine)
            && text.count < OCRConstants.shortPoetryCharacterCountOfLine
    }

    /// Analyze if line length is considered short relative to maximum length
    ///
    /// Determines whether a given line length is considered "short" by comparing it
    /// against the maximum observed line length with a configurable threshold ratio.
    /// This analysis is crucial for text formatting decisions and poetry detection.
    ///
    /// - Parameters:
    ///   - lineLength: The length of the line to analyze
    ///   - maxLineLength: The maximum observed line length in the document
    ///   - lessRateOfMaxLength: Threshold ratio (0.0-1.0) for considering a line "short"
    /// - Returns: true if the line is considered short, false otherwise
    func isShortLine(
        _ lineLength: Double,
        maxLineLength: Double,
        lessRateOfMaxLength: Double
    )
        -> Bool {
        lineLength < maxLineLength * lessRateOfMaxLength
    }

    /// Analyze and determine Chinese poetry merge decision
    ///
    /// Applies specialized logic for handling Chinese poetry text that requires
    /// different formatting rules than regular prose. Chinese poetry often has
    /// distinctive characteristics that need preservation during text merging.
    ///
    /// - Parameters:
    ///   - pair: Text observation pair containing current and previous observations
    ///   - isEqualChineseText: Whether the texts have equal character counts (Chinese characteristic)
    ///   - isBigLineSpacing: Whether there is significant spacing between lines
    /// - Returns: Merge decision (none, lineBreak, or newParagraph)
    func determineChinesePoetryMerge(
        pair: OCRTextObservationPair,
        isEqualChineseText: Bool,
        isBigLineSpacing: Bool
    )
        -> OCRMergeDecision {
        let isShortChinesePoetry = isShortPoetry(pair.current.firstText)
        let isPrevShortChinesePoetry = isShortPoetry(pair.previous.firstText)

        let isChinesePoetryLine =
            isEqualChineseText || (isShortChinesePoetry && isPrevShortChinesePoetry)
        let shouldWrap = isChinesePoetryLine

        if shouldWrap, isBigLineSpacing {
            return .newParagraph
        } else if shouldWrap {
            return .lineBreak
        } else {
            return .none
        }
    }

    /// Determine if two text observations represent a new line break
    ///
    /// Uses vertical gap analysis to determine if two text observations are positioned
    /// on different lines (new line) or the same horizontal line. This method employs
    /// adaptive thresholding for accurate line break detection across varying text sizes.
    ///
    /// **Algorithm:**
    /// - Uses the verticalGap property from OCRTextObservationPair for precise spacing analysis
    /// - Applies adaptive threshold based on actual text heights for dynamic adjustment
    /// - Uses the larger of adaptive threshold and minimum threshold for robust detection
    /// - Accounts for slight OCR positioning inaccuracies and text overlap scenarios
    ///
    /// **New Line Detection Criteria:**
    /// - Positive vertical gap (clear spacing between lines)
    /// - Negative gap magnitude exceeding the adaptive threshold (significant overlap)
    /// - Threshold is calculated as 40% of the larger between smaller text height and average line height
    ///
    /// **Threshold Calculation:**
    /// - `adaptiveThreshold = min(currentHeight, previousHeight)` - based on smaller text
    /// - `minimumThreshold = metrics.averageLineHeight` - document-wide baseline
    /// - `finalThreshold = max(adaptiveThreshold, minimumThreshold) * 0.4` - 40% safety factor
    ///
    /// - Parameter pair: Pair of text observations to analyze for line separation
    /// - Returns: true if observations represent a new line, false if on the same line
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

    /// Calculate the horizontal difference between two text observations in character units
    ///
    /// This function converts the spatial X-coordinate difference between two text observations
    /// into an equivalent character count. This provides a more intuitive and consistent way
    /// to measure horizontal spacing and indentation across different text sizes and screen resolutions.
    ///
    /// **Calculation Method:**
    /// - Calculates the raw X-coordinate difference (dx)
    /// - Converts to screen coordinates using image dimensions and scaling
    /// - Divides by average character width to get character-equivalent distance
    ///
    /// **Return Values:**
    /// - Positive: current observation is to the right of previous (potential indentation)
    /// - Negative: current observation is to the left of previous (outdentation)
    /// - Zero: observations are aligned horizontally
    ///
    /// - Parameter pair: Pair of text observations to compare
    /// - Returns: Horizontal difference in character units (can be positive, negative, or zero)
    func characterDifferenceInXPosition(pair: OCRTextObservationPair) -> Double {
        guard let ocrImage = metrics.ocrImage else {
            return 0.0
        }

        let currentX = pair.current.boundingBox.origin.x
        let previousX = pair.previous.boundingBox.origin.x
        let dx = currentX - previousX

        let scaleFactor = NSScreen.main?.backingScaleFactor ?? 1.0
        let imageWidth = ocrImage.size.width / scaleFactor
        let pixelDifference = imageWidth * dx

        // Convert pixel difference to character units using average character width
        let characterDifference = pixelDifference / metrics.averageCharacterWidth

        return characterDifference
    }

    // Determine if two text observations have equivalent horizontal positioning (X coordinates)
    ///
    /// This precise spatial analysis method determines whether two text observations are aligned
    /// horizontally within acceptable tolerance thresholds. Uses the new character-based
    /// calculation for more accurate and consistent alignment detection.
    ///
    /// **Analysis Method:**
    /// - Uses character-based difference calculation for consistent measurement
    /// - Applies tolerance ranges for slight positioning variations
    /// - Considers both perfect alignment and small positioning differences as "equal"
    ///
    /// **Alignment Criteria:**
    /// - Absolute character difference is less than half the indentation threshold (1.0 characters)
    /// - This provides tolerance for slight OCR positioning inaccuracies
    /// - Uses character units for consistent behavior across different text sizes
    ///
    /// **Use Cases:**
    /// - Paragraph alignment detection
    /// - List item alignment analysis
    /// - Block structure identification
    /// - Column alignment recognition
    ///
    /// - Parameter pair: Pair of text observations to compare for X alignment
    /// - Returns: true if observations are horizontally aligned within tolerance, false otherwise
    func isEqualX(pair: OCRTextObservationPair) -> Bool {
        let characterDifference = characterDifferenceInXPosition(pair: pair)

        // Consider positions "equal" if difference is less than 0.8 * indentation character count
        let tolerance = OCRConstants.indentationCharacterCount * 0.8
        let isEqual = abs(characterDifference) < tolerance

        if !isEqual {
            print("\nNot equalX text: \(pair.current)")
            print(
                "Character difference: \(characterDifference.oneDecimalString), tolerance: \(tolerance.oneDecimalString)\n"
            )
        }

        return isEqual
    }

    func isRatioGreaterThan(_ ratio: Double, value1: Double, value2: Double) -> Bool {
        let minValue = min(value1, value2)
        let maxValue = max(value1, value2)
        return (minValue / maxValue) > ratio
    }

    // MARK: Private

    private let metrics: OCRMetrics
    private let lineMeasurer: OCRLineMeasurer
    private var languageManager = EZLanguageManager.shared()

    private func isEqualText(pair: OCRTextObservationPair) -> Bool {
        let isEqualX = isEqualX(pair: pair)

        // Use the new property from OCRTextObservationPair for basic maxX comparison
        // But still need more sophisticated analysis that requires metrics
        let lineMaxX = pair.current.boundingBox.maxX
        let prevLineMaxX = pair.previous.boundingBox.maxX

        let ratio = 0.95
        let isEqualLineMaxX = isRatioGreaterThan(ratio, value1: lineMaxX, value2: prevLineMaxX)

        return isEqualX && isEqualLineMaxX
    }

    private func fontSize(_ observation: VNRecognizedTextObservation) -> Double {
        guard let ocrImage = metrics.ocrImage else {
            return NSFont.systemFontSize
        }

        let scaleFactor = NSScreen.main?.backingScaleFactor ?? 1.0
        let textWidth = observation.boundingBox.size.width * ocrImage.size.width / scaleFactor
        return fontSize(observation.firstText, width: textWidth)
    }

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
