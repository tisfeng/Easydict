//
//  OCRSection.swift
//  Easydict
//
//  Created by tisfeng on 2025/6/26.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation
import Vision

// MARK: - OCRBand

struct OCRBand {
    let sections: [OCRSection]
}

// MARK: - OCRSection

/// A comprehensive data structure that holds metrics, statistics, and processed results for a section of OCR observations.
///
/// This class combines the functionality of OCRSectionMetrics and OCRSection, providing both:
/// - Detailed metrics and statistics about the document's layout and structure
/// - The final processed text and language information for the section
///
/// This unified approach eliminates duplication and provides a single source of truth for all section-related data.
class OCRSection {
    // MARK: Lifecycle

    /// Initializes the metrics object, optionally with an image, language, and observations to begin processing immediately.
    convenience init(
        ocrImage: NSImage? = nil,
        language: Language = .auto,
        observations: [EZRecognizedTextObservation] = []
    ) {
        self.init()
        self.language = language
        self.ocrImage = ocrImage
        self.observations = observations

        // If no text observations provided, return early
        guard !observations.isEmpty else {
            return
        }

        // If we have both image and observations, perform full setup
        if let ocrImage {
            setupWithOCRData(
                ocrImage: ocrImage,
                language: language,
                observations: observations
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
    var observations: [EZRecognizedTextObservation] = []

    // MARK: - Line & Spacing Metrics

    /// The minimum line height observed across all text observations.
    private(set) var minLineHeight: Double = 1.0

    /// The cumulative total of all line heights, used for calculating the average.
    private(set) var totalLineHeight: Double = 0

    /// The calculated average line height across the document.
    private(set) var averageLineHeight: Double = 0

    /// The minimum spacing observed between adjacent lines (can be negative if lines overlap).
    private(set) var minLineSpacing: Double = 1.0

    /// The minimum positive (non-zero) spacing between lines.
    private(set) var minPositiveLineSpacing: Double = 1.0

    /// The cumulative total of all line spacings, used for calculating the average.
    private(set) var totalLineSpacing: Double = 0

    /// The calculated average spacing between text lines.
    private(set) var averageLineSpacing: Double = 0

    // MARK: - Reference Observations

    /// The observation with the greatest width.
    private(set) var maxLengthObservation: EZRecognizedTextObservation?

    /// The observation that extends furthest to the right (has the maximum `maxX` coordinate).
    private(set) var maxXObservation: EZRecognizedTextObservation?

    /// The observation that starts furthest to the left (has the minimum `minX` coordinate).
    private(set) var minXObservation: EZRecognizedTextObservation?

    /// The observation that contains the most characters.
    private(set) var maxCharacterCountObservation: EZRecognizedTextObservation?

    // MARK: - Content & Confidence Metrics

    /// A flag indicating if the document content is likely poetry.
    private(set) var isPoetry: Bool = false

    /// The total number of characters across all observations.
    private(set) var totalCharCount: Int = 0

    /// The total count of punctuation marks found in the text.
    private(set) var punctuationMarkCount: Int = 0

    /// The calculated average width of a single character.
    private(set) var averageCharacterWidth: Double = 0.0

    /// The overall confidence score of the OCR results, averaged from all observations.
    private(set) var confidence: Float = 0.0

    // MARK: - Section Results (from OCRSection)

    /// The merged text for this section after intelligent processing
    private(set) var mergedText: String = ""

    /// The detected language for this section
    private(set) var detectedLanguage: Language = .auto

    var genre: Genre = .plain {
        didSet {
            // If the genre is classical poetry, set the isPoetry flag to true.
            if genre == .poetry {
                isPoetry = true
            }
        }
    }

    /// The average number of characters per line.
    var charCountPerLine: Double {
        totalCharCount.double / observations.count.double
    }

    /// The average number of punctuation marks per line.
    var punctuationCountPerLine: Double {
        punctuationMarkCount.double / observations.count.double
    }

    /// The calculated maximum line length (width) from the `maxLengthObservation`.
    var maxLineLength: Double {
        maxLengthObservation?.lineWidth ?? 0.0
    }

    /// A calculated threshold for what is considered a "big" line spacing, useful for detecting paragraph breaks.
    ///
    /// Maybe text has a big average line spacing, but we want to detect paragraph breaks
    /// that are larger than the average line spacing.
    var bigLineSpacingThreshold: Double {
        max(min(averageLineHeight, minLineHeight * 1.1), averageLineSpacing * 1.2)
    }

    // MARK: - Metrics Calculation

    /// Calculates all statistical and spatial metrics for the provided OCR observations.
    /// This is the main entry point for processing a new set of OCR data.
    func setupWithOCRData(
        ocrImage: NSImage,
        language: Language,
        observations: [EZRecognizedTextObservation]
    ) {
        // Ensure we have clean state
        resetMetrics()

        // Set basic properties
        self.ocrImage = ocrImage
        self.language = language
        self.observations = observations

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
        if let textObservation = maxCharacterCountObservation {
            averageCharacterWidth = computeAverageCharacterWidth(
                from: textObservation,
                ocrImage: ocrImage
            )
        }

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
            "  - Character metrics → total: \(totalCharCount), avg per line: \(String(format: "%.2f", charCountPerLine))"
        )
        print(
            "  - Punctuation marks: \(punctuationMarkCount), avg per line: \(String(format: "%.2f", Double(punctuationMarkCount) / Double(lineCount)))"
        )

        print(
            "  - Min X position: \(String(format: "%.3f", minXObservation?.boundingBox.minX ?? 0))"
        )
    }

    /// Resets all metrics to their default initial values.
    func resetMetrics() {
        // Reset context data
        ocrImage = NSImage()
        language = .auto
        observations = []

        // Reset metrics data
        minLineHeight = 1.0
        totalLineHeight = 0
        averageLineHeight = 0

        minLineSpacing = 1.0
        minPositiveLineSpacing = 1.0
        totalLineSpacing = 0
        averageLineSpacing = 0

        maxLengthObservation = nil
        maxXObservation = nil
        minXObservation = nil
        maxCharacterCountObservation = nil

        isPoetry = false
        totalCharCount = 0
        punctuationMarkCount = 0
        averageCharacterWidth = 0
        confidence = 0

        genre = .plain

        // Reset section results
        mergedText = ""
        detectedLanguage = .auto
    }

    // MARK: - Section Results Management

    /// Sets the processed results for this section
    /// - Parameters:
    ///   - mergedText: The final merged and formatted text for this section
    ///   - detectedLanguage: The detected language for this section
    func setSectionResults(mergedText: String, detectedLanguage: Language) {
        self.mergedText = mergedText
        self.detectedLanguage = detectedLanguage
    }

    // MARK: Private

    /// A detector for identifying poetry-like text structures.
    private lazy var poetryDetector = OCRPoetryDetector(metrics: self)

    /// Performs a first-pass analysis on an observation to collect baseline metrics like line height and position.
    private func processObservationMetrics(_ textObservation: EZRecognizedTextObservation) {
        let boundingBox = textObservation.boundingBox
        let lineHeight: Double = boundingBox.size.height
        totalLineHeight += lineHeight

        if lineHeight < minLineHeight {
            minLineHeight = lineHeight
        }

        // Track x coordinates and line lengths
        let x = boundingBox.origin.x
        if x < minXObservation?.boundingBox.minX ?? .greatestFiniteMagnitude {
            minXObservation = textObservation
        }

        let lengthOfLine = boundingBox.size.width
        if lengthOfLine > maxLineLength {
            maxLengthObservation = textObservation
        }

        if boundingBox.maxX > maxXObservation?.boundingBox.maxX ?? 0 {
            maxXObservation = textObservation
        }

        // Track maximum character count line
        let currentCharCount = textObservation.firstText.count
        if let maxCharObservation = maxCharacterCountObservation {
            if currentCharCount > maxCharObservation.firstText.count {
                maxCharacterCountObservation = textObservation
            }
        } else {
            maxCharacterCountObservation = textObservation
        }

        // Calculate character and punctuation metrics
        let text = textObservation.firstText

        // Count ellipses ("...") and standalone punctuation marks properly
        let ellipsisRegex = Regex.ellipsis
        let ellipsisCount = text.matches(of: ellipsisRegex).count
        let remainingText = text.replacing(ellipsisRegex, with: "")

        let otherPunctuationsCount = remainingText.filter { $0.isPunctuation }.count
        let linePunctuationCount = ellipsisCount + otherPunctuationsCount

        punctuationMarkCount += linePunctuationCount

        totalCharCount += text.count - linePunctuationCount
    }

    /// Performs a second-pass analysis to calculate the spacing between consecutive lines.
    private func analyzeConsecutiveSpacing(
        current: EZRecognizedTextObservation,
        previous: EZRecognizedTextObservation,
        lineSpacingCount: inout Int
    ) {
        let pair = OCRObservationPair(current: current, previous: previous)
        let verticalGap = pair.verticalGap

        // Only count spacing between observations that are NOT on the same line
        // and have reasonable positive spacing (exclude too large gaps).
        if verticalGap > 0 {
            var lineSpacing = verticalGap
            let maxRatio = OCRConstants.maxLineSpacingHeightRatio
            if verticalGap / averageLineHeight > maxRatio {
                lineSpacing = averageLineHeight * maxRatio
            }
            totalLineSpacing += lineSpacing
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
        from textObservation: EZRecognizedTextObservation,
        ocrImage: NSImage
    )
        -> Double {
        // Vision framework provides normalized coordinates (0-1), so we multiply by image size
        // No need for scaleFactor since NSImage.size already gives us the logical size in points
        let textWidth = textObservation.boundingBox.size.width * ocrImage.size.width
        var charCount = textObservation.firstText.count.double

        // If text last char is punctuation, only count 0.5 char
        if let lastChar = textObservation.firstText.last,
           lastChar.isPunctuation {
            charCount -= 0.5
        }

        charCount = max(1, charCount) // Avoid negative

        return textWidth / charCount
    }

    /// Calculates the overall confidence score by averaging the confidence of all observations.
    private func computeOverallConfidence(from observations: [EZRecognizedTextObservation]) {
        guard !observations.isEmpty else {
            confidence = 0.0
            return
        }

        let totalConfidence =
            observations
                .compactMap { $0.confidence }
                .reduce(0, +)

        confidence = totalConfidence / Float(observations.count)
    }
}
