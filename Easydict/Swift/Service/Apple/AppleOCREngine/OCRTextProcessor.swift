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
/// 3.  **Metrics Calculation**: Initializes `OCRSectionMetrics` to analyze the document's structure.
/// 4.  **Text Merging**: Delegates to `OCRTextMerger` to perform intra-section text merging.
/// 5.  **Section Merging**: Uses `OCRSectionMerger` to merge text between sections.
/// 6.  **Result Finalization**: Populates the `EZOCRResult` with the final text.
public class OCRTextProcessor {
    // MARK: Internal

    private(set) var ocrSections: [OCRSection] = []

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
    ///   - smartMerging: A flag to enable the advanced text processing pipeline.
    func setupOCRResult(
        _ ocrResult: EZOCRResult,
        observations: [VNRecognizedTextObservation],
        ocrImage: NSImage,
        smartMerging: Bool,
        textAnalysis: TextAnalysis?
    ) {
        let recognizedTexts = observations.compactMap(\.firstText)

        // Set basic OCR result properties
        ocrResult.texts = recognizedTexts
        ocrResult.mergedText = recognizedTexts.joined(separator: "\n")
        ocrResult.raw = observations

        log("\nOriginal OCR observations:(\(ocrResult.from)) \(observations.formattedDescription)")

        // If intelligent joining is not enabled, return simple result
        guard smartMerging else { return }

        // Step 1: Detect sections by analyzing spatial distribution
        let sections = detectSections(observations: observations)
        log("\nDetected sections count: \(sections.count)")

        for section in sections {
            log("\nSection observations (\(section.count)): \(section.formattedDescription)")
        }

        let startTime = CFAbsoluteTimeGetCurrent()

        // Step 2: Process each section independently
        var allMergedTexts: [String] = []
        var ocrSections: [OCRSection] = []
        var totalConfidence = 0.0

        for (index, var section) in sections.enumerated() {
            var language = ocrResult.from
            // If has no designated language, detect it automatically.
            if language == .auto {
                // If text analysis is classical poetry or lyric, set language to classical Chinese.
                if let genre = textAnalysis?.genre, genre.isPoetryLyric {
                    log("Text analysis genre: \(genre)")
                    language = .classicalChinese
                } else {
                    language = languageDetector.detectLanguage(text: section.simpleMergedText)
                    log("Detected language: \(language)")
                }
            }

            log("\nProcessing section \(index + 1) with \(section.count) observations (\(language)")

            // Create metrics instance for this section
            let ocrSection = OCRSection()

            // If text language is classical Chinese, update metrics genre.
            // Later, we can use this to determine if the text is poetry.
            if language == .classicalChinese {
                ocrSection.genre = textAnalysis?.genre ?? .plain
            }

            ocrSection.setupWithOCRData(
                ocrImage: ocrImage,
                language: language,
                observations: section
            )

            // Accumulate confidence for overall result
            totalConfidence += Double(ocrSection.confidence)

            // Create text merger with section-specific metrics for intra-section merging
            let sectionTextMerger = OCRTextMerger(metrics: ocrSection)

            // Perform intelligent text merging within this section
            let mergedText = sectionTextMerger.performSmartMerging()
            log("\nMerged section [\(index + 1)]: \(mergedText)")

            section.mergedText = mergedText
            allMergedTexts.append(mergedText)

            // Set the section results in the metrics object
            ocrSection.setSectionResults(mergedText: mergedText, detectedLanguage: language)
            ocrSections.append(ocrSection)
        }

        self.ocrSections = ocrSections

        // Calculate average confidence across all sections
        let averageConfidence = sections.isEmpty ? 0.0 : totalConfidence / Double(sections.count)
        ocrResult.confidence = CGFloat(averageConfidence)

        log("Merge \(sections.count) sections cost time \(startTime.elapsedTimeString) seconds")

        // Combine all section texts with intelligent merging between sections
        let finalMergedText = sectionMerger.mergeSections(ocrSections).trim()

        // Update OCR result with intelligently merged text
        ocrResult.mergedText = finalMergedText
        ocrResult.texts = ocrResult.mergedText.components(separatedBy: OCRConstants.lineSeparator)

        log("\nOCR text (\(ocrResult.from), \(averageConfidence.string2f)): \(finalMergedText)\n")
    }

    // MARK: Private

    private let languageDetector = AppleLanguageDetector()
    private let sectionMerger = OCRSectionMerger()

