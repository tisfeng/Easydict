//
//  OCRPoetryDetector.swift
//  Easydict
//
//  Created by tisfeng on 2025/6/26.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation
import Vision

/// A detector for identifying poetry-like text structures in OCR results.
class OCRPoetryDetector {
    // MARK: Lifecycle

    init(metrics: OCRMetrics) {
        self.metrics = metrics
        self.lineMeasurer = OCRLineMeasurer(metrics: metrics)
    }

    // MARK: Internal

    /// Analyzes text layout patterns to determine if content represents poetry.
    func detectPoetry() -> Bool {
        print("📝 Start detecting poetry...")

        let observations = metrics.textObservations
        let lineCount = observations.count

        // Ensure there are at least two lines of text to analyze
        guard lineCount > 1 else {
            return debugEarlyFailure(reason: "Not enough lines to analyze for poetry detection.")
        }

        // Early validation checks
        if !performEarlyValidation() {
            return false
        }

        // Apply poetry detection rules
        if let stats = analyzeTextStatistics(observations: observations) {
            return applyPoetryDetectionRules(stats: stats)
        } else {
            return false // Prose patterns detected
        }
    }

    // MARK: Private

    private let metrics: OCRMetrics
    private let lineMeasurer: OCRLineMeasurer

    /// Performs early validation checks to quickly filter out non-poetry content.
    /// - Returns: `true` if content passes initial checks, `false` if it's clearly not poetry.
    private func performEarlyValidation() -> Bool {
        // Use metrics wordCountPerLine to determine if it is poetry-like
        let isPunctuationsLikePoetry = metrics.punctuationCountPerLine <= 2.5
        if !isPunctuationsLikePoetry {
            print("Too many punctuation per line (\(metrics.punctuationCountPerLine.string2f) > 2.5)")
            return debugEarlyFailure(reason: "Not poetry-like based on punctuation marks per line.")
        }

        // Use metrics charCountPerLine to determine if it is poetry-like
        let isMatchesPoetryPattern = matchesPoetryPattern(
            charCountPerLine: metrics.charCountPerLine,
            confidence: .custom(2.5)
        )

        if !isMatchesPoetryPattern {
            print("Not matching poetry char pattern: \(metrics.charCountPerLine.string2f) <= 2.5*X")
            return debugEarlyFailure(reason: "Not poetry-like based on overall character count.")
        }

        return true
    }

    /// Analyzes text observations to collect statistics for poetry detection.
    private func analyzeTextStatistics(observations: [VNRecognizedTextObservation])
        -> PoetryStatistics? {
        let lineCount = observations.count
        var endPunctuationCount = 0
        var suffixPunctuationCount = 0
        var noPunctuationLineCount = 0
        var totalWordCount = 0
        var punctuationCount = 0
        var totalCharCount = 0

        for i in 0 ..< lineCount {
            let observation = observations[i]
            let currentText = observation.firstText

            // Check for mid-sentence punctuation prose pattern
            if hasMidSentencePunctuation(in: currentText) {
                debugNonPoetryPattern(
                    pattern: "mid-sentence punctuation",
                    reason: "Line has mid-sentence punctuation followed by uppercase letter",
                    prevText: "",
                    currentText: currentText
                )
                return nil
            }

            // Analyze punctuation for current line
            let punctuationInfo = analyzePunctuationInLine(currentText)

            if punctuationInfo.isEmpty {
                noPunctuationLineCount += 1
            } else {
                punctuationCount += punctuationInfo.count
            }

            let lineCharCount = currentText.count - punctuationInfo.count
            totalCharCount += lineCharCount

            let wordCount = currentText.wordCount
            totalWordCount += wordCount

            if punctuationInfo.hasSuffix {
                suffixPunctuationCount += 1
            }

            let hasEndPunctuationSuffix = currentText.hasEndPunctuationSuffix
            if hasEndPunctuationSuffix {
                endPunctuationCount += 1
            }

            // Check prose patterns between consecutive lines
            if i > 0 {
                let prevObservation = observations[i - 1]
                let prevText = prevObservation.firstText

                let isPrevLineLong = lineMeasurer.isLongLine(
                    observation: prevObservation,
                    nextObservation: observation
                )

                if isPrevLineLong {
                    // Check for specific prose patterns in long lines
                    if checkLongLineProsePatterns(
                        prevText: prevText,
                        currentText: currentText,
                        hasEndPunctuationSuffix: hasEndPunctuationSuffix
                    ) {
                        return nil
                    }
                }
            }
        }

        return PoetryStatistics(
            endPunctuationCount: endPunctuationCount,
            suffixPunctuationCount: suffixPunctuationCount,
            noPunctuationLineCount: noPunctuationLineCount,
            totalWordCount: totalWordCount,
            punctuationCount: punctuationCount,
            totalCharCount: totalCharCount,
            lineCount: lineCount
        )
    }

