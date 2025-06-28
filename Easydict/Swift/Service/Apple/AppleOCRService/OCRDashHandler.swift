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

/// Handles dash-related operations for OCR text processing
class OCRDashHandler {
    // MARK: Internal

    /// Check if hyphenated word continuation needs special handling
    func checkNeedHandleLastDashOfText(
        current: VNRecognizedTextObservation,
        previous: VNRecognizedTextObservation,
        maxLineLength: Double
    )
        -> Bool {
        let text = current.text
        let prevText = previous.text

        let maxLineFrameX = previous.boundingBox.maxX
        let isPrevLongLine = isLongLineLength(maxLineFrameX, maxLineLength: maxLineLength)

        let isPrevLastDashChar = isLastJoinedDashCharacter(in: text, prevText: prevText)
        return isPrevLongLine && isPrevLastDashChar
    }

    /// Check if trailing dash should be removed to join hyphenated words
    func checkNeedRemoveLastDashOfText(
        current: VNRecognizedTextObservation,
        previous: VNRecognizedTextObservation
    )
        -> Bool {
        let text = current.text
        let prevText = previous.text

        guard !prevText.isEmpty else { return false }

        let removedPrevDashText = String(prevText.dropLast())
        let lastWord = removedPrevDashText.components(separatedBy: .whitespacesAndNewlines).last ?? ""
        let firstWord = text.components(separatedBy: .whitespacesAndNewlines).first ?? ""
        let newWord = lastWord + firstWord

        let isLowercaseWord = firstWord.first?.isLowercase ?? false
        let isSpelledCorrectly = (newWord as NSString).isSpelledCorrectly()

        return isLowercaseWord && isSpelledCorrectly
    }

    // MARK: Private

    /// Check if text contains a dash character used for word continuation
    private func isLastJoinedDashCharacter(in text: String, prevText: String) -> Bool {
        guard !prevText.isEmpty, !text.isEmpty else { return false }

        let prevLastChar = String(prevText.suffix(1))
        let dashCharacters = ["-", "–", "—"]

        guard dashCharacters.contains(prevLastChar) else { return false }

        let removedPrevDashText = String(prevText.dropLast())
        let lastWord = removedPrevDashText.components(separatedBy: .whitespacesAndNewlines).last ?? ""

        let isFirstCharAlphabet = text.first?.isLetter ?? false

        return !lastWord.isEmpty && isFirstCharAlphabet
    }

    /// Check if line length qualifies as "long" based on maximum line width
    private func isLongLineLength(_ lineLength: Double, maxLineLength: Double) -> Bool {
        lineLength >= maxLineLength * 0.9
    }
}
