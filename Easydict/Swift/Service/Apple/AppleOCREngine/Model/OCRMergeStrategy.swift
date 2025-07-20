//
//  OCRMergeStrategy.swift
//  Easydict
//
//  Created by tisfeng on 2025/7/17.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

// MARK: - OCRMergeStrategy

/// Strategy enumeration for merging two OCR text observations
///
/// This enumeration defines how two consecutive OCR text observations should be combined,
/// addressing both regular text merging and special dash character handling scenarios.
///
/// **Core Strategies:**
/// - **Regular Merging**: Standard text continuation with space or line breaks
/// - **Dash Handling**: Special processing for hyphenated words across lines
///
/// **Examples:**
/// ```
/// .joinWithSpace: "word1 word2"
/// .lineBreak: "word1\nword2"
/// .newParagraph: "word1\n\nword2"
/// .joinWithNoSpace: "word1-word2"
/// .joinRemovingDash: "word1word2"
/// ```
enum OCRMergeStrategy: CustomStringConvertible {
    /// Intentional line break preservation
    ///
    /// Used when the original document has intentional line breaks that should be
    /// preserved, such as in poetry, lists, or formatted text blocks.
    ///
    /// **Output**: "word1\nword2"
    case lineBreak

    /// Major content division with new paragraph
    ///
    /// Used when there is significant content separation requiring paragraph-level
    /// formatting, such as between different topics or major document sections.
    ///
    /// **Output**: "word1\n\nword2"
    case newParagraph

    /// Normal text continuation with space separation
    ///
    /// Used for continuous prose that should flow naturally together.
    /// This is the most common case for regular paragraph text.
    /// For English-like languages, this is the default behavior.
    ///
    /// **Output**: "word1 word2"
    case joinWithSpace

    /// Join text preserving the dash character
    ///
    /// Applied when the dash serves a meaningful purpose such as:
    /// - Compound words (e.g., "well-known")
    /// - Date ranges (e.g., "2020-2023")
    /// - Technical terms (e.g., "UTF-8")
    /// - Languages do not require space between words, such as Chinese, Japanese, etc.
    ///
    /// **Output**: "word1-word2"
    case joinWithNoSpace

    /// Join text removing the dash character
    ///
    /// Used for line-break hyphenation where the dash was inserted
    /// only for typographical purposes and should be removed:
    /// - "under-\nstanding" → "understanding"
    /// - "reconstruct-\ning" → "reconstructing"
    ///
    /// **Output**: "word1word2"
    case joinRemovingDash

    // MARK: Internal

    /// Determine if any form of line break should be inserted
    var needsLineBreak: Bool {
        switch self {
        case .joinRemovingDash, .joinWithNoSpace, .joinWithSpace:
            return false
        case .lineBreak, .newParagraph:
            return true
        }
    }

    /// Determine if a new paragraph should be created
    var createsNewParagraph: Bool {
        switch self {
        case .joinRemovingDash, .joinWithNoSpace, .joinWithSpace, .lineBreak:
            return false
        case .newParagraph:
            return true
        }
    }

    /// Determine if dash character should be preserved
    var preservesDash: Bool {
        switch self {
        case .joinRemovingDash, .joinWithSpace, .lineBreak, .newParagraph:
            return false
        case .joinWithNoSpace:
            return true
        }
    }

    /// Determine if text should be joined without separator
    var joinsText: Bool {
        switch self {
        case .joinWithSpace, .lineBreak, .newParagraph:
            return false
        case .joinRemovingDash, .joinWithNoSpace:
            return true
        }
    }

    var description: String {
        switch self {
        case .lineBreak:
            return "lineBreak"
        case .newParagraph:
            return "newParagraph"
        case .joinWithSpace:
            return "joinWithSpace"
        case .joinWithNoSpace:
            return "joinWithNoSpace"
        case .joinRemovingDash:
            return "joinRemovingDash"
        }
    }

    // MARK: - Factory Methods

    /// Create merge strategy from legacy OCRMergeDecision
    ///
    /// Provides compatibility with existing OCRMergeDecision enumeration
    /// by converting legacy merge decisions to the new unified strategy.
    ///
    /// - Parameter decision: Legacy merge decision to convert
    /// - Returns: Corresponding merge strategy
    static func from(_ decision: OCRMergeDecision) -> OCRMergeStrategy {
        switch decision {
        case .none:
            return .joinWithSpace
        case .lineBreak:
            return .lineBreak
        case .newParagraph:
            return .newParagraph
        }
    }

