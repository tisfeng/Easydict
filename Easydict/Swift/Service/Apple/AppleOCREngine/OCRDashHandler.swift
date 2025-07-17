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

/// Represents the strategic action to take when processing dash characters in OCR text
///
/// Dash characters in OCR text can serve different purposes and require different handling
/// strategies depending on their context and intended meaning.
enum DashHandlingAction {
    /// No special dash processing required
    ///
    /// Used when the dash is not part of a word continuation scenario,
    /// or when normal text merging rules should apply.
    case none

    /// Preserve the dash character and join adjacent words
    ///
    /// Applied when the dash serves a meaningful purpose such as:
    /// - Compound words (e.g., "well-known")
    /// - Date ranges (e.g., "2020-2023")
    /// - Technical terms (e.g., "UTF-8")
    case keepDashAndJoin

    /// Remove the dash and seamlessly join the words
    ///
    /// Used for line-break hyphenation where the dash was inserted
    /// only for typographical purposes and should be removed:
    /// - "under-\nstanding" → "understanding"
    /// - "reconstruct-\ning" → "reconstructing"
    case removeDashAndJoin
}

// MARK: - OCRDashHandler

/// Specialized processor for intelligent dash character handling in OCR text
///
/// This sophisticated handler addresses one of the most complex challenges in OCR text
/// processing: determining when dash characters represent meaningful punctuation versus
/// typographical artifacts from line-breaking hyphenation.
///
/// **Core Challenge:**
/// OCR often encounters text where words are hyphenated across line breaks for formatting.
/// The system must intelligently determine whether to:
/// - Preserve dashes that are part of the original content
/// - Remove dashes that are typographical artifacts
/// - Join hyphenated word fragments correctly
///
/// **Analysis Approach:**
/// - **Spatial Analysis**: Examines positioning and line breaks around dashes
/// - **Word Context**: Analyzes surrounding text for word fragment patterns
/// - **Language Rules**: Applies language-specific hyphenation conventions
/// - **Typography Detection**: Identifies line-break vs intentional hyphenation
///
/// **Example Scenarios:**
/// ```
/// Input:  "recon-\nstruction"  → Output: "reconstruction" (remove dash)
/// Input:  "state-of-the-art"   → Output: "state-of-the-art" (keep dash)
/// Input:  "twenty-first"       → Output: "twenty-first" (keep dash)
/// ```
///
/// Essential for producing clean, readable text from complex document layouts.
class OCRDashHandler {
    // MARK: Lifecycle

    /// Initialize dash handler with OCR metrics
    /// - Parameter metrics: OCR metrics containing necessary data for dash handling
    init(metrics: OCRMetrics) {
        self.metrics = metrics
        self.lineMeasurer = OCRLineMeasurer(metrics: metrics)
    }

    // MARK: Internal

    /// Analyze dash handling for a text observation pair and determine appropriate action
    ///
    /// This sophisticated analysis determines how to handle dash characters that may represent
    /// either meaningful punctuation or typographical artifacts from line-breaking hyphenation.
    /// The decision significantly impacts text readability and correctness.
    ///
    /// **Analysis Process:**
    /// 1. **Hyphenation Detection**: Checks if the text pair represents word continuation
    /// 2. **Line Length Validation**: Ensures the previous line is long enough to warrant continuation
    /// 3. **Word Reconstruction**: Creates the potentially joined word for validation
    /// 4. **Spelling Verification**: Uses spell-checking to determine if the joined word is valid
    /// 5. **Action Decision**: Returns appropriate handling strategy based on analysis
    ///
    /// **Decision Logic:**
    /// - `.none`: No dash handling needed (no hyphenation detected)
    /// - `.removeDashAndJoin`: Valid word continuation detected (spell-check passes)
    /// - `.keepDashAndJoin`: Uncertain case or meaningful dash (spell-check fails)
    ///
    /// **Examples:**
    /// - "under-\nstanding" → `.removeDashAndJoin` → "understanding"
    /// - "well-\nknown" → `.keepDashAndJoin` → "well-known"
    /// - "UTF-\n8" → `.keepDashAndJoin` → "UTF-8"
    ///
    /// - Parameter pair: Text observation pair containing potential dash continuation
    /// - Returns: Appropriate dash handling action for the text pair
    func analyzeDashHandling(_ pair: OCRTextObservationPair) -> DashHandlingAction {
        // First check if we have a potential hyphenated word continuation
        guard hasHyphenatedWordContinuation(pair) else {
            return .none
        }

        // Check if the previous line is long enough to warrant dash handling
        guard lineMeasurer.isLongLine(observation: pair.previous, nextObservation: pair.current) else {
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
