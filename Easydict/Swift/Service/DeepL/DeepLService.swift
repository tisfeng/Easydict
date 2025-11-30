//
//  DeepLService.swift
//  Easydict
//
//  Created by tisfeng on 2025/11/28.
//  Copyright © 2025 izual. All rights reserved.
//

import AFNetworking
import Defaults
import Foundation

private let kDeepLTranslateURL = "https://www.deepl.com/translator"

// MARK: - DeepLService

@objc(EZDeepLTranslate)
@objcMembers
class DeepLService: QueryService {
    // MARK: Internal

    // MARK: - Service Type & Configuration

    override func serviceType() -> ServiceType {
        .deepL
    }

    override func name() -> String {
        NSLocalizedString("deepL_translate", comment: "")
    }

    override func link() -> String {
        kDeepLTranslateURL
    }

    // MARK: - Word Link

    /// https://www.deepl.com/translator#en/zh/good
    override func wordLink(_ queryModel: EZQueryModel) -> String? {
        guard var from = languageCode(for: queryModel.queryFromLanguage),
              let to = languageCode(for: queryModel.queryTargetLanguage)
        else { return nil }

        from = removeLanguageVariant(from)

        let text = queryModel.queryText
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        // !!!: need to convert '/' to '%5C%2F'
        // e.g. https://www.deepl.com/translator#en/zh/computer%5C%2Fserver
        // FIX: https://github.com/tisfeng/Easydict/issues/60
        let encodedText = text.replacingOccurrences(of: "/", with: "%5C%2F")

        return "\(kDeepLTranslateURL)#\(from)/\(to)/\(encodedText)"
    }

    // MARK: - Supported Languages

    /// Supported languages: https://www.deepl.com/zh/docs-api/translate-text/
    override func supportLanguagesDictionary() -> MMOrderedDictionary {
        let languages: [Any] = [
            Language.auto, "auto",
            Language.simplifiedChinese, "zh-hans",
            Language.traditionalChinese, "zh-hant",
            Language.english, "en",
            Language.japanese, "ja",
            Language.korean, "ko",
            Language.french, "fr",
            Language.spanish, "es",
            Language.portuguese, "pt-PT",
            Language.brazilianPortuguese, "pt-BR",
            Language.italian, "it",
            Language.german, "de",
            Language.russian, "ru",
            Language.swedish, "sv",
            Language.romanian, "ro",
            Language.slovak, "sk",
            Language.dutch, "nl",
            Language.hungarian, "hu",
            Language.greek, "el",
            Language.danish, "da",
            Language.finnish, "fi",
            Language.polish, "pl",
            Language.czech, "cs",
            Language.turkish, "tr",
            Language.lithuanian, "lt",
            Language.latvian, "lv",
            Language.ukrainian, "uk",
            Language.bulgarian, "bg",
            Language.indonesian, "id",
            Language.slovenian, "sl",
            Language.estonian, "et",
            Language.norwegian, "nb",
            Language.arabic, "ar",
            NSNull(),
        ]

        let orderedDict = MMOrderedDictionary()
        for i in stride(from: 0, to: languages.count - 1, by: 2) {
            if let key = languages[i] as? NSObject,
               let value = languages[i + 1] as? NSObject {
                orderedDict.setObject(value, forKey: key)
            }
        }
        return orderedDict
    }

    // MARK: - Translate

    override func translate(
        _ text: String,
        from: Language,
        to: Language,
        completion: @escaping (EZQueryResult, (any Error)?) -> ()
    ) {
        if apiType == .webFirst {
            deepLWebTranslate(text, from: from, to: to, completion: completion)
        } else {
            deepLTranslate(text, from: from, to: to, completion: completion)
        }
    }

    override func autoConvertTraditionalChinese() -> Bool {
        true
    }

    // MARK: Private

    // MARK: - Private Properties

    private var authKey: String {
        // easydict://writeKeyValue?EZDeepLAuthKey=xxx
        Defaults[.deepLAuth]
    }

    private var apiType: DeepLAPIUsagePriority {
        // easydict://writeKeyValue?EZDeepLTranslationAPIKey=xxx
        Defaults[.deepLTranslation]
    }

    private var deepLTranslateEndPoint: String {
        // easydict://writeKeyValue?EZDeepLTranslateEndPointKey=xxx
        Defaults[.deepLTranslateEndPointKey]
    }
}

// MARK: - DeepLService + Language

extension DeepLService {
    // MARK: - Language Code Mapping

    func languageCode(for language: Language) -> String? {
        switch language {
        case .auto: return "auto"
        case .simplifiedChinese: return "zh-hans"
        case .traditionalChinese: return "zh-hant"
        case .english: return "en"
        case .japanese: return "ja"
        case .korean: return "ko"
        case .french: return "fr"
        case .spanish: return "es"
        case .portuguese: return "pt-PT"
        case .brazilianPortuguese: return "pt-BR"
        case .italian: return "it"
        case .german: return "de"
        case .russian: return "ru"
        case .swedish: return "sv"
        case .romanian: return "ro"
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
        case .slovenian: return "sl"
        case .estonian: return "et"
        case .norwegian: return "nb"
        case .arabic: return "ar"
        default: return nil
        }
    }

    // MARK: - Language Variant Helper

    /// Remove language variant, e.g. zh-hans --> zh, pt-BR --> pt
    /// Since DeepL API source language code is different from the target language code, it has no variant.
    /// DeepL Docs: https://developers.deepl.com/docs/zh/resources/supported-languages#source-languages
    func removeLanguageVariant(_ languageCode: String) -> String {
        languageCode.components(separatedBy: "-").first ?? languageCode
    }
}