    /// Create merge strategy from legacy DashHandlingAction
    ///
    /// Provides compatibility with existing DashHandlingAction enumeration
    /// by converting legacy dash actions to the new unified strategy.
    ///
    /// - Parameter action: Legacy dash handling action to convert
    /// - Returns: Corresponding merge strategy
    static func from(_ action: DashHandlingAction) -> OCRMergeStrategy {
        switch action {
        case .none:
            return .joinWithSpace
        case .keepDashAndJoin:
            return .joinWithNoSpace
        case .removeDashAndJoin:
            return .joinRemovingDash
        }
    }

    /// Create merge strategy from both legacy types
    ///
    /// Combines OCRMergeDecision and DashHandlingAction to create a unified strategy.
    /// If dash handling is needed, it takes priority; otherwise uses merge decision.
    ///
    /// - Parameters:
    ///   - decision: Text merging decision
    ///   - dashAction: Dash handling action
    /// - Returns: Unified merge strategy
    static func from(decision: OCRMergeDecision, dashAction: DashHandlingAction) -> OCRMergeStrategy {
        // Dash handling takes priority if present
        switch dashAction {
        case .none:
            return from(decision)
        case .keepDashAndJoin:
            return .joinWithNoSpace
        case .removeDashAndJoin:
            return .joinRemovingDash
        }
    }

    static func joinWithSpaceOrNot(pair: OCRTextObservationPair) -> OCRMergeStrategy {
        joinWithSpaceOrNot(
            firstText: pair.previous.firstText.lastWord,
            secondText: pair.current.firstText.firstWord
        )
    }

    /// Create merge strategy based on language context
    ///
    /// - Note: Maybe the joinedText language is different from OCR entire text language.
    static func joinWithSpaceOrNot(
        firstText: String,
        secondText: String,
    )
        -> OCRMergeStrategy {
        let joinedText = firstText + secondText
        // Determine language context
        let language = AppleLanguageDetector().detectLanguage(text: joinedText)
        if EZLanguageManager.shared().isLanguageWordsNeedSpace(language) {
            return .joinWithSpace
        }
        return .joinWithNoSpace
    }

    // MARK: - Output Generation

    /// Generate the appropriate separator string for this merge strategy
    ///
    /// - Returns: Separator string for text joining
    func separatorString() -> String {
        switch self {
        case .joinWithSpace:
            return " "
        case .lineBreak:
            return OCRConstants.lineBreakText
        case .newParagraph:
            return OCRConstants.paragraphBreakText
        case .joinWithNoSpace:
            return "-"
        case .joinRemovingDash:
            return ""
        }
    }

    /// Apply the merge strategy to join two text strings
    ///
    /// - Parameters:
    ///   - firstText: The first text string
    ///   - secondText: The second text string
    /// - Returns: Combined text according to the merge strategy
    func apply(firstText: String, secondText: String) -> String {
        switch self {
        case .joinWithSpace, .lineBreak, .newParagraph:
            return firstText + separatorString() + secondText
        case .joinWithNoSpace:
            return firstText + secondText
        case .joinRemovingDash:
            // Remove trailing dash from first text if present
            let cleanFirstText = firstText.hasSuffix("-") ? String(firstText.dropLast()) : firstText
            return cleanFirstText + secondText
        }
    }
}

// MARK: - Legacy Compatibility Extensions

extension OCRMergeDecision {
    /// Convert to unified merge strategy
    ///
    /// Provides easy migration path from legacy OCRMergeDecision
    /// to the new unified OCRMergeStrategy enumeration.
    var toMergeStrategy: OCRMergeStrategy {
        OCRMergeStrategy.from(self)
    }
}

extension DashHandlingAction {
    /// Convert to unified merge strategy
    ///
    /// Provides easy migration path from legacy DashHandlingAction
    /// to the new unified OCRMergeStrategy enumeration.
    var toMergeStrategy: OCRMergeStrategy {
        OCRMergeStrategy.from(self)
    }
}
