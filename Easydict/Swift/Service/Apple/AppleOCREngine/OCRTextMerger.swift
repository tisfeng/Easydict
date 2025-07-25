//
//  OCRTextMerger.swift
//  Easydict
//
//  Created by tisfeng on 2025/6/22.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation
import Vision

/**
 * An intelligent text merging engine for OCR results.
 *
 * This class takes a list of sorted `VNRecognizedTextObservation` objects and merges them
 * into a single, well-formatted string. It uses a context-aware approach to decide
 * whether to join lines with a space, a line break, or a new paragraph, and handles
 * special cases like hyphenated words and lists.
 */
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
    private lazy var lineAnalyzer = OCRLineAnalyzer(metrics: metrics)
    private lazy var dashHandler = OCRDashHandler(metrics: metrics)
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
        var currentParagraphObservations: [VNRecognizedTextObservation] = [observations[0]]

        // Reference for the observation with the maximum X-coordinate in the current context.
        var maxXLineTextObservation = observations[0]

        print("🔤 Starting OCR merge strategy analysis for \(observations.count) observations")

        // Process each observation starting from the second one.
        for i in 1 ..< observations.count {
            let current = observations[i]
            let previous = observations[i - 1]
            let pair = OCRTextObservationPair(current: current, previous: previous)

            print("\n📋 Analyzing pair [\(i - 1) → \(i)]:")
            print("  Previous: \(previous.firstText.prefix20)...")
            print("  Current:  \(current.firstText.prefix20)...")

            // Perform a comprehensive analysis to determine the merge strategy.
            let mergeStrategy = determineMergeStrategy(
                pair: pair,
                maxXObservation: maxXLineTextObservation,
                currentParagraphObservations: currentParagraphObservations
            )

            mergeStrategies.append(mergeStrategy)
            current.mergeStrategy = mergeStrategy

            // Update context based on the strategy decision.
            updateContextualTracking(
                strategy: mergeStrategy,
                currentObservation: current,
                currentParagraphObservations: &currentParagraphObservations,
                maxXObservation: &maxXLineTextObservation
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
        print("📝 Starting with: '\(currentText.prefix20)...'")

        // Apply each strategy to the subsequent observations.
        for (index, strategy) in strategies.enumerated() {
            let nextObservation = observations[index + 1]
            let nextText = nextObservation.firstText

            print("\n📋 Applying strategy [\(index)]: \(strategy)")
            print("  Current: '\(currentText.suffix20)...'")
            print("  Next: '\(nextText.prefix20)...'")

            // Apply the strategy to combine the current and next text.
            let combinedText = strategy.apply(firstText: currentText, secondText: nextText)
            currentText = combinedText

            print("  Result: '\(combinedText.suffix(40))...'")
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

    // swiftlint:disable function_body_length

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
        currentParagraphObservations: [VNRecognizedTextObservation]
    )
        -> OCRMergeStrategy {
        // High-priority conditions should be checked first.

        // 1. Priority: Check if the two observations are on the same line.
        if !lineAnalyzer.isNewLine(pair: pair) {
            print("    🔗 Same line continuation - join with space")
            return .joinWithSpace
        }

        // 2. Priority: Analyze dash handling for hyphenated words.
        let dashAction = dashHandler.analyzeDashHandling(pair)
        if dashAction != .none {
            let dashStrategy = OCRMergeStrategy.from(dashAction)
            print("    🔗 Dash strategy: \(dashStrategy)")
            return dashStrategy
        }

        // 3. Priority: Detect font size changes, which often indicate structural breaks.
        if lineAnalyzer.isDifferentFontSize(pair: pair) {
            print("    🔤 Font size change detected - new paragraph")
            return .newParagraph
        }

        let comparedObservation = getComparedObservation(
            pair: pair,
            maxXObservation: maxXObservation,
            currentParagraphObservations: currentParagraphObservations
        )

        let current = pair.current
        let previous = pair.previous

        let hasBigIndentation = lineAnalyzer.hasIndentation(
            observation: current,
            comparedObservation: previous,
            confidenceLevel: .custom(3)
        )

        let isPreviousLongText = lineAnalyzer.isLongText(
            observation: previous,
            nextObservation: current,
            comparedObservation: comparedObservation
        )

        if hasBigIndentation {
            print("    📏 Big indentation detected")
            if !isPreviousLongText {
                print("    📏 Big indentation and previous line is not long text - new paragraph")
                return .newParagraph
            }
        }

        let isPoetry = metrics.isPoetry

        let hasVeryBigLineSpacing = lineAnalyzer.isBigLineSpacing(
            pair: pair,
            confidenceLevel: .high
        )
        if hasVeryBigLineSpacing {
            print("    📏 Very big line spacing detected")
            if !isPreviousLongText {
                print(
                    "    📏 Previous line is not long text - new paragraph"
                )
                return .newParagraph
            }

            if isPoetry {
                print("    📏 Poetry detected - new paragraph")

                return .newParagraph
            }
        }

        let currentText = current.firstText
        let previousText = previous.firstText

        let isCurrentList = currentText.isListTypeFirstWord
        let isPreviousList = previousText.isListTypeFirstWord

        let firstObservation = currentParagraphObservations.first!
        let previousHasIndentation = lineAnalyzer.hasIndentation(observation: previous)
        let isEqualPairX = lineAnalyzer.isEqualX(pair: pair)
        let hasBigLineSpacing = lineAnalyzer.isBigLineSpacing(pair: pair)

        // Check for list patterns.
        if isCurrentList {
            print("    📋 List pattern detected")

            // Check if the two list items have the same X coordinate.
            let isEqualFirstLineX = lineAnalyzer.isEqualX(
                pair:
                .init(
                    current: current,
                    previous: firstObservation
                )
            )

            let isFirstObservationList = firstObservation.firstText.isListTypeFirstWord

            let hasPairIndentation = lineAnalyzer.hasIndentation(
                observation: current,
                comparedObservation: previous
            )

            if isFirstObservationList {
                if hasVeryBigLineSpacing {
                    print("    📋 List pattern with high line spacing - new paragraph")
                    return .newParagraph
                }

                if isEqualFirstLineX {
                    print("    📋 List pattern with equal X")

                    if hasPairIndentation {
                        print("    📋 List pattern with equal X and indentation - new paragraph")
                        return .newParagraph
                    }

                    if !hasBigLineSpacing {
                        print("    📋 No big line spacing - line break")
                        return .lineBreak
                    }
                } else {
                    print("    📋 List pattern with different X - new paragraph")
                    return .newParagraph
                }
            } else {
                if hasPairIndentation, !isEqualFirstLineX {
                    print("    📋 List pattern with indentation and different X - new paragraph")
                    return .newParagraph
                }
            }

            let firstHasIndentation =
                (previous == firstObservation)
                    ? previousHasIndentation
                    : lineAnalyzer.hasIndentation(observation: firstObservation)

            if !isEqualPairX, firstHasIndentation {
                print(
                    "    📋 List pattern with different X and first observation has indentation - new paragraph"
                )
                return .newParagraph
            }

            if lineAnalyzer.isBigLineSpacing(pair: pair, confidenceLevel: .custom(1.1)) {
                print("    📋 List pattern with big line spacing - new paragraph")
                return .newParagraph
            }

            if previousHasIndentation, !isEqualFirstLineX {
                print("    📋 List pattern with previous indentation - new paragraph")
                return .newParagraph
            }

            print("    📋 List pattern - line break")
            return .lineBreak
        }

        /**
         If text is a letter format, like:
         ```
                                    Wednesday, 4 Octobre 1950
         My dearest Nelson,
         ```
         If `distance` > 0.45, means it may need line break, or treat as new paragraph.
         */
        if isPreviousLongText {
            let dx = previous.boundingBox.minX - current.boundingBox.minX
            let distance = dx / metrics.maxLineLength
            if distance > 0.45 {
                print("    📄 Letter format detected - new paragraph")
                return .newParagraph
            }
        }

        // 4. Priority: Large line spacing often indicates intentional gaps.
        if hasBigLineSpacing {
            let isListItem = currentText.isListTypeFirstWord
            let shouldContinuePrevious =
                isPreviousLongText && currentText.isLowercaseFirstChar && !isListItem
            if shouldContinuePrevious {
                if isPoetry {
                    print("    📄 Poetry detecte - line break")
                    return .lineBreak
                }

                print("    📄 Page continuation detected - join with space")
                return .joinWithSpaceOrNot(pair: pair)
            } else {
                print("    📏 Big line spacing - new paragraph")
                return .newParagraph
            }
        }

        let mayBeDifferentFontSize = lineAnalyzer.isDifferentFontSize(
            pair: pair, confidenceLevel: .low
        )
        let mayBeBigLineSpacing = lineAnalyzer.isBigLineSpacing(pair: pair, confidenceLevel: .low)
        let mayBeNewParagraph = mayBeDifferentFontSize || mayBeBigLineSpacing

        if !isEqualPairX {
            print("    🔗 Different X detected")

            if !isPreviousLongText {
                print("    🔗 Different X and previous line is not long text - new paragraph")
                return .newParagraph
            }

            let isPreviousAbsoluteLongText = lineAnalyzer.isLongText(observation: previous)

            if !isPreviousAbsoluteLongText {
                print("    🔗 Previous line is NOT absolute long text")
                if previousHasIndentation {
                    print("    🔗 Different X and previous line has indentation - new paragraph")
                    return .newParagraph
                }

                if isPreviousList {
                    print("    🔗 Different X and previous line is a list - new paragraph")
                    return .newParagraph
                }

                if hasBigIndentation {
                    print("    🔗 Different X and has big indentation - new paragraph")
                    return .newParagraph
                }

                print("    🔗 Different X and previous line is not absolute long text - line break")
                return .lineBreak
            } else {
                print("    🔗 Previous line is absolute long text")
                if mayBeNewParagraph {
                    print("    🔗 May be new paragraph - new paragraph")
                    return .newParagraph
                }

                print(
                    "    🔗 Different X and previous line is absolute long text - join with space or not by language"
                )
                return .joinWithSpaceOrNot(pair: pair)
            }
        } else {
            print("    🔗 Same X detected")

            if !previousHasIndentation, !isPreviousLongText {
                print("    🔗 Has no indentation and previous line is not long text")

                if mayBeNewParagraph {
                    print("    🔗 May be new paragraph - new paragraph")
                    return .newParagraph
                }

                return .lineBreak
            }
        }

        if isPreviousList {
            print("    🔗 Previous line is a list")
            if previousHasIndentation, !isPreviousLongText {
                print("    🔗 Previous line has indentation and is not long text - new paragraph")
                return .newParagraph
            }

            if mayBeNewParagraph {
                print(
                    "🔢 May be new paragraph and previous line is a list - new paragraph"
                )
                return .newParagraph
            }
        }

        // 6. Priority: Comprehensive content pattern analysis.
        if mayBeNewParagraph {
            print(
                "\n🔤 May be new paragraph, mayBeBigLineSpacing: \(mayBeBigLineSpacing), mayBeDifferentFontSize: \(mayBeDifferentFontSize)"
            )

            if mayBeBigLineSpacing, mayBeDifferentFontSize {
                print("    📏 Big line spacing and different font size - new paragraph")
                return .newParagraph
            }

            // If it might be a new paragraph and should not join with the previous line,
            // it indicates a paragraph break is needed.
            if !isPreviousLongText {
                print("🔢 May be new paragraph and previous line is not long text - new paragraph")
                return .newParagraph
            }

            if currentText.isFirstLetterUpperCase,
               lineAnalyzer.isDifferentFontSize(pair: pair, confidenceLevel: .custom(0.5)) {
                print(
                    "🔢 May be new paragraph and current line starts with uppercase letter - new paragraph"
                )
                return .newParagraph
            }
        }

        let isShortLine = lineAnalyzer.isShortLineText(observation: current)
        let isPreviousShortLine = lineAnalyzer.isShortLineText(observation: previous)

        if isShortLine, isPreviousShortLine {
            print("    🎭 Short line pattern - line break")
            return .lineBreak
        }

        if isPoetry {
            print("    🎭 Poetry detected - line break")
            return .lineBreak
        }

        // Default merge strategy.
        print("    🔗 Default merge - join with space or not by language")
        return .joinWithSpaceOrNot(pair: pair)
    }

    // swiftlint:enable function_body_length

    /// Selects the appropriate reference observation for indentation and alignment checks.
    ///
    /// This logic determines whether to compare the current observation against the paragraph's
    /// rightmost observation (`maxXObservation`) or the globally rightmost observation
    /// (`metrics.maxXLineTextObservation`), depending on the paragraph's structure.
    ///
    /// - Parameters:
    ///   - pair: The current and previous observations.
    ///   - maxXObservation: The rightmost observation in the current paragraph.
    ///   - currentParagraphObservations: All observations in the current paragraph.
    /// - Returns: The observation to be used as a reference for comparison.
    private func getComparedObservation(
        pair: OCRTextObservationPair,
        maxXObservation: VNRecognizedTextObservation,
        currentParagraphObservations: [VNRecognizedTextObservation]
    )
        -> VNRecognizedTextObservation {
        guard let firstObservation = currentParagraphObservations.first,
              let maxXLineTextObservation = metrics.maxXLineTextObservation
        else {
            print("    📏 No maxXLineTextObservation available, using maxXObservation")
            return maxXObservation
        }

        // If the first observation has indentation, it signifies a new paragraph.
        // We need to check if the entire paragraph maintains this indentation.
        let isFirstObservationHasIndentation = lineAnalyzer.hasIndentation(
            observation: firstObservation
        )

        if !isFirstObservationHasIndentation {
            print("    📏 First observation has no indentation, using maxXLineTextObservation")
            return maxXLineTextObservation
        }

        // If the previous observation is the rightmost one in the paragraph and also the first,
        // use the global `maxXLineTextObservation` as the reference.
        if pair.previous == maxXObservation, maxXObservation == firstObservation {
            print("    📏 Using maxXLineTextObservation as compared observation")
            return maxXLineTextObservation
        }

        return maxXObservation
    }

    /// Updates the paragraph context after a merge strategy has been determined.
    ///
    /// Based on the applied strategy, this function either resets the context for a new paragraph
    /// or extends the current paragraph with the new observation.
    ///
    /// - Parameters:
    ///   - strategy: The merge strategy that was applied.
    ///   - currentObservation: The observation that was just processed.
    ///   - currentParagraphObservations: An in-out reference to the list of observations in the current paragraph.
    ///   - maxXObservation: An in-out reference to the rightmost observation in the current paragraph.
    private func updateContextualTracking(
        strategy: OCRMergeStrategy,
        currentObservation: VNRecognizedTextObservation,
        currentParagraphObservations: inout [VNRecognizedTextObservation],
        maxXObservation: inout VNRecognizedTextObservation
    ) {
        switch strategy {
        case .newParagraph:
            // Start a new paragraph, resetting the tracking variables.
            currentParagraphObservations = [currentObservation]
            maxXObservation = currentObservation

        case .joinRemovingDash, .joinWithNoSpace, .joinWithSpace, .lineBreak:
            // Continue the current paragraph and update tracking.
            currentParagraphObservations.append(currentObservation)

            // Update maxXObservation if the current one has a larger X-coordinate.
            let currentMaxX = currentObservation.boundingBox.maxX
            let maxX = maxXObservation.boundingBox.maxX

            if currentMaxX > maxX {
                maxXObservation = currentObservation
            }
        }
    }
}
