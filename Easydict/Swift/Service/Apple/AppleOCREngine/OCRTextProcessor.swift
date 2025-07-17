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

        // Segment sorted observations into paragraphs
        _ = segmentIntoParagraphs(observations: sortedObservations)

        // Perform intelligent text merging
        let mergedText = performIntelligentTextMerging(sortedObservations)

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

    /// Segment sorted OCR observations into paragraph blocks using multiple analysis criteria
    ///
    /// This sophisticated segmentation method analyzes text observations to identify natural
    /// paragraph boundaries and groups related text lines together. It uses multiple analysis
    /// criteria including indentation, line spacing, font consistency, and text length patterns
    /// to make intelligent segmentation decisions.
    ///
    /// **Segmentation Criteria:**
    /// - **Indentation Changes**: New indentation patterns often indicate new paragraphs
    /// - **Large Line Spacing**: Significant vertical gaps suggest paragraph breaks
    /// - **Font Size Changes**: Different font sizes may indicate headings or new sections
    /// - **Long Text Patterns**: Analysis of line length patterns for content flow
    /// - **Language-specific Rules**: Different handling for Chinese vs space-separated languages
    ///
    /// **Algorithm Flow:**
    /// 1. Initialize first paragraph with first observation
    /// 2. For each subsequent observation, analyze relationship with previous
    /// 3. Check for paragraph break indicators (indentation, spacing, font changes)
    /// 4. Group related observations into the same paragraph
    /// 5. Create new paragraph when break indicators are detected
    ///
    /// **Use Cases:**
    /// - Document structure analysis
    /// - Text formatting preservation
    /// - Content organization for translation
    /// - Reading flow optimization
    ///
    /// - Parameter observations: Array of sorted VNRecognizedTextObservation objects
    /// - Returns: Two-dimensional array where each sub-array represents a paragraph
    func segmentIntoParagraphs(
        observations: [VNRecognizedTextObservation]
    )
        -> [[VNRecognizedTextObservation]] {
        guard !observations.isEmpty else { return [] }

        var paragraphs: [[VNRecognizedTextObservation]] = []
        var currentParagraph: [VNRecognizedTextObservation] = [observations[0]]

        // Dynamic tracking for current paragraph characteristics
        var maxXLineTextObservation = observations[0] // For long text reference

        print("🔤 Starting paragraph segmentation for \(observations.count) observations")

        // Process each observation starting from the second one
        for i in 1 ..< observations.count {
            let currentObservation = observations[i]
            let previousObservation = observations[i - 1]
            let pair = OCRTextObservationPair(
                current: currentObservation,
                previous: previousObservation
            )

            print("\nProcessing observation [\(i)]: \(currentObservation)\n")

            let shouldStartNewParagraph = shouldCreateParagraphBreak(
                pair: pair,
                maxXObservation: previousObservation
            )

            if shouldStartNewParagraph {
                // Finalize current paragraph and start a new one
                paragraphs.append(currentParagraph)
                currentParagraph = [currentObservation]

                // Reset tracking variables for new paragraph
                maxXLineTextObservation = currentObservation

                let currentText = currentObservation.firstText.prefix(30)
                print("📄 New paragraph started: '\(currentText)...'")
            } else {
                // Add to current paragraph and update tracking variables
                currentParagraph.append(currentObservation)

                // Update maxLongLineTextObservation (observation with largest X coordinate)
                let currentMaxX = currentObservation.boundingBox.maxX
                let maxLongX = maxXLineTextObservation.boundingBox.maxX

                if currentMaxX > maxLongX {
                    maxXLineTextObservation = currentObservation
                }
            }
        }

        // Don't forget to add the last paragraph
        if !currentParagraph.isEmpty {
            paragraphs.append(currentParagraph)
        }

        print("✅ Segmentation complete: \(paragraphs.count) paragraphs identified")

        // Log paragraph summary
        for (index, paragraph) in paragraphs.enumerated() {
            let firstText = paragraph.first?.firstText.prefix(20) ?? "Empty"
            let lineCount = paragraph.count
            print("  Paragraph [\(index + 1)]: \(lineCount) lines - '\(firstText)...'")
        }

        return paragraphs
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
        // Create line analyzer for same-line detection
        let lineAnalyzer = OCRLineAnalyzer(metrics: metrics)

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

    /// Determine if a paragraph break should be created between current and previous observations
    ///
    /// This method applies multiple analysis criteria to determine if two consecutive text
    /// observations should be separated into different paragraphs. It uses a scoring system
    /// where multiple indicators can contribute to the break decision.
    ///
    /// **Break Indicators (in order of priority):**
    /// 1. **Font Size Changes**: Different font sizes suggest structural changes
    /// 2. **Large Line Spacing**: Significant vertical gaps indicate intentional breaks
    /// 3. **Indentation Changes**: New indentation patterns suggest new content blocks
    /// 4. **Text Flow Analysis**: Long text patterns and natural content flow
    /// 5. **Language-specific Rules**: Chinese vs space-separated language considerations
    ///
    /// - Parameters:
    ///   - pair: Text observation pair containing current and previous observations
    ///   - maxXTextObservation: Text observation with maximum X coordinate in current paragraph (for long text reference)
    /// - Returns: true if a paragraph break should be created, false to continue current paragraph
    private func shouldCreateParagraphBreak(
        pair: OCRTextObservationPair,
        maxXObservation: VNRecognizedTextObservation
    )
        -> Bool {
        let lineAnalyzer = OCRLineAnalyzer(metrics: metrics)

        let differentFontSize = lineAnalyzer.fontSizeDifference(pair: pair)
        let defaultFontSizeThreshold = lineAnalyzer.fontSizeThreshold(metrics.language)

        // 1. Check for font size changes (highest priority - likely headings/sections)
        if differentFontSize > defaultFontSizeThreshold {
            print("🔤 Font size change detected - creating paragraph break")
            print("\nDifferent font = \(differentFontSize), threshold = \(defaultFontSizeThreshold)")
            print("Pair: \(pair)\n")
            return true
        }

        let verticalGap = pair.verticalGap
        let defaultVerticalGapThreshold = metrics.bigLineSpacingThreshold

        // Use maxXLineTextObservation as reference for long text comparison
        let isPreviousLongText = lineAnalyzer.isLongText(
            observation: pair.previous,
            nextObservation: pair.current,
            comparedObservation: maxXObservation
        )
        let currentText = pair.current.firstText

        let hasCurrentBeginning = hasTypicalParagraphBeginning(currentText)
        let isCurrentList = currentText.isListTypeFirstWord

        // Check if should join with previous line based on text characteristics
        let shouldJoinWithPreviousLine = isPreviousLongText && !hasCurrentBeginning && !isCurrentList

        // 2. Check for big line spacing (high priority - intentional gaps)
        let isBigLineSpacing = verticalGap > defaultVerticalGapThreshold
        if isBigLineSpacing {
            print(
                "\n📏 Big berticalGap: \(verticalGap.threeDecimalString) > \(defaultVerticalGapThreshold.threeDecimalString)"
            )
            print("Pair: \(pair)\n")

            // For big line spacing, we need to check if this is a page turn
            let isTurnedPage = shouldJoinWithPreviousLine
            if isTurnedPage {
                print("📄 Page turn detected - do not create paragraph break")
                return false
            }

            print("📏 Big line spacing detected - creating paragraph break\n")

            return true
        }

        // 3. Check for indentation changes (medium-high priority)
        let currentHasIndentation = lineAnalyzer.hasIndentation(
            observation: pair.current,
            comparedObservation: pair.previous
        )

        if currentHasIndentation {
            print("\n🔤 Current line has indentation")

            // Check if previous line is a list
            let isPreviousList = pair.previous.firstText.isListTypeFirstWord
            if isPreviousList {
                print("📋 Previous line is a list")
                print("📝 Joining with previous line - no paragraph break")
                return false
            }

            print("🔢 Indentation change detected - creating paragraph break\n")

            return true
        }

        // 4. Analyze text flow patterns (medium priority)

        let mayBeDifferentFontSize = differentFontSize > defaultFontSizeThreshold * 0.7
        let mayBeBigLineSpacing = verticalGap > defaultVerticalGapThreshold * 0.7
        let mayBeNewParagraph = mayBeDifferentFontSize || mayBeBigLineSpacing

        if mayBeNewParagraph {
            if mayBeNewParagraph {
                print(
                    "\n🔤 May be new paragraph, mayBeBigLineSpacing: \(mayBeBigLineSpacing), mayBeDifferentFontSize: \(mayBeDifferentFontSize)"
                )
            }

            // If may be new paragraph, and should not join with previous line, means need a paragraph break
            if !shouldJoinWithPreviousLine {
                print("🔢 May be new paragraph detected - creating paragraph break\n")
                return true
            }
        }

        // 5. Language-specific rules
        if metrics.language.isChinese {
            return shouldCreateChineseParagraphBreak(
                pair: pair,
                lineAnalyzer: lineAnalyzer,
                maxLongLineTextObservation: maxXObservation
            )
        }

        return false
    }

    /// Apply Chinese-specific paragraph break rules
    ///
    /// Chinese text has different formatting conventions and may require
    /// different analysis approaches for paragraph detection.
    ///
    /// - Parameters:
    ///   - pair: Text observation pair to analyze
    ///   - lineAnalyzer: OCR line analyzer for text analysis
    ///   - minXLineTextObservation: Text observation with minimum X coordinate in current paragraph (for indentation reference)
    ///   - maxLongLineTextObservation: Text observation with maximum width in current paragraph (for long text reference)
    /// - Returns: true if a paragraph break should be created for Chinese text
    private func shouldCreateChineseParagraphBreak(
        pair: OCRTextObservationPair,
        lineAnalyzer: OCRLineAnalyzer,
        maxLongLineTextObservation: VNRecognizedTextObservation
    )
        -> Bool {
        // Check for equal Chinese text patterns (poetry or structured content)
        if lineAnalyzer.isEqualChineseText(pair: pair) {
            // Equal Chinese text usually belongs to the same paragraph/structure
            return false
        }

        // Check for short poetry patterns
        let currentText = pair.current.firstText
        let previousText = pair.previous.firstText

        if lineAnalyzer.isShortPoetry(currentText), lineAnalyzer.isShortPoetry(previousText) {
            // Short poetry lines usually belong together unless there's big spacing
            return lineAnalyzer.isBigLineSpacing(pair: pair)
        }

        // Chinese punctuation-based analysis with context-aware indentation check
        if previousText.hasEndPunctuationSuffix, !currentText.isEmpty {
            // If previous line ends with punctuation, might be paragraph end
            // Use minXLineTextObservation as reference for indentation comparison
            let isCurrentStartsWithIndentation = lineAnalyzer.hasIndentation(
                observation: pair.current,
                comparedObservation: pair.previous
            )
            return isCurrentStartsWithIndentation
        }

        return false
    }

    /// Check if text has typical paragraph ending characteristics
    private func hasTypicalParagraphEnding(_ text: String) -> Bool {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Empty or very short lines might be paragraph separators
        if trimmedText.isEmpty || trimmedText.count < 3 {
            return true
        }

        // Lines ending with punctuation (except commas and semicolons)
        if text.hasEndPunctuationSuffix {
            let endPunctuation = [".", "!", "?", "。", "！", "？"]
            return endPunctuation.contains { trimmedText.hasSuffix($0) }
        }

        return false
    }

    /// Check if text has typical paragraph beginning characteristics
    private func hasTypicalParagraphBeginning(_ text: String) -> Bool {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedText.isEmpty {
            return false
        }

        // Check for capitalized start (for English-like languages)
        if languageManager.isLanguageWordsNeedSpace(metrics.language) {
            return trimmedText.isFirstLetterUpperCase
        }

        // For Chinese and other languages, use basic pattern detection
        return false
    }
}
