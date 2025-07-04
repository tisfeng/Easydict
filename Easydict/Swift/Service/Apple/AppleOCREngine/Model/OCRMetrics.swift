//
//  OCRMetrics.swift
//  Easydict
//
//  Created by tisfeng on 2025/6/26.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation
import Vision

// MARK: - OCRMetrics

/// Comprehensive statistical metrics and context data repository for OCR text processing
///
/// This central metrics collection serves as the authoritative data source for all OCR
/// text analysis and processing decisions. It maintains document-wide statistics,
/// spatial measurements, and contextual information that enable intelligent text
/// merging, formatting, and layout analysis.
///
/// **Primary Responsibilities:**
/// - **Document Statistics**: Line heights, spacings, character counts, and text patterns
/// - **Spatial Analysis**: Position data, indentation patterns, and layout measurements
/// - **Reference Observations**: Key text observations used for comparative analysis
/// - **Processing Context**: Language settings, source images, and configuration data
/// - **Threshold Calculations**: Dynamic thresholds based on document characteristics
///
/// **Key Metric Categories:**
/// 1. **Line Measurements**: Heights, spacings, and positioning data
/// 2. **Text Analysis**: Character counts, word patterns, and language-specific metrics
/// 3. **Reference Points**: Longest lines, minimum positions, and boundary observations
/// 4. **Calculated Thresholds**: Dynamic values for same-line detection and formatting decisions
///
/// **Usage Pattern:**
/// ```swift
/// let metrics = OCRMetrics()
/// metrics.language = .english
/// metrics.collectLineLayoutMetrics(observation, index: 0, observations: all, lineSpacingCount: &count)
/// let isLongLine = metrics.averageCharacterWidth > 0 && lineMeasurer.isLongLine(observation)
/// ```
///
/// Essential for maintaining consistency and accuracy across the entire OCR processing pipeline.
class OCRMetrics {
    // MARK: Lifecycle

    /// Initialize OCR metrics with optional language specification
    ///
    /// Creates a new metrics instance with all values reset to initial state.
    /// If a language is provided, it will be set immediately for language-specific processing.
    ///
    /// - Parameter language: Target language for OCR processing (defaults to .auto)
    convenience init(language: Language) {
        self.init()
        self.language = language
    }

    // MARK: Internal

    // MARK: - Processing Context Data

    /// Source image for OCR processing
    ///
    /// The original image containing the text to be processed. Used for spatial
    /// calculations, character width measurements, and layout analysis.
    var ocrImage: NSImage = .init()

    /// Target language for OCR recognition and text processing
    ///
    /// Influences text analysis algorithms, formatting rules, and language-specific
    /// processing decisions throughout the OCR pipeline.
    var language: Language = .auto

    /// Complete array of text observations from Vision framework
    ///
    /// All recognized text observations in their original order, providing the
    /// foundation for statistical analysis and spatial relationship calculations.
    var textObservations: [VNRecognizedTextObservation] = []

    // MARK: - Line Height and Spacing Metrics

    /// Minimum observed line height across all text observations
    ///
    /// Used for establishing baselines for same-line detection and vertical
    /// relationship analysis. Critical for accurate line grouping.
    var minLineHeight: Double = .greatestFiniteMagnitude

    /// Cumulative total of all line heights for average calculation
    ///
    /// Aggregated during metrics collection to compute document-wide average
    /// line height for consistent formatting decisions.
    var totalLineHeight: Double = 0

    /// Calculated average line height across the document
    ///
    /// Primary metric for line spacing analysis and vertical relationship
    /// determination. Updated after all observations are processed.
    var averageLineHeight: Double = 0

    /// Minimum observed spacing between adjacent text lines
    ///
    /// Used for detecting tight line spacing and understanding document
    /// layout density. Important for distinguishing normal text from lists.
    var minLineSpacing: Double = .greatestFiniteMagnitude

