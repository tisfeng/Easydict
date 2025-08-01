//
//  OCRMergeStrategy.swift
//  Easydict
//
//  Created by tisfeng on 2025/7/17.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

// MARK: - OCRMergeStrategy

/**
 * Defines the strategy for merging two consecutive OCR text observations.
 *
 * Each case represents a specific formatting decision when combining a `previous`
 * and `current` text observation.
 */
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

    /// Creates a merge strategy from a `DashHandlingAction`.
    /// - Parameter action: The dash handling action to convert.
    /// - Returns: The corresponding merge strategy.
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

    /// Determines the appropriate merge strategy based on the language context of the joined text.
    /// - Parameter pair: The text observation pair to analyze.
    /// - Returns: `.joinWithSpace` for space-separated languages, `.joinWithNoSpace` otherwise.
    static func mergeStrategy(for pair: OCRTextObservationPair) -> OCRMergeStrategy {
        mergeStrategy(
            firstText: pair.previous.firstText.lastWord,
            secondText: pair.current.firstText.firstWord
        )
    }

    /// Determines the appropriate join strategy based on the language context of the joined text.
    /// - Parameters:
    ///   - firstText: The first text string.
    ///   - secondText: The second text string.
    /// - Returns: `.joinWithSpace` for space-separated languages, `.joinWithNoSpace` otherwise.
    static func mergeStrategy(
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

    /// Generates the appropriate separator string for this merge strategy.
    /// - Returns: The separator string for text joining.
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

    /// Applies the merge strategy to join two text strings.
    /// - Parameters:
    ///   - firstText: The first text string.
    ///   - secondText: The second text string.
    /// - Returns: The combined text according to the merge strategy.
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

    /// Language detector for determining language context of joined text.
    static private var languageDetector: AppleLanguageDetector {
        AppleLanguageDetector(enableClassicalChineseDetection: false)
    }
}
