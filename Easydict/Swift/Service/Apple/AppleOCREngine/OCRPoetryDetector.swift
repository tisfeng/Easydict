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

        // Use metrics wordCountPerLine to determine if it is poetry-like
        let isPunctuationPerLineLikePoetry = metrics.punctuationMarkCountPerLine <= 2.5
        if !isPunctuationPerLineLikePoetry {
            print("❌ Not poetry-like based on punctuation marks per line.")
            return false
        }

        // Use metrics charCountPerLine to determine if it is poetry-like
        let isCharCountPerLineLikePoetry = matchesPoetryPattern(
            wordCountPerLine: 0,
            charCountPerLine: metrics.charCountPerLine,
            confidence: .custom(2.2)
        )

        if !isCharCountPerLineLikePoetry {
            print("❌ Not poetry-like based on overall character count.")
            return false
        }

        var endPunctuationCount = 0
        var suffixPunctuationCount = 0
        var noPunctuationLineCount = 0
        var totalWordCount = 0
        var longLineCount = 0

        var punctuationMarkCount = 0
        var totalCharCount = 0

        for i in 0 ..< lineCount {
            let observation = observations[i]
            let text = observation.firstText

            var punctuationSet = CharacterSet.punctuationCharacters
            // Remove common poetry punctuation marks
            punctuationSet.remove(charactersIn: "《》一•·-#—")

            // Count ellipses ("...") and standalone punctuation marks properly
            let ellipsisRegex = Regex.ellipsis
            let ellipsisCount = text.matches(of: ellipsisRegex).count
            let remainingText = text.replacing(ellipsisRegex, with: "")

            let otherPunctuationsCount = remainingText.unicodeScalars
                .filter { punctuationSet.contains($0) }
                .count

            let linePunctuationCount = ellipsisCount + otherPunctuationsCount
            if linePunctuationCount == 0 {
                noPunctuationLineCount += 1
            } else {
                punctuationMarkCount += linePunctuationCount
            }

            let lineCharCount = text.count - linePunctuationCount
            totalCharCount += lineCharCount

            let wordCount = text.wordCount
            totalWordCount += wordCount

            if let last = text.last, let scalar = last.unicodeScalars.first {
                if punctuationSet.contains(scalar) {
                    suffixPunctuationCount += 1
                }
            }

            let hasEndPunctuationSuffix = text.hasEndPunctuationSuffix
            if hasEndPunctuationSuffix {
                endPunctuationCount += 1
            }

            if i > 0 {
                let prevObservation = observations[i - 1]
                let isPrevLineLong = lineMeasurer.isLongLine(
                    observation: prevObservation,
                    nextObservation: observation
                )

                // If the previous line is long
                if isPrevLineLong {
                    longLineCount += 1

                    let prevText = prevObservation.firstText
                    if prevText.hasListPrefix {
                        print("Previous line is a list line, maybe not poetry")

                        if hasEndPunctuationSuffix {
                            print("❓ Current line ends with punctuation, maybe not poetry")
                            return false
                        }

                        let isLongLine = lineMeasurer.isLongLine(
                            observation: prevObservation,
                            nextObservation: observation
                        )

                        if isLongLine {
                            print("❓ Previous line is a long list line, maybe not poetry")
                            return false
                        }
                    }

                    /**
                     If current line ends with punctuation, and previous line is long without punctuation suffix,
                     then it is maybe not poetry.

                     Example:

                     10月1日 | 星期日 | 国庆节

                     只要我们展现意志，大自然会为我们找到出
                     路。
                     */
                    if hasEndPunctuationSuffix {
                        let prevHasPunctuationSuffix = prevText.last?.isPunctuation ?? false
                        let matchesPoetryPattern = matchesPoetryPattern(
                            wordCountPerLine: prevText.wordCount.double,
                            charCountPerLine: prevText.count.double,
                            confidence: .custom(1.0)
                        )

                        if !prevHasPunctuationSuffix, !matchesPoetryPattern {
                            print(
                                "❓ Current line has end punctuation, previous line is long without punctuation suffix"
                            )
                            print("❓ And not matching poetry pattern, maybe not poetry")
                            return false
                        }
                    }
                }
            }
        }

        let wordCountPerLine = totalWordCount.double / lineCount.double
        let punctuationPerLine = punctuationMarkCount.double / lineCount.double
        let charCountPerLine = totalCharCount.double / lineCount.double

        let endPunctuationRatio = endPunctuationCount.double / lineCount.double
        let suffixPunctuationRatio = suffixPunctuationCount.double / lineCount.double
        let noPunctuationLineRatio = noPunctuationLineCount.double / lineCount.double
        let longLineRatio = longLineCount.double / lineCount.double

        print("\n📊 Poetry Analysis Summary:")
        print("  - Lines: \(lineCount)")

        print(
            "  - Total char count: \(totalCharCount), chars per line: \(charCountPerLine.string2f))"
        )
        print(
            "  - Total words: \(totalWordCount), words per line: \(wordCountPerLine.string2f))"
        )
        print(
            "  - Punctuation marks count: \(punctuationMarkCount), punctuation per line: \(punctuationPerLine.string2f))"
        )
        print(
            "  - Lines ending with punctuation: \(endPunctuationCount)/\(lineCount) = \(endPunctuationRatio.string2f)"
        )
        print(
            "  - Punctuation suffix ratio: \(suffixPunctuationCount)/\(lineCount) = \(suffixPunctuationRatio.string2f)"
        )
        print(
            "  - No punctuation lines: \(noPunctuationLineCount)/\(lineCount) = \(noPunctuationLineRatio.string2f)"
        )
        print(
            "  - Long lines: \(longLineCount)/\(lineCount) = \(longLineRatio.string2f)"
        )

        print("\n🔍 Poetry Detection Rules:")

        /*
         Poetry Detection Rule Summary:
         =============================
         Rule 1: Character count validation (>= 2 chars per line)
         Rule 2: Punctuation density check (<= 2 marks per line)
         Rule 3: Poetry pattern matching (word/char count thresholds)
         Rule 4: Low punctuation density with 1.0x multiplier
         Rule 5: High end punctuation ratio with 1.5x multiplier
         Rule 6: High punctuation suffix ratio with 1.5x multiplier
         Rule 7: High no-punctuation line ratio with 1.5x multiplier
         Rule 8: Very low punctuation density with 1.5x multiplier
         Rule 9: Combined criteria with 1.5x multiplier
         */

        // Rule 1: Single character per line (like vertical poetry)
        if charCountPerLine < 2 {
            print(
                "❌ Rule 1: Too few characters per line (\(charCountPerLine.string2f) < 2)"
            )
            return false
        }
        print(
            "✅ Rule 1: Sufficient characters per line (\(charCountPerLine.string2f) >= 2)"
        )

        // Rule 2: Too many punctuation marks per line
        if punctuationPerLine > 2.0 {
            print(
                "❌ Rule 2: Too many punctuation marks per line (\(punctuationPerLine.string2f))"
            )
            return false
        }
        print(
            "✅ Rule 2: Reasonable punctuation density (\(punctuationPerLine.string2f) <= 2)"
        )

        let matchesPoetryPattern2_0 = matchesPoetryPattern(
            wordCountPerLine: wordCountPerLine,
            charCountPerLine: charCountPerLine,
            confidence: .custom(2.0)
        )

        // Rule 3: Poetry-like word and character counts match
        if !matchesPoetryPattern2_0 {
            print(
                "❌ Rule 3: Not poetry-like enough: \(wordCountPerLine.string2f) words, \(charCountPerLine.string2f) chars"
            )
            return false
        }
        print("✅ Rule 3: Matches poetry-like with multiplier 2.0")

        // Strict poetry detection rules based on patterns
        let matchesPoetryPattern1_0 = matchesPoetryPattern(
            wordCountPerLine: wordCountPerLine,
            charCountPerLine: charCountPerLine
        )

        if matchesPoetryPattern1_0 {
            print("📝 Poetry-like multiplier 1.0 detected")
            if punctuationPerLine <= 1.5 {
                print(
                    "✅ Rule 4: Low punctuation density (\(punctuationPerLine.string1f) <= 1.5)"
                )
                return true
            }
        }

        let matchesPoetryPattern1_5 = matchesPoetryPattern(
            wordCountPerLine: wordCountPerLine,
            charCountPerLine: charCountPerLine,
            confidence: .custom(1.5)
        )

        if matchesPoetryPattern1_5 {
            print("📝 Poetry-like multiplier 1.5 detected")
            if endPunctuationRatio >= 0.8 {
                print(
                    "✅ Rule 5: High end punctuation ratio (\(endPunctuationRatio.string2f) >= 0.8"
                )
                return true
            }

            if suffixPunctuationRatio >= 0.8 {
                print(
                    "✅ Rule 6: High punctuation suffix ratio (\(suffixPunctuationRatio.string2f) >= 0.8"
                )
                return true
            }

            if noPunctuationLineRatio >= 0.9 {
                print(
                    "✅ Rule 7: High no punctuation line ratio (\(noPunctuationLineRatio.string2f) >= 0.9"
                )
                return true
            }

            if punctuationPerLine <= 0.1 {
                print(
                    "✅ Rule 8: Very low punctuation density (\(punctuationPerLine.string2f) <= 0.1)"
                )
                return true
            }

            if endPunctuationRatio == 0,
               suffixPunctuationRatio < 0.2,
               noPunctuationLineRatio > 0.8,
               punctuationPerLine < 0.2 {
                print(
                    "✅ Rule 9: No end punctuation, low suffix punctuation, high no-punctuation ratio, low punctuation density"
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
        confidence: OCRConfidenceLevel = .custom(1.0)
    )
        -> Bool {
        let wordCountThreshold = OCRConstants.poetryWordCountOfLine * confidence.multiplier
        let charCountThreshold = OCRConstants.poetryCharacterCountOfLine * confidence.multiplier

        if wordCountPerLine <= wordCountThreshold || charCountPerLine <= charCountThreshold {
            print(
                """
                📝 Line is poetry-like:
                words \(wordCountPerLine.string2f) <= \(wordCountThreshold.string2f),
                chars \(charCountPerLine.string2f) <= \(charCountThreshold.string2f),
                confidence: \(confidence)
                """
            )
            return true
        }
        return false
    }

    // swiftlint:enable function_body_length
}
