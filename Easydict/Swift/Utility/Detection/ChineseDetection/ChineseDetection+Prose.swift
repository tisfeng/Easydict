//
//  ChineseDetection+Prose.swift
//  Easydict
//
//  Created by tisfeng on 2025/4/2.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

extension ChineseDetection {
    ///  Detect if the text is classical Prose.
    func isClassicalProse(_ analysis: ChineseAnalysis) -> Bool {
        logInfo("\n ------ detecting classical prose ------")

        if analysis.textCharCount < 10 || analysis.phraseAnalysis.phrases.count < 2 {
            logInfo(
                "❌ Text character count is less than 10, or phrases count is less than 2, skipping detection."
            )
            return false
        }

        let hasZeroeModernChinese = analysis.modernChineseRatio == 0

        /**
         日落山水静，为君起松声。

         小楼一夜听春雨，深巷明朝卖杏花。
         */
        if analysis.phraseAnalysis.phrases.count == 2,
           analysis.phraseAnalysis.isUniformLength,
           analysis.phraseAnalysis.maxLength < 8,
           hasZeroeModernChinese {
            logInfo(
                "✅ Prose, phrase length is uniform, max length is less than 8, and modern Chinese ratio is 0."
            )
            return true
        }

        /**
         念征衣未捣，佳人拂杵，有盈盈泪。
         */
        if analysis.phraseAnalysis.phrases.count >= 3,
           analysis.phraseAnalysis.averageLength < 5,
           analysis.phraseAnalysis.maxLength < 6,
           hasZeroeModernChinese {
            logInfo(
                "✅ Prose, phrase average length <= 5, and max length < 10, and modern Chinese ratio = 0."
            )
            return true
        }

        if analysis.phraseAnalysis.phrases.count >= 4,
           analysis.phraseAnalysis.averageLength <= 6,
           hasZeroeModernChinese {
            logInfo("✅ Prose, phrase average length <= 6, and modern Chinese ratio = 0.")
            return true
        }

        if analysis.phraseAnalysis.phrases.count >= 8,
           analysis.phraseAnalysis.averageLength < 8,
           analysis.modernChineseRatio < 0.05 {
            logInfo("✅ Prose, phrase average length < 8, and modern Chinese ratio < 0.05.")
            return true
        }

        if analysis.phraseAnalysis.averageLength < 9,
           analysis.classicalChineseRatio > 0.1,
           analysis.modernChineseRatio < 0.05 {
            logInfo(
                "✅ Prose, phrase average length < 9, and classical ratio > 0.1, and modern ratio < 0.05."
            )
            return true
        }

        logInfo("❌ No classical Chinese markers detected.")

        return false
    }
}
