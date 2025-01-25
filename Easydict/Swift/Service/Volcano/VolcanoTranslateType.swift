//
//  VolcanoTranslateType.swift
//  Easydict
//
//  Created by Jerry on 2024-08-11.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation

struct VolcanoTranslateType: Equatable {
    static let unsupported = VolcanoTranslateType(sourceLanguage: "unsupported", targetLanguage: "unsupported")

    // Volcano supported languages: https://www.volcengine.com/docs/4640/35107
    // Volcano languages support bidirectional translations except Slovak
    static let supportLanguagesDictionary: [Language: String] = [
        .simplifiedChinese: "zh",
        .traditionalChinese: "zh-Hant",
        .vietnamese: "vi",
        .italian: "it",
        .indonesian: "id",
        .hindi: "hi",
        .english: "en",
        .hebrew: "he",
        .spanish: "es",
        .ukrainian: "uk",
        .urdu: "ur",
        .turkish: "tr",
        .thai: "th",
        .tamil: "ta",
        .telugu: "te",
        .slovenian: "sl",
        .slovak: "sk",
        .swedish: "sv",
        .japanese: "ja",
        .portuguese: "pt",
        .norwegian: "no",
        .burmese: "my",
        .bengali: "bn",
        .mongolian: "mn",
        .malay: "ms",
        .romanian: "ro",
        .lithuanian: "lt",
        .latvian: "lv",
        .lao: "lo",
        .croatian: "hr",
        .czech: "cs",
        .dutch: "nl",
        .korean: "ko",
        .khmer: "km",
        .finnish: "fi",
        .french: "fr",
        .russian: "ru",
        .german: "de",
        .danish: "da",
        .persian: "fa",
        .polish: "pl",
        .bulgarian: "bg",
        .arabic: "ar",
        .estonian: "et",
        .classicalChinese: "lzh",
        .serbian: "sr",
        .hungarian: "hu",
        .georgian: "ka",
    ]

    var sourceLanguage: String
    var targetLanguage: String

    static func transType(from: Language, to: Language) -> VolcanoTranslateType {
        guard let fromLanguage = supportLanguagesDictionary[from],
              let toLanguage = supportLanguagesDictionary[to]
        else {
            return .unsupported
        }

        // Volcano doesn't support Slovak as source langauge
        guard fromLanguage != supportLanguagesDictionary[.slovak]
        else {
            return .unsupported
        }

        return VolcanoTranslateType(sourceLanguage: fromLanguage, targetLanguage: toLanguage)
    }
}
