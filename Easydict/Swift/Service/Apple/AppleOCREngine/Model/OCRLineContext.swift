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

/// Comprehensive OCR line context data for text merging
struct OCRLineContext {
    // MARK: Lifecycle

    // MARK: - Initializer

    /// Create OCRLineContext with automatic analysis
    /// - Parameters:
    ///   - textObservationPair: Pair of current and previous text observations
    ///   - metrics: OCR metrics for creating internal analyzer
    init(pair: OCRTextObservationPair, metrics: OCRMetrics) {
        self.pair = pair

        // Create internal analyzer
        self.analyzer = OCRLineAnalyzer(metrics: metrics)

        // Automatically calculate properties using analyzer
        self.isPrevLongText = analyzer.isLongText(pair.previous)
        self.hasIndentation = analyzer.hasIndentation(pair.current)
        self.hasPrevIndentation = analyzer.hasIndentation(pair.previous)
        self.isBigLineSpacing = analyzer.isBigLineSpacing(pair, greaterThanLineHeightRatio: 1.0)
        self.isEqualChineseText = analyzer.isEqualChineseText(pair)
    }

    // MARK: Internal

    /// Pair of current and previous text observations
    let pair: OCRTextObservationPair

    // Text analysis properties
    let isPrevLongText: Bool
    let hasIndentation: Bool
    let hasPrevIndentation: Bool
    let isBigLineSpacing: Bool

    // Specific formatting flags
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
        analyzer.isEqualFontSize(pair)
    }

    /// Determine Chinese poetry merge decision
    func determineChinesePoetryMerge() -> OCRMergeDecision {
        analyzer.determineChinesePoetryMerge(
            pair,
            isEqualChineseText: isEqualChineseText,
            isBigLineSpacing: isBigLineSpacing
        )
    }

    /// Determine list merge decision
    func determineListMerge() -> OCRMergeDecision {
        analyzer.determineListMerge(pair, isBigLineSpacing: isBigLineSpacing)
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
}
