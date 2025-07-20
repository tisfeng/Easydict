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

/// Main OCR text processing coordinator that handles the complete OCR text processing pipeline
///
/// This class serves as the central coordinator for processing raw OCR observations into
/// intelligently formatted text results. It applies sophisticated algorithms to:
///
/// **Core Functionality:**
/// - **Statistical Analysis**: Calculates line metrics, character widths, and spacing patterns
/// - **Text Sorting**: Orders text observations correctly (top-to-bottom, left-to-right)
/// - **Intelligent Merging**: Applies context-aware text joining based on spatial relationships
/// - **Poetry Detection**: Identifies and preserves poetic text formatting
/// - **Dash Handling**: Manages hyphenation and line continuation scenarios
/// - **Text Normalization**: Applies language-specific formatting and error correction
///
/// **Processing Pipeline:**
/// 1. Initialize basic OCR result properties
/// 2. Calculate confidence scores
/// 3. Setup comprehensive metrics calculation (集中化处理所有统计指标)
/// 4. Detect poetry patterns using calculated metrics
/// 5. Sort observations spatially using enhanced algorithms
/// 6. Apply intelligent text merging with spatial awareness
/// 7. Normalize final text output with language-specific rules
///
/// Originally ported from EZAppleService.setupOCRResult method with significant enhancements.
///
/// - Note: This class is designed to work with Apple's Vision framework text observations
public class OCRTextProcessor {
    // MARK: Internal

    lazy var lineAnalyzer = OCRLineAnalyzer(metrics: metrics)

    // MARK: - Debug Helpers

    /// Print debug information for paragraph segmentation
    func debugParagraphSegmentation(_ paragraphs: [[VNRecognizedTextObservation]]) {
        print("\n=== OCR Paragraph Segmentation Debug ===")
        for (index, paragraph) in paragraphs.enumerated() {
            print("Paragraph \(index + 1) (\(paragraph.count) lines):")
            for (lineIndex, observation) in paragraph.enumerated() {
                let text = observation.topCandidates(1).first?.string ?? ""
                let boundingBox = observation.boundingBox
                print("  Line \(lineIndex + 1): \"\(text)\" at y=\(boundingBox.origin.y)")
            }
            print("")
        }
        print("=== End Debug ===\n")
    }

    /// Process OCR observations into structured result with intelligent text merging
    ///
    /// This is the main entry point for processing raw Vision framework observations
    /// into intelligently formatted text. The method handles both simple and advanced
    /// processing modes, with the advanced mode leveraging comprehensive metrics
    /// calculation for superior text merging results.
    ///
    /// **Simple Mode (intelligentJoined = false):**
    /// - Basic text extraction and confidence calculation
    /// - Line-by-line joining with newline separators
    /// - Minimal processing overhead
    ///
    /// **Advanced Mode (intelligentJoined = true):**
    /// - Comprehensive metrics calculation (集中化指标计算)
    /// - Poetry detection and preservation
    /// - Spatial-aware text sorting
    /// - Intelligent text merging with context awareness
    /// - Language-specific normalization
    ///
    /// - Parameters:
    ///   - ocrResult: The result object to populate with processed text
    ///   - observations: Raw text observations from Vision framework
    ///   - ocrImage: Source image for spatial calculations
    ///   - intelligentJoined: Whether to enable advanced text processing
    func setupOCRResult(
        _ ocrResult: EZOCRResult,
        observations: [VNRecognizedTextObservation],
        ocrImage: NSImage,
        intelligentJoined: Bool
    ) {
        let recognizedTexts = observations.compactMap(\.firstText)

        // Set basic OCR result properties
        ocrResult.texts = recognizedTexts
        ocrResult.mergedText = recognizedTexts.joined(separator: "\n")
        ocrResult.raw = recognizedTexts

        // Initialize language detection if not already set
        if ocrResult.from == .auto {
            ocrResult.from = languageDetector.detectLanguage(text: ocrResult.mergedText)
        }

        // If intelligent joining is not enabled, return simple result
        guard intelligentJoined else { return }

        print("\nOCR objects: \(observations.formattedDescription)")

        // Sort text observations for proper order
        let sortedObservations = sortTextObservations(observations)
        print("Sorted OCR objects: \(sortedObservations.formattedDescription)")

        metrics.setupWithOCRData(
            ocrImage: ocrImage,
            language: ocrResult.from,
            observations: sortedObservations
        )
        ocrResult.confidence = CGFloat(metrics.confidence)

        // Analyze merge strategies for sorted observations
        let mergeStrategies = analyzeMergeStrategies(observations: sortedObservations)

        for (index, observation) in sortedObservations.enumerated() {
            if let mergeStrategy = observation.mergeStrategy {
                print(" [\(index)]: strategy: \(mergeStrategy), \(observation.prefix20)")
            }
        }

        //        let mergedText = performIntelligentTextMerging(sortedObservations)

        // Apply merge strategies to generate final text
        let mergedText = applyMergeStrategies(
            observations: sortedObservations,
            strategies: mergeStrategies
        )

        // Update OCR result with intelligently merged text
        ocrResult.mergedText = mergedText.trimmingCharacters(in: .whitespacesAndNewlines)
        ocrResult.texts = ocrResult.mergedText.components(
            separatedBy: OCRConstants.lineBreakText
        )

        print(
            "OCR text (\(ocrResult.from)(\(String(format: "%.2f", ocrResult.confidence))): \(ocrResult.mergedText)"
        )
    }