    /// Minimum positive (non-zero) line spacing value
    ///
    /// Excludes overlapping or touching lines to establish realistic
    /// baseline spacing for the document layout.
    var minPositiveLineSpacing: Double = .greatestFiniteMagnitude

    /// Cumulative total of all line spacings for average calculation
    ///
    /// Aggregated to compute document-wide average line spacing patterns
    /// for consistent vertical formatting decisions.
    var totalLineSpacing: Double = 0

    /// Calculated average spacing between text lines
    ///
    /// Key metric for determining significant line gaps and paragraph
    /// boundaries throughout the document.
    var averageLineSpacing: Double = 0

    // MARK: - Horizontal Position and Length Metrics

    /// Leftmost X coordinate among all text observations
    ///
    /// Establishes the document's left margin for indentation analysis
    /// and relative positioning calculations.
    var minX: Double = .greatestFiniteMagnitude

    /// Maximum observed line length (rightmost extent)
    ///
    /// Defines the document's effective width and serves as reference
    /// for relative line length calculations and "long line" detection.
    var maxLineLength: Double = 0

    /// Minimum observed line length
    ///
    /// Used for understanding the range of line lengths and detecting
    /// unusually short lines that may indicate special formatting.
    var minLineLength: Double = .greatestFiniteMagnitude

    // MARK: - Reference Text Observations

    /// Text observation with the maximum line length (extends furthest right)
    ///
    /// Used as reference point for character width calculations and relative
    /// line length analysis. Critical for "long line" detection algorithms.
    var maxLongLineTextObservation: VNRecognizedTextObservation?

    /// Text observation positioned at the minimum X coordinate (leftmost)
    ///
    /// Serves as the document's left margin reference for indentation
    /// analysis and relative positioning calculations.
    var minXLineTextObservation: VNRecognizedTextObservation?

    /// Text observation containing the maximum number of characters
    ///
    /// Used for character width calculations and text density analysis.
    /// Provides the most reliable data for character spacing measurements.
    var maxCharacterCountLineTextObservation: VNRecognizedTextObservation?

    // MARK: - Content Analysis Metrics

    /// Whether the document content is identified as poetry
    ///
    /// Influences text merging decisions and formatting preservation.
    /// Set by the poetry detection algorithm based on line patterns.
    var isPoetry: Bool = false

    /// Average number of characters per line across the document
    ///
    /// Key metric for understanding text density and supporting poetry
    /// detection, language analysis, and formatting decisions.
    var charCountPerLine: Double = 0

    /// Total character count across all text observations
    ///
    /// Used for document-wide statistics and density calculations.
    /// Supports various text analysis and quality metrics.
    var totalCharCount: Int = 0

    /// Count of punctuation marks found in the text
    ///
    /// Supports language detection, sentence boundary identification,
    /// and text formatting analysis throughout the document.
    var punctuationMarkCount: Int = 0

    /// Calculated average width of characters in the document
    ///
    /// Critical for spatial analysis, character counting, and determining
    /// how much text can fit in remaining line space. Used extensively
    /// for "long line" detection and text merging decisions.
    var averageCharacterWidth: Double = 0.0

    /// Maximum word length observed (tracked for space-separated languages)
    ///
    /// Used for understanding text patterns and supporting language-specific
    /// processing decisions, particularly for English and similar languages.
    var maxWordLength: Int = 0

    // MARK: - Calculated Thresholds

    /// Dynamic threshold for same-line detection based on minimum line height
    ///
    /// Calculated as 80% of the minimum line height to provide robust
    /// same-line detection that adapts to the document's text characteristics.
    var sameLineThreshold: Double { minLineHeight * 0.8 }

