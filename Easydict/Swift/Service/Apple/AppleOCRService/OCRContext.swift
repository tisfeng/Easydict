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

// MARK: - TextAnalysisContext

/// Encapsulates text analysis properties for break type determination
struct TextAnalysisContext {
    let isPrevEndPunctuation: Bool
    let isPrevLongText: Bool
    let hasIndentation: Bool
    let hasPrevIndentation: Bool
    let isBigLineSpacing: Bool
}

// MARK: - TextObservations

struct TextObservations {
    let previousTextObservation: VNRecognizedTextObservation
    let currentTextObservation: VNRecognizedTextObservation
    let nextTextObservation: VNRecognizedTextObservation?
}

// MARK: - TextContent

/// Contains text content for analysis operations
struct TextContent {
    let previousText: String
    let currentText: String
}

// MARK: - FormattingData

/// Encapsulates formatting data to reduce parameter count
struct FormattingData {
    let current: VNRecognizedTextObservation
    let previous: VNRecognizedTextObservation
    let context: TextAnalysisContext
    let textContent: TextContent
    let isEqualChineseText: Bool
    let isPrevList: Bool
    let isList: Bool
}
