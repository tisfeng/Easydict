//
//  OCRContext.swift
//  Easydict
//
//  Created by tisfeng on 2025/6/26.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation
import Vision

// MARK: - OCRContext

/// Encapsulates OCR context data for text merging operations
struct OCRContext {
    let ocrImage: NSImage
    let language: Language
    let isPoetry: Bool
    let singleAlphabetWidth: Double
    let charCountPerLine: Double
    let minLineHeight: Double
    let averageLineHeight: Double
    let maxLineLength: Double
    let textObservations: [VNRecognizedTextObservation]
    let minXLineTextObservation: VNRecognizedTextObservation?
    let maxCharacterCountLineTextObservation: VNRecognizedTextObservation?
    let maxLongLineTextObservation: VNRecognizedTextObservation?
}

// MARK: - OCRLineContext

/// Comprehensive OCR line context data for text merging
struct OCRLineContext {
    // MARK: Lifecycle

    // MARK: - Initializer

    /// Create OCRLineContext with automatic analysis
    /// - Parameters:
    ///   - current: Current text observation
    ///   - previous: Previous text observation
    ///   - context: OCR context for creating internal analyzer
    init(
        current: VNRecognizedTextObservation,
        previous: VNRecognizedTextObservation,
        context: OCRContext
    ) {
        self.current = current
        self.previous = previous

        // Create internal analyzer
        self.analyzer = OCRLineAnalyzer(context: context)

        // Automatically calculate properties using analyzer
        self.isPrevLongText = analyzer.isLongTextObservation(previous, isStrict: false)
        self.hasIndentation = analyzer.hasIndentationOfTextObservation(current)
        self.hasPrevIndentation = analyzer.hasIndentationOfTextObservation(previous)
        self.isBigLineSpacing = analyzer.isBigSpacingLineOfTextObservation(
            current: current,
            previous: previous,
            greaterThanLineHeightRatio: 1.0
        )
        self.isEqualChineseText = analyzer.isEqualChineseTextObservation(
            current: current,
            previous: previous
        )
    }

    // MARK: Internal

    let current: VNRecognizedTextObservation
    let previous: VNRecognizedTextObservation

    // Text analysis properties
    let isPrevLongText: Bool
    let hasIndentation: Bool
    let hasPrevIndentation: Bool
    let isBigLineSpacing: Bool

    // Specific formatting flags
    let isEqualChineseText: Bool

    var isList: Bool { current.text.isListTypeFirstWord }
    var isPrevList: Bool { previous.text.isListTypeFirstWord }

    // Computed text properties for convenience
    var currentText: String { current.text }
    var previousText: String { previous.text }

    var isFirstLetterUpperCase: Bool { currentText.isFirstLetterUpperCase }

    var hasEndPunctuation: Bool { currentText.hasEndPunctuationSuffix }
    var hasPrevEndPunctuation: Bool { previousText.hasEndPunctuationSuffix }

    // MARK: - Convenience Methods

    /// Check if font sizes are equal between current and previous observations
    var isEqualFontSize: Bool {
        analyzer.checkEqualFontSize(current: current, previous: previous)
    }

    /// Handle Chinese poetry analysis
    func handleChinesePoetry() -> (shouldWrap: Bool, isNewParagraph: Bool) {
        analyzer.handleChinesePoetry(
            currentText: currentText,
            previousText: previousText,
            isEqualChineseText: isEqualChineseText,
            isBigLineSpacing: isBigLineSpacing
        )
    }

    /// Handle list formatting analysis
    func handleListFormatting() -> (needLineBreak: Bool, isNewParagraph: Bool) {
        analyzer.handleListFormatting(
            isPrevList: isPrevList,
            isList: isList,
            isBigLineSpacing: isBigLineSpacing
        )
    }

    /// Check if previous line length is short
    func isPrevShortLine(maxLineLength: Double, lessRateOfMaxLength: Double = 0.85) -> Bool {
        let prevLineLength = previous.boundingBox.width
        return analyzer.isShortLineLength(
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

// MARK: - OCRConstants

/// Constants used for OCR text processing
enum OCRConstants {
    static let lineBreakText = "\n"
    static let paragraphBreakText = "\n\n"
    static let indentationCharacterCount: Double = 2.0
    static let paragraphLineHeightRatio: Double = 1.5
    static let shortPoetryCharacterCountOfLine = 12
    static let chineseDifferenceFontThreshold: Double = 3.0
    static let englishDifferenceFontThreshold: Double = 5.0
}
