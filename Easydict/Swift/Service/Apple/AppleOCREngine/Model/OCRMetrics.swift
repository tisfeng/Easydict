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

/// A data structure that holds comprehensive metrics and statistics for a set of OCR observations.
///
/// This class analyzes the geometry and content of all text observations to understand the document's
/// layout and structure, which is crucial for making intelligent text merging decisions.
class OCRMetrics {
    // MARK: Lifecycle

    /// Initializes the metrics object, optionally with an image, language, and observations to begin processing immediately.
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

    // MARK: - Processing Context

    /// The source image from which OCR was performed.
    var ocrImage: NSImage? = .init()

    /// The dominant language detected in the OCR text.
    var language: Language = .auto

    /// The complete array of text observations from the Vision framework.
    var textObservations: [VNRecognizedTextObservation] = []

    // MARK: - Line & Spacing Metrics

    /// The minimum line height observed across all text observations.
    var minLineHeight: Double = .greatestFiniteMagnitude

    /// The cumulative total of all line heights, used for calculating the average.
    var totalLineHeight: Double = 0

    /// The calculated average line height across the document.
    var averageLineHeight: Double = 0

    /// The minimum spacing observed between adjacent lines (can be negative if lines overlap).
    var minLineSpacing: Double = .greatestFiniteMagnitude

    /// The minimum positive (non-zero) spacing between lines.
    var minPositiveLineSpacing: Double = .greatestFiniteMagnitude

    /// The cumulative total of all line spacings, used for calculating the average.
    var totalLineSpacing: Double = 0

    /// The calculated average spacing between text lines.
    var averageLineSpacing: Double = 0

    // MARK: - Reference Observations

    /// The observation with the greatest width.
    var maxLineLengthObservation: VNRecognizedTextObservation?

    /// The observation that extends furthest to the right (has the maximum `maxX` coordinate).
    var maxXLineTextObservation: VNRecognizedTextObservation?

    /// The observation that starts furthest to the left (has the minimum `minX` coordinate).
    var minXLineTextObservation: VNRecognizedTextObservation?

    /// The observation that contains the most characters.
    var maxCharacterCountLineTextObservation: VNRecognizedTextObservation?

    // MARK: - Content & Confidence Metrics

    /// A flag indicating if the document content is likely poetry.
    var isPoetry: Bool = false

    /// The average number of characters per line.
    var charCountPerLine: Double = 0

    /// The total number of characters across all observations.
    var totalCharCount: Int = 0

    /// The total count of punctuation marks found in the text.
    var punctuationMarkCount: Int = 0

    /// The calculated average width of a single character.
    var averageCharacterWidth: Double = 0.0

    /// The overall confidence score of the OCR results, averaged from all observations.
    var confidence: Float = 0.0

    /// The calculated maximum line length (width) from the `maxLineLengthObservation`.
    var maxLineLength: Double {
        maxLineLengthObservation?.lineWidth ?? 0.0
    }

    /// A calculated threshold for what is considered a "big" line spacing, useful for detecting paragraph breaks.
    var bigLineSpacingThreshold: Double {
        min(averageLineHeight, minLineHeight * 1.1)
    }

    // MARK: - Metrics Calculation

    /// Calculates all statistical and spatial metrics for the provided OCR observations.
    /// This is the main entry point for processing a new set of OCR data.
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
            "  - Line length → max: \(String(format: "%.3f", maxLineLength))"
        )
        print(
            "  - Character metrics → width: \(String(format: "%.3f", averageCharacterWidth)), total: \(totalCharCount)"
        )
        print("  - Average chars per line: \(String(format: "%.1f", charCountPerLine))")
        print("  - Min X position: \(String(format: "%.3f", minXLineTextObservation?.boundingBox.minX ?? 0))")
    }

    // MARK: Private

    /// A detector for identifying poetry-like text structures.
    private lazy var poetryDetector = OCRPoetryDetector(metrics: self)

    /// Resets all metrics to their default initial values.
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

        maxLineLengthObservation = nil

        maxXLineTextObservation = nil
        minXLineTextObservation = nil
        maxCharacterCountLineTextObservation = nil

        isPoetry = false
        charCountPerLine = 0
        totalCharCount = 0
        punctuationMarkCount = 0
        averageCharacterWidth = 0.0
        confidence = 0.0
    }

    /// Performs a first-pass analysis on an observation to collect baseline metrics like line height and position.
    private func processObservationMetrics(_ textObservation: VNRecognizedTextObservation) {
        let boundingBox = textObservation.boundingBox
        let lineHeight: Double = boundingBox.size.height
        totalLineHeight += lineHeight

        if lineHeight < minLineHeight {
            minLineHeight = lineHeight
        }

        // Track x coordinates and line lengths
        let x = boundingBox.origin.x
        if x < minXLineTextObservation?.boundingBox.minX ?? .greatestFiniteMagnitude {
            minXLineTextObservation = textObservation
        }

        let lengthOfLine = boundingBox.size.width
        if lengthOfLine > maxLineLength {
            maxLineLengthObservation = textObservation
        }

        if boundingBox.maxX > maxXLineTextObservation?.boundingBox.maxX ?? 0 {
            maxXLineTextObservation = textObservation
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
            "  [\(index)]: \(currentText.prefix20)... , gap: \(gap.threeDecimalString), height: \(lineHeight.threeDecimalString)"
        )
    }

    /// Performs a second-pass analysis to calculate the spacing between consecutive lines.
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

    /// Computes the average character width based on a given text observation.
    private func computeAverageCharacterWidth(
        from textObservation: VNRecognizedTextObservation,
        ocrImage: NSImage
    )
        -> Double {
        // Vision framework provides normalized coordinates (0-1), so we multiply by image size
        // No need for scaleFactor since NSImage.size already gives us the logical size in points
        let textWidth = textObservation.boundingBox.size.width * ocrImage.size.width
        return textWidth / textObservation.firstText.count.double
    }

    /// Calculates the overall confidence score by averaging the confidence of all observations.
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
