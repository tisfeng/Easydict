//
//  AliTranslateType.swift
//  Easydict
//
//  Created by choykarl on 2023/12/20.
//  Copyright © 2023 izual. All rights reserved.
//

import Foundation

struct AliTranslateType: Equatable {
    var sourceLanguage: String
    var targetLanguage: String

    static let unsupported = AliTranslateType(sourceLanguage: "unsupported", targetLanguage: "unsupported")

    /// https://help.aliyun.com/zh/machine-translation/support/supported-languages-and-codes#h2-url-1
    static let supportLanguagesDictionary: [Language: String] = [
        .auto: "auto",
        .simplifiedChinese: "zh",

        /**
            traditionalChinese code is "zh-tw", but Ali only support traditionalChinese <--> simplifiedChinese, so we convert traditionalChinese manually.
            */
        .traditionalChinese: "zh", // "zh-tw"
        .english: "en",
        .japanese: "ja",
        .korean: "ko",
        .french: "fr",
        .spanish: "es",
        .portuguese: "pt",
        .italian: "it",
        .german: "de",
        .russian: "ru",
        .arabic: "ar",
        .swedish: "sv",
        .romanian: "ro",
        .thai: "th",
        .slovak: "sk",
        .dutch: "nl",
        .hungarian: "hu",
        .greek: "el",
        .danish: "da",
        .finnish: "fi",
        .polish: "pl",
        .czech: "cs",
        .turkish: "tr",
        .lithuanian: "lt",
        .latvian: "lv",
        .bulgarian: "bg",
        .malay: "ms",
        .slovenian: "sl",
        .estonian: "et",
        .vietnamese: "vi",
        .persian: "fa",
        .hindi: "hi",
        .telugu: "te",
        .tamil: "ta",
        .urdu: "ur",
        .filipino: "fil",
        .khmer: "km",
        .lao: "lo",
        .bengali: "bn",
        .burmese: "my",
        .norwegian: "no",
        .croatian: "hbs",
        .mongolian: "mn",
        .hebrew: "he",
    ]

    static func transType(from: Language, to: Language) -> AliTranslateType {
        /**
         文本翻译除繁体中文、蒙语、粤语外，其他212种语言，可支持任意两种语言之间互译。繁体中文、蒙语、粤语仅支持与中文之间的互译。文本翻译支持源语言的自动语言检测，语言代码为auto（粤语为源语言时，不支持使用auto作为语言代码）。

         https://help.aliyun.com/zh/machine-translation/support/supported-languages-and-codes
         */

        if from == .mongolian, !to.isKindOfChinese() || to == .mongolian, !from.isKindOfChinese() {
            return .unsupported
        }

        guard var fromLanguage = supportLanguagesDictionary[from],
              var toLanguage = supportLanguagesDictionary[to]
        else {
            return .unsupported
        }

        // If translate traditionalChinese <--> simplifiedChinese, use Ali API directly.
        if EZLanguageManager.shared().onlyContainsChineseLanguages([from, to]) {
            let traditionalLangaugeCode = "zh-tw"

            // Maybe traditionalChinese --> traditionalChinese
            if from == .traditionalChinese {
                fromLanguage = traditionalLangaugeCode
            }
            if to == .traditionalChinese {
                toLanguage = traditionalLangaugeCode
            }
        }

        return AliTranslateType(sourceLanguage: fromLanguage, targetLanguage: toLanguage)
    }
}
