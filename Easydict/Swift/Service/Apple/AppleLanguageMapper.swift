//
//  AppleLanguageMapper.swift
//  Easydict
//
//  Created by tisfeng on 2025/6/23.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation
import NaturalLanguage

// MARK: - AppleLanguageMapper

public class AppleLanguageMapper: NSObject {
    // MARK: Public

    /// Returns a dictionary mapping `Language` to `String` for Apple Translation Shortcut.
    public var supportedLanguages: [Language: String] {
        languageMap
    }

    public func language(for appleLanguageCode: String) -> Language? {
        for (key, value) in languageMap where value == appleLanguageCode {
            return key
        }
        return nil
    }

    /// Convert Language to BCP-47 language code for Apple Translation API, supported macOS 15+.
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

    /// Convert NLLanguage to Language enum
    public func languageEnum(from appleLanguage: NLLanguage) -> Language {
        for (language, nlLanguage) in appleLanguagesDictionary where nlLanguage == appleLanguage {
            return language
        }
        return .auto
    }

    // MARK: Internal

    static let shared = AppleLanguageMapper()

    /// Returns a dictionary mapping `Language` to `NLLanguage` for Natural Language processing
    ///
    /// This comprehensive mapping provides conversion between Easydict's internal language
    /// enumeration and Apple's Natural Language framework language identifiers. The mapping
    /// follows BCP-47 language tag standards and supports language detection, text processing,
    /// and linguistic analysis throughout the application.
    ///
    /// **Language Tag Format:**
    /// - Uses standard BCP-47 language tags (e.g., "en" for English, "zh-Hans" for Simplified Chinese)
    /// - Includes script subtags where necessary (Hans/Hant for Chinese variants)
    /// - Covers major world languages supported by Apple's Natural Language framework
    ///
    /// **Primary Use Cases:**
    /// - Language detection and identification
    /// - Text processing and linguistic analysis
    /// - Natural language understanding features
    /// - Integration with Apple's ML and NLP frameworks
    ///
    /// - Note: Based on the comprehensive language mapping from the original Objective-C implementation
    var appleLanguagesDictionary: [Language: NLLanguage] {
        [
            .auto: .undetermined, // und
            .simplifiedChinese: .simplifiedChinese, // zh-Hans
            .traditionalChinese: .traditionalChinese, // zh-Hant
            .english: .english, // en
            .japanese: .japanese, // ja
            .korean: .korean, // ko
            .french: .french, // fr
            .spanish: .spanish, // es
            .portuguese: .portuguese, // pt
            .italian: .italian, // it
            .german: .german, // de
            .russian: .russian, // ru
            .arabic: .arabic, // ar
            .swedish: .swedish, // sv
            .romanian: .romanian, // ro
            .thai: .thai, // th
            .slovak: .slovak, // sk
            .dutch: .dutch, // nl
            .hungarian: .hungarian, // hu
            .greek: .greek, // el
            .danish: .danish, // da
            .finnish: .finnish, // fi
            .polish: .polish, // pl
            .czech: .czech, // cs
            .turkish: .turkish, // tr
            .ukrainian: .ukrainian, // uk
            .bulgarian: .bulgarian, // bg
            .indonesian: .indonesian, // id
            .malay: .malay, // ms
            .vietnamese: .vietnamese, // vi
            .persian: .persian, // fa
            .hindi: .hindi, // hi
            .telugu: .telugu, // te
            .tamil: .tamil, // ta
            .urdu: .urdu, // ur
            .khmer: .khmer, // km
            .lao: .lao, // lo
            .bengali: .bengali, // bn
            .burmese: .burmese, // my
            .norwegian: .norwegian, // nb
            .croatian: .croatian, // hr
            .mongolian: .mongolian, // mn
            .hebrew: .hebrew, // he
            .georgian: .georgian, // ka
        ]
    }

    /// Recognized languages for NLLanguageRecognizer and other NLP tasks.
    var recognizedLanguages: [NLLanguage] {
        Array(appleLanguagesDictionary.values)
    }

