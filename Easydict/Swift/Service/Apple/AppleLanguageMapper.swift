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

    /// Convert Language to BCP-47 language code for Translation API
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

    // MARK: Internal

    @objc static let shared = AppleLanguageMapper()

    // MARK: Private

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
