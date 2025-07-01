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

/// Represents the action to take when handling dash characters in OCR text
enum DashHandlingAction {
    /// No special action needed
    case none

    /// Keep the dash character as is, and join the words
    case keepDashAndJoin

    /// Remove the dash, and join the words
    case removeDashAndJoin
}

// MARK: - OCRDashHandler

/// Handles dash-related operations for OCR text processing.
///
/// We have to handle the dash character in OCR text processing, especially when it is used for word continuation. For example, in the text:
///
/// ```
/// little coolness; it comes hotter and hotter, you sleep in beginning of after-
/// noon. Then I try to work again, but it is hard, because it does not get cooler
/// ```
class OCRDashHandler {
    // MARK: Lifecycle

    /// Initialize dash handler with OCR metrics
    /// - Parameter metrics: OCR metrics containing necessary data for dash handling
    init(metrics: OCRMetrics) {
        self.metrics = metrics
        self.lineMeasurer = OCRLineMeasurer(metrics: metrics)
    }

    // MARK: Internal

    /// Analyze dash handling for a text observation pair
    /// Returns the appropriate action to take for dash processing
    func analyzeDashHandling(_ pair: OCRTextObservationPair) -> DashHandlingAction {
        // First check if we have a potential hyphenated word continuation
        guard hasHyphenatedWordContinuation(pair) else {
            return .none
        }

        // Check if the previous line is long enough to warrant dash handling
        guard lineMeasurer.isLongLine(pair.previous) else {
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

    // MARK: Private

    private let metrics: OCRMetrics
    private let lineMeasurer: OCRLineMeasurer

    /// Characters that can be used for word continuation
    private let dashCharacters = ["-", "–", "—"]

    /// Check if the text pair represents a hyphenated word continuation
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

    /// Check if previous text ends with a dash character
    private func previousTextEndsWithDash(_ text: String) -> Bool {
        guard let lastChar = text.last else { return false }
        return dashCharacters.contains(String(lastChar))
    }

    /// Get the word that appears before the dash in the text
    private func getWordBeforeDash(from text: String) -> String {
        let textWithoutDash = String(text.dropLast())
        return textWithoutDash.lastWord
    }

    /// Create the joined word by combining the word before dash with the first word of current text
    private func createJoinedWord(from pair: OCRTextObservationPair) -> String {
        let wordBeforeDash = getWordBeforeDash(from: pair.previous.firstText)
        let firstWordOfCurrent = pair.current.firstText.firstWord
        return wordBeforeDash + firstWordOfCurrent
    }

    /// Check if a word is spelled correctly
    private func isSpelledCorrectly(_ word: String) -> Bool {
        (word as NSString).isSpelledCorrectly()
    }
}
