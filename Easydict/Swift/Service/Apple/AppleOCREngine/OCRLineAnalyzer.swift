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
        let isEqualX = isEqualX(textObservationPair)
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
    func isEqualChineseText(_ pair: OCRTextObservationPair) -> Bool {
        let isEqualLength = isEqualCharacterLength(pair)
        return isEqualLength && languageManager.isChineseLanguage(metrics.language)
    }

    /// Analyze if there is significant line spacing between two text observations
    func isBigLineSpacing(
        _ pair: OCRTextObservationPair,
        greaterThanLineHeightRatio: Double
    )
        -> Bool {
        let prevBoundingBox = pair.previous.boundingBox
        let boundingBox = pair.current.boundingBox
        let lineHeight = boundingBox.size.height

        // !!!: deltaY may be < 0
        let deltaY = prevBoundingBox.origin.y - (boundingBox.origin.y + lineHeight)
        let lineHeightRatio = deltaY / lineHeight
        let averageLineHeightRatio = deltaY / metrics.averageLineHeight

        let isPrevEndPunctuationChar = pair.previous.firstText.hasEndPunctuationSuffix

        // Since line spacing sometimes is too small and imprecise, we do not use it.
        if lineHeightRatio > 1.0 || averageLineHeightRatio > greaterThanLineHeightRatio {
            return true
        }

        if lineHeightRatio > 0.6,
           !lineMeasurer.isLongLine(pair.previous)
           || isPrevEndPunctuationChar
           || pair.previous === metrics.maxLongLineTextObservation {
            return true
        }

        let isFirstLetterUpperCase = pair.current.firstText.isFirstLetterUpperCase

        // For English text
        if languageManager.isEnglishLanguage(metrics.language), isFirstLetterUpperCase {
            if lineHeightRatio > 0.85 {
                return true
            } else {
                if lineHeightRatio > 0.6, isPrevEndPunctuationChar {
                    return true
                }
            }
        }

        return false
    }

    /// Analyze and compare font sizes between two text observations
    func isEqualFontSize(_ pair: OCRTextObservationPair) -> Bool {
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
        _ pair: OCRTextObservationPair,
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
        _ pair: OCRTextObservationPair,
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

    /// Determine if current observation represents a new line relative to previous observation
    ///
    /// Analyzes spatial relationships between two text observations to determine
    /// if they represent text on different lines or the same line. This is fundamental
    /// for proper text flow reconstruction from OCR results.
    ///
    /// **Analysis Criteria:**
    /// - Y coordinate differences (vertical separation)
    /// - X coordinate gaps (horizontal separation)
    /// - Bounding box overlaps and relationships
    /// - Minimum line height thresholds
    ///
    /// - Parameter textObservationPair: Pair of text observations to analyze
    /// - Returns: true if the current observation is on a new line, false if same line
    func isNewLineRelativeToPrevious(
        _ textObservationPair: OCRTextObservationPair
    )
        -> Bool {
        let currentBoundingBox = textObservationPair.current.boundingBox
        let previousBoundingBox = textObservationPair.previous.boundingBox

        let deltaY =
            previousBoundingBox.origin.y
                - (currentBoundingBox.origin.y + currentBoundingBox.size.height)
        let deltaX =
            currentBoundingBox.origin.x
                - (previousBoundingBox.origin.x + previousBoundingBox.size.width)

        // Check Y coordinate for new line
        if deltaY > 0 {
            return true
        } else if abs(deltaY) < metrics.minLineHeight / 2 {
            // Since OCR may have slight overlaps, consider it a new line if deltaY is small.
            return true
        }

        // Check X coordinate gap for line detection
        return deltaX > 0.07
    }

    /// Determine if two text observations are on the same horizontal line
    ///
    /// Performs precise same-line detection by comparing the vertical center positions
    /// of text bounding boxes against a calculated threshold. This is essential for
    /// proper text ordering and spacing decisions.
    ///
    /// **Algorithm:**
    /// - Calculates center Y coordinates for both observations
    /// - Compares vertical distance against dynamic threshold
    /// - Accounts for Vision framework's coordinate system (origin at bottom-left)
    /// - Uses minimum line height-based threshold for accuracy
    ///
    /// - Parameter pair: Pair of text observations to compare
    /// - Returns: true if observations are on the same line, false otherwise
    func isSameLine(_ pair: OCRTextObservationPair) -> Bool {
        // Box origin at the image's lower-left corner.
        let currentBoundingBox = pair.current.boundingBox
        let previousBoundingBox = pair.previous.boundingBox

        // Calculate Y coordinate difference (taking into account coordinate system)
        let currentCenterY = currentBoundingBox.origin.y - currentBoundingBox.size.height / 2
        let previousCenterY = previousBoundingBox.origin.y - previousBoundingBox.size.height / 2
        let deltaY = abs(currentCenterY - previousCenterY)

        return deltaY <= metrics.sameLineThreshold
    }

    // MARK: Private

    private let metrics: OCRMetrics
    private let lineMeasurer: OCRLineMeasurer
    private var languageManager = EZLanguageManager.shared()

    // MARK: - Helper Methods

    private func isEqualX(_ pair: OCRTextObservationPair) -> Bool {
        // Calculate threshold based on average character width and indentation constant
        let threshold = metrics.averageCharacterWidth * OCRConstants.indentationCharacterCount

        let lineX = pair.current.boundingBox.origin.x
        let prevLineX = pair.previous.boundingBox.origin.x
        let dx = lineX - prevLineX

        let scaleFactor = NSScreen.main?.backingScaleFactor ?? 1.0
        let maxLength = metrics.ocrImage.size.width * metrics.maxLineLength / scaleFactor
        let difference = maxLength * dx

        // dx > 0, means current line may has indentation.
        if (dx > 0 && difference < threshold) || abs(difference) < (threshold / 2) {
            return true
        }

        print("Not equalX text: \(pair.current)")
        print("difference: \(difference), threshold: \(threshold)")

        return false
    }

    private func isEqualCharacterLength(_ pair: OCRTextObservationPair) -> Bool {
        let isEqual = isEqualText(pair)

        let currentText = pair.current.firstText
        let previousText = pair.previous.firstText

        let isCurrentEndPunctuationChar = currentText.hasEndPunctuationSuffix
        let isPreviousEndPunctuationChar = previousText.hasEndPunctuationSuffix

        let isEqualLength = currentText.count == previousText.count
        let isEqualEndSuffix = isCurrentEndPunctuationChar && isPreviousEndPunctuationChar

        return isEqual && isEqualLength && isEqualEndSuffix
    }

    private func isEqualText(_ pair: OCRTextObservationPair) -> Bool {
        let isEqualX = isEqualX(pair)

        let lineMaxX = pair.current.boundingBox.maxX
        let prevLineMaxX = pair.previous.boundingBox.maxX

        let ratio = 0.95
        let isEqualLineMaxX = isRatioGreaterThan(ratio, value1: lineMaxX, value2: prevLineMaxX)

        return isEqualX && isEqualLineMaxX
    }

    private func isRatioGreaterThan(_ ratio: Double, value1: Double, value2: Double) -> Bool {
        let minValue = min(value1, value2)
        let maxValue = max(value1, value2)
        return (minValue / maxValue) > ratio
    }

    private func fontSize(_ observation: VNRecognizedTextObservation) -> Double {
        let scaleFactor = NSScreen.main?.backingScaleFactor ?? 1.0
        let textWidth =
            observation.boundingBox.size.width * metrics.ocrImage.size.width / scaleFactor
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
