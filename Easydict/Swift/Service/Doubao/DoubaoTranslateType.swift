//
//  DoubaoTranslateType.swift
//  Easydict
//
//  Created by Liaoworking on 2025/9/30.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation

// MARK: - DoubaoTranslateType

struct DoubaoTranslateType: Equatable {
    static let unsupported = DoubaoTranslateType(sourceLanguage: "", targetLanguage: "")

    /// Doubao supported languages
    static let supportLanguagesDictionary: [Language: String] = [
        .auto: "auto",
        .simplifiedChinese: "zh",
        .traditionalChinese: "zh-Hant",
        .english: "en",
        .japanese: "ja",
        .korean: "ko",
        .french: "fr",
        .spanish: "es",
        .portuguese: "pt",
        .brazilianPortuguese: "pt-BR",
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
        .ukrainian: "uk",
        .bulgarian: "bg",
        .indonesian: "id",
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
        .serbian: "sr",
        .croatian: "hr",
        .mongolian: "mn",
        .hebrew: "he",
        .georgian: "ka",
    ]

    let sourceLanguage: String
    let targetLanguage: String

    static func transType(from: Language, to: Language) -> DoubaoTranslateType {
        guard let sourceLang = supportLanguagesDictionary[from],
              let targetLang = supportLanguagesDictionary[to] else {
            return .unsupported
        }

        return DoubaoTranslateType(sourceLanguage: sourceLang, targetLanguage: targetLang)
    }
}
