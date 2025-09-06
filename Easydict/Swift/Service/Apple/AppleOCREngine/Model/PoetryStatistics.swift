//
//  PoetryStatistics.swift
//  Easydict
//
//  Created by tisfeng on 2025/8/7.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

// MARK: - PoetryStatistics

/// Statistics collected during text analysis for poetry detection.
struct PoetryStatistics {
    let endPunctuationCount: Int
    let suffixPunctuationCount: Int
    let noPunctuationLineCount: Int
    let totalWordCount: Int
    let punctuationCount: Int
    let totalCharCount: Int
    let lineCount: Int

    // MARK: - Computed properties for ratios

    var charCountPerLine: Double {
        totalCharCount.double / lineCount.double
    }

    var wordCountPerLine: Double {
        totalWordCount.double / lineCount.double
    }

    var punctuationPerLine: Double {
        punctuationCount.double / lineCount.double
    }

    // MARK: - Ratios of punctuation types

    var endPunctuationRatio: Double {
        endPunctuationCount.double / lineCount.double
    }

    var suffixPunctuationRatio: Double {
        suffixPunctuationCount.double / lineCount.double
    }

    var noPunctuationLineRatio: Double {
        noPunctuationLineCount.double / lineCount.double
    }

    // MARK: - Debug Methods

    /// Prints statistics summary for debugging.
    func printStatisticsSummary() {
        print("\n📊 Poetry Analysis Summary:")
        print("- Lines: \(lineCount)")
        print(
            "- Total char count: \(totalCharCount), chars per line: \(charCountPerLine.string2f))"
        )
        print(
            "- Total words: \(totalWordCount), words per line: \(wordCountPerLine.string2f))"
        )
        print(
            "- Punctuation marks count: \(punctuationCount), per line: \(punctuationPerLine.string2f))"
        )
        print(
            "- Lines ending with punctuation: \(endPunctuationCount)/\(lineCount) = \(endPunctuationRatio.string2f)"
        )
        print(
            "- Punctuation suffix ratio: \(suffixPunctuationCount)/\(lineCount) = \(suffixPunctuationRatio.string2f)"
        )
        print(
            "- No punctuation lines: \(noPunctuationLineCount)/\(lineCount) = \(noPunctuationLineRatio.string2f)"
        )
    }
}

// MARK: - PoetryPunctuationInLine

/// Information about punctuation in a line of text.
struct PoetryPunctuationInLine {
    let count: Int
    let hasSuffix: Bool

    /// Returns true if there are no punctuation marks in the line.
    var isEmpty: Bool {
        count == 0
    }
}