    // MARK: - Text Segmentation Methods

    /// Analyze OCR observations and determine merge strategies for each text pair
    ///
    /// This method provides a comprehensive analysis approach for OCR text merging by examining
    /// each consecutive pair of text observations and determining the optimal merge strategy.
    /// Unlike the complex performIntelligentTextMerging, this method focuses on clear,
    /// analyzable decisions for each text relationship.
    ///
    /// **Analysis Process:**
    /// 1. **Pair Creation**: Forms consecutive observation pairs for analysis
    /// 2. **Multi-criteria Analysis**: Examines spatial relationships, content patterns, and formatting
    /// 3. **Strategy Assignment**: Determines appropriate OCRMergeStrategy for each pair
    /// 4. **Context Tracking**: Maintains paragraph-level context for better decisions
    ///
    /// **Strategy Categories:**
    /// - `.joinWithSpace`: Normal text continuation with space
    /// - `.lineBreak`: Intentional line breaks (poetry, lists)
    /// - `.newParagraph`: Major content divisions
    /// - `.joinWithNoSpace`: Dash-preserved compound words
    /// - `.joinRemovingDash`: Hyphenation removal for word continuation
    ///
    /// - Parameter observations: Array of sorted VNRecognizedTextObservation objects
    /// - Returns: Array of OCRMergeStrategy decisions corresponding to each observation pair
    @discardableResult
    func analyzeMergeStrategies(
        observations: [VNRecognizedTextObservation]
    )
        -> [OCRMergeStrategy] {
        guard observations.count > 1 else { return [] }

        var mergeStrategies: [OCRMergeStrategy] = []

        // Dynamic tracking for context-aware decisions
        var currentParagraphObservations: [VNRecognizedTextObservation] = [observations[0]]
        var maxXLineTextObservation = observations[0] // For long text reference

        print("🔤 Starting OCR merge strategy analysis for \(observations.count) observations")

        // Process each observation starting from the second one
        for i in 1 ..< observations.count {
            let currentObservation = observations[i]
            let previousObservation = observations[i - 1]
            let pair = OCRTextObservationPair(
                current: currentObservation,
                previous: previousObservation
            )

            print("\n📋 Analyzing pair [\(i - 1) → \(i)]:")
            print("  Previous: \(previousObservation.firstText.prefix20)...")
            print("  Current:  \(currentObservation.firstText.prefix20)...")

            // Comprehensive analysis to determine merge strategy
            let mergeStrategy = determineMergeStrategy(
                pair: pair,
                maxXObservation: maxXLineTextObservation,
                currentParagraphObservations: currentParagraphObservations
            )

            mergeStrategies.append(mergeStrategy)
            currentObservation.mergeStrategy = mergeStrategy

            // Update context based on the strategy decision
            updateContextualTracking(
                strategy: mergeStrategy,
                currentObservation: currentObservation,
                currentParagraphObservations: &currentParagraphObservations,
                maxXObservation: &maxXLineTextObservation
            )

            print("  📝 Strategy: \(mergeStrategy)")
        }

        print("✅ Merge strategy analysis complete: \(mergeStrategies.count) strategies determined")
        return mergeStrategies
    }

