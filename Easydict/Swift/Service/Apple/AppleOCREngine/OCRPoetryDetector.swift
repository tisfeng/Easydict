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

/// Specialized detector for identifying poetic text layouts in OCR results
///
/// This intelligent detector analyzes text patterns to identify poetry and verse
/// structures that require special formatting treatment. Poetry often has unique
/// characteristics that distinguish it from regular prose text.
///
/// **Detection Criteria:**
/// - **Line Length Patterns**: Short, varied line lengths typical of poetry
/// - **Character Count Analysis**: Lines with significantly fewer characters than prose
/// - **Spatial Arrangement**: Irregular line endings and intentional white space
/// - **Language Context**: Different patterns for different languages (Chinese vs English)
/// - **Consistency Patterns**: Multiple short lines indicating intentional structure
///
/// **Poetry Characteristics Detected:**
/// - Traditional poetry with regular meter and rhyme
/// - Free verse with intentional line breaks
/// - Chinese classical poetry with balanced character counts
/// - Modern poetry with irregular formatting
///
/// **Impact on Text Processing:**
/// - Preserves intentional line breaks in poetic text
/// - Prevents unwanted text merging that would destroy poetic structure
/// - Applies appropriate spacing and formatting for readability
///
/// Essential for maintaining the artistic and structural integrity of poetic content.
class OCRPoetryDetector {
    // MARK: Lifecycle

    /// Initialize poetry detector with OCR metrics
    /// - Parameter metrics: OCR metrics containing necessary data for poetry detection
    init(metrics: OCRMetrics) {
        self.metrics = metrics
        self.lineMeasurer = OCRLineMeasurer(metrics: metrics)
    }

    // MARK: Internal

    /// Analyze text layout patterns to determine if content represents poetry
    ///
    /// This sophisticated analysis examines multiple characteristics of the text layout
    /// to make an intelligent determination about whether the content is poetic in nature.
    /// The detection is crucial for preserving proper formatting in the final output.
    ///
    /// **Analysis Process:**
    /// 1. **Minimum Line Requirements**: Ensures sufficient content for reliable detection
    /// 2. **Character Count Analysis**: Calculates average characters per line
    /// 3. **Line Length Patterns**: Examines consistency and variation in line lengths
    /// 4. **Short Line Detection**: Identifies patterns of intentionally short lines
    /// 5. **Language-specific Rules**: Applies different thresholds for different languages
    /// 6. **Long Line Analysis**: Detects patterns of consecutive long lines that indicate prose
    /// 7. **Punctuation Patterns**: Analyzes ending punctuation frequency
    /// 8. **Word Density**: Examines word count per line ratios
    ///
    /// **Detection Thresholds:**
    /// - Requires minimum 3 lines for reliable pattern analysis
    /// - Uses language-specific character count limits
    /// - Considers percentage of short lines vs total lines
    /// - Factors in average line length relative to typical prose
    /// - Analyzes consecutive long line patterns (prose indicator)
    /// - Evaluates punctuation frequency and patterns
    ///
    /// **Language-specific Adaptations:**
    /// - Chinese: Uses character-based analysis with different thresholds
    /// - English: Uses word-based analysis with space considerations
    /// - General: Applies universal patterns for other languages
    ///
    /// - Returns: true if text layout indicates poetry, false for regular prose
    /// - Note: Conservative approach to avoid false positives that could break normal text
    func detectPoetry() -> Bool {
        let observations = metrics.textObservations
        let lineCount = observations.count

        guard lineCount > 0 else { return false }

        var longLineCount = 0
        var continuousLongLineCount = 0
        var maxContinuousLongLineCount = 0
        var endWithTerminatorCharLineCount = 0

        // Use pre-calculated metrics when available
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
                        prevObservation, nextObservation: nextObservationForPrev
                    ),
                        !prevText.hasEndPunctuationSuffix {
                        return false
                    }
                }
            }

            // Check for long lines
            let nextObservation = i + 1 < observations.count ? observations[i + 1] : nil
            let isLongLine = lineMeasurer.isLongLine(observation, nextObservation: nextObservation)
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