    /// Detects sections and groups text observations by spatial regions.
    ///
    /// Handles complex document layouts with vertical sections that may have different column counts:
    /// - Single column sections (titles, abstracts, conclusions)
    /// - Multi-column sections (main content, 2 columns)
    ///
    /// The algorithm works by:
    /// 1. Dividing the document into horizontal bands based on Y-coordinates
    /// 2. Analyzing each band separately to determine its column structure
    /// 3. Merging results while maintaining reading order
    ///
    /// - Parameter observations: All text observations.
    /// - Returns: Array of sections, each containing observations for that section, ordered for proper reading flow.
    private func detectSections(
        observations: [VNRecognizedTextObservation],
        maxColumns: Int = 2
    )
        -> [[VNRecognizedTextObservation]] {
        guard !observations.isEmpty else { return [] }

        // Step 1: Group observations into horizontal bands
        let horizontalBands = groupIntoHorizontalBands(observations)
        log("\nDetected \(horizontalBands.count) horizontal bands")

        // Step 2: Analyze each band to determine its column structure
        var allSections: [[VNRecognizedTextObservation]] = []

        for band in horizontalBands {
            let bandSections = analyzeColumnStructure(in: band, maxColumns: maxColumns)
            allSections.append(contentsOf: bandSections)
        }

        // Step 3: Sort each section's observations for reading order
        allSections = allSections.map { sortTextObservations($0) }

        // Remove empty sections
        return allSections.filter { !$0.isEmpty }
    }

    /// Groups observations into horizontal bands based on Y-coordinate proximity.
    private func groupIntoHorizontalBands(_ observations: [VNRecognizedTextObservation])
        -> [[VNRecognizedTextObservation]] {
        // Sort by Y-coordinate (top to bottom in Vision coordinates - higher Y = higher position)
        let sortedByY = observations.sorted { $0.boundingBox.origin.y > $1.boundingBox.origin.y }

        var bands: [[VNRecognizedTextObservation]] = []
        var currentBand: [VNRecognizedTextObservation] = []

        let averageHeight = observations.averageHeight

        for (index, observation) in sortedByY.enumerated() {
            if index > 0 {
                let pair = OCRObservationPair(current: observation, previous: sortedByY[index - 1])
                let isBigGap = pair.verticalGap / averageHeight > 1.5

                // Large vertical gap - start new band
                if isBigGap, !currentBand.isEmpty {
                    bands.append(currentBand)
                    currentBand = []
                }
                currentBand.append(observation)
            } else {
                // First observation, just add it to the current band
                currentBand.append(observation)
            }
        }

        // Add the last band
        if !currentBand.isEmpty {
            bands.append(currentBand)
        }

        return bands
    }

    /// Analyzes the column structure within a horizontal band.
    private func analyzeColumnStructure(in band: [VNRecognizedTextObservation], maxColumns: Int)
        -> [[VNRecognizedTextObservation]] {
        guard !band.isEmpty else { return [] }

        for observation in band {
            let minX = observation.boundingBox.minX
            let maxX = observation.boundingBox.maxX

            // If the band contains observations that span both sides of the page,
            // it indicates a single-column section (like titles or abstracts).
            if minX < 0.5, maxX > 0.5 {
                return [band]
            }
        }

        // Multi-column section - use clustering to detect columns
        return detectMultiColumnStructure(in: band, maxColumns: maxColumns)
    }

    /// Detects multi-column structure within a band using X-coordinate clustering.
    ///
    /// - TODO: This method currently uses a simple X-coordinate thresholding approach.
    /// It can be enhanced with more sophisticated clustering algorithms if needed.
    /// Maybe later we can support more than 2 columns.
    private func detectMultiColumnStructure(in band: [VNRecognizedTextObservation], maxColumns: Int)
        -> [[VNRecognizedTextObservation]] {
        guard !band.isEmpty else { return [] }

        // Initialize columns array
        var columns: [[VNRecognizedTextObservation]] = Array(repeating: [], count: maxColumns)

        // Group observations into columns based on X-coordinate position
        for observation in band {
            let minX = observation.boundingBox.minX

            // Determine column index based on X position using dynamic thresholds
            let columnIndex: Int = min(Int(minX * CGFloat(maxColumns)), maxColumns - 1)

            columns[columnIndex].append(observation)
        }

        // Remove empty columns and return only non-empty ones
        return columns.filter { !$0.isEmpty }
    }

    /// Sorts text observations within a single section into a logical reading order.
    ///
    /// This method handles sorting within a single section/column:
    /// - Top-to-bottom, left-to-right reading order
    /// - Uses line analysis to determine same-line vs different-line text
    ///
    /// - Parameter observations: The unsorted array of `VNRecognizedTextObservation` from a single section.
    /// - Returns: A sorted array of observations within the section.
    private func sortTextObservations(_ observations: [VNRecognizedTextObservation])
        -> [VNRecognizedTextObservation] {
        guard !observations.isEmpty else { return observations }

        // Sort within section: top-to-bottom, then left-to-right for same line
        return observations.sorted { obj1, obj2 in
            let boundingBox1 = obj1.boundingBox
            let boundingBox2 = obj2.boundingBox

            // Create text observation pair for line analysis
            let pair = OCRObservationPair(current: obj1, previous: obj2)

            let lineAnalyzer = OCRLineAnalyzer(metrics: OCRSection())
            // Use the enhanced isNewLine algorithm to determine if they're on the same line
            if !lineAnalyzer.isNewLine(pair: pair) {
                // Same line: sort by X coordinate (left to right)
                return boundingBox1.origin.x < boundingBox2.origin.x
            } else {
                // Different lines: sort by Y coordinate (top to bottom)
                // In Vision coordinate system, higher Y means higher position
                return boundingBox1.origin.y > boundingBox2.origin.y
            }
        }
    }
}
