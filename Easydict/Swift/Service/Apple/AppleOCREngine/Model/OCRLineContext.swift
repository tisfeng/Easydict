//
//  OCRLineContext.swift
//  Easydict
//
//  Created by tisfeng on 2025/6/30.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation
import Vision

// MARK: - OCRLineContext

/// Comprehensive analysis context for intelligent OCR text line merging decisions
///
/// This sophisticated data structure encapsulates all the analytical results needed to make
/// informed decisions about how two adjacent text observations should be merged. It serves
/// as a centralized repository of pre-calculated analysis results, eliminating redundant
/// calculations and ensuring consistent decision-making across the text processing pipeline.
///
/// **Core Analysis Categories:**
/// - **Spatial Analysis**: Line positioning, indentation, and spacing relationships
/// - **Content Analysis**: Text length, character patterns, and language-specific characteristics
/// - **Formatting Detection**: Poetry patterns, list structures, and special content types
/// - **Context Evaluation**: Relationship patterns between adjacent text observations
///
/// **Pre-calculated Properties:**
/// - `isPrevLongText`: Whether the previous text line fills most of the available space
/// - `hasIndentation`: Whether the current line is indented relative to the document margin
/// - `hasPrevIndentation`: Whether the previous line has indentation
/// - `isBigLineSpacing`: Whether there is significant vertical spacing between the lines
/// - `isEqualChineseText`: Whether both lines have equal character counts (Chinese poetry indicator)
///
/// **Usage Pattern:**
/// ```swift
/// let context = OCRLineContext(pair: textPair, metrics: ocrMetrics)
/// let decision = textMerger.determineMergeDecision(lineContext: context)
/// ```
///
/// Essential for maintaining consistency and performance in complex text merging algorithms.
struct OCRLineContext {
    // MARK: Lifecycle

    // MARK: - Initializer

    /// Create comprehensive OCR line context with automatic analysis
    ///
    /// Initializes the context by performing immediate analysis of the text observation pair
    /// using the provided metrics. All analytical properties are pre-calculated during
    /// initialization to ensure consistent results and optimal performance.
    ///
    /// **Initialization Process:**
    /// 1. Store the text observation pair for reference
    /// 2. Create internal line analyzer with provided metrics
    /// 3. Calculate all spatial and content analysis properties
    /// 4. Store results for immediate access by decision algorithms
    ///
    /// - Parameters:
    ///   - pair: Text observation pair containing current and previous observations
    ///   - metrics: OCR metrics containing document-wide analysis data and thresholds
    init(pair: OCRTextObservationPair, metrics: OCRMetrics) {
        self.pair = pair
        self.metrics = metrics

        // Create internal analyzer
        self.analyzer = OCRLineAnalyzer(metrics: metrics)

        // Automatically calculate properties using analyzer
        self.isPrevLongText = analyzer.isLongText(pair.previous, nextObservation: pair.current)
        self.hasPrevIndentation = analyzer.hasIndentation(pair.previous)
        self.hasIndentation = analyzer.hasIndentation(pair.current)
        self.isBigLineSpacing = analyzer.isBigLineSpacing(pair: pair)
        self.isEqualChineseText = analyzer.isEqualChineseText(pair: pair)
    }

    // MARK: Internal

    /// Text observation pair containing current and previous observations
    ///
    /// The fundamental data for analysis, containing both the current text observation
    /// being processed and its immediate predecessor for contextual comparison.
    let pair: OCRTextObservationPair

    // MARK: - Spatial Analysis Properties

    /// Whether the previous text line is considered "long" (fills most available space)
    ///
    /// Long lines typically indicate continuous prose text that flows naturally to
    /// the next line, suggesting the text should be merged with minimal separation.
    let isPrevLongText: Bool

    /// Whether the current text line has indentation relative to the document margin
    ///
    /// Indentation often indicates special formatting such as paragraph beginnings,
    /// block quotes, code blocks, or list item continuation.
    let hasIndentation: Bool

    /// Whether the previous text line has indentation relative to the document margin
    ///
    /// Previous line indentation provides context for understanding formatting
    /// patterns and making consistent merging decisions.
    let hasPrevIndentation: Bool

