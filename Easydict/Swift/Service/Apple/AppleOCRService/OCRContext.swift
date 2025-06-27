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

/// Encapsulates context for a specific line of OCR text, including formatting and analysis properties
struct OCRLineContext {
    let current: VNRecognizedTextObservation
    let previous: VNRecognizedTextObservation

    // Text analysis properties
    let isPrevEndPunctuation: Bool
    let isPrevLongText: Bool
    let hasIndentation: Bool
    let hasPrevIndentation: Bool
    let isBigLineSpacing: Bool

    // Specific formatting flags
    let isEqualChineseText: Bool
    let isPrevList: Bool
    let isList: Bool

    // Computed text properties for convenience
    var currentText: String { current.text }
    var previousText: String { previous.text }
}

// MARK: - OCRConstants

/// Constants used for OCR text processing and merging
enum OCRConstants {
    /// Line break character
    static let lineBreakText = "\n"

    /// Paragraph break characters
    static let paragraphBreakText = "\n\n"

    /// Indentation text (currently empty)
    static let indentationText = ""

    /// Ratio threshold for paragraph line height detection, default is 1.5
    static let paragraphLineHeightRatio: CGFloat = 1.5

    /// Maximum character count per line for short poetry detection, default is 12
    static let shortPoetryCharacterCountOfLine = 12

    /// Indentation character count, default is 1.2
    static let indentationCharacterCount = 1.2

    /// Chinese difference font threshold, default is 3
    /// Chinese fonts seem to be more precise.
    static let chineseDifferenceFontThreshold = 3.0

    /// English difference font threshold, default is 5
    /// Note: English uppercase-lowercase font size is not precise, so threshold should a bit large.
    static let englishDifferenceFontThreshold = 5.0
}