    /// Analyzes punctuation in a single line of text.
    /// - Parameter text: The text to analyze
    /// - Returns: Information about punctuation count and suffix
    private func analyzePunctuationInLine(_ text: String) -> PoetryPunctuationInLine {
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

        let totalCount = ellipsisCount + otherPunctuationsCount

        let hasSuffix: Bool
        if let last = text.last, let scalar = last.unicodeScalars.first {
            hasSuffix = punctuationSet.contains(scalar)
        } else {
            hasSuffix = false
        }

        return PoetryPunctuationInLine(count: totalCount, hasSuffix: hasSuffix)
    }

    /// Checks if a line of text has mid-sentence punctuation patterns that indicate prose.
    ///
    /// Specifically looks for cases where:
    /// 1. End punctuation appears in the middle of the line (sentence end)
    /// 2. Followed by the first letter character being uppercase (new sentence start)
    ///
    /// Example:
    /// ```
    /// travel the same distance. This is
    /// ```
    ///
    /// - Parameter text: The text to analyze
    /// - Returns: `true` if mid-sentence punctuation pattern is detected, `false` otherwise
    private func hasMidSentencePunctuation(in text: String) -> Bool {
        // Find the position of end punctuation marks in the text
        for (index, char) in text.enumerated() {
            let charString = String(char)
            if charString.isEndPunctuation {
                // Check if the first letter character after punctuation is uppercase
                let remainingText = String(text.dropFirst(index + 1))
                let firstLetter = remainingText.first { $0.isLetter }
                if let firstLetter, firstLetter.isUppercase {
                    return true // Mid-sentence punctuation pattern detected
                }
            }
        }

        return false
    }

    /// Checks for prose patterns in long lines.
    /// - Parameters:
    ///   - prevText: Previous line text
    ///   - currentText: Current line text
    ///   - hasEndPunctuationSuffix: Whether current line has end punctuation
    /// - Returns: `true` if prose pattern detected, `false` if no prose pattern found
    private func checkLongLineProsePatterns(
        prevText: String,
        currentText: String,
        hasEndPunctuationSuffix: Bool
    )
        -> Bool {
        let isPrevFirstCharLowercase = prevText.isFirstCharLowercase
        let isPrevLastCharUppercase = prevText.isFirstCharUppercase
        let prevHasPunctuationSuffix = prevText.last?.isPunctuation ?? false
        let isFirstCharLowercase = currentText.isFirstCharLowercase

        // If current line has end punctuation suffix
        if hasEndPunctuationSuffix {
            /**
             Check for English prose patterns:

             If the previous line first character is lowercase or last character is uppercase,
             previous is long without punctuation suffix, and the current line has end punctuation,
             then it is maybe not poetry.

              ```
              Apply computer vision algorithms to
              perform a variety of tasks on input
              images and videos.
              ```
              */

            if !prevHasPunctuationSuffix, isPrevFirstCharLowercase || isPrevLastCharUppercase {
                debugNonPoetryPattern(
                    pattern: "Long English prose pattern",
                    reason: "Previous starts with lowercase or uppercase, current has end punctuation",
                    prevText: prevText,
                    currentText: currentText
                )
                return true // Prose pattern detected
            }

            /**
             If current line ends with punctuation, and previous line is long
             without punctuation suffix, then it is maybe not poetry.

             Example:

             10月1日 | 星期日 | 国庆节

             只要我们展现意志，大自然会为我们找到出
             路。
             */

            let matchesPoetryPattern = matchesPoetryPattern(
                wordCountPerLine: prevText.wordCount.double,
                charCountPerLine: prevText.count.double,
                confidence: .custom(1.5)
            )

            if !prevHasPunctuationSuffix, !matchesPoetryPattern {
                debugNonPoetryPattern(
                    pattern: "long line prose pattern",
                    reason: "Current has end punctuation, previous is long without punctuation suffix",
                    prevText: prevText,
                    currentText: currentText
                )
                return true // Prose pattern detected
            }
        }

        /**
         Check for special list case:

         ```
         · fix: change Volcano response Extra type
            from String to Dictionary by @tisfeng in
            #863
         · feat: support auto detection for classical
            Chinese (Enabled in beta mode) by
            @tisfeng in #872
         ```
         */

        if prevText.hasListPrefix {
            if !prevHasPunctuationSuffix, isFirstCharLowercase {
                debugNonPoetryPattern(
                    pattern: "special list case",
                    reason: "Previous list is long, current starts with lowercase",
                    prevText: prevText,
                    currentText: currentText
                )
                return true // Prose pattern detected
            }
        }

        return false // Continue analysis - no prose pattern found
    }

