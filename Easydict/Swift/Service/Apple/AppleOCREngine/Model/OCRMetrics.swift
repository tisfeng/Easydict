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
/// let metrics = OCRMetrics(language: .english)
/// // OR
/// let metrics = OCRMetrics(ocrImage: image, language: .english, textObservations: observations)
/// let isLongLine = metrics.averageCharacterWidth > 0 && lineMeasurer.isLongLine(observation)
/// ```
///
/// Essential for maintaining consistency and accuracy across the entire OCR processing pipeline.
class OCRMetrics {
    // MARK: Lifecycle

    /// Initialize OCR metrics with optional context data
    ///
    /// Creates a new metrics instance with configurable initial state.
    /// This convenience initializer can handle various initialization scenarios
    /// from simple language setup to full OCR processing context.
    ///
    /// - Parameters:
    ///   - ocrImage: Source image containing text to be processed (optional)
    ///   - language: Target language for OCR processing (defaults to .auto)
    ///   - textObservations: Pre-existing text observations to process
    convenience init(
        ocrImage: NSImage? = nil,
        language: Language = .auto,
        textObservations: [VNRecognizedTextObservation] = []
    ) {
        self.init()
        self.language = language

        if let ocrImage = ocrImage {
            self.ocrImage = ocrImage
        }

        // If no text observations provided, return early
        guard !textObservations.isEmpty else {
            return
        }

        self.textObservations = textObservations

        // If we have both image and observations, perform full setup
        if let ocrImage {
            setupWithOCRData(
                ocrImage: ocrImage,
                language: language,
                observations: textObservations
            )
        }
    }

    // MARK: Internal

    // MARK: - Processing Context Data

    /// Source image for OCR processing
    ///
    /// The original image containing the text to be processed. Used for spatial
    /// calculations, character width measurements, and layout analysis.
    var ocrImage: NSImage? = .init()

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
    /// - Note: This value may be negative if lines overlap or touch.
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

    /// Overall confidence score for the OCR result
    ///
    /// Calculated as the average of all individual text observation confidence scores.
    /// Range: 0.0 to 1.0, where 1.0 indicates maximum confidence.
    /// Used for assessing the reliability of the OCR recognition results.
    var confidence: Float = 0.0

    var bigLineSpacingThreshold: Double {
        min(averageLineHeight, averageLineSpacing * 1.4)
    }

    // MARK: - Comprehensive Metrics Calculation

