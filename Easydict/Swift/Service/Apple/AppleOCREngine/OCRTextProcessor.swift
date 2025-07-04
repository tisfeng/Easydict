//
//  OCRTextProcessor.swift
//  Easydict
//
//  Created by tisfeng on 2025/6/22.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation
import Vision

// MARK: - OCRTextProcessor

/// Main OCR text processing coordinator that handles the complete OCR text processing pipeline
/// Ported from EZAppleService setupOCRResult method
public class OCRTextProcessor {
    // MARK: Internal

    /// Process OCR observations into structured result with intelligent text merging
    func setupOCRResult(
        _ ocrResult: EZOCRResult,
        observations: [VNRecognizedTextObservation],
        ocrImage: NSImage,
        intelligentJoined: Bool
    ) {
        // Reset statistics
        metrics.resetMetrics()

        // Setup properties
        metrics.language = ocrResult.from
        metrics.ocrImage = ocrImage
        metrics.textObservations = observations
        metrics.ocrImage = ocrImage

        let recognizedTexts = observations.compactMap(\.firstText)

        print("Original OCR strings (\(ocrResult.from)): \(recognizedTexts)")
        print("\nOCR objects: \(observations.formattedDescription)")

        // Set basic OCR result properties
        ocrResult.texts = recognizedTexts
        ocrResult.mergedText = recognizedTexts.joined(separator: "\n")
        ocrResult.raw = recognizedTexts

        // Calculate confidence
        calculateConfidence(ocrResult, observations: observations)

        // If intelligent joining is not enabled, return simple result
        guard intelligentJoined else { return }

        let lineCount = observations.count
        var lineSpacingCount = 0

        // Calculate line statistics
        for (index, textObservation) in observations.enumerated() {
            metrics.collectLineLayoutMetrics(
                textObservation,
                index: index,
                observations: observations,
                lineSpacingCount: &lineSpacingCount
            )

            // Update maximum word length for space-separated languages
            metrics.updateMaxWordLength(textObservation)
        }

        // Calculate average character width from the line with most characters
        if let textObservation = metrics.maxCharacterCountLineTextObservation {
            metrics.averageCharacterWidth =
                metrics.calculateCharacterWidthMetric(
                    textObservation, ocrImage: ocrImage
                )
        }

        // Store final calculated values
        metrics.averageLineHeight =
            metrics.totalLineHeight / lineCount.double
        if lineSpacingCount > 0 {
            metrics.averageLineSpacing =
                metrics.totalLineSpacing / lineSpacingCount.double
        }

        // Detect if text is poetry
        metrics.isPoetry = poetryDetector.detectPoetry()
        print("isPoetry: \(metrics.isPoetry)")

        // Sort text observations for proper order
        let sortedObservations = sortTextObservations(observations)
        print("Sorted OCR objects: \(sortedObservations.formattedDescription)")

        // Perform intelligent text merging
        let mergedText = performIntelligentTextMerging(sortedObservations)

        // Update OCR result with intelligently merged text
        ocrResult.mergedText = mergedText.trimmingCharacters(in: .whitespacesAndNewlines)
        ocrResult.texts = ocrResult.mergedText.components(
            separatedBy: OCRConstants.lineBreakText
        )

        let showMergedText = String(ocrResult.mergedText.prefix(100))
        print(
            "OCR text (\(ocrResult.from)(\(String(format: "%.2f", ocrResult.confidence))): \(showMergedText)"
        )
    }

    // MARK: Private

    private let languageManager = EZLanguageManager.shared()

    // Helper components
    private let metrics = OCRMetrics()
    private lazy var poetryDetector = OCRPoetryDetector(metrics: metrics)
    private lazy var dashHandler = OCRDashHandler(metrics: metrics)
    private lazy var textNormalizer = OCRTextNormalizer(metrics: metrics)
    private lazy var textMerger = OCRTextMerger(metrics: metrics)

    /// Calculate and set the overall confidence score for OCR result
    private func calculateConfidence(
        _ ocrResult: EZOCRResult,
        observations: [VNRecognizedTextObservation]
    ) {
        guard !observations.isEmpty else {
            ocrResult.confidence = 0.0
            return
        }

        let totalConfidence =
            observations
                .compactMap { $0.topCandidates(1).first?.confidence }
                .reduce(0, +)
        ocrResult.confidence = CGFloat(totalConfidence / Float(observations.count))
    }

    /// Sort text observations by vertical position (top to bottom)
    private func sortTextObservations(_ observations: [VNRecognizedTextObservation])
        -> [VNRecognizedTextObservation] {
        observations.sorted { obj1, obj2 in
            let boundingBox1 = obj1.boundingBox
            let boundingBox2 = obj2.boundingBox

            let y1 = boundingBox1.origin.y
            let y2 = boundingBox2.origin.y

            // Check if they are on the same line (within threshold)
            let deltaY = abs(y1 - y2)

            if deltaY <= metrics.sameLineThreshold {
                // Same line: sort by X coordinate (left to right)
                return boundingBox1.origin.x < boundingBox2.origin.x
            } else {
                // Different lines: sort by Y coordinate (top to bottom)
                // Note: In Vision coordinate system, Y=0 is at bottom, so higher Y means higher position
                return y1 > y2
            }
        }
    }

    /// Perform intelligent text merging based on spatial relationships and context
    private func performIntelligentTextMerging(_ observations: [VNRecognizedTextObservation])
        -> String {
        var mergedText = ""

        for (index, textObservation) in observations.enumerated() {
            let recognizedText = textObservation.firstText

            print("\n\(textObservation)")

            if index > 0 {
                let prevTextObservation = observations[index - 1]

                let textObservationPair = OCRTextObservationPair(
                    current: textObservation,
                    previous: prevTextObservation
                )

                // Analyze dash handling for this text pair
                let dashAction = dashHandler.analyzeDashHandling(textObservationPair)

                var joinedString: String

                switch dashAction {
                case .none:
                    // No dash handling needed, proceed with normal text merging
                    joinedString = textMerger.joinedString(for: textObservationPair)

                case .keepDashAndJoin:
                    // Keep the dash, and join the words
                    joinedString = ""

                case .removeDashAndJoin:
                    // Remove the dash, and join the words
                    joinedString = ""
                    if !mergedText.isEmpty {
                        // Remove last dash from mergedText
                        mergedText.removeLast()
                    }
                }

                // Store joinedString in observation (mimic original behavior)
                textObservation.joinedString = joinedString

                // 1. append joined string
                mergedText += joinedString
            }

            // 2. append line text
            mergedText += recognizedText
        }

        if Configuration.shared.enableOCRTextNormalization {
            mergedText = textNormalizer.normalizeText(mergedText)
        }

        return mergedText.trim()
    }
}