    // MARK: Private

    private let languageManager = EZLanguageManager.shared()

    // Helper components
    private let metrics = OCRMetrics()
    private let languageDetector = AppleLanguageDetector()
    private lazy var dashHandler = OCRDashHandler(metrics: metrics)
    private lazy var textNormalizer = OCRTextNormalizer(metrics: metrics)
    private lazy var textMerger = OCRTextMerger(metrics: metrics)

    /// Perform intelligent text merging based on spatial relationships and context
    private func performIntelligentTextMerging(_ observations: [VNRecognizedTextObservation])
        -> String {
        print("Performing intelligent text merging...")
        var mergedText = ""

        for (index, textObservation) in observations.enumerated() {
            let recognizedText = textObservation.firstText

            print("\nPerforming merging, index: \(index)\n\(textObservation)")

            if index > 0 {
                let prevTextObservation = observations[index - 1]

                let textObservationPair = OCRTextObservationPair(
                    current: textObservation,
                    previous: prevTextObservation
                )

                // Analyze dash handling for this text pair
                let dashAction = dashHandler.analyzeDashHandling(textObservationPair)

                var joinedString: String

                switch dashAction {
                case .none:
                    // No dash handling needed, proceed with normal text merging
                    joinedString = textMerger.joinedString(for: textObservationPair)

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
                textObservation.joinedString = joinedString

                // 1. append joined string
                mergedText += joinedString
            }

            // 2. append line text
            mergedText += recognizedText
        }

        if Configuration.shared.enableOCRTextNormalization {
            mergedText = textNormalizer.normalizeText(mergedText)
        }

        return mergedText.trim()
    }

    /// Sort text observations by vertical position (top to bottom) and horizontal position (left to right)
    ///
    /// Uses the enhanced isNewLine algorithm for accurate line separation detection,
    /// providing better sorting accuracy than simple threshold-based approaches.
    ///
    /// **Sorting Logic:**
    /// - Groups observations on the same horizontal line using isNewLine analysis
    /// - Within same line: sorts left to right (X coordinate ascending)
    /// - Between different lines: sorts top to bottom (Y coordinate descending in Vision system)
    ///
    /// **Vision Coordinate System:**
    /// - Origin at bottom-left (0,0)
    /// - Y increases upward
    /// - Higher Y values = visually higher text (earlier in reading order)
    ///
    /// - Parameter observations: Array of text observations to sort
    /// - Returns: Sorted observations in proper reading order
    ///
    /// - Note: Currently only supports one-page OCR results.
    /// - TODO: Extend to multi-page OCR results in future versions.
    private func sortTextObservations(_ observations: [VNRecognizedTextObservation])
        -> [VNRecognizedTextObservation] {
        // 1. Sort observations by origin.y
        let sortedObservations = observations.sorted {
            $0.boundingBox.origin.y > $1.boundingBox.origin.y
        }

        // 2. Sort observations by origin.x within same line
        return sortedObservations.sorted { obj1, obj2 in
            let boundingBox1 = obj1.boundingBox
            let boundingBox2 = obj2.boundingBox

            // Create text observation pair for analysis
            let pair = OCRTextObservationPair(current: obj1, previous: obj2)

            // Use the enhanced isNewLine algorithm
            if !lineAnalyzer.isNewLine(pair: pair) {
                // Same line: sort by X coordinate (left to right)
                return boundingBox1.origin.x < boundingBox2.origin.x
            } else {
                // Different lines: sort by Y coordinate (top to bottom)
                // In Vision coordinate system, higher Y means higher position (earlier in reading order)
                return boundingBox1.origin.y > boundingBox2.origin.y
            }
        }
    }

    /// Determine the optimal merge strategy for a text observation pair
    ///
    /// This method applies comprehensive analysis to determine how two consecutive text
    /// observations should be merged. It considers multiple factors in a prioritized order
    /// to make consistent and intelligent decisions.
    ///
    /// **Analysis Priority Order:**
    /// 1. **Dash Handling**: Check for hyphenation scenarios first
    /// 2. **Font Changes**: Detect structural changes (headings, sections)
    /// 3. **Spacing Analysis**: Identify intentional gaps and line breaks
    /// 4. **Indentation**: Recognize paragraph structure changes
    /// 5. **Content Patterns**: Apply language-specific rules
    ///
    /// - Parameters:
    ///   - pair: Text observation pair to analyze
    ///   - maxXObservation: Observation with maximum X coordinate in current paragraph
    ///   - currentParagraphObservations: Current paragraph context for reference
    /// - Returns: Optimal merge strategy for this text pair
    private func determineMergeStrategy(
        pair: OCRTextObservationPair,
        maxXObservation: VNRecognizedTextObservation,
        currentParagraphObservations: [VNRecognizedTextObservation]
    )
        -> OCRMergeStrategy {
        // Check if this might be a line continuation
        if !lineAnalyzer.isNewLine(pair: pair) {
            print("    🔗 Same line continuation - join with space")
            return .joinWithSpace
        }

        // 1. Priority: Dash handling analysis
        let dashAction = dashHandler.analyzeDashHandling(pair)
        if dashAction != .none {
            let dashStrategy = OCRMergeStrategy.from(dashAction)
            print("    🔗 Dash strategy: \(dashStrategy)")
            return dashStrategy
        }

        // 2. Priority: Font size changes (structural indicators)
        if lineAnalyzer.isDifferentFontSize(pair: pair) {
            print("    🔤 Font size change detected - new paragraph")
            return .newParagraph
        }

        // 3. Priority: Large line spacing (intentional gaps)
        if lineAnalyzer.isBigLineSpacing(pair: pair) {
            // Check if this is actually a page continuation

            let comparedObservation = getComparedObservation(
                pair: pair,
                maxXObservation: maxXObservation,
                currentParagraphObservations: currentParagraphObservations
            )

            let isPreviousLongText = lineAnalyzer.isLongText(
                observation: pair.previous,
                nextObservation: pair.current,
                comparedObservation: comparedObservation
            )

            let currentText = pair.current.firstText
            let isListItem = currentText.isListTypeFirstWord

            let shouldContinuePrevious =
                isPreviousLongText && currentText.isLowercaseFirstChar && !isListItem
            if shouldContinuePrevious {
                print("    📄 Page continuation detected - join with space")
                return .joinWithSpaceOrNot(pair: pair)
            } else {
                print("    📏 Big line spacing - new paragraph")
                return .newParagraph
            }
        }

        let hasIndentation = lineAnalyzer.hasIndentation(
            observation: pair.current,
            comparedObservation: pair.previous
        )

        let isPreviousAbsoluteLongText = lineAnalyzer.isLongText(
            observation: pair.previous,
        )

        // 4. Priority: Indentation changes (paragraph structure)
        if hasIndentation {
            // Check for special cases (lists, continuations)
            let isPreviousList = pair.previous.firstText.isListTypeFirstWord
            if isPreviousList, isPreviousAbsoluteLongText {
                print("    📋 List item with indentation - join with space")
                return .joinWithSpace
            } else {
                print("    🔢 Indentation change - new paragraph")
                return .newParagraph
            }
        }

        // 5. Priority: Content pattern analysis
        return determineGeneralMergeStrategy(
            pair: pair,
            maxXObservation: maxXObservation,
            currentParagraphObservations: currentParagraphObservations
        )
    }

    /// Determine merge strategy for general (non-Chinese) text patterns
    private func determineGeneralMergeStrategy(
        pair: OCRTextObservationPair,
        maxXObservation: VNRecognizedTextObservation,
        currentParagraphObservations: [VNRecognizedTextObservation]
    )
        -> OCRMergeStrategy {
        let differentFontSize = lineAnalyzer.fontSizeDifference(pair: pair)
        let defaultFontSizeThreshold = lineAnalyzer.fontSizeThreshold(metrics.language)

        let verticalGap = pair.verticalGap
        let defaultVerticalGapThreshold = metrics.bigLineSpacingThreshold

        let comparedObservation = getComparedObservation(
            pair: pair,
            maxXObservation: maxXObservation,
            currentParagraphObservations: currentParagraphObservations
        )

        // Use maxXLineTextObservation as reference for long text comparison
        let isPreviousLongText = lineAnalyzer.isLongText(
            observation: pair.previous,
            nextObservation: pair.current,
            comparedObservation: comparedObservation
        )

        let currentText = pair.current.firstText
        let previousText = pair.previous.firstText

        let hasPreviousEndPunctuation = previousText.hasEndPunctuationSuffix

        let isCurrentList = currentText.isListTypeFirstWord
        let isPreviousList = previousText.isListTypeFirstWord

        // Check if should join with previous line based on text characteristics
        let shouldJoinWithPreviousLine = isPreviousLongText

        let differentFontSizeRate = differentFontSize / defaultFontSizeThreshold
        let mayBeDifferentFontSize = differentFontSizeRate > 0.7
        let mayBeBigLineSpacing = verticalGap / defaultVerticalGapThreshold > 0.75
        let mayBeNewParagraph = mayBeDifferentFontSize || mayBeBigLineSpacing

        // For Chinese text, we have special handling
        if metrics.language.isChinese {
            if lineAnalyzer.isEqualChineseText(pair: pair) {
                print("    🏮 Equal Chinese text - line break")
                return .lineBreak
            }
        }

        if mayBeNewParagraph {
            print(
                "\n🔤 May be new paragraph, mayBeBigLineSpacing: \(mayBeBigLineSpacing), mayBeDifferentFontSize: \(mayBeDifferentFontSize)"
            )

            if mayBeBigLineSpacing && mayBeDifferentFontSize {
                print("    📏 Big line spacing and different font size - new paragraph")
                return .newParagraph
            }

            // If may be new paragraph, and should not join with previous line, means need a paragraph break
            if !shouldJoinWithPreviousLine {
                print("🔢 May be new paragraph and previous line is not long text - new paragraph")
                return .newParagraph
            }

            if isCurrentList || isPreviousList {
                print(
                    "🔢 May be new paragraph and current or previous line is a list - new paragraph"
                )
                return .newParagraph
            }

            if differentFontSizeRate > 0.5, currentText.isFirstLetterUpperCase {
                print(
                    "🔢 May be new paragraph and current line starts with uppercase letter - new paragraph"
                )
                return .newParagraph
            }
        }

        // Check for list patterns
        if isCurrentList {
            print("    📋 List pattern detected")

            // Sometimes list may be checked incorrectly, so we check previous line is long text
            if isPreviousLongText, !hasPreviousEndPunctuation {
                print("    📋 List continuation - join with space or not by language")
                return .joinWithSpaceOrNot(pair: pair)
            }

            print("    📋 List pattern - line break")
            return .lineBreak
        }

        let isEqualAlignment = lineAnalyzer.isEqualAlignment(pair: pair)

        if !isPreviousLongText, !isEqualAlignment {
            print("    📝 Previous line is not long text and not equal alignment - line break")
            return .lineBreak
        }

        let isShortLine = lineAnalyzer.isShortLine(
            pair.current.lineWidth,
            maxLineLength: metrics.maxLineLength,
            lessRateOfMaxLength: 0.5
        )
        let isPreviousShortLine = lineAnalyzer.isShortLine(
            pair.previous.lineWidth,
            maxLineLength: metrics.maxLineLength,
            lessRateOfMaxLength: 0.5
        )

        if isShortLine, isPreviousShortLine {
            print("    🎭 Short line pattern - line break")
            return .lineBreak
        }

        print("    🔗 Default merge - join with space or not by language")
        return .joinWithSpaceOrNot(pair: pair)
    }

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

        // If first observation has indentation, means it is a new paragraph start,
        // We need to check if this paragraph all has indentation.
        let isFirstObservationHasIndentation = lineAnalyzer.hasIndentation(
            observation: firstObservation
        )

        if !isFirstObservationHasIndentation {
            print("    📏 First observation has no indentation, using maxXLineTextObservation")
            return maxXLineTextObservation
        }

        // If maxXLineTextObservation is the first observation in current paragraph,
        // use `metrics.maxXLineTextObservation` as compared observation.
        if pair.previous == maxXObservation, maxXObservation == firstObservation {
            print("    📏 Using maxXLineTextObservation as compared observation")
            return maxXLineTextObservation
        }

        return maxXObservation
    }

