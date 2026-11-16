//
//  QwenMTService+Language.swift
//  Easydict
//
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation

extension QwenMTService {
    func makeLanguageDictionary() -> MMOrderedDictionary {
        // The app's language set intersected with Qwen-MT Plus/Flash's documented languages.
        let codes: [Language: String] = [
            .auto: "auto",
            .simplifiedChinese: "zh",
            .traditionalChinese: "zh_tw",
            .english: "en",
            .japanese: "ja",
            .korean: "ko",
            .french: "fr",
            .spanish: "es",
            .catalan: "ca",
            .portuguese: "pt",
            .brazilianPortuguese: "pt",
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
            .filipino: "tl",
            .khmer: "km",
            .lao: "lo",
            .bengali: "bn",
            .burmese: "my",
            .norwegian: "nb",
            .serbian: "sr",
            .croatian: "hr",
            .hebrew: "he",
            .georgian: "ka",
        ]
        let dictionary = MMOrderedDictionary()
        for language in EZLanguageManager.shared().allLanguages {
            if let code = codes[language] {
                dictionary.setObject(code as NSString, forKey: language.rawValue as NSString)
            }
        }
        return dictionary
    }

    /// Lite supports fewer languages than Plus and Flash, including their dated variants.
    func translationLanguageCode(for language: Language, model: String) -> String? {
        guard let code = languageCode(forLanguage: language) else { return nil }
        if model.hasPrefix("qwen-mt-lite") {
            let liteCodes: Set = [
                "auto", "en", "zh", "zh_tw", "ru", "ja", "ko", "es", "fr", "pt", "de",
                "it", "th", "vi", "id", "ms", "ar", "hi", "he", "ur", "bn", "pl", "nl",
                "tr", "km", "cs", "sv", "hu", "da", "fi", "tl", "fa",
            ]
            guard liteCodes.contains(code) else { return nil }
        }
        return code
    }
}
