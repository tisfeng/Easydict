//
//  DoubaoTranslateType.swift
//  Easydict
//
//  Created by Liaoworking on 2025/9/30.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

// MARK: - DoubaoTranslateType

struct DoubaoTranslateType: Equatable {
    static let unsupported = DoubaoTranslateType(sourceLanguage: "", targetLanguage: "")

    /// Doubao supported languages
    /// Docs: https://console.volcengine.com/ark/region:ark+cn-beijing/model/detail?Id=doubao-seed-translation
    static let supportLanguagesDictionary: [Language: String] = [
        .auto: "auto",
        .simplifiedChinese: "zh",
        .traditionalChinese: "zh-Hant",
        .english: "en",
        .japanese: "ja",
        .korean: "ko",
        .german: "de",
        .french: "fr",
        .spanish: "es",
        .italian: "it",
        .portuguese: "pt",
        .russian: "ru",
        .thai: "th",
        .vietnamese: "vi",
        .arabic: "ar",
        .czech: "cs",
        .danish: "da",
        .finnish: "fi",
        .croatian: "hr",
        .hungarian: "hu",
        .indonesian: "id",
        .malay: "ms",
        .norwegian: "nb", // Norwegian Bokmål
        .dutch: "nl",
        .polish: "pl",
        .romanian: "ro",
        .swedish: "sv",
        .turkish: "tr",
        .ukrainian: "uk",
    ]

    let sourceLanguage: String
    let targetLanguage: String

    static func transType(from: Language, to: Language) -> DoubaoTranslateType {
        guard let sourceLang = supportLanguagesDictionary[from],
              let targetLang = supportLanguagesDictionary[to]
        else {
            return .unsupported
        }

        return DoubaoTranslateType(sourceLanguage: sourceLang, targetLanguage: targetLang)
    }
}
