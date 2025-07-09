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

    /// Check if text observation has indentation relative to the minimum X position
    ///
    /// Analyzes whether a text observation is indented by comparing its X position
    /// against the leftmost text observation in the document. This is crucial for
    /// detecting paragraph indentation, block quotes, and list structures.
    ///
    /// - Parameter observation: The text observation to analyze for indentation
    /// - Returns: true if the observation is indented, false if aligned with left margin
    func hasIndentation(_ observation: VNRecognizedTextObservation) -> Bool {
        guard let minXObservation = metrics.minXLineTextObservation else { return false }
        let textObservationPair = OCRTextObservationPair(
            current: observation, previous: minXObservation
        )
        let isEqualX = isEqualX(pair: textObservationPair)
        return !isEqualX
    }

    /// Determine if text observation represents a long line of text
    func isLongText(
        _ observation: VNRecognizedTextObservation,
        minimumRemainingCharacters: Double? = nil
    )
        -> Bool {
        lineMeasurer.isLongLine(
            observation,
            minimumRemainingCharacters: minimumRemainingCharacters
        )
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
        return isEqualLength && languageManager.isChineseLanguage(metrics.language)
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
                "Big line spacing detected, verticalGap: \(pair.verticalGap.threeDecimalString) > \(finalThreshold.threeDecimalString)"
            )
            print("Current: \(pair.current)")
        }

        return isBigSpacing
    }

    /// Analyze and compare font sizes between two text observations
    func isEqualFontSize(pair: OCRTextObservationPair) -> Bool {
        let currentFontSize = fontSize(pair.current)
        let prevFontSize = fontSize(pair.previous)

        let differentFontSize = abs(currentFontSize - prevFontSize)
        let isEqual = differentFontSize <= fontSizeThreshold(metrics.language)
        if !isEqual {
            print(
                "Not equal font: diff = \(differentFontSize) (\(prevFontSize), \(currentFontSize))"
            )
        }
        return isEqual
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

    /// Analyze and determine list merge decision
    ///
    /// Handles text merging decisions specifically for list-style content such as
    /// numbered lists, bullet points, and other structured list formats. This
    /// ensures proper formatting and structure preservation for list items.
    ///
    /// **List Detection Patterns:**
    /// - Numbered lists (1., 2., 3., etc.)
    /// - Bullet points (•, -, *, etc.)
    /// - Alphabetic lists (a., b., c., etc.)
    /// - Roman numerals (i., ii., iii., etc.)
    ///
    /// - Parameters:
    ///   - pair: Text observation pair containing current and previous observations
    ///   - isBigLineSpacing: Whether there is significant spacing between lines
    /// - Returns: Merge decision based on list structure requirements
    func determineListMerge(
        pair: OCRTextObservationPair,
        isBigLineSpacing: Bool
    )
        -> OCRMergeDecision {
        let isPrevList = pair.previous.firstText.isListTypeFirstWord
        let isList = pair.current.firstText.isListTypeFirstWord

        if isPrevList {
            if isList {
                return isBigLineSpacing ? .newParagraph : .lineBreak
            } else {
                // List ends, next is new paragraph if big spacing
                return isBigLineSpacing ? .newParagraph : .none
            }
        }
        if isList {
            // New list starts
            return isBigLineSpacing ? .newParagraph : .lineBreak
        }
        return .none
    }

    /// Determine if two text observations are on the same horizontal line
    ///
    /// Uses vertical gap analysis to determine if two text observations are positioned
    /// on the same horizontal line. This is more accurate than center-point comparison
    /// as it accounts for different text heights and overlapping scenarios.
    ///
    /// **Algorithm:**
    /// - Uses the verticalGap property from OCRTextObservationPair
    /// - Applies adaptive threshold based on actual text heights
    /// - Accounts for slight OCR positioning inaccuracies
    /// - Considers both positive gaps (spacing) and negative gaps (overlap)
    ///
    /// **Same Line Criteria:**
    /// - Very small positive gap (minimal spacing between words)
    /// - Small negative gap (slight overlap due to OCR inaccuracy)
    /// - Gap magnitude less than a fraction of the smaller text height
    ///
    /// - Parameter pair: Pair of text observations to compare
    /// - Returns: true if observations are on the same line, false otherwise
    func isSameLine(pair: OCRTextObservationPair) -> Bool {
        let verticalGap = pair.verticalGap

        // Calculate adaptive threshold based on actual text heights
        let currentHeight = pair.current.boundingBox.size.height
        let previousHeight = pair.previous.boundingBox.size.height
        let smallerHeight = min(currentHeight, previousHeight)

        // Use a fraction of the smaller text height as threshold
        // This is more adaptive than using global minimum line height
        let adaptiveThreshold = smallerHeight * 0.3 // 30% of smaller text height

        // Also consider a minimum threshold to avoid being too strict with very small text
        let minimumThreshold = metrics.minPositiveLineSpacing * 0.4 // 40% of minimum line height

        // Use the larger of the two thresholds for better accuracy
        let threshold = max(adaptiveThreshold, minimumThreshold)

        // Consider same line if gap is within threshold (allowing for slight overlap or minimal spacing)
        return abs(verticalGap) <= threshold
    }

    // MARK: - Helper Methods

    // Determine if two text observations have equivalent horizontal positioning (X coordinates)
    ///
    /// This precise spatial analysis method determines whether two text observations are aligned
    /// horizontally within acceptable tolerance thresholds. The analysis is crucial for detecting
    /// indentation patterns, paragraph boundaries, and structured content formatting.
    ///
    /// **Analysis Method:**
    /// - Calculates dynamic threshold based on average character width and indentation constants
    /// - Accounts for screen scaling factors for accurate measurements
    /// - Applies tolerance ranges for slight positioning variations
    /// - Uses relative positioning analysis for robust detection
    ///
    /// **Threshold Calculation:**
    /// - Based on `averageCharacterWidth * OCRConstants.indentationCharacterCount`
    /// - Incorporates screen scaling factor for high-resolution displays
    /// - Provides half-threshold tolerance for boundary cases
    /// - Adapts to document-specific character sizing
    ///
    /// **Use Cases:**
    /// - Paragraph indentation detection
    /// - List item alignment analysis
    /// - Block quote structure identification
    /// - Table column alignment recognition
    ///
    /// - Parameter pair: Pair of text observations to compare for X alignment
    /// - Returns: true if observations are horizontally aligned within tolerance, false otherwise
    func isEqualX(pair: OCRTextObservationPair) -> Bool {
        guard let ocrImage = metrics.ocrImage else {
            return false
        }

        // Calculate threshold based on average character width and indentation constant
        let threshold = metrics.averageCharacterWidth * OCRConstants.indentationCharacterCount

        let lineX = pair.current.boundingBox.origin.x
        let prevLineX = pair.previous.boundingBox.origin.x
        let dx = lineX - prevLineX

        let scaleFactor = NSScreen.main?.backingScaleFactor ?? 1.0
        let maxLength = ocrImage.size.width * metrics.maxLineLength / scaleFactor
        let difference = maxLength * dx

        // dx > 0, means current line may has indentation.
        if (dx > 0 && difference < threshold) || abs(difference) < (threshold / 2) {
            return true
        }

        print("Not equalX text: \(pair.current)")
        print("difference: \(difference), threshold: \(threshold)")

        return false
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
        let textWidth =
            observation.boundingBox.size.width * ocrImage.size.width / scaleFactor
        return fontSize(observation.firstText, width: textWidth)
    }

    private func fontSize(_ text: String, width textWidth: Double) -> Double {
        let systemFontSize = NSFont.systemFontSize
        let font = NSFont.boldSystemFont(ofSize: systemFontSize)

        let width = text.size(withAttributes: [.font: font]).width

        /**
         systemFontSize / width = x / textWidth
         x = textWidth * (systemFontSize / width)
         */
        let fontSize = textWidth * (systemFontSize / width)

        return fontSize
    }

    private func fontSizeThreshold(_ language: Language) -> Double {
        languageManager.isChineseLanguage(language)
            ? OCRConstants.chineseDifferenceFontThreshold
            : OCRConstants.englishDifferenceFontThreshold
    }
}
