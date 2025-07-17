//
//  OCRMergeDecision.swift
//  Easydict
//
//  Created by tisfeng on 2025/6/30.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

// MARK: - OCRMergeDecision

/// Strategic decisions for merging adjacent text observations in OCR processing
///
/// This enumeration represents the three fundamental strategies for combining text
/// observations based on their spatial relationships, content characteristics, and
/// formatting requirements. Each decision type produces different output formatting
/// to preserve the original document's structure and readability.
///
/// **Decision Types:**
/// - **None**: Normal text continuation with space separation
/// - **Line Break**: Intentional line separation while maintaining text flow
/// - **New Paragraph**: Major content division requiring paragraph separation
///
/// **Impact on Output:**
/// - `.none`: "word1 word2" (space-separated continuation)
/// - `.lineBreak`: "word1\nword2" (single line break)
/// - `.newParagraph`: "word1\n\nword2" (double line break for paragraph)
///
/// **Usage Context:**
/// Used throughout the text merging pipeline to make consistent formatting
/// decisions that preserve document structure while ensuring readability.
enum OCRMergeDecision {
    /// Normal text continuation - join with space separation
    ///
    /// Used when text observations represent continuous prose that should flow
    /// naturally together. This is the most common case for regular paragraph text.
    case none

    /// Intentional line break - preserve line structure
    ///
    /// Used when the original document has intentional line breaks that should be
    /// preserved, such as in poetry, lists, or formatted text blocks.
    case lineBreak

    /// Major content division - create new paragraph
    ///
    /// Used when there is a significant content separation requiring paragraph-level
    /// formatting, such as between different topics or major document sections.
    case newParagraph

    // MARK: Internal

    /// Determine if any form of line break should be inserted
    ///
    /// Returns true for both `.lineBreak` and `.newParagraph` decisions,
    /// indicating that some form of line separation is needed rather than
    /// simple space-based text continuation.
    var needLineBreak: Bool {
        switch self {
        case .none:
            return false
        case .lineBreak, .newParagraph:
            return true
        }
    }

    /// Determine if a new paragraph should be started
    ///
    /// Returns true only for `.newParagraph` decisions, indicating that
    /// a major content division requires paragraph-level separation with
    /// additional spacing (typically double line breaks).
    var isNewParagraph: Bool {
        switch self {
        case .lineBreak, .none:
            return false
        case .newParagraph:
            return true
        }
    }

    /// Factory method to create merge decision from boolean flags
    ///
    /// Convenience method for converting traditional boolean-based decision flags
    /// into the structured merge decision enumeration. Useful for migrating from
    /// legacy code or interfacing with systems that use boolean flags.
    ///
    /// **Decision Logic:**
    /// - If `isNewParagraph` is true: Returns `.newParagraph`
    /// - Else if `needLineBreak` is true: Returns `.lineBreak`
    /// - Otherwise: Returns `.none`
    ///
    /// - Parameters:
    ///   - needLineBreak: Whether any form of line break is needed
    ///   - isNewParagraph: Whether a new paragraph should be started
    /// - Returns: Corresponding merge decision enumeration value
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
    static let englishDifferenceFontThreshold: Double = 4.0
}