    /// Whether there is significant vertical spacing between the current and previous lines
    ///
    /// Large line spacing often indicates paragraph breaks, section divisions,
    /// or other major content separations that should be preserved.
    let isBigLineSpacing: Bool

    // MARK: - Language-specific Analysis Properties

    /// Whether both text lines have equal character counts (Chinese poetry indicator)
    ///
    /// Equal character counts in Chinese text often indicate classical poetry or
    /// structured verse that requires special formatting preservation.
    let isEqualChineseText: Bool

    // MARK: - Convenience Properties

    /// Convenience accessor for the current observation
    var current: VNRecognizedTextObservation { pair.current }

    /// Convenience accessor for the previous observation
    var previous: VNRecognizedTextObservation { pair.previous }

    /// Whether the current observation represents a list item
    var isList: Bool { current.firstText.isListTypeFirstWord }

    /// Whether the previous observation represents a list item
    var isPrevList: Bool { previous.firstText.isListTypeFirstWord }

    /// Text content of the current observation
    var currentText: String { current.firstText }

    /// Text content of the previous observation
    var previousText: String { previous.firstText }

    /// Whether the current text starts with an uppercase letter
    var isFirstLetterUpperCase: Bool { currentText.isFirstLetterUpperCase }

    /// Whether the current text has ending punctuation
    var hasEndPunctuation: Bool { currentText.hasEndPunctuationSuffix }

    /// Whether the previous text has ending punctuation
    var hasPrevEndPunctuation: Bool { previousText.hasEndPunctuationSuffix }

    // MARK: - Convenience Methods

    /// Check if font sizes are equal between current and previous observations
    var isEqualFontSize: Bool {
        analyzer.isEqualFontSize(pair: pair)
    }

    /// Determine Chinese poetry merge decision
    func determineChinesePoetryMerge() -> OCRMergeDecision {
        analyzer.determineChinesePoetryMerge(
            pair: pair,
            isEqualChineseText: isEqualChineseText,
            isBigLineSpacing: isBigLineSpacing
        )
    }

    /// Analyze and determine list merge decision
    ///
    /// Handles text merging decisions specifically for list-style content such as
    /// numbered lists, bullet points, and other structured list formats. This
    /// ensures proper formatting and structure preservation for list items.
    ///
    /// **List Detection Patterns:**
    /// - Numbered lists (1., 2., 3., etc.)
    /// - Bullet points (•, -, *, etc.)
    /// - Alphabetic lists (a., b., c., etc.)
    /// - Roman numerals (i., ii., iii., etc.)
    ///
    /// - Parameters:
    ///   - pair: Text observation pair containing current and previous observations
    ///   - isBigLineSpacing: Whether there is significant spacing between lines
    /// - Returns: Merge decision based on list structure requirements
    func determineListMerge() -> OCRMergeDecision {
        let isPrevList = pair.previous.firstText.isListTypeFirstWord
        let isList = pair.current.firstText.isListTypeFirstWord

        if isPrevList {
            if isList {
                return isBigLineSpacing ? .newParagraph : .lineBreak
            }

            // List ends, next is new paragraph if big spacing
            return isBigLineSpacing ? .newParagraph : .none
        }

        if isList {
            if isPrevLongText {
                return isBigLineSpacing && hasPrevEndPunctuation ? .lineBreak : .none
            }

            // New list starts
            return isBigLineSpacing ? .newParagraph : .lineBreak
        }

        return .none
    }

    /// Check if previous line length is short
    func isPrevShortLine(maxLineLength: Double, lessRateOfMaxLength: Double = 0.85) -> Bool {
        let prevLineLength = previous.boundingBox.width
        return analyzer.isShortLine(
            prevLineLength,
            maxLineLength: maxLineLength,
            lessRateOfMaxLength: lessRateOfMaxLength
        )
    }

    /// Check if previous line is less than half short
    func isPrevLessHalfShortLine(maxLineLength: Double) -> Bool {
        isPrevShortLine(maxLineLength: maxLineLength, lessRateOfMaxLength: 0.5)
    }

    // MARK: Private

    // Private analyzer for advanced operations - created internally
    private let analyzer: OCRLineAnalyzer

    private let metrics: OCRMetrics
}