    /// Applies poetry detection rules based on collected statistics.
    /// - Parameter stats: Collected text statistics
    /// - Returns: `true` if content is determined to be poetry, `false` otherwise
    private func applyPoetryDetectionRules(stats: PoetryStatistics) -> Bool {
        stats.printStatisticsSummary()

        print("\n🔍 Poetry Detection Rules:")

        // Rule 1: Single character per line (like vertical poetry)
        if stats.charCountPerLine < 2 {
            return debugRuleFailed(
                rule: "Rule 1",
                reason: "Too few characters per line (\(stats.charCountPerLine.string2f) < 2)"
            )
        }
        print("✅ Rule 1: Sufficient characters per line (\(stats.charCountPerLine.string2f) >= 2)")

        // Rule 2: Too many punctuation marks per line
        if stats.punctuationPerLine > 2.0 {
            return debugRuleFailed(
                rule: "Rule 2",
                reason: "Too many punctuation marks per line (\(stats.punctuationPerLine.string2f))"
            )
        }
        print(
            "✅ Rule 2: Reasonable punctuation density (\(stats.punctuationPerLine.string2f) <= 2)"
        )

        let matchesPoetryPattern2_0 = matchesPoetryPattern(
            wordCountPerLine: stats.wordCountPerLine,
            charCountPerLine: stats.charCountPerLine,
            confidence: .custom(2.0)
        )

        // Rule 3: Poetry-like word and character counts match
        if !matchesPoetryPattern2_0 {
            return debugRuleFailed(
                rule: "Rule 3",
                reason:
                "Not poetry-like enough: \(stats.wordCountPerLine.string2f) words, \(stats.charCountPerLine.string2f) chars"
            )
        }
        print("✅ Rule 3: Matches poetry-like with multiplier 2.0")

        // Apply advanced pattern detection rules
        return applyAdvancedPoetryRules(stats: stats)
    }