    /// Setup metrics with OCR data and calculate comprehensive statistics
    ///
    /// This is the primary entry point for initializing OCR metrics with complete context.
    /// It sets up the language and performs comprehensive metrics calculations in one atomic operation.
    /// This method replaces all scattered metric calculations previously distributed across the codebase.
    ///
    /// **Key Benefits:**
    /// - Centralized metrics calculation
    /// - Atomic operation ensuring data consistency
    /// - Eliminates code duplication
    /// - Provides comprehensive debug output
    ///
    /// **Calculated Metrics:**
    /// - Line height statistics (min, average, total)
    /// - Line spacing measurements and patterns
    /// - Horizontal positioning and line length data
    /// - Character width calculations from representative lines
    /// - Word length analysis for space-separated languages
    /// - Reference observation identification (longest, shortest, etc.)
    /// - Overall confidence score calculation
    /// - Poetry detection analysis
    ///
    /// - Parameters:
    ///   - observations: Array of VNRecognizedTextObservation from Vision framework
    ///   - ocrImage: Source image for character width and spatial calculations
    ///   - language: Target language for OCR processing and text analysis
    ///   - detectPoetry: Whether to perform poetry detection (defaults to false)
    func setupWithOCRData(
        ocrImage: NSImage,
        language: Language,
        observations: [VNRecognizedTextObservation]
    ) {
        // Ensure we have clean state
        resetMetrics()

        // Set basic properties
        self.ocrImage = ocrImage
        self.language = language
        textObservations = observations

        guard !observations.isEmpty else { return }

        let lineCount = observations.count
        var lineSpacingCount = 0

        // First pass: Process each observation to accumulate baseline metrics
        for textObservation in observations {
            processObservationMetrics(textObservation)
        }

        // Calculate average line height after first pass
        averageLineHeight = totalLineHeight / lineCount.double

        // Second pass: Analyze spacing between consecutive observations
        for index in 1 ..< observations.count {
            let textObservation = observations[index]
            let prevObservation = observations[index - 1]

            analyzeConsecutiveSpacing(
                current: textObservation,
                previous: prevObservation,
                lineSpacingCount: &lineSpacingCount
            )
        }

        if lineSpacingCount > 0 {
            averageLineSpacing = totalLineSpacing / lineSpacingCount.double
        }

        // Calculate average character width from the line with most characters
        if let textObservation = maxCharacterCountLineTextObservation {
            averageCharacterWidth = computeAverageCharacterWidth(
                from: textObservation,
                ocrImage: ocrImage
            )
        }

        // Calculate total character count and average per line
        totalCharCount = observations.map { $0.firstText.count }.reduce(0, +)
        charCountPerLine = totalCharCount.double / lineCount.double

        // Calculate overall confidence score
        computeOverallConfidence(from: observations)

        isPoetry = poetryDetector.detectPoetry()
        print("🎭 Poetry detected: \(isPoetry)")

        // Output comprehensive metrics summary
        print("📊 OCR Metrics Summary:")
        print("  - Total observations: \(lineCount)")
        print("  - Confidence score: \(String(format: "%.3f", confidence))")
        print(
            "  - Line height → min: \(String(format: "%.3f", minLineHeight)), avg: \(String(format: "%.3f", averageLineHeight))"
        )
        print(
            "  - Line spacing → min: \(String(format: "%.3f", minLineSpacing)), positive min: \(String(format: "%.3f", minPositiveLineSpacing)), avg: \(String(format: "%.3f", averageLineSpacing))"
        )
        print(
            "  - Big line spacing threshold: \(String(format: "%.3f", bigLineSpacingThreshold))"
        )
        print(
            "  - Line length → min: \(String(format: "%.3f", minLineLength)), max: \(String(format: "%.3f", maxLineLength))"
        )
        print(
            "  - Character metrics → width: \(String(format: "%.3f", averageCharacterWidth)), total: \(totalCharCount)"
        )
        print("  - Average chars per line: \(String(format: "%.1f", charCountPerLine))")
        print("  - Min X position: \(String(format: "%.3f", minX))")
    }

    // MARK: Private

    /// Poetry detector for analyzing text patterns and structure
    ///
    /// Used internally to determine if the processed text represents poetry
    /// based on line patterns, spacing, and structural characteristics.
    private lazy var poetryDetector = OCRPoetryDetector(metrics: self)

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
    private func resetMetrics() {
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
        confidence = 0.0
    }