    /// Determine merge strategy for Chinese text patterns
    private func determineChineseMergeStrategy(pair: OCRTextObservationPair) -> OCRMergeStrategy {
        // Check for equal Chinese text patterns (poetry or structured content)
        if lineAnalyzer.isEqualChineseText(pair: pair) {
            print("    🏮 Equal Chinese text - line break")
            return .lineBreak
        }

        // Check for short poetry patterns
        let currentText = pair.current.firstText
        let previousText = pair.previous.firstText

        if lineAnalyzer.isShortPoetry(currentText), lineAnalyzer.isShortPoetry(previousText) {
            print("    🎭 Chinese poetry pattern - line break")
            return .lineBreak
        }

        // Chinese punctuation-based analysis
        if previousText.hasEndPunctuationSuffix, !currentText.isEmpty {
            let firstChar = String(currentText.prefix(1))
            if firstChar.isChinesePunctuationStart {
                print("    🔗 Chinese punctuation continuation - join with space")
                return .joinWithSpace
            } else {
                print("    📝 Chinese sentence end - new paragraph")
                return .newParagraph
            }
        }

        print("    🔗 Default Chinese merge - join with space")
        return .joinWithSpace
    }

    /// Update contextual tracking variables based on merge strategy decision
    private func updateContextualTracking(
        strategy: OCRMergeStrategy,
        currentObservation: VNRecognizedTextObservation,
        currentParagraphObservations: inout [VNRecognizedTextObservation],
        maxXObservation: inout VNRecognizedTextObservation
    ) {
        switch strategy {
        case .newParagraph:
            // Start new paragraph - reset tracking
            currentParagraphObservations = [currentObservation]
            maxXObservation = currentObservation

        case .joinRemovingDash, .joinWithNoSpace, .joinWithSpace, .lineBreak:
            // Continue current paragraph - update tracking
            currentParagraphObservations.append(currentObservation)

            // Update maxXObservation if current has larger X coordinate
            let currentMaxX = currentObservation.boundingBox.maxX
            let maxX = maxXObservation.boundingBox.maxX

            if currentMaxX > maxX {
                maxXObservation = currentObservation
            }
        }
    }

