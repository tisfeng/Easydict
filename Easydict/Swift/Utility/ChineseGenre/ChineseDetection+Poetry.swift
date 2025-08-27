//
//  ChineseGenreAnalyzer+Poetry.swift
//  Easydict
//
//  Created by tisfeng on 2025/4/2.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

extension ChineseGenreAnalyzer {
    /// Detect if the text is Chinese classical Poetry
    func isClassicalPoetry(_ analysis: TextAnalysis) -> Bool {
        logInfo("\n----- Classical Poetry Detection -----")

        // Check poetry format characteristics
        let hasStandardLength = analysis.phraseInfo.phrases.allSatisfy { phrase in
            let len = phrase.filter { !$0.isWhitespace && !$0.isPunctuation }.count
            return len == 5 || len == 7 // 五言或七言
        }

        let hasUniformLength = analysis.phraseInfo.isUniformLength
        let hasStrongParallel = analysis.phraseInfo.parallelRatio >= 0.7
        let isPoetry = hasStandardLength && (hasUniformLength || hasStrongParallel)
        logInfo("Classical Poetry Detection: \(isPoetry ? "✅ Poetry" : "❌ Not Poetry")")

        return isPoetry
    }
}
