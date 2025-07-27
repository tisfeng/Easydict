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
class OCRPoetryDetector {
    // MARK: Lifecycle

    init(metrics: OCRMetrics) {
        self.metrics = metrics
        self.lineMeasurer = OCRLineMeasurer(metrics: metrics)
    }

    // MARK: Internal

    // swiftlint:disable function_body_length

    /// Analyzes text layout patterns to determine if content represents poetry.
    func detectPoetry() -> Bool {
        print("📝 Start detecting poetry...")

        let observations = metrics.textObservations
        let lineCount = observations.count

        guard lineCount > 0 else {
            return false
        }

        var endPunctuationLineCount = 0
        var punctuationSuffixCount = 0
        var noPunctuationLineCount = 0

        // Use pre-calculated metrics from OCRMetrics when available
        let punctuationMarkCount = metrics.punctuationMarkCount
        let charCountPerLine = metrics.charCountPerLine

        // Calculate additional metrics needed for poetry detection
        var totalWordCount = 0

        for i in 0 ..< lineCount {
            let observation = observations[i]
            let text = observation.firstText

            var punctuationSet = CharacterSet.punctuationCharacters
            // Remove common poetry punctuation marks
            punctuationSet.remove(charactersIn: "《》·-#—")

            // Check if the text contains punctuation marks
            let containsPunctuation = text.rangeOfCharacter(from: punctuationSet) != nil
            if !containsPunctuation {
                noPunctuationLineCount += 1
            }

            let wordCount = text.wordCount
            totalWordCount += wordCount
            print(
                "📄 Line \(i): '\(text.prefix20)' (words: \(wordCount), chars: \(text.count))"
            )

            if text.last?.isPunctuation ?? false {
                punctuationSuffixCount += 1
            }

            // Check if line ends with punctuation
            let hasEndPunctuationSuffix = text.hasEndPunctuationSuffix
            if hasEndPunctuationSuffix {
                print("📝 Line \(i) ends with punctuation: \(text)")

                endPunctuationLineCount += 1

                /**
                 10月1日  |  星期日  |  国庆节

                 只要我们展现意志，大自然会为我们找到出
                 路。
                 */
                if i > 0 {
                    let prevObservation = observations[i - 1]
                    let nextObservationForPrev = i < observations.count ? observation : nil
                    let isPrevLongLine = lineMeasurer.isLongLine(
                        observation: prevObservation,
                        nextObservation: nextObservationForPrev
                    )

                    let prevText = prevObservation.firstText
                    let isPrevHasPunctuationSuffix = prevText.last?.isPunctuation ?? false

                    if isPrevLongLine, !isPrevHasPunctuationSuffix {
                        print(
                            "❌ Previous line is a long line without punctuation, cannot be poetry."
                        )
                        return false
                    }
                }
            }
        }

        let wordCountPerLine = totalWordCount.double / lineCount.double
        let numberOfPunctuationMarksPerLine = punctuationMarkCount.double / lineCount.double

        let endWithTerminatorRatio = endPunctuationLineCount.double / lineCount.double
        let punctuationSuffixRatio = punctuationSuffixCount.double / lineCount.double
        let noPunctuationRatio = noPunctuationLineCount.double / lineCount.double

        print("\n📊 Poetry Analysis Summary:")
        print("  - Lines: \(lineCount)")
        print(
            "  - Total words: \(totalWordCount), avg words per line: \(String(format: "%.2f", wordCountPerLine))"
        )
        print(
            "  - Char count per line: \(String(format: "%.2f", charCountPerLine)), punctuation marks count: \(punctuationMarkCount)"
        )
        print(
            "  - Punctuation marks per line: \(String(format: "%.2f", numberOfPunctuationMarksPerLine))"
        )
        print(
            "  - Lines ending with punctuation: \(endPunctuationLineCount)/\(lineCount) = \(String(format: "%.1f", endWithTerminatorRatio))"
        )
        print(
            "  - Punctuation suffix ratio: \(punctuationSuffixCount)/\(lineCount) = \(String(format: "%.1f", punctuationSuffixRatio))"
        )

        print("\n🔍 Poetry Detection Rules:")

        // Rule 1: Single character per line (like vertical poetry)
        if charCountPerLine < 2 {
            print(
                "❌ Rule 1: Too few characters per line (\(String(format: "%.2f", charCountPerLine)) < 2)"
            )
            return false
        }
        print(
            "✅ Rule 1: Sufficient characters per line (\(String(format: "%.2f", charCountPerLine)) >= 2)"
        )

        // Rule 2: Too many punctuation marks per line
        if numberOfPunctuationMarksPerLine > 2.5 {
            print(
                "❌ Rule 2: Too many punctuation marks per line (\(String(format: "%.2f", numberOfPunctuationMarksPerLine)))"
            )
            return false
        }
        print(
            "✅ Rule 2: Reasonable punctuation density (\(String(format: "%.2f", numberOfPunctuationMarksPerLine)) <= 2)"
        )

        let matchesPoetryPattern2_0 = matchesPoetryPattern(
            wordCountPerLine: wordCountPerLine,
            charCountPerLine: charCountPerLine,
            confidenceLevel: .custom(2.0)
        )

        if !matchesPoetryPattern2_0 {
            print(
                "❌ Rule 3: Not poetry-like enough: \(String(format: "%.2f", wordCountPerLine)) words, \(String(format: "%.2f", charCountPerLine)) chars"
            )
            return false
        }

        // Rule 3a: No punctuation but many words per line
        if punctuationMarkCount == 0, wordCountPerLine >= 5 {
            print("✅ Rule 4: No punctuation + many words per line - POETRY DETECTED")
            return true
        }
        print("⚪ Rule 4: No punctuation + many words per line pattern not met")

        // Rule 4: All lines end with punctuation
        if endPunctuationLineCount == lineCount {
            print("✅ Rule 5: All lines end with punctuation - POETRY DETECTED")
            return true
        }
        print(
            "⚪ Rule 5: Not all lines end with punctuation (\(endPunctuationLineCount)/\(lineCount))"
        )

        let matchesPoetryPattern1_0 = matchesPoetryPattern(
            wordCountPerLine: wordCountPerLine,
            charCountPerLine: charCountPerLine
        )

        let matchesPoetryPattern1_5 = matchesPoetryPattern(
            wordCountPerLine: wordCountPerLine,
            charCountPerLine: charCountPerLine,
            confidenceLevel: .custom(1.5)
        )

        if matchesPoetryPattern1_0 {
            print("Poetry-like multiplier 1.0 detected - POETRY DETECTED")
            if numberOfPunctuationMarksPerLine <= 1.5 {
                print(
                    "✅ Rule: Low punctuation density (\(String(format: "%.2f", numberOfPunctuationMarksPerLine)) - POETRY DETECTED"
                )
                return true
            }
        }

        if matchesPoetryPattern1_5 {
            print("Poetry-like multiplier 1.5 detected - POETRY DETECTED")
            if endWithTerminatorRatio >= 0.8 {
                print(
                    "✅ Rule: High end punctuation ratio (\(String(format: "%.1f", endWithTerminatorRatio * 100))%) - POETRY DETECTED"
                )
                return true
            }

            if punctuationSuffixRatio >= 0.8 {
                print(
                    "✅ Rule: High punctuation suffix ratio (\(String(format: "%.1f", punctuationSuffixRatio * 100))%) - POETRY DETECTED"
                )
                return true
            }

            if noPunctuationRatio >= 0.9 {
                print(
                    "✅ Rule: High no punctuation line ratio (\(String(format: "%.1f", noPunctuationRatio * 100))%) - POETRY DETECTED"
                )
                return true
            }

            if numberOfPunctuationMarksPerLine <= 0.1 {
                print(
                    "✅ Rule: Very low punctuation density (\(String(format: "%.2f", numberOfPunctuationMarksPerLine)) - POETRY DETECTED"
                )
                return true
            }
        }

        print("❌ No poetry detection rules matched, returning false.")
        return false
    }

    // MARK: Private

    private let metrics: OCRMetrics
    private let lineMeasurer: OCRLineMeasurer

    /// Checks if the line matches the poetry pattern based on word and character counts.
    private func matchesPoetryPattern(
        wordCountPerLine: Double,
        charCountPerLine: Double,
        confidenceLevel: OCRConfidenceLevel = .custom(1.0)
    )
        -> Bool {
        let wordCountThreshold = OCRConstants.poetryWordCountOfLine * confidenceLevel.multiplier
        let charCountThreshold = OCRConstants.poetryCharacterCountOfLine * confidenceLevel.multiplier

        if wordCountPerLine < wordCountThreshold || charCountPerLine < charCountThreshold {
            print(
                "📝 Line is poetry-like: \(wordCountPerLine) words, \(charCountPerLine) chars, confidenceLevel: \(confidenceLevel)"
            )
            return true
        }
        return false
    }

    // swiftlint:enable function_body_length
}
