//
//  ChineseGenreAnalyzer+Prose.swift
//  Easydict
//
//  Created by tisfeng on 2025/4/2.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

extension ChineseGenreAnalyzer {
    ///  Detect if the text is classical Prose.
    func isClassicalProse(_ analysis: TextAnalysis) -> Bool {
        logInfo("\n ------ detecting classical prose ------")

        let averageLength = analysis.phraseInfo.averageLength
        let phraseCount = analysis.phraseInfo.phrases.count
        let maxLength = analysis.phraseInfo.maxLength
        let hasZeroModernRatio = analysis.lingInfo.hasZeroModernRatio()
        let hasLowModernRatio = analysis.lingInfo.hasLowModernRatio()

        // Prose case: 烂游胜赏，高低灯火，鼎沸笙箫。一年三百六十日，愿长似今宵。
        if averageLength < 5, maxLength < 8, hasZeroModernRatio {
            logInfo(
                "✅ Prose, phrase average length < 5, max length < 8, and modern Chinese ratio is 0."
            )
            return true
        }

        if phraseCount >= 8, averageLength < 9, hasLowModernRatio {
            logInfo("✅ Prose, phrase count >= 8, average length < 9, and has low modern ratio.")
            return true
        }

        logInfo("❌ No classical Chinese prose detected.")

        return false
    }
}