    /// Apply merge strategies to combine OCR observations into final text
    ///
    /// This method takes the analyzed merge strategies and applies them to the text observations
    /// to generate the final merged text result. It provides a clean, strategy-driven approach
    /// to text merging that's easier to understand and debug than the legacy merging logic.
    ///
    /// **Merging Process:**
    /// 1. **Start with first observation**: Begin with the first text observation
    /// 2. **Apply each strategy**: For each subsequent observation, apply the determined strategy
    /// 3. **Handle special cases**: Process dash removal and special character handling
    /// 4. **Generate separators**: Apply appropriate separators based on strategy
    /// 5. **Normalize output**: Apply final text normalization if enabled
    ///
    /// **Strategy Application:**
    /// - `.joinWithSpace`: Add space separator between texts
    /// - `.lineBreak`: Add single line break separator
    /// - `.newParagraph`: Add double line break separator
    /// - `.joinWithNoSpace`: Add dash separator (preserve compound words)
    /// - `.joinRemovingDash`: Remove dash from previous text and join directly
    ///
    /// - Parameters:
    ///   - observations: Array of sorted text observations
    ///   - strategies: Array of merge strategies corresponding to observation pairs
    /// - Returns: Final merged text string
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

        // Start with the first observation
        var currentText = observations[0].firstText
        print("📝 Starting with: '\(currentText.prefix20)...'")

        // Apply each strategy to subsequent observations
        for (index, strategy) in strategies.enumerated() {
            let nextObservation = observations[index + 1]
            let nextText = nextObservation.firstText

            print("\n📋 Applying strategy [\(index)]: \(strategy)")
            print("  Current: '\(currentText.suffix20)...'")
            print("  Next: '\(nextText.prefix20)...'")

            // Apply the strategy to combine current and next text
            let combinedText = strategy.apply(firstText: currentText, secondText: nextText)
            currentText = combinedText

            print("  Result: '\(combinedText.suffix(40))...'")
        }

        mergedText = currentText

        // Apply text normalization if enabled
        if Configuration.shared.enableOCRTextNormalization {
            print("🔧 Applying text normalization...")
            mergedText = textNormalizer.normalizeText(mergedText)
        }

        let finalText = mergedText.trim()
        print("✅ Merge complete. Final length: \(finalText.count) characters")

        return finalText
    }
}

extension String {
    /// Check if string starts with Chinese punctuation that typically continues a sentence
    var isChinesePunctuationStart: Bool {
        let chineseContinuationPunctuation = ["，", "。", "！", "？", "；", "：", "、"]
        return chineseContinuationPunctuation.contains { self.hasPrefix($0) }
    }
}