    /// Reset all metrics data to initial values for new OCR processing session
    ///
    /// Clears all accumulated metrics and resets the instance to a clean state,
    /// ready for processing a new document. This ensures no data contamination
    /// between different OCR processing sessions.
    ///
    /// **Reset Categories:**
    /// - Processing context (image, language, observations)
    /// - Line measurements (heights, spacings, positions)
    /// - Reference observations (longest lines, positions, character counts)
    /// - Content analysis (poetry flags, character metrics, punctuation counts)
    /// - Calculated metrics (averages, character widths, word lengths)
    func resetMetrics() {
        // Reset context data
        ocrImage = NSImage()
        language = .auto
        textObservations = []

        // Reset metrics data
        minLineHeight = .greatestFiniteMagnitude
        totalLineHeight = 0
        averageLineHeight = 0

        minLineSpacing = .greatestFiniteMagnitude
        minPositiveLineSpacing = .greatestFiniteMagnitude
        totalLineSpacing = 0
        averageLineSpacing = 0

        minX = .greatestFiniteMagnitude
        maxLineLength = 0
        minLineLength = .greatestFiniteMagnitude

        maxLongLineTextObservation = nil
        minXLineTextObservation = nil
        maxCharacterCountLineTextObservation = nil

        isPoetry = false
        charCountPerLine = 0
        totalCharCount = 0
        punctuationMarkCount = 0
        averageCharacterWidth = 0.0
        maxWordLength = 0
    }

    /// Collect line spacing, height, and positioning metrics
    func collectLineLayoutMetrics(
        _ textObservation: VNRecognizedTextObservation,
        index: Int,
        observations: [VNRecognizedTextObservation],
        lineSpacingCount: inout Int
    ) {
        let boundingBox = textObservation.boundingBox
        let lineHeight = boundingBox.size.height
        totalLineHeight += lineHeight

        if lineHeight < minLineHeight {
            minLineHeight = lineHeight
        }

        // Calculate line spacing
        if index > 0 {
            let prevObservation = observations[index - 1]
            let prevBoundingBox = prevObservation.boundingBox

            let deltaY = prevBoundingBox.origin.y - (boundingBox.origin.y + boundingBox.size.height)

            if deltaY > 0, deltaY < averageLineHeight * OCRConstants.paragraphLineHeightRatio {
                totalLineSpacing += deltaY
                lineSpacingCount += 1
            }

            if deltaY < minLineSpacing {
                minLineSpacing = deltaY
            }

            if deltaY > 0, deltaY < minPositiveLineSpacing {
                minPositiveLineSpacing = deltaY
            }
        }

        // Track x coordinates and line lengths
        let x = boundingBox.origin.x
        if x < minX {
            minX = x
            minXLineTextObservation = textObservation
        }

        let lengthOfLine = boundingBox.size.width
        if lengthOfLine > maxLineLength {
            maxLineLength = lengthOfLine
            maxLongLineTextObservation = textObservation
        }

        // Track maximum character count line
        let currentCharCount = textObservation.firstText.count
        if let maxCharObservation = maxCharacterCountLineTextObservation {
            if currentCharCount > maxCharObservation.firstText.count {
                maxCharacterCountLineTextObservation = textObservation
            }
        } else {
            maxCharacterCountLineTextObservation = textObservation
        }

        if lengthOfLine < minLineLength {
            minLineLength = lengthOfLine
        }
    }

    /// Calculate single character width metric for text observation
    func calculateCharacterWidthMetric(
        _ textObservation: VNRecognizedTextObservation,
        ocrImage: NSImage
    )
        -> Double {
        let scaleFactor = NSScreen.main?.backingScaleFactor ?? 1.0
        let textWidth = textObservation.boundingBox.size.width * ocrImage.size.width / scaleFactor
        return textWidth / textObservation.firstText.count.double
    }

    /// Update maximum word length for space-separated languages
    /// This method should only be called for languages that use spaces between words
    /// - Parameter textObservation: The text observation to analyze
    func updateMaxWordLength(_ textObservation: VNRecognizedTextObservation) {
        let languageManager = EZLanguageManager.shared()

        // Only track word length for languages that use spaces between words
        guard languageManager.isLanguageWordsNeedSpace(language) else {
            return
        }

        let words = textObservation.firstText.wordComponents

        for word in words where word.count > maxWordLength {
            maxWordLength = word.count
        }
    }
}
