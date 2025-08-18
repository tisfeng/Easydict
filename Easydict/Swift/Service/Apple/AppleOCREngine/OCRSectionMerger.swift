//
//  OCRSectionMerger.swift
//  Easydict
//
//  Created by tisfeng on 2025/8/15.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

// MARK: - OCRSectionMerger

class OCRSectionMerger {
    // MARK: Internal

    /// Merges multiple OCR sections into a single formatted string.
    ///
    /// This method analyzes the spatial layout of sections to determine appropriate merge strategies
    /// and applies them to produce the final merged text.
    ///
    /// - Parameter ocrSections: Array of OCR sections with spatial information and merged text
    /// - Returns: Final merged text with appropriate formatting
    func mergeSections(_ ocrSections: [OCRSection]) -> String {
        guard ocrSections.count > 1 else {
            // Single section - return its merged text
            return ocrSections.first?.mergedText ?? ""
        }

        // Analyze section merge strategies
        let sectionMergeStrategies = analyzeSectionMergeStrategies(ocrSections: ocrSections)

        // Apply section merge strategies to generate the final text
        let mergedText = applySectionMergeStrategies(
            ocrSections: ocrSections,
            strategies: sectionMergeStrategies
        )

        return mergedText
    }

    /// Merges multiple OCR bands (columns) within a horizontal band into a single formatted string.
    ///
    /// This method is specifically designed for merging side-by-side bands (columns) within the same
    /// horizontal region. It assumes the bands are spatially adjacent horizontally and applies
    /// appropriate merge strategies for column-based layouts.
    ///
    /// - Parameter ocrBands: Array of OCR sections representing bands/columns within a horizontal region
    /// - Returns: Final merged text with appropriate formatting for horizontal layout
    func mergeBands(_ ocrBands: [OCRSection]) -> String {
        guard ocrBands.count > 1 else {
            // Single band - return its merged text
            return ocrBands.first?.mergedText ?? ""
        }

        log("🔤 Starting OCR band merge for \(ocrBands.count) bands in horizontal layout")

        // For bands within the same horizontal region, we primarily use side-by-side merge strategies
        var bandMergeStrategies: [OCRMergeStrategy] = []

        // Process each band starting from the second one
        for i in 1 ..< ocrBands.count {
            let currentBand = ocrBands[i]
            let previousBand = ocrBands[i - 1]

            log("\n📋 Analyzing band pair [\(i - 1) → \(i)]:")
            log("  Previous band text: \(previousBand.mergedText.prefix(20))")
            log("  Current band text:  \(currentBand.mergedText.prefix(20))")

            // Determine merge strategy for side-by-side bands
            let mergeStrategy = determineSideBySideMergeStrategy(
                currentSection: currentBand,
                previousSection: previousBand
            )

            bandMergeStrategies.append(mergeStrategy)
            log("  📝 Band [\(i)] Strategy: \(mergeStrategy)")
        }

        // Apply band merge strategies to generate the final text
        let mergedText = applySectionMergeStrategies(
            ocrSections: ocrBands,
            strategies: bandMergeStrategies
        )

        log("🏁 Band merge complete.")
        return mergedText
    }

    // MARK: Private

