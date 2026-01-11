//
//  GoogleService+Language.swift
//  Easydict
//
//  Created by tisfeng on 2025/11/28.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

// MARK: - GoogleService + Language

extension GoogleService {
    // MARK: - Text Length Helper

    /// Get max text length for Google Translate.
    func maxTextLength(_ text: String, fromLanguage: Language) -> String {
        // Chinese max text length 1800
        // English max text length 5000
        if EZLanguageManager.shared().isChineseLanguage(fromLanguage), text.count > 1800 {
            return String(text.prefix(1800))
        } else {
            return (text as NSString).trimmingToMaxLength(5000)
        }
    }

    // MARK: - Language Code Mapping

    func languageCode(for language: Language) -> String? {
        switch language {
        case .auto: return "auto"
        case .simplifiedChinese: return "zh-CN"
        case .traditionalChinese: return "zh-TW"
        case .english: return "en"
        case .japanese: return "ja"
        case .korean: return "ko"
        case .french: return "fr"
        case .spanish: return "es"
        case .portuguese: return "pt-PT"
        case .brazilianPortuguese: return "pt"
        case .italian: return "it"
        case .german: return "de"
        case .russian: return "ru"
        case .arabic: return "ar"
        case .swedish: return "sv"
        case .romanian: return "ro"
        case .thai: return "th"
        case .slovak: return "sk"
        case .dutch: return "nl"
        case .hungarian: return "hu"
        case .greek: return "el"
        case .danish: return "da"
        case .finnish: return "fi"
        case .polish: return "pl"
        case .czech: return "cs"
        case .turkish: return "tr"
        case .lithuanian: return "lt"
        case .latvian: return "lv"
        case .ukrainian: return "uk"
        case .bulgarian: return "bg"
        case .indonesian: return "id"
        case .malay: return "ms"
        case .slovenian: return "sl"
        case .estonian: return "et"
        case .vietnamese: return "vi"
        case .persian: return "fa"
        case .hindi: return "hi"
        case .telugu: return "te"
        case .tamil: return "ta"
        case .urdu: return "ur"
        case .filipino: return "tl"
        case .khmer: return "km"
        case .lao: return "lo"
        case .bengali: return "bn"
        case .burmese: return "my"
        case .norwegian: return "no"
        case .serbian: return "sr"
        case .croatian: return "hr"
        case .mongolian: return "mn"
        case .hebrew: return "iw"
        case .georgian: return "ka"
        default: return nil
        }
    }

    // MARK: - Language from Code

    func language(fromCode code: String) -> Language? {
        switch code {
        case "auto": return .auto
        case "zh-CN": return .simplifiedChinese
        case "zh-TW": return .traditionalChinese
        case "en": return .english
        case "ja": return .japanese
        case "ko": return .korean
        case "fr": return .french
        case "es": return .spanish
        case "pt-PT": return .portuguese
        case "pt": return .brazilianPortuguese
        case "it": return .italian
        case "de": return .german
        case "ru": return .russian
        case "ar": return .arabic
        case "sv": return .swedish
        case "ro": return .romanian
        case "th": return .thai
        case "sk": return .slovak
        case "nl": return .dutch
        case "hu": return .hungarian
        case "el": return .greek
        case "da": return .danish
        case "fi": return .finnish
        case "pl": return .polish
        case "cs": return .czech
        case "tr": return .turkish
        case "lt": return .lithuanian
        case "lv": return .latvian
        case "uk": return .ukrainian
        case "bg": return .bulgarian
        case "id": return .indonesian
        case "ms": return .malay
        case "sl": return .slovenian
        case "et": return .estonian
        case "vi": return .vietnamese
        case "fa": return .persian
        case "hi": return .hindi
        case "te": return .telugu
        case "ta": return .tamil
        case "ur": return .urdu
        case "tl": return .filipino
        case "km": return .khmer
        case "lo": return .lao
        case "bn": return .bengali
        case "my": return .burmese
        case "no": return .norwegian
        case "sr": return .serbian
        case "hr": return .croatian
        case "mn": return .mongolian
        case "iw": return .hebrew
        case "ka": return .georgian
        default: return nil
        }
    }
}
