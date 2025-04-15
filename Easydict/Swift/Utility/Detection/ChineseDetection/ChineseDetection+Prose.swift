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

        if analysis.textInfo.characterCount < 10 || analysis.phraseInfo.phrases.count < 2 {
            logInfo(
                "❌ Text character count is less than 10, or phrases count is less than 2, skipping detection."
            )
            return false
        }

        /**
         日落山水静，为君起松声。

         小楼一夜听春雨，深巷明朝卖杏花。
         */
        if analysis.phraseInfo.phrases.count == 2,
           analysis.phraseInfo.isUniformLength,
           analysis.phraseInfo.maxLength < 8,
           analysis.lingInfo.hasZeroModernRatio() {
            logInfo(
                "✅ Prose, phrase length is uniform, max length is less than 8, and modern Chinese ratio is 0."
            )
            return true
        }

        /**
         念征衣未捣，佳人拂杵，有盈盈泪。
         */
        if analysis.phraseInfo.phrases.count >= 3,
           analysis.phraseInfo.averageLength < 5,
           analysis.phraseInfo.maxLength < 6,
           analysis.lingInfo.hasZeroModernRatio() {
            logInfo(
                "✅ Prose, phrase average length <= 5, and max length < 10, and has zero modern Chinese ratio."
            )
            return true
        }

        if analysis.phraseInfo.phrases.count >= 4,
           analysis.phraseInfo.averageLength <= 6,
           analysis.lingInfo.hasZeroModernRatio() {
            logInfo("✅ Prose, phrase average length <= 6, and has zero modern Chinese ratio.")
            return true
        }

        if analysis.phraseInfo.phrases.count >= 8,
           analysis.phraseInfo.averageLength < 8,
           analysis.lingInfo.hasLowModernRatio() {
            logInfo("✅ Prose, phrase average length < 8, and has low modern ratio.")
            return true
        }

        if analysis.phraseInfo.averageLength < 9,
           analysis.lingInfo.hasHighClassicalRatio(),
           analysis.lingInfo.hasLowModernRatio() {
            logInfo(
                "✅ Prose, phrase average length < 9, and has high classical ratio, and has low modern ratio."
            )
            return true
        }

        logInfo("❌ No classical Chinese markers detected.")
        return false
    }
}
