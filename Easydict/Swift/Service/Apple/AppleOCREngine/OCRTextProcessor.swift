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
///
/// This class serves as the central coordinator for processing raw OCR observations into
/// intelligently formatted text results. It applies sophisticated algorithms to:
///
/// **Core Functionality:**
/// - **Statistical Analysis**: Calculates line metrics, character widths, and spacing patterns
/// - **Text Sorting**: Orders text observations correctly (top-to-bottom, left-to-right)
/// - **Intelligent Merging**: Applies context-aware text joining based on spatial relationships
/// - **Poetry Detection**: Identifies and preserves poetic text formatting
/// - **Dash Handling**: Manages hyphenation and line continuation scenarios
/// - **Text Normalization**: Applies language-specific formatting and error correction
///
/// **Processing Pipeline:**
/// 1. Initialize basic OCR result properties
/// 2. Calculate confidence scores
/// 3. Setup comprehensive metrics calculation (集中化处理所有统计指标)
/// 4. Detect poetry patterns using calculated metrics
/// 5. Sort observations spatially using enhanced algorithms
/// 6. Apply intelligent text merging with spatial awareness
/// 7. Normalize final text output with language-specific rules
///
/// Originally ported from EZAppleService.setupOCRResult method with significant enhancements.
///
/// - Note: This class is designed to work with Apple's Vision framework text observations
public class OCRTextProcessor {
    // MARK: Internal

    /// Process OCR observations into structured result with intelligent text merging
    ///
    /// This is the main entry point for processing raw Vision framework observations
    /// into intelligently formatted text. The method handles both simple and advanced
    /// processing modes, with the advanced mode leveraging comprehensive metrics
    /// calculation for superior text merging results.
    ///
    /// **Simple Mode (intelligentJoined = false):**
    /// - Basic text extraction and confidence calculation
    /// - Line-by-line joining with newline separators
    /// - Minimal processing overhead
    ///
    /// **Advanced Mode (intelligentJoined = true):**
    /// - Comprehensive metrics calculation (集中化指标计算)
    /// - Poetry detection and preservation
    /// - Spatial-aware text sorting
    /// - Intelligent text merging with context awareness
    /// - Language-specific normalization
    ///
    /// - Parameters:
    ///   - ocrResult: The result object to populate with processed text
    ///   - observations: Raw text observations from Vision framework
    ///   - ocrImage: Source image for spatial calculations
    ///   - intelligentJoined: Whether to enable advanced text processing
    func setupOCRResult(
        _ ocrResult: EZOCRResult,
        observations: [VNRecognizedTextObservation],
        ocrImage: NSImage,
        intelligentJoined: Bool
    ) {
        let recognizedTexts = observations.compactMap(\.firstText)

        print("Original OCR strings (\(ocrResult.from)): \(recognizedTexts)")
        print("\nOCR objects: \(observations.formattedDescription)")

        // Set basic OCR result properties
        ocrResult.texts = recognizedTexts
        ocrResult.mergedText = recognizedTexts.joined(separator: "\n")
        ocrResult.raw = recognizedTexts

        // Initialize language detection if not already set
        if ocrResult.from == .auto {
            ocrResult.from = languageDetector.detectLanguage(text: ocrResult.mergedText)
        }

        // If intelligent joining is not enabled, return simple result
        guard intelligentJoined else { return }

        // Calculate confidence using metrics (both simple and advanced modes)
        metrics.setupWithOCRData(
            ocrImage: ocrImage,
            language: ocrResult.from,
            observations: observations
        )
        ocrResult.confidence = CGFloat(metrics.confidence)

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
    private let languageDetector = AppleLanguageDetector()
    private lazy var dashHandler = OCRDashHandler(metrics: metrics)
    private lazy var textNormalizer = OCRTextNormalizer(metrics: metrics)
    private lazy var textMerger = OCRTextMerger(metrics: metrics)

    /// Sort text observations by vertical position (top to bottom) and horizontal position (left to right)
    ///
    /// Uses the enhanced isSameLine algorithm for accurate same-line detection,
    /// providing better sorting accuracy than simple threshold-based approaches.
    ///
    /// **Sorting Logic:**
    /// - Groups observations on the same horizontal line using isSameLine analysis
    /// - Within same line: sorts left to right (X coordinate ascending)
    /// - Between different lines: sorts top to bottom (Y coordinate descending in Vision system)
    ///
    /// **Vision Coordinate System:**
    /// - Origin at bottom-left (0,0)
    /// - Y increases upward
    /// - Higher Y values = visually higher text (earlier in reading order)
    ///
    /// - Parameter observations: Array of text observations to sort
    /// - Returns: Sorted observations in proper reading order
    private func sortTextObservations(_ observations: [VNRecognizedTextObservation])
        -> [VNRecognizedTextObservation] {
        // Create line analyzer for same-line detection
        let lineAnalyzer = OCRLineAnalyzer(metrics: metrics)

        return observations.sorted { obj1, obj2 in
            let boundingBox1 = obj1.boundingBox
            let boundingBox2 = obj2.boundingBox

            // Create text observation pair for analysis
            let pair = OCRTextObservationPair(current: obj2, previous: obj1)

            // Use the enhanced isSameLine algorithm
            if lineAnalyzer.isSameLine(pair: pair) {
                // Same line: sort by X coordinate (left to right)
                return boundingBox1.origin.x < boundingBox2.origin.x
            } else {
                // Different lines: sort by Y coordinate (top to bottom)
                // In Vision coordinate system, higher Y means higher position (earlier in reading order)
                return boundingBox1.origin.y > boundingBox2.origin.y
            }
        }
    }

    /// Perform intelligent text merging based on spatial relationships and context
    private func performIntelligentTextMerging(_ observations: [VNRecognizedTextObservation])
        -> String {
        print("Performing intelligent text merging...")
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
