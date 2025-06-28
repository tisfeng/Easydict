//
//  AppleLanguageMapper.swift
//  Easydict
//
//  Created by tisfeng on 2025/6/23.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

// MARK: - AppleLanguageMapper

@objc
public class AppleLanguageMapper: NSObject {
    // MARK: Public

    @objc
    public var supportedLanguages: [Language: String] {
        languageMap
    }

    @objc
    public func appleLanguageCode(for language: Language) -> String {
        languageMap[language] ?? "en_US"
    }

    @objc
    public func language(for appleLanguageCode: String) -> Language {
        for (key, value) in languageMap where value == appleLanguageCode {
            return key
        }
        return .english
    }

    /// Convert Language to BCP-47 language code for Apple Translation API
    @objc
    public func languageCode(for language: Language) -> String {
        switch language {
        case .auto: return "und"
        case .simplifiedChinese: return "zh-Hans"
        case .traditionalChinese: return "zh-Hant"
        case .english: return "en"
        case .japanese: return "ja"
        case .korean: return "ko"
        case .french: return "fr"
        case .spanish: return "es"
        case .portuguese: return "pt"
        case .italian: return "it"
        case .german: return "de"
        case .russian: return "ru"
        case .arabic: return "ar"
        case .thai: return "th"
        case .polish: return "pl"
        case .turkish: return "tr"
        case .indonesian: return "id"
        case .vietnamese: return "vi"
        case .dutch: return "nl"
        case .ukrainian: return "uk"
        case .hindi: return "hi"
        default: return "en"
        }
    }

    /// Convert an array of `Language` to Apple OCR language codes.
    public func appleOCRLanguageCodes(for languages: [Language]) -> [String] {
        var appleOCRLanguageCodes: [String] = []
        for language in languages {
            if let appleOCRLanguageCode = ocrLanguageDictionary[language] {
                appleOCRLanguageCodes.append(appleOCRLanguageCode)
            }
        }
        return appleOCRLanguageCodes
    }

    // MARK: Internal

    @objc static let shared = AppleLanguageMapper()

    /// Sort the OCR languages based on user preferences.
    func sortOCRLanguages(
        recognitionLanguages: [Language],
        preferredLanguages: [Language]
    )
        -> [Language] {
        var newRecognitionLanguages = recognitionLanguages
        for preferredLanguage in preferredLanguages.reversed() {
            if let index = newRecognitionLanguages.firstIndex(of: preferredLanguage) {
                newRecognitionLanguages.remove(at: index)
                newRecognitionLanguages.insert(preferredLanguage, at: 0)
            }
        }

        /**
         Since ocr Chinese mixed with English is not very accurate,
         we need to move Chinese to the first priority if newRecognitionLanguages first object is English and if user system language contains Chinese.

         风云 wind and clouds 99$ é

         */

        let userPreferredLanguages = EZLanguageManager.shared().preferredLanguages

        // Move Chinese to the first priority if the first language is English and if user system language contains Chinese.
        if let firstLanguage = newRecognitionLanguages.first, firstLanguage == .english {
            for language in userPreferredLanguages where language.isKindOfChinese() {
                if let index = newRecognitionLanguages.firstIndex(of: language) {
                    newRecognitionLanguages.remove(at: index)
                    newRecognitionLanguages.insert(language, at: 0)
                    break
                }
            }
        }

        return newRecognitionLanguages
    }

    /// Get OCR recognition languages for a specific language.
    func ocrRecognitionLanguages(for language: Language) -> [String] {
        let ocrLanguages = Array(ocrLanguageDictionary.keys)
        let perferredLanguages = EZLanguageManager.shared().preferredLanguages

        var finalRecognitionLanguages = sortOCRLanguages(
            recognitionLanguages: ocrLanguages,
            preferredLanguages: perferredLanguages
        )

        // If language is NOT auto, sort with the specific language first
        if language != .auto {
            finalRecognitionLanguages = sortOCRLanguages(
                recognitionLanguages: finalRecognitionLanguages,
                preferredLanguages: [language]
            )
        }

        // Convert to Apple OCR language codes
        return finalRecognitionLanguages.compactMap { ocrLanguageDictionary[$0] }
    }

    // MARK: Private

    /// Apple OCR languages are from `request.supportedRecognitionLanguages()`
    /// Currently 18 languages supported, BCP 47 language code, e.g. "zh-Hans" for Simplified Chinese.
    private let ocrLanguageDictionary: [Language: String] = [
        .simplifiedChinese: "zh-Hans",
        .traditionalChinese: "zh-Hant",
        .english: "en-US",
        .japanese: "ja-JP",
        .korean: "ko-KR",
        .french: "fr-FR",
        .spanish: "es-ES",
        .portuguese: "pt-BR",
        .italian: "it-IT",
        .german: "de-DE",
        .russian: "ru-RU",
        .ukrainian: "uk-UA",
        // macOS 14.5
        .thai: "th-TH",
        .vietnamese: "vi-VN",
        // macOS 15+
        .arabic: "ar-SA",
    ]

    /// Apple Translation Shortcut Language Mapper
    private let languageMap: [Language: String] = [
        .auto: "auto",
        .simplifiedChinese: "zh_CN",
        .traditionalChinese: "zh_TW",
        .english: "en_US",
        .japanese: "ja_JP",
        .korean: "ko_KR",
        .french: "fr_FR",
        .spanish: "es_ES",
        .portuguese: "pt_BR",
        .italian: "it_IT",
        .german: "de_DE",
        .russian: "ru_RU",
        .arabic: "ar_AE",
        .thai: "th_TH",
        .polish: "pl_PL",
        .turkish: "tr_TR",
        .indonesian: "id_ID",
        .vietnamese: "vi_VN",
        // macOS 14+
        .dutch: "nl_NL",
        .ukrainian: "uk_UA",
        // macOS 15+
        .hindi: "hi_IN",
    ]
}
