//
//  OCRPoetryDetector.swift
//  Easydict
//
//  Created by tisfeng on 2025/6/26.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation
import Vision

// MARK: - OCRPoetryDetector

/// Handles poetry detection logic for OCR text observations
class OCRPoetryDetector {
    // MARK: Internal

    /// Detect if the text layout represents poetry based on line characteristics
    func detectPoetry(observations: [VNRecognizedTextObservation]) -> Bool {
        let lineCount = observations.count
        var longLineCount = 0
        var continuousLongLineCount = 0
        var maxContinuousLongLineCount = 0

        var totalCharCount = 0
        var totalWordCount = 0
        var punctuationMarkCount = 0
        var endWithTerminatorCharLineCount = 0

        for i in 0 ..< lineCount {
            let observation = observations[i]
            let text = observation.text

            totalCharCount += text.count
            totalWordCount += text.wordCount

            // Check if line ends with punctuation
            let isEndPunctuationChar = text.hasEndPunctuationSuffix
            if isEndPunctuationChar {
                endWithTerminatorCharLineCount += 1

                // Check for prose patterns
                if i > 0 {
                    let prevObservation = observations[i - 1]
                    let prevText = prevObservation.text
                    if isLongTextObservation(prevObservation), !prevText.hasEndPunctuationSuffix {
                        return false
                    }
                }
            }

            // Check for long lines
            let isLongLine = isLongTextObservation(observation)
            if isLongLine {
                longLineCount += 1

                if !isEndPunctuationChar {
                    continuousLongLineCount += 1
                    if continuousLongLineCount > maxContinuousLongLineCount {
                        maxContinuousLongLineCount = continuousLongLineCount
                    }
                } else {
                    continuousLongLineCount = 0
                }
            } else {
                continuousLongLineCount = 0
            }

            // Count punctuation marks
            punctuationMarkCount += text.countPunctuationMarks()
        }

        let charCountPerLine = totalCharCount.double / lineCount.double
        let wordCountPerLine = totalWordCount.double / lineCount.double
        let numberOfPunctuationMarksPerLine = punctuationMarkCount.double / lineCount.double

        // Poetry detection rules

        // Single character per line (like vertical poetry)
        if charCountPerLine < 2 {
            return false
        }

        // Too many punctuation marks per line
        if numberOfPunctuationMarksPerLine > 2 {
            return false
        }

        // No punctuation but many words per line
        if punctuationMarkCount == 0, wordCountPerLine >= 5 {
            return true
        }

        // All lines end with punctuation
        if endWithTerminatorCharLineCount == lineCount {
            return true
        }

        // Continuous long lines with some punctuation (prose pattern)
        if maxContinuousLongLineCount >= 2, endWithTerminatorCharLineCount > 0 {
            return false
        }

        // English poetry pattern
        if endWithTerminatorCharLineCount == 0, lineCount >= 6,
           numberOfPunctuationMarksPerLine <= 1.5 {
            return true
        }

        // Too many long lines (prose pattern)
        let tooManyLongLine = longLineCount.double / lineCount.double > 0.4
        if tooManyLongLine {
            return false
        }

        return true
    }

    // MARK: Private

    /// Determine if a text observation represents a long line
    private func isLongTextObservation(_ observation: VNRecognizedTextObservation) -> Bool {
        // Simplified version - in real implementation this would need maxLineLength reference
        let observationWidth = observation.boundingBox.width
        return observationWidth > 0.85 // Assume 85% of some reference width
    }
}
