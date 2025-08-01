//
//  OCRTextMerger.swift
//  Easydict
//
//  Created by tisfeng on 2025/6/22.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation
import Vision

/// An intelligent text merging engine for OCR results.
///
/// This class takes a list of sorted `VNRecognizedTextObservation` objects and merges them
/// into a single, well-formatted string. It uses a context-aware approach to decide
/// whether to join lines with a space, a line break, or a new paragraph, and handles
/// special cases like hyphenated words and lists.
class OCRTextMerger {
    // MARK: Lifecycle

    init(metrics: OCRMetrics) {
        self.metrics = metrics
    }

    // MARK: Internal

    /// Merges sorted OCR observations into a single formatted string.
    ///
    /// This is the main entry point for the text merging process. It orchestrates
    /// the analysis of merge strategies and their application to produce the final output.
    ///
    /// - Parameter sortedObservations: An array of `VNRecognizedTextObservation` sorted in reading order.
    /// - Returns: A single string representing the merged and formatted text.
    func performIntelligentTextMerging(_ sortedObservations: [VNRecognizedTextObservation])
        -> String {
        // Analyze merge strategies for sorted observations.
        let mergeStrategies = analyzeMergeStrategies(observations: sortedObservations)

        // Apply merge strategies to generate the final text.
        let mergedText = applyMergeStrategies(
            observations: sortedObservations,
            strategies: mergeStrategies
        )

        for (index, observation) in sortedObservations.enumerated() {
            // The merge strategy starts from the second observation.
            // `mergeStrategy` was set in `analyzeMergeStrategies`.
            if let mergeStrategy = observation.mergeStrategy {
                print(" [\(index)]: strategy: \(mergeStrategy), \(observation.prefix20)")
            }
        }

        return mergedText
    }

    // MARK: Private

    private let metrics: OCRMetrics
    private lazy var textNormalizer = OCRTextNormalizer(metrics: metrics)

    // MARK: - Merge Strategy Analysis

    /// Determines the merge strategy for each pair of adjacent OCR observations.
    /// - Parameter observations: The sorted observations to analyze.
    /// - Returns: An array of `OCRMergeStrategy` corresponding to each observation pair.
    @discardableResult
    private func analyzeMergeStrategies(
        observations: [VNRecognizedTextObservation]
    )
        -> [OCRMergeStrategy] {
        // At least two observations are needed to form a pair.
        guard observations.count > 1 else { return [] }

        var mergeStrategies: [OCRMergeStrategy] = []

        // Dynamic tracking for context-aware decisions.
        var paragraphObservations: [VNRecognizedTextObservation] = [observations[0]]

        // Reference for the observation with the maximum X-coordinate in the current context.
        var maxXLineTextObservation = observations[0]

        print("🔤 Starting OCR merge strategy analysis for \(observations.count) observations")

        // Process each observation starting from the second one.
        for i in 1 ..< observations.count {
            let current = observations[i]
            let previous = observations[i - 1]
            let pair = OCRTextObservationPair(current: current, previous: previous)

            print("\n📋 Analyzing pair [\(i - 1) → \(i)]:")
            print("  Previous: \(previous.firstText.prefix20)")
            print("  Current:  \(current.firstText.prefix20)")

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

            print("  📝 Strategy: \(mergeStrategy)")
        }

        print("✅ Merge strategy analysis complete: \(mergeStrategies.count) strategies determined")
        return mergeStrategies
    }

    /// Applies the determined strategies to produce the final merged text.
    ///
    /// - Parameters:
    ///   - observations: The original sorted observations.
    ///   - strategies: The merge strategies for each adjacent pair.
    /// - Returns: The final merged and formatted text.
    private func applyMergeStrategies(
        observations: [VNRecognizedTextObservation],
        strategies: [OCRMergeStrategy]
    )
        -> String {
        guard !observations.isEmpty else { return "" }
        guard observations.count == strategies.count + 1 else {
            print(
                "⚠️ Warning: Observations count (\(observations.count)) != strategies count + 1 (\(strategies.count + 1))"
            )
            return observations.map(\.firstText).joined(separator: " ")
        }

        print("🔧 Applying merge strategies to \(observations.count) observations")

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
            print("🔧 Applying text normalization...")
            mergedText = textNormalizer.normalizeText(mergedText)
        }

        let finalText = mergedText.trim()
        print("✅ Merge complete. Final length: \(finalText.count) characters")

        return finalText
    }

    /// Determines the merge strategy between two adjacent text observations.
    ///
    /// This function analyzes various factors like line breaks, hyphenation, font size, indentation,
    /// line spacing, and list formatting to decide whether to join text with a space, a line break,
    /// a new paragraph, or handle hyphenated words.
    ///
    /// - Parameters:
    ///   - pair: The current and previous observations to compare.
    ///   - maxXObservation: The observation with the rightmost boundary in the current paragraph, used for layout context.
    ///   - currentParagraphObservations: All observations belonging to the current paragraph.
    /// - Returns: The most appropriate `OCRMergeStrategy` for the given pair.
    private func determineMergeStrategy(
        pair: OCRTextObservationPair,
        maxXObservation: VNRecognizedTextObservation,
        paragraphObservations: [VNRecognizedTextObservation]
    )
        -> OCRMergeStrategy {
        // Create context object to reduce code duplication
        let context = OCRMergeContext(
            pair: pair,
            maxXObservation: maxXObservation,
            paragraphObservations: paragraphObservations,
            metrics: metrics
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
        observation: VNRecognizedTextObservation,
        paragraphObservations: inout [VNRecognizedTextObservation],
        rightmostObservation: inout VNRecognizedTextObservation
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
