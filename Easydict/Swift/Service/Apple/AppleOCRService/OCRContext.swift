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

/// Comprehensive OCR formatting data that includes all context needed for text merging
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

/// Constants used for Apple OCR text processing
enum OCRConstants {
    static let lineBreakText = "\n"
    static let paragraphBreakText = "\n\n"
    static let indentationCharacterCount: Double = 2.0
    static let paragraphLineHeightRatio: Double = 1.5
    static let shortPoetryCharacterCountOfLine = 12
    static let chineseDifferenceFontThreshold: Double = 3.0
    static let englishDifferenceFontThreshold: Double = 5.0
}