    /// Determines the merge strategy for each pair of adjacent OCR sections.
    ///
    /// For each pair of sections, this method analyzes the relationship between the last observation
    /// of the previous section and the first observation of the current section to determine the
    /// appropriate merge strategy. All OCRMergeStrategy cases except lineBreak can be used between sections.
    ///
    /// - Parameter sections: The sections to analyze.
    /// - Returns: An array of `OCRMergeStrategy` corresponding to each section pair.
    @discardableResult
    private func analyzeSectionMergeStrategies(ocrSections: [OCRSection]) -> [OCRMergeStrategy] {
        // At least two sections are needed to form a pair
        guard ocrSections.count > 1 else { return [] }

        var sectionMergeStrategies: [OCRMergeStrategy] = []

        log("🔤 Starting OCR section merge strategy analysis for \(ocrSections.count) sections")

        // Process each section starting from the second one
        for i in 1 ..< ocrSections.count {
            let currentSection = ocrSections[i]
            let previousSection = ocrSections[i - 1]

            log("\n📋 Analyzing section pair [\(i - 1) → \(i)]:")
            log("  Previous section text: \(previousSection.mergedText.prefix(20))")
            log("  Current section text:  \(currentSection.mergedText.prefix(20))")

            // Default merge strategy for vertical section pairs
            var mergeStrategy = OCRMergeStrategy.newParagraph

            // Check if two sections are multi-column
            let currentMinX = currentSection.observations.minX
            let previousMaxX = previousSection.observations.maxX
            if currentMinX > previousMaxX {
                log("  Sections appear to be multi-column layout")
                // Determine merge strategy for side-by-side sections
                mergeStrategy = determineSideBySideMergeStrategy(
                    currentSection: currentSection,
                    previousSection: previousSection
                )
            }
            sectionMergeStrategies.append(mergeStrategy)

            log("  📝 Section [\(i)] Strategy: \(mergeStrategy)")
        }

        log("🏁 Section merge strategy complete.")
        return sectionMergeStrategies
    }

    /// Determines the appropriate merge strategy between two side-by-side sections.
    ///
    /// This method is specifically for sections that are positioned horizontally adjacent to each other
    /// (multi-column layout). It analyzes content patterns and linguistic context to determine
    /// whether sections should be joined with space, no space, or handle hyphenated words.
    /// Note: This function is only called for side-by-side sections, not vertically stacked ones.
    private func determineSideBySideMergeStrategy(
        currentSection: OCRSection,
        previousSection: OCRSection
    )
        -> OCRMergeStrategy {
        // Get the last observation from previous section and first from current section
        guard let previous = previousSection.observations.last,
              let current = currentSection.observations.first
        else {
            log("    Warning: Missing observations, using newParagraph strategy")
            return .newParagraph
        }

        let previousText = previous.firstText
        let currentText = current.firstText
        let pair = OCRObservationPair(current: current, previous: previous)

        log("  Analyzing side-by-side section pair:")
        log("    Previous: '\(previousText)'")
        log("    Current: '\(currentText)'")

        // Use the current section's metrics for analysis
        let dashHandler = OCRDashHandler(metrics: previousSection)

        // Check for hyphenated words first (highest priority)
        if let strategy = dashHandler.dashMergeStrategy(pair) {
            log("    Detected hyphenated word, using joinRemovingDash")
            return strategy
        }

        let lineAnalyzer = OCRLineAnalyzer(metrics: previousSection)
        let isLongText = lineAnalyzer.isLongText(
            observation: previous,
            nextObservation: current,
        )
        if !isLongText {
            log("    Short text detected, using newParagraph strategy")
            return .newParagraph
        }

        if previousText.hasEndPunctuationSuffix {
            log("    Previous text ends with punctuation, using newParagraph strategy")
            return .newParagraph
        }

        return .mergeStrategy(for: pair)
    }

    /// Applies section merge strategies to generate the final merged text.
    private func applySectionMergeStrategies(
        ocrSections: [OCRSection],
        strategies: [OCRMergeStrategy]
    )
        -> String {
        guard !ocrSections.isEmpty else { return "" }
        guard ocrSections.count == strategies.count + 1 else {
            log(
                "⚠️ Warning: Sections count (\(ocrSections.count)) != strategies count + 1 (\(strategies.count + 1))"
            )
            return ocrSections.map(\.mergedText).joined(
                separator: OCRConstants.paragraphSeparator
            )
        }

        log("🔧 Applying section merge strategies to \(ocrSections.count) sections")

        var result = ocrSections[0].mergedText

        // Apply each strategy to merge the subsequent section
        for (index, strategy) in strategies.enumerated() {
            let nextSectionText = ocrSections[index + 1].mergedText

            // Use the strategy's apply method to merge texts
            result = strategy.apply(firstText: result, secondText: nextSectionText)

            log("  Applied \(strategy) between sections \(index) and \(index + 1)")
        }

        let finalText = result.trimmingCharacters(in: .whitespacesAndNewlines)

        log("🎯 Final section merged text: \(finalText.prefix(20))...")
        return finalText
    }
}