    /// Applies advanced poetry detection rules.
    /// - Parameter stats: Poetry statistics containing all ratios
    /// - Returns: `true` if advanced rules indicate poetry, `false` otherwise
    private func applyAdvancedPoetryRules(stats: PoetryStatistics) -> Bool {
        // Strict poetry detection rules based on patterns
        let matchesPoetryPattern1_0 = matchesPoetryPattern(
            wordCountPerLine: stats.wordCountPerLine,
            charCountPerLine: stats.charCountPerLine
        )

        if matchesPoetryPattern1_0 {
            print("📝 Poetry-like multiplier 1.0 detected")
            if stats.punctuationPerLine <= 1.5 {
                print(
                    "✅ Rule 4: Low punctuation density (\(stats.punctuationPerLine.string1f) <= 1.5)"
                )
                return true
            }
        }

        let matchesPoetryPattern1_5 = matchesPoetryPattern(
            wordCountPerLine: stats.wordCountPerLine,
            charCountPerLine: stats.charCountPerLine,
            confidence: .custom(1.5)
        )

        if matchesPoetryPattern1_5 {
            print("📝 Poetry-like multiplier 1.5 detected")
            if stats.endPunctuationRatio >= 0.8 {
                print(
                    "✅ Rule 5: High end punctuation ratio (\(stats.endPunctuationRatio.string2f) >= 0.8)"
                )
                return true
            }

            if stats.suffixPunctuationRatio >= 0.8 {
                print(
                    "✅ Rule 6: High punctuation suffix ratio (\(stats.suffixPunctuationRatio.string2f) >= 0.8)"
                )
                return true
            }

            if stats.noPunctuationLineRatio >= 0.9 {
                print(
                    "✅ Rule 7: High no punctuation line ratio (\(stats.noPunctuationLineRatio.string2f) >= 0.9)"
                )
                return true
            }

            if stats.punctuationPerLine <= 0.1 {
                print(
                    "✅ Rule 8: Very low punctuation density (\(stats.punctuationPerLine.string2f) <= 0.1)"
                )
                return true
            }

            if stats.endPunctuationRatio == 0,
               stats.suffixPunctuationRatio < 0.2,
               stats.noPunctuationLineRatio > 0.8,
               stats.punctuationPerLine < 0.2 {
                print(
                    "✅ Rule 9: No end punctuation, low suffix punctuation, high no-punctuation ratio, low punctuation density"
                )
                return true
            }
        }

        return debugEarlyFailure(reason: "No poetry detection rules matched, returning false.")
    }

    /// Prints debug information when a non-poetry pattern is detected and returns false.
    private func debugNonPoetryPattern(
        pattern: String,
        reason: String,
        prevText: String,
        currentText: String
    ) {
        print("🔍 Detected \(pattern):")
        print("❓ \(reason)")
        print("❓ Maybe not poetry, returning false")
        print("prevText: \(prevText)")
        print("currentText: \(currentText)")
    }

    /// Prints debug information when a poetry detection rule fails and returns false.
    /// - Parameters:
    ///   - rule: The rule description (e.g., "Rule 1", "Rule 2")
    ///   - reason: The detailed reason why the rule failed
    /// - Returns: Always returns false for rule failure
    private func debugRuleFailed(rule: String, reason: String) -> Bool {
        print("❌ \(rule): \(reason)")
        return false
    }

    /// Prints debug information for early detection failure and returns false.
    /// - Parameter reason: The reason for early failure
    /// - Returns: Always returns false for early exit
    private func debugEarlyFailure(reason: String) -> Bool {
        print("❌ Early failure: \(reason)")
        return false
    }

    /// Checks if the line matches the poetry pattern based on word and character counts.
    private func matchesPoetryPattern(
        wordCountPerLine: Double? = nil,
        charCountPerLine: Double,
        confidence: ConfidenceLevel = .custom(1.0)
    )
        -> Bool {
        guard let wordCountPerLine else {
            print("📝 No word count available, assuming poetry-like")
            return true
        }

        let maxPoetryWords = OCRConstants.maxPoetryWordsPerLine * confidence.multiplier
        let maxPoetryChars = OCRConstants.maxPoetryCharsPerLine * confidence.multiplier

        let matchesWordCount = wordCountPerLine <= maxPoetryWords
        let matchesCharCount = charCountPerLine <= maxPoetryChars

        if matchesWordCount || matchesCharCount {
            print(
                """
                📝 Line is poetry-like:
                words \(wordCountPerLine.string2f) <= \(maxPoetryWords.string2f),
                chars \(charCountPerLine.string2f) <= \(maxPoetryChars.string2f),
                confidence: \(confidence)
                """
            )
            return true
        }
        return false
    }
}
