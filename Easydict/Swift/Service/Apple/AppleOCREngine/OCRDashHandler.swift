//
//  OCRDashHandler.swift
//  Easydict
//
//  Created by tisfeng on 2025/6/26.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation
import Vision

// MARK: - OCRDashHandler

/// A specialized handler for intelligently processing dash characters in OCR text.
///
/// ### Three Primary Dash Scenarios:
/// ```
/// 1. Line-break hyphenation (joinRemovingDash):
///    Input:  "recon-\nstruction"  → Output: "reconstruction"
///    The dash was inserted for typographical line breaking and should be removed.
///
/// 2. Compound words (joinWithNoSpace):
///    Input:  "state-of-\nthe-art"   → Output: "state-of-the-art"
///    The dash is meaningful and should be preserved without spacing.
///
/// 3. Separated dash (joinWithSpace):
///    Input:  "true or -\nfalse"   → Output: "true or - false"
///    The dash stands alone and needs spaces around it for proper formatting.
/// ```
///
/// Essential for producing clean, readable text from complex document layouts.
class OCRDashHandler {
    // MARK: Lifecycle

    /// Initializes the dash handler with the provided OCR metrics.
    /// - Parameter metrics: The OCR metrics containing necessary data for dash handling.
    init(metrics: OCRSection) {
        self.metrics = metrics
        self.lineMeasurer = OCRLineMeasurer(metrics: metrics)
    }

    // MARK: Internal

    /// Dash merge strategy for OCR text observations.
    func dashMergeStrategy(_ pair: OCRObservationPair) -> OCRMergeStrategy? {
        analyzeDashHandling(pair)
    }

    // MARK: Private

    private let metrics: OCRSection
    private let lineMeasurer: OCRLineMeasurer

    /// Characters that can be used for word continuation.
    private let dashCharacters = ["-", "–", "—"]

    /// Analyzes dash handling and determines the appropriate merge strategy.
    ///
    /// - Parameter pair: The pair of previous and current observations.
    /// - Returns: The appropriate OCR merge strategy for dash handling, or `nil` if no special dash handling is needed.
    private func analyzeDashHandling(_ pair: OCRObservationPair) -> OCRMergeStrategy? {
        // First check if we have a potential dash-related scenario
        guard hasDashScenario(pair) else {
            return nil
        }

        // Chinese and other non-space languages handle dashes differently
        let isLatinText = metrics.language.requiresWordSpacing
        guard isLatinText else {
            return nil
        }

        // Check if the previous line is long enough to warrant dash handling
        let isPreviousLineLongEnough = lineMeasurer.isLongLine(
            observation: pair.previous,
            nextObservation: pair.current
        )
        guard isPreviousLineLongEnough else {
            return nil
        }

        // Determine the specific dash scenario
        return determineDashMergeStrategy(for: pair)
    }

    /// Checks if the text pair represents any dash-related scenario.
    /// - Parameter pair: The text observation pair.
    /// - Returns: `true` if there's a dash scenario to handle, `false` otherwise.
    private func hasDashScenario(_ pair: OCRObservationPair) -> Bool {
        let currentText = pair.current.firstText
        let previousText = pair.previous.firstText

        guard !previousText.isEmpty, !currentText.isEmpty else { return false }

        // Check if previous text ends with a dash or current text starts with a dash
        return previousTextEndsWithDash(previousText) || currentText.first == "-"
    }

    /// Determines the specific merge strategy for the dash scenario.
    /// - Parameter pair: The text observation pair.
    /// - Returns: The appropriate OCRMergeStrategy.
    private func determineDashMergeStrategy(for pair: OCRObservationPair) -> OCRMergeStrategy {
        let previousText = pair.previous.firstText
        let currentText = pair.current.firstText

        // Scenario 1: Line-break hyphenation (e.g., "recon-\nstruction")
        if previousTextEndsWithDash(previousText), currentText.first?.isLetter == true {
            let wordBeforeDash = getWordBeforeDash(from: previousText)
            if !wordBeforeDash.isEmpty {
                let joinedWord = createJoinedWord(from: pair)
                if isSpelledCorrectly(joinedWord) {
                    return .joinRemovingDash
                }
            }
        }

        // Scenario 2: Separated dash (e.g., "true or -\nfalse", "true or\n- false")
        if previousText.hasSuffix(" -") || currentText.hasPrefix("- ") {
            return .joinWithSpace
        }

        // Scenario 3: Compound words (default case for meaningful dashes)
        // This includes cases like "state-of-\nthe-art" where the dash should be preserved
        return .joinWithNoSpace
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
    private func createJoinedWord(from pair: OCRObservationPair) -> String {
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
