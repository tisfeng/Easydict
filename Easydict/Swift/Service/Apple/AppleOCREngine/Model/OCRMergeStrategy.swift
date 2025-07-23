//
//  OCRMergeStrategy.swift
//  Easydict
//
//  Created by tisfeng on 2025/7/17.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

// MARK: - OCRMergeStrategy

/// Defines the strategy for merging two consecutive OCR text observations.
///
/// Each case represents a specific formatting decision when combining a `previous`
/// and `current` text observation.
enum OCRMergeStrategy: CustomStringConvertible {
    /// Represents an intentional line break, such as in poetry or lists.
    /// A single newline character (`\n`) is inserted.
    case lineBreak

    /// Represents a paragraph break.
    /// Two newline characters (`\n\n`) are inserted to create a visible separation.
    case newParagraph

    /// Joins two observations with a single space.
    /// This is the default for continuous text in most languages.
    case joinWithSpace

    /// Joins two observations with no space in between.
    /// This is used for languages that do not use spaces, like Chinese and Japanese.
    case joinWithNoSpace

    /// Joins two observations by removing a hyphen from the end of the first one.
    /// This handles cases where a word is hyphenated across two lines.
    case joinRemovingDash

    // MARK: Internal

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
        let language = languageDetector.detectLanguage(text: joinedText)

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

    // MARK: Private

    /// Language detector for determining language context of joined text, do not need to detect classical Chinese
    static private var languageDetector: AppleLanguageDetector {
        AppleLanguageDetector(enableClassicalChineseDetection: false)
    }
}

// MARK: - OCRConstants

/// Constants used for OCR text processing
enum OCRConstants {
    static let lineBreakText = "\n"
    static let paragraphBreakText = "\n\n"

    /// Default is 1.8 characters for indentation, should be less than 2 characters
    static let indentationCharacterCount: Double = 1.8
    static let paragraphLineHeightRatio: Double = 1.5
    static let shortPoetryCharacterCountOfLine = 12

    static let chineseDifferenceFontThreshold: Double = 3.0

    /// 5.0 for English text font, may be not precise, so use a larger threshold
    static let englishDifferenceFontThreshold: Double = 5.0
}
