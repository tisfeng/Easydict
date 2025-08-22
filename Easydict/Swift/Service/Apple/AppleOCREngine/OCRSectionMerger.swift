//
//  OCRSectionMerger.swift
//  Easydict
//
//  Created by tisfeng on 2025/6/22.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation
import Vision

/// An intelligent section merging engine for OCR results.
///
/// This class takes a single OCR section containing multiple `EZRecognizedTextObservation` objects
/// and merges them into a single, well-formatted string. It uses a context-aware approach to decide
/// whether to join observations with a space, a line break, or a new paragraph, and handles
/// special cases like hyphenated words and lists.
///
/// This is the counterpart to `OCRBandMerger` which handles merging multiple sections within a band.
/// `OCRSectionMerger` focuses on intra-section merging of individual text observations.
class OCRSectionMerger {
    // MARK: Lifecycle

    init(section: OCRSection) {
        self.section = section
    }

    // MARK: Internal

    /// Merges text observations within a single OCR section into a formatted string.
    ///
    /// This is the main entry point for the section merging process. It orchestrates
    /// the analysis of merge strategies and their application to produce the final output.
    /// The observations are retrieved from the section object passed during initialization.
    ///
    /// This method handles intra-section merging, analyzing spatial relationships and content
    /// patterns between individual text observations to determine optimal joining strategies.
    ///
    /// - Returns: A single string representing the merged and formatted text for this section.
    func performSmartMerging() -> String {
        let sortedObservations = section.observations

        // Analyze merge strategies for sorted observations.
        let mergeStrategies = analyzeMergeStrategies(observations: sortedObservations)

        // Apply merge strategies to generate the final text.
        let mergedText = applyMergeStrategies(
            observations: sortedObservations, strategies: mergeStrategies
        )

        for (index, observation) in sortedObservations.enumerated() {
            // The merge strategy starts from the second observation.
            // `mergeStrategy` was set in `analyzeMergeStrategies`.
            if let mergeStrategy = observation.mergeStrategy {
                log(" [\(index)]: strategy: \(mergeStrategy), \(observation.prefix20)")
            }
        }

        return mergedText
    }

    // MARK: Private

    private let section: OCRSection
    private lazy var textNormalizer = OCRTextNormalizer(metrics: section)

    // MARK: - Merge Strategy Analysis

    /// Determines the merge strategy for each pair of adjacent OCR observations.
    /// - Parameter observations: The sorted observations to analyze.
    /// - Returns: An array of `OCRMergeStrategy` corresponding to each observation pair.
    @discardableResult
    private func analyzeMergeStrategies(
        observations: [EZRecognizedTextObservation]
    )
        -> [OCRMergeStrategy] {
        // At least two observations are needed to form a pair.
        guard observations.count > 1 else { return [] }

        var mergeStrategies: [OCRMergeStrategy] = []

        // Dynamic tracking for context-aware decisions.
        var paragraphObservations: [EZRecognizedTextObservation] = [observations[0]]

        // Reference for the observation with the maximum X-coordinate in the current context.
        var maxXLineTextObservation = observations[0]

        log("🔤 Starting OCR section merge strategy analysis for \(observations.count) observations")

        // Process each observation starting from the second one.
        for i in 1 ..< observations.count {
            var current = observations[i]
            let previous = observations[i - 1]
            let pair = OCRObservationPair(current: current, previous: previous)

            log("\n📋 Analyzing pair [\(i - 1) → \(i)]:")
            log("  Previous: \(previous.firstText.prefix20)")
            log("  Current:  \(current.firstText.prefix20)")

            // Perform a comprehensive analysis to determine the merge strategy.
            let mergeStrategy = determineMergeStrategy(
                pair: pair,
                maxXObservation: maxXLineTextObservation,
                paragraphObservations: paragraphObservations
            )

            mergeStrategies.append(mergeStrategy)
            current.mergeStrategy = mergeStrategy

            // Update context based on the strategy decision.
            updateParagraphContext(
                appliedStrategy: mergeStrategy,
                observation: current,
                paragraphObservations: &paragraphObservations,
                rightmostObservation: &maxXLineTextObservation
            )

            log("  📝 Strategy: \(mergeStrategy)")
        }

        log(
            "✅ Section merge strategy analysis complete: \(mergeStrategies.count) strategies determined"
        )
        return mergeStrategies
    }

