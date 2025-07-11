//
//  String+Detect.swift
//  Easydict
//
//  Created by tisfeng on 2025/7/5.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation
import RegexBuilder

// MARK: - String Detection Extensions

extension String {
    /// Check if the string is predominantly Simplified Chinese.
    ///
    /// This method determines if a string is Simplified Chinese based on the proportion of Simplified characters.
    /// It extracts all Chinese characters and calculates the ratio of Simplified to Traditional characters.
    /// If the ratio of Simplified characters exceeds a certain threshold (e.g., 80%), the string is considered Simplified Chinese.
    /// This approach is robust against mixed content with a few Traditional characters.
    ///
    /// - Returns: true if the majority of Chinese characters are Simplified, false otherwise.
    var isSimplifiedChinese: Bool {
        // 1. Extract all Chinese characters from the string.
        let chineseChars = filter { String($0).isChineseTextByRegex }
        guard !chineseChars.isEmpty else { return false }

        // 2. Count the number of characters that are Traditional.
        // A character is considered Traditional if it changes when converted to Simplified Chinese.
        let traditionalCharCount = chineseChars.filter {
            String($0) != String($0).toSimplifiedChinese()
        }.count

        // 3. Calculate the number of Simplified characters.
        let simplifiedCharCount = chineseChars.count - traditionalCharCount

        // 4. Determine if Simplified characters make up the majority.
        // We use a threshold of 0.8 to be certain.
        // This means that if more than 80% of the Chinese characters are Simplified,
        // we classify the text as Simplified Chinese.
        let simplifiedRatio = Double(simplifiedCharCount) / Double(chineseChars.count)
        return simplifiedRatio >= 0.8
    }

    /// Check if the string is Chinese text by regex unicode range.
    var isChineseTextByRegex: Bool {
        // Use RegexBuilder to match Chinese characters (CJK Unified Ideographs)

        // Check if the entire string matches Chinese characters
        wholeMatch(of: Regex.chineseText) != nil
    }

    /// Check if character is English alphabet (basic Latin only)
    var isEnglishAlphabet: Bool {
        count == 1 && isEnglishText
    }

    /// Check if string contains only English alphabet characters
    var isEnglishText: Bool {
        !isEmpty && allSatisfy { $0.isLetter && $0.isASCII }
    }

    /// Check if character is Latin alphabet (used by English, French, Spanish, etc.)
    var isLatinAlphabet: Bool {
        count == 1 && isLatinText
    }

    /// Check if string contains only alphabetic characters
    var isLatinText: Bool {
        //        let latinTextRegex = Regex {
        //            OneOrMore {
        //                CharacterClass(
        //                    "a" ... "z",
        //                    "A" ... "Z",
        //                    "\u{00C0}" ... "\u{00FF}" // Latin-1 Supplement (À-ÿ)
        //                )
        //            }
        //        }

        // Use Unicode property to match Latin characters
        let latinTextRegex = try! Regex(#"\p{Latin}+"#)

        return wholeMatch(of: latinTextRegex) != nil
    }

    /// Check if string contains only numeric characters
    var isNumeric: Bool {
        !isEmpty && allSatisfy { $0.isNumber }
    }

    /// Check if string is numeric-heavy (>70% numbers)
    var isNumericHeavy: Bool {
        let digitCount = filter { $0.isNumber }.count
        return Double(digitCount) / Double(count) > 0.7
    }
}
