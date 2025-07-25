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

/// A detector for identifying poetry-like text structures in OCR results.
///
/// This class analyzes the layout and content of text observations to determine if they
/// follow patterns commonly found in poetry. The detection is based on a combination of
/// line length consistency, alignment, and the number of stanzas (groups of lines).
///
/// ### Detection Criteria:
/// - **Line Length**: Poetry often consists of relatively short lines.
/// - **Alignment**: Lines in a stanza may share a common left or right alignment.
/// - **Stanzas**: The presence of distinct groups of lines separated by larger vertical gaps.
class OCRPoetryDetector {
    // MARK: Lifecycle

    /// Initializes the poetry detector with the provided OCR metrics.
    /// - Parameter metrics: The OCR metrics containing necessary data for poetry detection.
    init(metrics: OCRMetrics) {
        self.metrics = metrics
        self.lineMeasurer = OCRLineMeasurer(metrics: metrics)
    }

    // MARK: Internal

    /// Analyzes text layout patterns to determine if content represents poetry.
    ///
    /// This sophisticated analysis examines multiple characteristics of the text layout
    /// to make an intelligent determination about whether the content is poetic in nature.
    /// The detection is crucial for preserving proper formatting in the final output.
    ///
    /// - Returns: `true` if text layout indicates poetry, `false` for regular prose.
    func detectPoetry() -> Bool {
        let observations = metrics.textObservations
        let lineCount = observations.count

        guard lineCount > 0 else { return false }

        var longLineCount = 0
        var continuousLongLineCount = 0
        var maxContinuousLongLineCount = 0
        var endWithTerminatorCharLineCount = 0

        // Use pre-calculated metrics from OCRMetrics when available
        let punctuationMarkCount = metrics.punctuationMarkCount
        let charCountPerLine = metrics.charCountPerLine

        // Calculate additional metrics needed for poetry detection
        var totalWordCount = 0

        for i in 0 ..< lineCount {
            let observation = observations[i]
            let text = observation.firstText

            totalWordCount += text.wordCount

            // Check if line ends with punctuation
            let hasEndPunctuationSuffix = text.hasEndPunctuationSuffix
            if hasEndPunctuationSuffix {
                endWithTerminatorCharLineCount += 1

                // Check for prose patterns
                if i > 0 {
                    let prevObservation = observations[i - 1]
                    let prevText = prevObservation.firstText
                    let nextObservationForPrev = i < observations.count ? observation : nil
                    if lineMeasurer.isLongLine(
                        observation: prevObservation,
                        nextObservation: nextObservationForPrev
                    ),
                        !prevText.hasEndPunctuationSuffix {
                        return false
                    }
                }
            }

            // Check for long lines
            let nextObservation = i + 1 < observations.count ? observations[i + 1] : nil
            let isLongLine = lineMeasurer.isLongLine(
                observation: observation, nextObservation: nextObservation
            )
            if isLongLine {
                longLineCount += 1

                if !hasEndPunctuationSuffix {
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
        }

        // Calculate averages after processing all lines
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

    private let metrics: OCRMetrics
    private let lineMeasurer: OCRLineMeasurer
}