    /// Applies the determined strategies to produce the final merged text.
    ///
    /// - Parameters:
    ///   - observations: The original sorted observations.
    ///   - strategies: The merge strategies for each adjacent pair.
    /// - Returns: The final merged and formatted text.
    private func applyMergeStrategies(
        observations: [EZRecognizedTextObservation],
        strategies: [OCRMergeStrategy]
    )
        -> String {
        guard !observations.isEmpty else { return "" }
        guard observations.count == strategies.count + 1 else {
            log(
                "⚠️ Warning: Observations count (\(observations.count)) != strategies count + 1 (\(strategies.count + 1))"
            )
            return observations.map(\.firstText).joined(separator: " ")
        }

        log("🔧 Applying merge strategies to \(observations.count) observations within section")

        var mergedText = ""

        // Start with the text of the first observation.
        var currentText = observations[0].firstText

        // Apply each strategy to the subsequent observations.
        for (index, strategy) in strategies.enumerated() {
            let nextObservation = observations[index + 1]
            let nextText = nextObservation.firstText

            // Apply the strategy to combine the current and next text.
            let combinedText = strategy.apply(firstText: currentText, secondText: nextText)
            currentText = combinedText
        }

        mergedText = currentText

        // Apply text normalization if the feature is enabled.
        if Configuration.shared.enableOCRTextNormalization {
            log("🔧 Applying text normalization...")
            mergedText = textNormalizer.normalizeText(mergedText)
        }

        let finalText = mergedText.trim()
        log("✅ Section merge complete. Final length: \(finalText.count) characters")

        return finalText
    }

    /// Determines the merge strategy between two adjacent text observations within a section.
    ///
    /// This function analyzes various factors like line breaks, hyphenation, font size, indentation,
    /// line spacing, and list formatting to decide whether to join text with a space, a line break,
    /// a new paragraph, or handle hyphenated words.
    ///
    /// This method focuses on intra-section analysis, considering the spatial and contextual
    /// relationships between observations within the same section boundaries.
    ///
    /// - Parameters:
    ///   - pair: The current and previous observations to compare.
    ///   - maxXObservation: The observation with the rightmost boundary in the current paragraph, used for layout context.
    ///   - currentParagraphObservations: All observations belonging to the current paragraph.
    /// - Returns: The most appropriate `OCRMergeStrategy` for the given pair.
    private func determineMergeStrategy(
        pair: OCRObservationPair,
        maxXObservation: EZRecognizedTextObservation,
        paragraphObservations: [EZRecognizedTextObservation]
    )
        -> OCRMergeStrategy {
        // Create context object to reduce code duplication
        let context = OCRMergeContext(
            pair: pair,
            maxXObservation: maxXObservation,
            paragraphObservations: paragraphObservations,
            metrics: section
        )

        // Create analyzer with context and delegate the strategy determination
        let analyzer = OCRMergeAnalyzer(context: context)
        return analyzer.determineMergeStrategy()
    }

    /// Updates the paragraph tracking context based on the applied merge strategy.
    ///
    /// When a line break or new paragraph strategy is applied, this method resets the tracking
    /// to start a new paragraph context. For joining strategies, it extends the current
    /// paragraph with the new observation and updates the rightmost boundary reference.
    ///
    /// - Parameters:
    ///   - appliedStrategy: The merge strategy that was applied to the current observation pair.
    ///   - observation: The current observation being processed.
    ///   - paragraphObservations: In-out array tracking all observations in the current paragraph.
    ///   - rightmostObservation: In-out reference to the observation with the rightmost boundary in the current paragraph.
    private func updateParagraphContext(
        appliedStrategy: OCRMergeStrategy,
        observation: EZRecognizedTextObservation,
        paragraphObservations: inout [EZRecognizedTextObservation],
        rightmostObservation: inout EZRecognizedTextObservation
    ) {
        switch appliedStrategy {
        case .lineBreak, .newParagraph:
            // Start a new paragraph, resetting the tracking context.
            paragraphObservations = [observation]
            rightmostObservation = observation

        case .joinRemovingDash, .joinWithNoSpace, .joinWithSpace:
            // Continue the current paragraph and update tracking.
            paragraphObservations.append(observation)

            // Update rightmost observation if current one extends further right.
            if observation.boundingBox.maxX > rightmostObservation.boundingBox.maxX {
                rightmostObservation = observation
            }
        }
    }
}
