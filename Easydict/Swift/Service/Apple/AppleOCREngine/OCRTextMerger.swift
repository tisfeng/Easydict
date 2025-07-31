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
            print("  Previous: \(previous.firstText.prefix20)")
            print("  Current:  \(current.firstText.prefix20)")

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
            print("    🔤 Font size change detected")
            return .newParagraph
        }

        // The first observation in the current paragraph, used to determine indentation and alignment.
        let firstObservation = currentParagraphObservations.first!
        let isFirstHasIndentation = lineAnalyzer.hasIndentation(
            observation: firstObservation
        )

        let current = pair.current
        let previous = pair.previous

        let currentText = current.firstText
        let previousText = previous.firstText

        let hasBigIndentation = lineAnalyzer.hasIndentation(
            observation: current,
            comparedObservation: previous,
            confidence: .custom(2.0)
        )

        let comparedObservation = isFirstHasIndentation ? maxXObservation : metrics.maxXObservation

        /// Relative long, means previous line is long text compared to comparedObservation
        let isPreviousLongText = lineAnalyzer.isLongText(
            observation: previous,
            nextObservation: current,
            comparedObservation: comparedObservation
        )

        // 4. Priority: Check for big indentation, used to indicate new paragraphs.
        if hasBigIndentation {
            print("    📏 Big indentation detected")
            if !isPreviousLongText {
                print("    📏 Big indentation and previous line is not long text - new paragraph")
                return .newParagraph
            }
        }

        // For poetry, we only need to decide between line break and new paragraph.
        let isPoetry = metrics.isPoetry

        let hasVeryBigLineSpacing = lineAnalyzer.isBigLineSpacing(pair: pair, confidence: .high)

        // 5. Priority: Check for very big line spacing
        if hasVeryBigLineSpacing {
            print("    📏 Very big line spacing detected")

            // If poetry has very big line spacing, then new paragraph.
            if isPoetry {
                print("    📏 Very big line spacing in poetry - line break")
                return .newParagraph
            }

            if !isPreviousLongText {
                print("    📏 Previous line is not long text - new paragraph")
                return .newParagraph
            }

            if previousText.hasEndPunctuationSuffix, !currentText.isFirstCharLowercase {
                print("    📏 Previous line ends with punctuation and current starts with uppercase - new paragraph")
                return .newParagraph
            }
        }

        // 6. Priority: For other poetry cases, just line breaks.
        if isPoetry {
            print("    🎭 Poetry detected - line break")
            return .lineBreak
        }

        let isCurrentList = currentText.isListTypeFirstWord
        let isPreviousList = previousText.isListTypeFirstWord

        let isPrevHasIndentation = (previous == firstObservation)
            ? isFirstHasIndentation
            : lineAnalyzer.hasIndentation(observation: previous)

        let isEqualPairX = lineAnalyzer.isEqualX(pair: pair)
        let hasBigLineSpacing = lineAnalyzer.isBigLineSpacing(pair: pair)

        let hasPairIndentation = lineAnalyzer.hasIndentation(
            observation: current,
            comparedObservation: previous
        )

        // 7. Priority: Check if the current line is a list item.
        if isCurrentList {
            print("    📋 List pattern detected")

            let firstPair = OCRTextObservationPair(current: current, previous: firstObservation)

            /// If current list line X is equal to first observation X
            let isEqualFirstLineX = lineAnalyzer.isEqualX(pair: firstPair)

            let isFirstObservationList = firstObservation.firstText.isListTypeFirstWord

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

            if !isEqualPairX, isFirstHasIndentation {
                print(
                    "    📋 List pattern with different X and first observation has indentation - new paragraph"
                )
                return .newParagraph
            }

            if isPrevHasIndentation, !isEqualFirstLineX {
                print("    📋 List pattern with previous indentation - new paragraph")
                return .newParagraph
            }

            print("    📋 List pattern - line break")
            return .lineBreak
        }

        /**
         Special case:

         If text is a letter format, we may need new paragraph when the distance between
         previous and current line is too far.

         If `distance` > 0.45, means it may need line break, or treat as new paragraph.

         Example:

         ```
                                    Wednesday, 4 Octobre 1950
         My dearest Nelson,
         ```
         */
        if isPreviousLongText {
            let dx = previous.boundingBox.minX - current.boundingBox.minX
            let distance = dx / metrics.maxLineLength
            if distance > 0.45 {
                print("    📄 Letter format detected - new paragraph")
                return .newParagraph
            }
        }

        // 8. Priority: Large line spacing often indicates intentional gaps.
        if hasBigLineSpacing {
            let shouldJoin = isPreviousLongText && currentText.isFirstCharLowercase && !isCurrentList
            if shouldJoin {
                print("    📄 Page continuation detected - join with space")
                return .joinWithSpaceOrNot(pair: pair)
            } else {
                print("    📏 Big line spacing - new paragraph")
                return .newParagraph
            }
        }

        let mayBeDifferentFontSize = lineAnalyzer.isDifferentFontSize(pair: pair, confidence: .low)
        let mayBeBigLineSpacing = lineAnalyzer.isBigLineSpacing(pair: pair, confidence: .low)
        let mayBeNewParagraph = mayBeDifferentFontSize || mayBeBigLineSpacing
        if mayBeNewParagraph {
            print(
                "    🔤 May be new paragraph detected: mayBeBigLineSpacing: \(mayBeBigLineSpacing), mayBeDifferentFontSize: \(mayBeDifferentFontSize)"
            )
        }

        // Special case: Check for Chinese pairs.
        let equalChinesePair = lineAnalyzer.isEqualChinesePair(pair)
        if equalChinesePair {
            print("    🔗 Equal Chinese pair - line break")
            return .lineBreak
        }

        // Special case: Classical Chinese long text with end punctuation.
        if metrics.language == .classicalChinese {
            if isPreviousLongText, previousText.hasEndPunctuationSuffix,
               !isPrevHasIndentation, isEqualPairX {
                print("    🎭 Classical Chinese long text with end punctuation - line break")
                return .lineBreak
            }
        }

        let isPrevAbsoluteLongText = lineAnalyzer.isLongText(observation: previous, nextObservation: current)

        // 9. Priority: Check for different X coordinates.
        if !isEqualPairX {
            print("    🔗 Different X detected")

            if !isPreviousLongText {
                print("    🔗 Different X and previous line is not long text - new paragraph")
                return .newParagraph
            }

            if !isPrevAbsoluteLongText {
                print("    🔗 Previous line is NOT absolute long text")
                if isPrevHasIndentation {
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
                // Different X, and previous line is absolute long text

                /**
                 Special case:

                 If different X, previous line is a list and long, current line has pair indentation,
                 it may be not a new paragraph.

                 Example:

                 ```
                 The rules are as follows:

                 1. I am a girl with severe depression
                    and severe anxiety.
                 2. I am the second daughter in my
                    family, 10 years younger than my
                 ```
                 */

                if hasPairIndentation, !isPreviousList {
                    // return lineBreakOrParagraph(mayBeNewParagraph)
                    print(
                        "    🔗 Has pair indentation, previous line is absolute long and NOT list - new paragraph"
                    )
                    return .newParagraph
                }

                /**
                 Special case:

                 If has different X,  previous and current line both have indentation,
                 we should not join them, because it may be a new paragraph.

                 Example:

                 ```
                                V. SECURITY CHALLENGES AND OPPORTUNITIES
                    In the following, we discuss existing security challenges
                 and shed light on possible security opportunities and research
                 ```
                 */

                let hasIndentation = lineAnalyzer.hasIndentation(observation: current)
                if hasIndentation, isPrevHasIndentation, !hasPairIndentation {
                    print(
                        "    🔗 Different X, previous and current line both have indentation - new paragraph"
                    )
                    return .newParagraph
                }

                print(
                    "    🔗 Different X and previous line is absolute long text - join with space or not by language"
                )
                return .joinWithSpaceOrNot(pair: pair)
            }
        } else {
            print("    🔗 Same X detected")

            /**
             Special case: Check if need new paragraph when previous is a list.

             ```
                   III. IMPLICATIONS OF HTTP/2 FEATURES ON 5G SBA
                   HTTP/2 introduces multiple features that we explore
             hereafter and discuss the security impact of their possible
             ```
             */
            if isPreviousList {
                if mayBeNewParagraph, !currentText.isFirstCharLowercase {
                    print(
                        "  📋 Previous is list and may be new paragraph, and current is not lowercase - new paragraph"
                    )
                    return .newParagraph
                }
            }

            if !isPreviousLongText {
                print("    🔗 Previous line is not long text - line break or new paragraph")
                return lineBreakOrParagraph(mayBeNewParagraph)
            } else {
                // If previous line is the first observation, cuase isPreviousLongText is always true.
                let shouldLineBreak = previous == firstObservation && !isPrevHasIndentation && !isPrevAbsoluteLongText
                if shouldLineBreak {
                    print("    🔗 Previous is first observation and short - line break or new paragraph")
                    return lineBreakOrParagraph(mayBeNewParagraph)
                }

                let isShortLine = lineAnalyzer.isShortLine(observation: current)
                let isPreviousShortLine = lineAnalyzer.isShortLine(observation: previous)

                // Special case: Check for short lines.
                if isShortLine, isPreviousShortLine {
                    print("    🎭 Short line pattern - line break")
                    return .lineBreak
                }
            }
        }

        // Special case: Check for big line spacing and different font size.
        if mayBeBigLineSpacing, mayBeDifferentFontSize {
            print("    📏 Big line spacing and different font size - new paragraph")
            return .newParagraph
        }

        // Default merge strategy.
        print("    🔗 Default merge - join with space or not by language")
        return .joinWithSpaceOrNot(pair: pair)
    }

    // swiftlint:enable function_body_length

    /// Determines whether to use a line break or start a new paragraph based on the context.
    private func lineBreakOrParagraph(_ shouldStartNewParagraph: Bool) -> OCRMergeStrategy {
        shouldStartNewParagraph ? .newParagraph : .lineBreak
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
        case .lineBreak, .newParagraph:
            // Start a new paragraph, resetting the tracking variables.
            currentParagraphObservations = [currentObservation]
            maxXObservation = currentObservation

        case .joinRemovingDash, .joinWithNoSpace, .joinWithSpace:
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
