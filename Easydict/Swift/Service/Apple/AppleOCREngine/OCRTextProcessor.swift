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
/// 5.  **Section Merging**: Uses `OCRBandMerger` to merge text between sections.
/// 6.  **Result Finalization**: Populates the `EZOCRResult` with the final text.
public class OCRTextProcessor {
    // MARK: Internal

    private(set) var bands: [OCRBand] = []

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
        // Set basic OCR result properties
        updateOCRResult(ocrResult, observations: observations)

        log("\nOriginal OCR observations:(\(ocrResult.from)) \(observations.formattedDescription)")

        // If intelligent joining is not enabled, return simple result
        guard smartMerging else { return }

        // Perform intelligent merging pipeline
        performIntelligentMerging(
            ocrResult,
            observations: observations,
            ocrImage: ocrImage,
            textAnalysis: textAnalysis
        )
    }

    // MARK: Private

    private let languageDetector = AppleLanguageDetector()

    /// Performs the intelligent merging pipeline for enhanced OCR processing.
    private func performIntelligentMerging(
        _ ocrResult: EZOCRResult,
        observations: [VNRecognizedTextObservation],
        ocrImage: NSImage,
        textAnalysis: TextAnalysis?
    ) {
        let startTime = CFAbsoluteTimeGetCurrent()

        // Step 1: Detect and process bands
        let detectedBands = detectBands(observations)
        let totalSections = detectedBands.reduce(0) { $0 + $1.sections.count }
        log(
            "\nDetected \(detectedBands.count) horizontal bands with \(totalSections) total sections"
        )

        // Step 2: Process all bands and sections
        let (processedBands, totalConfidence) = processBands(
            detectedBands,
            ocrResult: ocrResult,
            ocrImage: ocrImage,
            textAnalysis: textAnalysis
        )

        // Step 3: Store results and calculate confidence
        bands = processedBands
        let averageConfidence = calculateAverageConfidence(
            processedBands, totalConfidence: totalConfidence
        )
        log("Merge \(totalSections) sections cost time \(startTime.elapsedTimeString) seconds")

        // Step 4: Merge bands and finalize result
        let finalMergedText = mergeBandsToFinalText(processedBands)
        updateOCRResult(ocrResult, mergedText: finalMergedText, confidence: averageConfidence)
    }

    /// Processes all bands and their sections to create processed OCRBand objects.
    private func processBands(
        _ bands: [OCRBand],
        ocrResult: EZOCRResult,
        ocrImage: NSImage,
        textAnalysis: TextAnalysis?
    )
        -> (processedBands: [OCRBand], totalConfidence: Double) {
        var processedBands: [OCRBand] = []
        var totalConfidence = 0.0

        for (bandIndex, band) in bands.enumerated() {
            log("\nProcessing band \(bandIndex + 1) with \(band.sections.count) sections")

            let (processedSections, bandConfidence) = processSectionsInBand(
                band,
                bandIndex: bandIndex,
                ocrResult: ocrResult,
                ocrImage: ocrImage,
                textAnalysis: textAnalysis
            )

            totalConfidence += bandConfidence
            processedBands.append(OCRBand(sections: processedSections))
        }

        return (processedBands, totalConfidence)
    }

    /// Processes all sections within a single band.
    private func processSectionsInBand(
        _ band: OCRBand,
        bandIndex: Int,
        ocrResult: EZOCRResult,
        ocrImage: NSImage,
        textAnalysis: TextAnalysis?
    )
        -> (processedSections: [OCRSection], bandConfidence: Double) {
        var processedSections: [OCRSection] = []
        var bandConfidence = 0.0

        for (sectionIndex, section) in band.sections.enumerated() {
            let observations = section.observations

            log(
                "\nSection observations (\(observations.count)): \(observations.formattedDescription)"
            )

            let language = detectLanguageForSection(
                observations: observations,
                ocrResult: ocrResult,
                textAnalysis: textAnalysis
            )

            log(
                "\nProcessing section \(bandIndex + 1).\(sectionIndex + 1) with \(observations.count) observations (\(language)"
            )

            let ocrSection = createAndSetupOCRSection(
                observations: observations,
                language: language,
                ocrImage: ocrImage,
                textAnalysis: textAnalysis
            )

            let mergedText = performSectionMerging(
                ocrSection,
                bandIndex: bandIndex,
                sectionIndex: sectionIndex
            )
            ocrSection.setSectionResults(mergedText: mergedText, detectedLanguage: language)

            bandConfidence += Double(ocrSection.confidence)
            processedSections.append(ocrSection)
        }

        return (processedSections, bandConfidence)
    }

    /// Detects the appropriate language for a section.
    private func detectLanguageForSection(
        observations: [VNRecognizedTextObservation],
        ocrResult: EZOCRResult,
        textAnalysis: TextAnalysis?
    )
        -> Language {
        var language = ocrResult.from
        guard language == .auto else { return language }

        // Check for classical poetry/lyric genre
        if let genre = textAnalysis?.genre, genre.isPoetryLyric {
            log("Text analysis genre: \(genre)")
            return .classicalChinese
        }

        // Auto-detect language
        language = languageDetector.detectLanguage(text: observations.simpleMergedText)
        log("Detected language: \(language)")
        return language
    }

    /// Creates and configures an OCRSection instance.
    private func createAndSetupOCRSection(
        observations: [VNRecognizedTextObservation],
        language: Language,
        ocrImage: NSImage,
        textAnalysis: TextAnalysis?
    )
        -> OCRSection {
        let ocrSection = OCRSection()

        // Set genre for classical Chinese
        if language == .classicalChinese {
            ocrSection.genre = textAnalysis?.genre ?? .plain
        }

        ocrSection.setupWithOCRData(
            ocrImage: ocrImage,
            language: language,
            observations: observations
        )

        return ocrSection
    }

    /// Performs text merging within a single section.
    private func performSectionMerging(
        _ section: OCRSection,
        bandIndex: Int,
        sectionIndex: Int
    )
        -> String {
        let sectionTextMerger = OCRSectionMerger(section: section)
        let mergedText = sectionTextMerger.performSmartMerging()
        log("\nMerged section [\(bandIndex + 1).\(sectionIndex + 1)]: \(mergedText)")
        return mergedText
    }

    /// Calculates average confidence across all processed sections.
    private func calculateAverageConfidence(
        _ processedBands: [OCRBand],
        totalConfidence: Double
    )
        -> Double {
        let totalSectionCount = processedBands.reduce(0) { $0 + $1.sections.count }
        return totalSectionCount == 0 ? 0.0 : totalConfidence / Double(totalSectionCount)
    }

    /// Merges all processed bands into final text.
    private func mergeBandsToFinalText(_ processedBands: [OCRBand]) -> String {
        var mergedBandTexts: [String] = []

        for (bandIndex, band) in processedBands.enumerated() {
            let bandMerger = OCRBandMerger(band: band)
            let bandText = bandMerger.performSmartMerging()
            log("\nMerged band [\(bandIndex + 1)]: \(bandText)")
            mergedBandTexts.append(bandText)
        }

        let finalMergedText =
            mergedBandTexts
                .filter { !$0.isEmpty }
                .joined(separator: OCRMergeStrategy.newParagraph.separatorString())
                .trim()

        return finalMergedText
    }

    /// Updates OCR result with text data and optional confidence.
    private func updateOCRResult(
        _ ocrResult: EZOCRResult,
        observations: [VNRecognizedTextObservation]? = nil,
        mergedText: String? = nil,
        confidence: Double? = nil
    ) {
        if let observations {
            // Basic setup mode: set up initial properties from raw observations
            let recognizedTexts = observations.compactMap(\.firstText)
            ocrResult.texts = recognizedTexts
            ocrResult.mergedText = recognizedTexts.joined(separator: "\n")
            ocrResult.raw = observations
        }

        if let mergedText {
            // Finalization mode: update with processed text and confidence
            ocrResult.mergedText = mergedText
            ocrResult.texts = mergedText.components(separatedBy: OCRConstants.lineSeparator)

            if let confidence {
                ocrResult.confidence = CGFloat(confidence)
                log("\nOCR text (\(ocrResult.from), \(confidence.string2f)): \(mergedText)\n")
            }
        }
    }

    // MARK: - Band Detection

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
    /// - Returns: Array of OCRHorizontalBands, each containing bands for that horizontal region.
    private func detectBands(
        _ observations: [VNRecognizedTextObservation],
        maxColumns: Int = 2
    )
        -> [OCRBand] {
        guard !observations.isEmpty else { return [] }

        // Step 1: Group observations into horizontal bands
        let horizontalBandGroups = groupIntoHorizontalBands(observations)
        log("\nDetected \(horizontalBandGroups.count) horizontal band groups")

        // Step 2: Analyze each band group to determine its column structure
        var allHorizontalBands: [OCRBand] = []

        for bandGroup in horizontalBandGroups {
            let bandSections = analyzeColumnStructure(in: bandGroup, maxColumns: maxColumns)

            // Convert each section to an OCRBand and create OCRHorizontalBands
            let ocrBands = bandSections.compactMap { section -> OCRSection? in
                guard !section.isEmpty else { return nil }
                // Step 3: Sort each section's observations for reading order
                let sortedObservations = sortTextObservations(section)
                return OCRSection(observations: sortedObservations)
            }

            if !ocrBands.isEmpty {
                allHorizontalBands.append(OCRBand(sections: ocrBands))
            }
        }

        return allHorizontalBands
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
