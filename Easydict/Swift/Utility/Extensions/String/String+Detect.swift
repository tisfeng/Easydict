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
    /// Check if the string is Simplified Chinese.
    /// Characters in the text must be all Simplified Chinese characters, otherwise it will return false.
    var isSimplifiedChinese: Bool {
        let pureText = removingNonLetters()
        if !pureText.isChineseTextByRegex {
            return false
        }

        let simplifiedChinese = pureText.toSimplifiedChinese()
        return simplifiedChinese == pureText
    }

    /// Check if the string is Chinese text by regex unicode range.
    var isChineseTextByRegex: Bool {
        // Use RegexBuilder to match Chinese characters (CJK Unified Ideographs)

        //  let chineseCharacterRegex = try! Regex(#"\p{Han}+"#)

        let chineseCharacterRegex = Regex {
            OneOrMore {
                CharacterClass("\u{4e00}" ... "\u{9fa5}")
            }
        }

        // Check if the entire string matches Chinese characters
        return wholeMatch(of: chineseCharacterRegex) != nil
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

    /// Check if character is whitespace or punctuation
    var isWhitespaceOrPunctuation: Bool {
        guard let char = first else { return false }

        return count == 1 && (char.isWhitespace || char.isPunctuation || char.isSymbol)
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

    /// Check if string contains mixed scripts (different writing systems)
    var hasMixedScripts: Bool {
        var hasLatin = false
        var hasChinese = false
        var hasOther = false

        for char in self {
            let charString = String(char)
            if charString.isLatinAlphabet {
                hasLatin = true
            } else if charString.isChineseTextByRegex {
                hasChinese = true
            } else if !charString.isWhitespaceOrPunctuation {
                hasOther = true
            }
        }

        // Mixed if we have at least 2 different script types
        let scriptCount = [hasLatin, hasChinese, hasOther].filter { $0 }.count
        return scriptCount >= 2
    }
}