    /// Process individual text observation to accumulate line height and positioning metrics
    ///
    /// This method performs the first-pass analysis of each text observation, collecting
    /// essential metrics including line heights, horizontal positioning, line lengths,
    /// word length analysis, and identifying key reference observations for later calculations.
    ///
    /// **Collected Metrics:**
    /// - Line height accumulation for average calculation
    /// - Minimum line height tracking
    /// - Horizontal positioning (minX, line lengths)
    /// - Reference observation identification (longest line, leftmost position, max characters)
    /// - Debug gap logging for consecutive observations
    ///
    /// **Design Note:**
    /// This method focuses purely on individual observation processing and reference
    /// tracking. Gap calculations and spacing analysis are handled separately in
    /// the second pass to ensure all baseline metrics are established first.
    ///
    /// - Parameters:
    ///   - textObservation: The text observation to process
    private func processObservationMetrics(_ textObservation: VNRecognizedTextObservation) {
        let boundingBox = textObservation.boundingBox
        let lineHeight: Double = boundingBox.size.height
        totalLineHeight += lineHeight

        if lineHeight < minLineHeight {
            minLineHeight = lineHeight
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

        // Calculate index for gap logging (only if not the first observation)
        guard let index = textObservations.firstIndex(of: textObservation), index > 0 else {
            return
        }

        let pair = OCRTextObservationPair(
            current: textObservation,
            previous: textObservations[index - 1]
        )
        let gap = pair.verticalGap
        let currentText = textObservation.firstText

        print(
            "  [\(index)]: \(currentText.prefix(5))... , gap: \(gap.threeDecimalString), height: \(lineHeight.threeDecimalString)"
        )
    }

    /// Analyze spacing between consecutive text observations (second pass)
    ///
    /// This method performs sophisticated spacing analysis between consecutive text
    /// observations using the established baseline metrics from the first pass.
    /// It employs intelligent filtering to distinguish between normal line spacing
    /// and paragraph breaks or multi-column layouts.
    ///
    /// **Enhanced Algorithm:**
    /// - Uses established average line height for consistent threshold calculations
    /// - Applies paragraph break filtering to exclude unusually large gaps
    /// - Tracks minimum spacing values regardless of filtering decisions
    /// - Focuses on inter-line spacing rather than intra-paragraph gaps
    ///
    /// **Spacing Classification:**
    /// - Normal line spacing: Positive gaps smaller than paragraph threshold
    /// - Excluded gaps: Zero/negative gaps, paragraph breaks, multi-column jumps
    /// - All gaps contribute to minimum spacing tracking for comprehensive analysis
    ///
    /// - Parameters:
    ///   - current: Current text observation
    ///   - previous: Previous text observation
    ///   - lineSpacingCount: Reference counter for valid spacing measurements
    private func analyzeConsecutiveSpacing(
        current: VNRecognizedTextObservation,
        previous: VNRecognizedTextObservation,
        lineSpacingCount: inout Int
    ) {
        let pair = OCRTextObservationPair(current: current, previous: previous)
        let verticalGap = pair.verticalGap

        // Only count spacing between observations that are NOT on the same line
        // and have reasonable positive spacing (exclude paragraph breaks)
        if verticalGap > 0, verticalGap < averageLineHeight * OCRConstants.paragraphLineHeightRatio {
            totalLineSpacing += verticalGap
            lineSpacingCount += 1
        }

        if verticalGap < minLineSpacing {
            minLineSpacing = verticalGap
        }

        if verticalGap > 0, verticalGap < minPositiveLineSpacing {
            minPositiveLineSpacing = verticalGap
        }
    }

    /// Calculate average character width from text observation dimensions
    ///
    /// Computes the average width of characters by dividing the physical text width
    /// by the character count, accounting for display scaling factors.
    ///
    /// - Parameters:
    ///   - textObservation: Text observation with bounding box and character data
    ///   - ocrImage: Source image for dimension calculations
    /// - Returns: Average character width in points
    private func computeAverageCharacterWidth(
        from textObservation: VNRecognizedTextObservation,
        ocrImage: NSImage
    )
        -> Double {
        let scaleFactor = NSScreen.main?.backingScaleFactor ?? 1.0
        let textWidth = textObservation.boundingBox.size.width * ocrImage.size.width / scaleFactor
        return textWidth / textObservation.firstText.count.double
    }

    /// Compute overall confidence score from text observations
    ///
    /// Calculates the average confidence score across all text observations,
    /// providing a unified measure of OCR recognition reliability for the entire document.
    ///
    /// - Parameter observations: Array of text observations with confidence data
    private func computeOverallConfidence(from observations: [VNRecognizedTextObservation]) {
        guard !observations.isEmpty else {
            confidence = 0.0
            return
        }

        let totalConfidence =
            observations
                .compactMap { $0.topCandidates(1).first?.confidence }
                .reduce(0, +)

        confidence = totalConfidence / Float(observations.count)
    }
}
