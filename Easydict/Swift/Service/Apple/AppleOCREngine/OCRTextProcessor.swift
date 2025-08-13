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
    ///   - smartMerging: A flag to enable the advanced text processing pipeline.
    ///   - textAnalysis: Pre-computed text analysis containing genre information (optional)
    func setupOCRResult(
        _ ocrResult: EZOCRResult,
        observations: [VNRecognizedTextObservation],
        ocrImage: NSImage,
        smartMerging: Bool,
        textAnalysis: TextAnalysis?
    ) {
        let recognizedTexts = observations.compactMap(\.firstText)

        // Reset metrics for new processing
        metrics.resetMetrics()

        // Set basic OCR result properties
        ocrResult.texts = recognizedTexts
        ocrResult.mergedText = recognizedTexts.joined(separator: "\n")

        log("\nOriginal OCR observations:(\(ocrResult.from)) \(observations.formattedDescription)")

        // If intelligent joining is not enabled, return simple result
        guard smartMerging else { return }

        // Step 1: Detect sections by analyzing spatial distribution
        let sections = detectSections(observations: observations)
        ocrResult.raw = sections

        log("\nDetected sections count: \(sections.count)")
        for section in sections {
            log("\nSection observations (\(section.count)): \(section.formattedDescription)")
        }

        let startTime = CFAbsoluteTimeGetCurrent()

        // Step 2: Process each section independently
        var allMergedTexts: [String] = []

        for (index, var section) in sections.enumerated() {
            log("\nProcessing section \(index + 1) with \(section.count) observations")
            metrics.setupWithOCRData(
                ocrImage: ocrImage,
                language: ocrResult.from,
                observations: section
            )
            ocrResult.confidence = CGFloat(metrics.confidence)

            // Perform intelligent text merging for this section
            let sectionMergedText = textMerger.performSmartMerging(section)
            log("\nMerged section [\(index + 1)]: \(sectionMergedText)")

            section.mergedText = sectionMergedText
            allMergedTexts.append(sectionMergedText)
        }

        // Show OCR debug window for analysis (only in debug builds)
        #if DEBUG
        if Configuration.shared.beta {
            Task { @MainActor in
                showOCRDebugWindow(image: ocrImage, sections: sections)
            }
        }
        #endif

        log("Merge \(observations.count) sections cost time \(startTime.elapsedTimeString) seconds")

        // If text language is classical Chinese, update metrics genre.
        // Later, we can use this to determine if the text is poetry.
        if ocrResult.from == .classicalChinese {
            metrics.genre = textAnalysis?.genre ?? .plain
        }

        // Combine all section texts
        let finalMergedText = allMergedTexts.joined(separator: OCRConstants.paragraphSeparator)
        log("\nFinal merged text: \(finalMergedText)")

        // Update OCR result with intelligently merged text
        ocrResult.mergedText = finalMergedText.trimmingCharacters(in: .whitespacesAndNewlines)
        ocrResult.texts = ocrResult.mergedText.components(separatedBy: OCRConstants.lineSeparator)

        log(
            "\nOCR text (\(ocrResult.from), \(ocrResult.confidence.string2f)): \(ocrResult.mergedText)\n"
        )
    }

    /// Checks if the given observations suggest that image cropping would improve OCR accuracy.
    ///
    /// - Parameters:
    ///   - observations: Text observations from OCR
    ///   - ocrImage: The original image
    /// - Returns: A cropped image if optimization is recommended, nil otherwise
    func getCroppedImageIfNeeded(
        observations: [VNRecognizedTextObservation],
        ocrImage: NSImage
    )
        -> NSImage? {
        guard !observations.isEmpty else { return nil }

        // Calculate the bounding box that contains all text
        let textBoundingBox = observations.calculateSectionBoundingBox()
        let textArea = textBoundingBox.width * textBoundingBox.height

        let threshold = 0.5

        // Total image area in normalized coordinates is 1.0 (1.0 * 1.0)

        log("Text bounding box (Vision coords): \(textBoundingBox)")
        log("Text area: \(textArea.string3f), threshold: \(threshold.string2f)")

        // Check if text area is less than threshold
        if textArea < threshold {
            log("Text area is less than threshold, cropping needed")
            return cropImageToTextRegion(image: ocrImage, textBoundingBox: textBoundingBox)
        } else {
            log("Text area is sufficient, no cropping needed")
            return nil
        }
    }

    // MARK: Private

    private let metrics = OCRMetrics()
    private lazy var textMerger = OCRTextMerger(metrics: metrics)
    private lazy var lineAnalyzer = OCRLineAnalyzer(metrics: metrics)

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

        let avgHeight =
            observations.map { $0.boundingBox.height }.reduce(0, +) / CGFloat(observations.count)
        let bandThreshold = avgHeight * 3.0 // Significant vertical gap indicates new section

        for (index, observation) in sortedByY.enumerated() {
            if index == 0 {
                currentBand.append(observation)
            } else {
                let previousY = sortedByY[index - 1].boundingBox.origin.y
                let currentY = observation.boundingBox.origin.y
                let verticalGap = previousY - currentY // Gap between previous and current

                if verticalGap > bandThreshold {
                    // Large vertical gap - start new band
                    if !currentBand.isEmpty {
                        bands.append(currentBand)
                        currentBand = []
                    }
                }
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
            let pair = OCRTextObservationPair(current: obj1, previous: obj2)

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

    /// Crops the image to focus on the text region with some padding.
    /// - Parameters:
    ///   - image: The original image
    ///   - textBoundingBox: The bounding box containing all text (in Vision coordinates)
    /// - Returns: The cropped image, or nil if cropping fails
    private func cropImageToTextRegion(image: NSImage, textBoundingBox: CGRect) -> NSImage? {
        let imageSize = image.size
        let imageWidth = imageSize.width
        let imageHeight = imageSize.height

        // Convert Vision coordinates to image coordinates
        // Vision: (0,0) at bottom-left, Y increases upward
        // NSImage: (0,0) at bottom-left, Y increases upward (same as Vision)
        let padding: CGFloat = 0.15 // 10% padding on each side

        // Calculate padded region in Vision coordinates
        let paddedMinX = max(0, textBoundingBox.minX - padding)
        let paddedMaxX = min(1, textBoundingBox.maxX + padding)
        let paddedMinY = max(0, textBoundingBox.minY - padding)
        let paddedMaxY = min(1, textBoundingBox.maxY + padding)

        // Convert to NSImage coordinates (points, not pixels)
        let cropMinX = paddedMinX * imageWidth
        let cropMaxX = paddedMaxX * imageWidth
        let cropMinY = paddedMinY * imageHeight
        let cropMaxY = paddedMaxY * imageHeight

        let cropWidth = cropMaxX - cropMinX
        let cropHeight = cropMaxY - cropMinY
        let cropOrigin = NSPoint(x: cropMinX, y: cropMinY)
        let cropSize = NSSize(width: cropWidth, height: cropHeight)

        let cropRect = NSRect(origin: cropOrigin, size: cropSize)
        let destRect = NSRect(origin: .zero, size: cropSize)

        log("Cropping image from \(imageSize) to region: \(cropRect)")

        // Create a new NSImage with the cropped size
        let croppedImage = NSImage(size: cropSize)
        croppedImage.lockFocus()
        image.draw(in: destRect, from: cropRect, operation: .copy, fraction: 1.0)
        croppedImage.unlockFocus()

        log("Cropped image size: \(croppedImage.size)")

        return croppedImage
    }
}
