//
//  OCRDashHandler.swift
//  Easydict
//
//  Created by tisfeng on 2025/6/26.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation
import Vision

// MARK: - DashHandlingAction

/**
 * Defines actions for handling dash characters in OCR text.
 *
 * Dash characters in OCR text can serve different purposes and require different handling
 * strategies depending on their context and intended meaning.
 */
enum DashHandlingAction {
    /// No special dash processing required.
    /// Used when the dash is not part of a word continuation scenario,
    /// or when normal text merging rules should apply.
    case none

    /// Preserve the dash character and join adjacent words.
    /// Applied when the dash serves a meaningful purpose such as:
    /// - Compound words (e.g., "well-known")
    /// - Date ranges (e.g., "2020-2023")
    /// - Technical terms (e.g., "UTF-8")
    case keepDashAndJoin

    /// Remove the dash and seamlessly join the words.
    /// Used for line-break hyphenation where the dash was inserted
    /// only for typographical purposes and should be removed:
    /// - "under-\nstanding" → "understanding"
    /// - "reconstruct-\ning" → "reconstructing"
    case removeDashAndJoin
}

// MARK: - OCRDashHandler

/**
 * A specialized handler for intelligently processing dash characters in OCR text.
 *
 * ### Example Scenarios:
 * ```
 * Input:  "recon-\nstruction"  → Output: "reconstruction" (remove dash)
 * Input:  "state-of-the-art"   → Output: "state-of-the-art" (keep dash)
 * Input:  "twenty-first"       → Output: "twenty-first" (keep dash)
 * ```
 *
 * Essential for producing clean, readable text from complex document layouts.
 */
class OCRDashHandler {
    // MARK: Lifecycle

    /// Initializes the dash handler with the provided OCR metrics.
    /// - Parameter metrics: The OCR metrics containing necessary data for dash handling.
    init(metrics: OCRMetrics) {
        self.metrics = metrics
        self.lineMeasurer = OCRLineMeasurer(metrics: metrics)
    }

    // MARK: Internal

    /// Decides how to handle dashes between two text observations.
    ///
    /// - Parameter pair: The pair of previous and current observations.
    /// - Returns: The appropriate dash handling action (`.none`, `.removeDashAndJoin`, or `.keepDashAndJoin`).
    func analyzeDashHandling(_ pair: OCRTextObservationPair) -> DashHandlingAction {
        // First check if we have a potential hyphenated word continuation
        guard hasHyphenatedWordContinuation(pair) else {
            return .none
        }

        // Chinese does not require special dash handling, so return none
        let isLatinText = EZLanguageManager.shared().isLanguageWordsNeedSpace(metrics.language)
        guard isLatinText else {
            return .none
        }

        // Check if the previous line is long enough to warrant dash handling
        let isPreviousLineLongEnough = lineMeasurer.isLongLine(
            observation: pair.previous,
            nextObservation: pair.current
        )
        guard isPreviousLineLongEnough else {
            return .none
        }

        // Check if the joined word would be spelled correctly
        let joinedWord = createJoinedWord(from: pair)
        if isSpelledCorrectly(joinedWord) {
            return .removeDashAndJoin
        } else {
            return .keepDashAndJoin
        }
    }

    func dashMergeStrategy(_ pair: OCRTextObservationPair) -> OCRMergeStrategy? {
        let dashAction = analyzeDashHandling(pair)
        if dashAction != .none {
            let dashStrategy = OCRMergeStrategy.from(dashAction)
            return dashStrategy
        }
        return nil
    }

    // MARK: Private

    private let metrics: OCRMetrics
    private let lineMeasurer: OCRLineMeasurer

    /// Characters that can be used for word continuation.
    private let dashCharacters = ["-", "–", "—"]

    /// Checks if the text pair represents a hyphenated word continuation.
    /// - Parameter pair: The text observation pair.
    /// - Returns: `true` if it's a hyphenated word continuation, `false` otherwise.
    private func hasHyphenatedWordContinuation(_ pair: OCRTextObservationPair) -> Bool {
        let currentText = pair.current.firstText
        let previousText = pair.previous.firstText

        guard !previousText.isEmpty, !currentText.isEmpty else { return false }

        // Check if previous text ends with a dash
        guard previousTextEndsWithDash(previousText) else { return false }

        // Check if current text starts with a letter (word continuation)
        guard currentText.first?.isLetter == true else { return false }

        // Check if there's a valid word before the dash
        let wordBeforeDash = getWordBeforeDash(from: previousText)
        return !wordBeforeDash.isEmpty
    }

    /// Checks if the previous text ends with a dash character.
    /// - Parameter text: The text to check.
    /// - Returns: `true` if the text ends with a dash, `false` otherwise.
    private func previousTextEndsWithDash(_ text: String) -> Bool {
        guard let lastChar = text.last else { return false }
        return dashCharacters.contains(String(lastChar))
    }

    /// Extracts the word that appears before the dash in the text.
    /// - Parameter text: The text containing the word and dash.
    /// - Returns: The word before the dash.
    private func getWordBeforeDash(from text: String) -> String {
        let textWithoutDash = String(text.dropLast())
        return textWithoutDash.lastWord
    }

    /// Creates the joined word by combining the word before the dash with the first word of the current text.
    /// - Parameter pair: The text observation pair.
    /// - Returns: The combined word.
    private func createJoinedWord(from pair: OCRTextObservationPair) -> String {
        let wordBeforeDash = getWordBeforeDash(from: pair.previous.firstText)
        let firstWordOfCurrent = pair.current.firstText.firstWord
        return wordBeforeDash + firstWordOfCurrent
    }

    /// Checks if a word is spelled correctly.
    /// - Parameter word: The word to check.
    /// - Returns: `true` if the word is spelled correctly, `false` otherwise.
    private func isSpelledCorrectly(_ word: String) -> Bool {
        (word as NSString).isSpelledCorrectly()
    }
}
