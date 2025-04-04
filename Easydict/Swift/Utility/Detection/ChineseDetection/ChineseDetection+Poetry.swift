//
//  ChineseDetection+Poetry.swift
//  Easydict
//
//  Created by tisfeng on 2025/4/2.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

extension ChineseDetection {
    /// Detect if the text is Chinese classical Poetry
    func isClassicalPoetry(_ contentInfo: ContentInfo) -> Bool {
        logInfo("\n----- Classical Poetry Detection -----")

        if contentInfo.textCharCount < 10, contentInfo.phraseAnalysis.phrases.count < 2 {
            logInfo("Text is too short to be poetry.")
            return false
        }

        // Check poetry format characteristics
        let hasStandardLength = contentInfo.phraseAnalysis.phrases.allSatisfy { phrase in
            let len = phrase.filter { !$0.isWhitespace && !$0.isPunctuation }.count
            return len == 5 || len == 7 // 五言或七言
        }

        let hasUniformLength = contentInfo.phraseAnalysis.isUniformLength
        let hasProperPhraseCount = contentInfo.phraseAnalysis.phrases.count >= 4 // 至少四句
        let hasStrongParallel = contentInfo.parallelStructureRatio >= 0.7

        // Final decision based on multiple factors
        let isPoetry =
            (hasStandardLength && hasUniformLength && hasProperPhraseCount)
                || (hasStandardLength && hasStrongParallel)

        if isPoetry {
            logInfo("✅ Poetry, detected as classical poetry.")
        }

        return isPoetry
    }
}
