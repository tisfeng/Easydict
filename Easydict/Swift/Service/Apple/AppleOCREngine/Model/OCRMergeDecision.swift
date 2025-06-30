//
//  OCRMergeDecision.swift
//  Easydict
//
//  Created by tisfeng on 2025/6/30.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

// MARK: - OCRMergeDecision

/// Represents merge decisions for text merging operations
enum OCRMergeDecision {
    /// No special formatting needed
    case none

    /// Need line break
    case lineBreak

    /// Need new paragraph
    case newParagraph

    // MARK: Internal

    /// Whether a line break should be inserted
    var needLineBreak: Bool {
        switch self {
        case .none:
            return false
        case .lineBreak, .newParagraph:
            return true
        }
    }

    /// Whether a new paragraph should be started
    var isNewParagraph: Bool {
        switch self {
        case .lineBreak, .none:
            return false
        case .newParagraph:
            return true
        }
    }

    /// Create merge decision from boolean flags
    static func from(needLineBreak: Bool, isNewParagraph: Bool) -> OCRMergeDecision {
        if isNewParagraph {
            return .newParagraph
        } else if needLineBreak {
            return .lineBreak
        } else {
            return .none
        }
    }
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
