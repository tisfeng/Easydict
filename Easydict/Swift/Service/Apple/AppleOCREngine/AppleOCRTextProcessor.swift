//
//  AppleOCRTextProcessor.swift
//  Easydict
//
//  Created by tisfeng on 2025/6/22.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation
import Vision

// MARK: - AppleOCRTextProcessor

/// Main OCR text processing coordinator that handles the complete OCR text processing pipeline
/// Ported from EZAppleService setupOCRResult method
public class AppleOCRTextProcessor {
    // MARK: Internal

    /// Process OCR observations into structured result with intelligent text merging
    func setupOCRResult(
        _ ocrResult: EZOCRResult,
        observations: [VNRecognizedTextObservation],
        ocrImage: NSImage,
        intelligentJoined: Bool
    ) {
        self.ocrImage = ocrImage
        language = ocrResult.from

        // Reset statistics
        metrics.resetMetrics()

        print("\nTextObservations: \(observations.formattedDescription)")

        let recognizedTexts = observations.compactMap(\.firstText)

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

        print("Original OCR strings (\(ocrResult.from)): \(recognizedTexts)")

        // Detect if text is poetry
        metrics.isPoetry = poetryDetector.detectPoetry()
        print("isPoetry: \(metrics.isPoetry)")

        // Sort text observations for proper order
        let sortedObservations = sortTextObservations(observations)
        print("Sorted OCR strings: \(sortedObservations.recognizedTexts)")

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

    private var ocrImage = NSImage()
    private var language: Language = .auto
    private let languageManager = EZLanguageManager.shared()

    // Helper components
    private let metrics = OCRMetrics()
    private lazy var poetryDetector = OCRPoetryDetector(metrics: metrics)
    private lazy var dashHandler = OCRDashHandler(metrics: metrics)

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

            return y2 - y1 <= metrics.minLineHeight * 0.8
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

                // Determine if this is a new line
                let isNewLine = isNewLineRelativeToPrevious(textObservationPair)

                var joinedString: String

                // Analyze dash handling for this text pair
                let dashAction = dashHandler.analyzeDashHandling(textObservationPair)

                switch dashAction {
                case .none:
                    // No dash handling needed, proceed with normal text merging
                    if isNewLine {
                        // Update metrics with current context data
                        metrics.ocrImage = ocrImage
                        metrics.language = language

                        // Create text merger with OCR metrics
                        let textMerger = AppleOCRTextMerger(metrics: metrics)

                        joinedString = textMerger.joinedString(for: textObservationPair)
                    } else {
                        // If the same line, just join two texts
                        joinedString = " "
                    }

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
                setJoinedString(for: textObservation, joinedString: joinedString)

                // 1. append joined string
                mergedText += joinedString
            }

            // 2. append line text
            mergedText += recognizedText
        }

        // Apply final text processing
        return replaceSimilarDotSymbol(in: mergedText).trim()
    }

    /// Replace similar dot symbols with standardized middle dot character
    private func replaceSimilarDotSymbol(in string: String) -> String {
        let charSet = CharacterSet(charactersIn: "⋅•⋅‧∙")
        let components = string.components(separatedBy: charSet)

        if components.count > 1 {
            let trimmedComponents = components.compactMap { component in
                let trimmed = component.trimmingCharacters(in: .whitespaces)
                return trimmed.isEmpty ? nil : trimmed
            }
            return trimmedComponents.joined(separator: " · ")
        }

        return string
    }

    /// Determine if current observation represents a new line relative to previous observation
    private func isNewLineRelativeToPrevious(
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

    /// Store joined string in text observation using associated objects
    private func setJoinedString(for observation: VNRecognizedTextObservation, joinedString: String) {
        objc_setAssociatedObject(
            observation,
            "joinedString",
            joinedString,
            .OBJC_ASSOCIATION_COPY_NONATOMIC
        )
    }
}