    /// Custom language hints for improving detection accuracy
    ///
    /// Combines base probability weights with user preference boost.
    /// High weights for common/misdetected languages, lower for distinct patterns.
    /// User preferred languages get +1.0 boost for better UX.
    /// - Helps with "apple" → "en" instead of "tr" problem
    var customLanguageHints: [NLLanguage: Double] {
        // Base language weights optimized for balanced accuracy
        var customHints: [NLLanguage: Double] = [
            // High priority languages (commonly misdetected or very frequent)
            .english: 2.0, // Reduced from 3.0: Still boosted but not overwhelming
            .simplifiedChinese: 1.5, // Reduced from 2.5: Still prioritized
            .traditionalChinese: 1.0, // Keep as reference point

            // Major Asian languages
            .japanese: 0.8, // 門 Reduced from 1.2: Should detect `Traditional Chinese` properly
            .korean: 0.7, // Increased from 0.6: Should detect Korean properly

            // Major European languages (often confused with each other)
            .french: 0.8, // Increased from 0.5: Better French detection
            .spanish: 0.8, // Increased from 0.5: Better Spanish detection
            .italian: 0.6, // Reduced from 0.7 (come)
            .portuguese: 0.7, // Increased from 0.4: Better Portuguese detection
            .german: 0.6, // Increased from 0.3: Better German detection
            .dutch: 0.4, // Increased from 0.25: Better Dutch detection

            // Other European languages
            .russian: 0.8, // Increased from 0.4: Cyrillic script
            .polish: 0.4, // Increased from 0.2: Latin script but distinct
            .czech: 0.3, // Increased from 0.15: Latin script but distinct
            .turkish: 0.08, // Further reduced from 0.2: Often causes false positives
            .catalan: 0.1, // Reduced from 0.15: Often confused with Spanish/French

            // Middle Eastern and others
            .arabic: 0.3, // Distinct script
            .persian: 0.2, // Similar to Arabic but less common
            .thai: 0.3, // Distinct script
            .vietnamese: 0.25, // Latin script with diacritics
            .hindi: 0.2, // Devanagari script

            // Nordic languages
            .swedish: 0.15,
            .danish: 0.15,
            .norwegian: 0.15,
            .finnish: 0.1, // Different language family

            // Less common but supported
            .ukrainian: 0.3, // Cyrillic, similar to Russian
            .bulgarian: 0.15, // Cyrillic
            .romanian: 0.2, // Romance language
            .hungarian: 0.05, // Reduced: Unique language family but often causes false positives
            .greek: 0.2, // Distinct script
            .slovak: 0.05, // Reduced: Similar to Czech, often causes false positives
            .croatian: 0.1, // Reduced: Latin script, can cause confusion
            .indonesian: 0.1, // Reduced: Latin script, can be confused with English
            .malay: 0.08, // Reduced: Similar to Indonesian
        ]

        // Get user preferred languages and boost their weights
        let preferredLanguages = EZLanguageManager.shared().preferredLanguages
        let preferredNLLanguages = preferredLanguages.compactMap { language in
            appleLanguagesDictionary[language]
        }

        // Boost preferred languages
        for preferredLanguage in preferredNLLanguages {
            if let currentWeight = customHints[preferredLanguage] {
                // Add boost based on current weight tier
                let boost = currentWeight >= 2.0 ? 1.5 : 1.0
                customHints[preferredLanguage] = currentWeight + boost
            } else {
                // New preferred language not in base hints
                customHints[preferredLanguage] = 1.0
            }
        }

        // Set default weight for any remaining supported languages
        let supportedLanguages = recognizedLanguages
        for language in supportedLanguages where !customHints.keys.contains(language) {
            customHints[language] = 0.05 // Lower default to avoid false positives
        }

        return customHints
    }

    /// Get OCR recognition languages for a specific language.
    func ocrRecognitionLanguageStrings(for language: Language, isModernOCR: Bool = false)
        -> [String] {
        let languages = sortedOCRRecognitionLanguages(for: language, isModernOCR: isModernOCR)
        let dictionary = ocrLanguageDictionary(isModernOCR: isModernOCR)

        // Convert to Apple OCR language codes
        return languages.compactMap { dictionary[$0] }
    }

    func ocrRecognitionLocaleLanguages(for language: Language, isModernOCR: Bool = false) -> [Locale
        .Language
    ] {
        let languages = sortedOCRRecognitionLanguages(for: language, isModernOCR: isModernOCR)

        // Convert to Locale.Language
        return languages.compactMap { $0.localeLanguage }
    }

