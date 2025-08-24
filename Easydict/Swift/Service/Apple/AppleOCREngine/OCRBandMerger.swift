//
//  OCRBandMerger.swift
//  Easydict
//
//  Created by tisfeng on 2025/8/15.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

// MARK: - OCRBandMerger

/// An intelligent band merging engine for OCR results.
///
/// This class takes an OCR band containing multiple sections and merges them
/// into a single, well-formatted string. It uses spatial layout analysis to determine
/// appropriate merge strategies for side-by-side sections (columns) within the same
/// horizontal band.
class OCRBandMerger {
    // MARK: Lifecycle

    init(band: OCRBand) {
        self.band = band
    }

    // MARK: Internal

    /// Merges sections within the OCR band into a formatted string.
    ///
    /// This is the main entry point for the band merging process. It orchestrates
    /// the analysis of merge strategies and their application to produce the final output.
    /// The sections are retrieved from the band object passed during initialization.
    ///
    /// - Returns: A single string representing the merged and formatted text.
    func performSmartMerging() -> String {
        guard band.sections.count > 1 else {
            // Single section - return its merged text
            return band.sections.first?.mergedText ?? ""
        }

        log("🔤 Starting OCR band merge for \(band.sections.count) sections in horizontal layout")

        // For sections within the same horizontal band, we primarily use side-by-side merge strategies
        var sectionMergeStrategies: [OCRMergeStrategy] = []

        // Process each section starting from the second one
        for i in 1 ..< band.sections.count {
            let currentSection = band.sections[i]
            let previousSection = band.sections[i - 1]

            log("📋 Analyzing section pair [\(i - 1) → \(i)]:")
            log("  Previous section text: \(previousSection.mergedText.prefix(20))")
            log("  Current section text:  \(currentSection.mergedText.prefix(20))")

            // Determine merge strategy for side-by-side sections
            let mergeStrategy = determineSideBySideMergeStrategy(
                currentSection: currentSection,
                previousSection: previousSection
            )

            sectionMergeStrategies.append(mergeStrategy)
            log("  📝 Section [\(i)] Strategy: \(mergeStrategy)")
        }

        // Apply section merge strategies to generate the final text
        let mergedText = applySectionMergeStrategies(
            ocrSections: band.sections,
            strategies: sectionMergeStrategies
        )

        log("🏁 Band merge complete.")
        return mergedText
    }

    // MARK: Private

    private let band: OCRBand

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
            nextObservation: current
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
