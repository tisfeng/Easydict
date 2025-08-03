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

/// The main coordinator for the OCR text processing pipeline.
///
/// This class orchestrates the process of converting raw `VNRecognizedTextObservation` objects
/// into a final, intelligently formatted text string. It manages the overall workflow, delegating
/// specific tasks to other specialized components.
///
/// ### Processing Pipeline:
/// 1.  **Language Detection**: Determines the language of the recognized text.
/// 2.  **Spatial Sorting**: Orders observations into a logical reading order using `sortTextObservations`.
/// 3.  **Metrics Calculation**: Initializes `OCRMetrics` to analyze the document's structure.
/// 4.  **Text Merging**: Delegates to `OCRTextMerger` to perform the context-aware merging.
/// 5.  **Result Finalization**: Populates the `EZOCRResult` with the final text.
public class OCRTextProcessor {
    // MARK: Internal

    /// Processes raw OCR observations to produce a structured `EZOCRResult`.
    ///
    /// This is the main entry point for the processor. It takes the raw observations and, if
    /// `intelligentJoined` is enabled, orchestrates a full pipeline of sorting, metrics analysis,
    /// and intelligent merging. Otherwise, it performs a simple text join.
    ///
    /// - Parameters:
    ///   - ocrResult: The result object to be populated.
    ///   - observations: The raw `VNRecognizedTextObservation` array from the Vision framework.
    ///   - ocrImage: The source image, used for spatial calculations.
    ///   - intelligentJoined: A flag to enable the advanced text processing pipeline.
    func setupOCRResult(
        _ ocrResult: EZOCRResult,
        observations: [VNRecognizedTextObservation],
        ocrImage: NSImage,
        intelligentJoined: Bool
    ) {
        let recognizedTexts = observations.compactMap(\.firstText)

        // Set basic OCR result properties
        ocrResult.texts = recognizedTexts
        ocrResult.mergedText = recognizedTexts.joined(separator: "\n")
        ocrResult.raw = recognizedTexts

        var genre = Genre.plain

        // Initialize language detection if not already set
        if ocrResult.from == .auto {
            ocrResult.from = languageDetector.detectLanguage(text: ocrResult.mergedText)
            genre = languageDetector.getTextAnalysis()?.genre ?? .plain
        }

        // If intelligent joining is not enabled, return simple result
        guard intelligentJoined else { return }

//        print("\nOCR objects: \(observations.formattedDescription)")

        // Sort text observations for proper order
        let sortedObservations = sortTextObservations(observations)
//        print("Sorted OCR objects: \(sortedObservations.formattedDescription)")

        metrics.setupWithOCRData(
            ocrImage: ocrImage,
            language: ocrResult.from,
            observations: sortedObservations
        )
        ocrResult.confidence = CGFloat(metrics.confidence)

        // If text language is classical Chinese, update metrics genre.
        // Later, we can use this to determine if the text is poetry.
        if ocrResult.from == .classicalChinese {
            metrics.genre = genre
        }

        let mergedText = textMerger.performIntelligentTextMerging(sortedObservations)

        // Update OCR result with intelligently merged text
        ocrResult.mergedText = mergedText.trimmingCharacters(in: .whitespacesAndNewlines)
        ocrResult.texts = ocrResult.mergedText.components(
            separatedBy: OCRConstants.lineBreakText
        )

        print(
            "\nOCR text (\(ocrResult.from), \(ocrResult.confidence.string2f)): \(ocrResult.mergedText)\n"
        )
    }

    // MARK: Private

    private let metrics = OCRMetrics()
    private let languageDetector = AppleLanguageDetector()
    private lazy var textMerger = OCRTextMerger(metrics: metrics)
    private lazy var lineAnalyzer = OCRLineAnalyzer(metrics: metrics)

    /// Sorts text observations into a logical reading order (top-to-bottom, left-to-right).
    ///
    /// This method uses spatial analysis to correctly order observations, even for text on the same line.
    /// It is a crucial prerequisite for accurate text merging.
    ///
    /// - Parameter observations: The unsorted array of `VNRecognizedTextObservation`.
    /// - Returns: A sorted array of observations, ready for merging.
    private func sortTextObservations(_ observations: [VNRecognizedTextObservation])
        -> [VNRecognizedTextObservation] {
        // 1. Sort observations by origin.y
        let sortedObservations = observations.sorted {
            $0.boundingBox.origin.y > $1.boundingBox.origin.y
        }

        // 2. Sort observations by origin.x within same line
        return sortedObservations.sorted { obj1, obj2 in
            let boundingBox1 = obj1.boundingBox
            let boundingBox2 = obj2.boundingBox

            // Create text observation pair for analysis
            let pair = OCRTextObservationPair(current: obj1, previous: obj2)

            // Use the enhanced isNewLine algorithm
            if !lineAnalyzer.isNewLine(pair: pair) {
                // Same line: sort by X coordinate (left to right)
                return boundingBox1.origin.x < boundingBox2.origin.x
            } else {
                // Different lines: sort by Y coordinate (top to bottom)
                // In Vision coordinate system, higher Y means higher position (earlier in reading order)
                return boundingBox1.origin.y > boundingBox2.origin.y
            }
        }
    }
}