    /// Check if the language is supported by Apple OCR.
    func isSupportedOCRLanguage(_ language: Language, isModernOCR: Bool = false) -> Bool {
        let dictionary = ocrLanguageDictionary(isModernOCR: isModernOCR)
        return dictionary.keys.contains(language)
    }

    /// Get Language enum for Apple OCR language.
    /// - Parameter appleLanguage: The BCP-47 language code for Apple OCR.
    /// - Parameter isModernOCR: Whether to check in modern OCR language mappings
    /// - Returns: The corresponding Language enum, or nil if not found.
    func languageEnum(appleOCRLanguage: String, isModernOCR: Bool = false) -> Language? {
        let dictionary = ocrLanguageDictionary(isModernOCR: isModernOCR)
        for (language, code) in dictionary where code == appleOCRLanguage {
            return language
        }
        return nil
    }

    // MARK: Private

    /// Apple Translation Shortcut supported languages map.
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

    /// Apple OCR languages mapping from Language enum to BCP-47 language codes.
    /// - Parameter isModernOCR: Whether to include languages for modern OCR API (macOS 15.0+)
    /// - Returns: Dictionary mapping Language to BCP-47 language code
    private func ocrLanguageDictionary(isModernOCR: Bool = false) -> [Language: String] {
        var dictionary: [Language: String] = [
            // Base languages supported in legacy OCR
            .simplifiedChinese: "zh-Hans",
            .traditionalChinese: "zh-Hant",
            .classicalChinese: "zh-Hans", // Treat as Simplified Chinese for OCR, for `isSupportedOCRLanguage`
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

        if isModernOCR {
            // Additional languages in modern OCR API (macOS 15.0+)
            dictionary.merge([
                .turkish: "tr-TR",
                .indonesian: "id-ID",
                .czech: "cs-CZ",
                .danish: "da-DK",
                .dutch: "nl-NL",
                .norwegian: "no-NO",
                .malay: "ms-MY",
                .polish: "pl-PL",
                .romanian: "ro-RO",
                .swedish: "sv-SE",
            ]) { _, new in new }
        }

        return dictionary
    }

    /// Returns sorted OCR languages for Apple OCR recognition.
    /// - Parameter isModernOCR: Whether to return languages for modern OCR API (macOS 15.0+) which supports more languages
    /// - Note: The order of languages is important for recognition accuracy.
    private func sortedOCRLanguages(isModernOCR: Bool = false) -> [Language] {
        // Base languages supported in legacy OCR (macOS 14.x and earlier)
        var languages: [Language] = [
            .english,
            .simplifiedChinese,
            .traditionalChinese,
            .classicalChinese,
            .japanese,
            .korean,
            .french,
            .spanish,
            .portuguese,
            .italian,
            .german,
            .russian,
            .ukrainian,
            // macOS 14.5
            .thai,
            .vietnamese,
            // macOS 15+
            .arabic,
        ]

        if isModernOCR {
            // Additional languages in modern OCR API (macOS 15.0+)
            languages.append(contentsOf: [
                .turkish,
                .indonesian,
                .czech,
                .danish,
                .dutch,
                .norwegian,
                .malay,
                .polish,
                .romanian,
                .swedish,
            ])
        }

        return languages
    }

    /// Get sorted OCR recognition languages for a specific language.
    private func sortedOCRRecognitionLanguages(for language: Language, isModernOCR: Bool = false)
        -> [Language] {
        // User preferred languages
        let perferredLanguages = EZLanguageManager.shared().preferredLanguages

        var finalRecognitionLanguages = sortOCRLanguages(
            recognitionLanguages: sortedOCRLanguages(isModernOCR: isModernOCR),
            preferredLanguages: perferredLanguages
        )

        // If language is NOT auto, sort with the specific language first
        if language != .auto {
            finalRecognitionLanguages = sortOCRLanguages(
                recognitionLanguages: finalRecognitionLanguages,
                preferredLanguages: [language]
            )
        }

        return finalRecognitionLanguages
    }

    /// Sort the OCR languages based on user preferences.
    /// The langauges will be sorted such that the preferred languages appear first.
    /// THe front of languages will be recognized first.
    private func sortOCRLanguages(
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

         ```
         风云 wind and clouds 99$ é
         ```

         Later: But if the ocr text is English, use Chinese to recognize it, it will be not accurate.
         It's hard to judge whether the text contains Chinese or not, so it's not suitable to put Chinese to the first priority.
         */

        return newRecognitionLanguages
    }
}
