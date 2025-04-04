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
    func isClassicalProse(_ contentInfo: ContentInfo) -> Bool {
        logInfo("\n ------ detecting classical prose ------")

        if contentInfo.textCharCount < 10 || contentInfo.phraseAnalysis.phrases.count < 2 {
            logInfo("❌ Text character count is less than 10, or phrases count is less than 2, skipping detection.")
            return false
        }

        let hasZeroeModernChineseRatio = contentInfo.modernChineseRatio == 0

        /**
         日落山水静，为君起松声。

         小楼一夜听春雨，深巷明朝卖杏花。
         */
        if contentInfo.phraseAnalysis.phrases.count == 2,
           contentInfo.phraseAnalysis.isUniformLength,
           contentInfo.phraseAnalysis.maxLength < 8,
           hasZeroeModernChineseRatio {
            logInfo("✅ Prose, phrase length is uniform, max length is less than 8, and modern Chinese ratio is 0.")
            return true
        }

        /**
         念征衣未捣，佳人拂杵，有盈盈泪。
         */
        if contentInfo.phraseAnalysis.phrases.count >= 3,
           contentInfo.phraseAnalysis.averageLength <= 5,
           contentInfo.phraseAnalysis.maxLength < 10,
           contentInfo.modernChineseRatio == 0 {
            logInfo("✅ Prose, phrase average length <= 5, and max length < 10, and modern Chinese ratio = 0.")
            return true
        }

        if contentInfo.phraseAnalysis.phrases.count >= 4,
           contentInfo.phraseAnalysis.averageLength <= 6,
           contentInfo.modernChineseRatio == 0 {
            logInfo("✅ Prose, phrase average length <= 6, and modern Chinese ratio = 0.")
            return true
        }

        if contentInfo.phraseAnalysis.phrases.count >= 8,
           contentInfo.phraseAnalysis.averageLength < 8,
           contentInfo.modernChineseRatio < 0.05 {
            logInfo("✅ Prose, phrase average length < 7, and modern Chinese ratio < 0.05.")
            return true
        }

        if contentInfo.phraseAnalysis.averageLength < 8,
           contentInfo.classicalChineseRatio > 0.1,
           contentInfo.modernChineseRatio < 0.05 {
            logInfo(
                "✅ Prose, phrase average length < 7, and classical ratio > 0.1, and modern ratio < 0.05."
            )
            return true
        }

        logInfo("❌ No classical Chinese markers detected.")

        return false
    }
}
