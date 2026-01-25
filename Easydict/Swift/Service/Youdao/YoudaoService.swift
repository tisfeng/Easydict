//
//  YoudaoService.swift
//  Easydict
//
//  Created by tisfeng on 2025/1/1.
//  Copyright © 2025 izual. All rights reserved.
//

import Alamofire
import CryptoKit
import CryptoSwift
import Defaults
import Foundation

// MARK: - Constants

let kYoudaoTranslateURL = "https://fanyi.youdao.com"
let kYoudaoDictURL = "https://dict.youdao.com"

// MARK: - YoudaoService

@objc(EZYoudaoService)
class YoudaoService: QueryService {
    // MARK: Internal

    var headers: HTTPHeaders {
        [
            "User-Agent": EZUserAgent,
            "Referer": kYoudaoTranslateURL,
            "Cookie": "OUTFOX_SEARCH_USER_ID=1796239350@10.110.96.157;",
        ]
    }

    // TODO: refactor QueryService, move these keys to QueryService
    var translationKey: Defaults.Key<String> {
        stringDefaultsKey(.translation, defaultValue: "1")
    }

    var sentenceKey: Defaults.Key<String> {
        stringDefaultsKey(.sentence, defaultValue: "1")
    }

    var dictionaryKey: Defaults.Key<String> {
        stringDefaultsKey(.dictionary, defaultValue: "1")
    }

    override func serviceType() -> ServiceType {
        .youdao
    }

    override func apiKeyRequirement() -> ServiceAPIKeyRequirement {
        .none
    }

    override func link() -> String {
        kYoudaoTranslateURL
    }

    /**
     Youdao word link, support 4 languages: en, ja, ko, fr, and to Chinese. https://www.youdao.com/result?word=good&lang=en

     means: en <-> zh-CHS, ja <-> zh-CHS, ko <-> zh-CHS, fr <-> zh-CHS, if language not in this list, then return nil.
     */
    override func wordLink(_ queryModel: QueryModel) -> String? {
        let encodedWord = queryModel.queryText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let foreignLanguage = youdaoDictForeignLanguage(queryModel) else {
            return link()
        }
        return "\(kYoudaoDictURL)/result?word=\(encodedWord)&lang=\(foreignLanguage)"
    }

    override func name() -> String {
        NSLocalizedString("youdao_dict", comment: "")
    }

    override func intelligentQueryTextType() -> EZQueryTextType {
        MyConfiguration.shared.intelligentQueryTextTypeForServiceType(serviceType())
    }

    // TODO: add configuration UI
    override func supportedQueryType() -> EZQueryTextType {
        var typeOptions: EZQueryTextType = []

        let isTranslationEnabled = Defaults[translationKey].boolValue
        let isSentenceEnabled = Defaults[sentenceKey].boolValue
        let isDictionaryEnabled = Defaults[dictionaryKey].boolValue

        if isTranslationEnabled {
            typeOptions.insert(.translation)
        }
        if isSentenceEnabled {
            typeOptions.insert(.sentence)
        }
        if isDictionaryEnabled {
            typeOptions.insert(.dictionary)
        }

        return typeOptions
    }

    // TODO: refactor QueryService, replace supportLanguagesDictionary with languagesDictionary
    override func supportLanguagesDictionary() -> MMOrderedDictionary {
        languagesDictionary.toMMOrderedDictionary()
    }

    /// Translate text using Youdao API.
    override func translate(
        _ text: String,
        from: Language,
        to: Language
    ) async throws
        -> QueryResult {
        guard !text.isEmpty else {
            throw QueryError(type: .parameter, message: "Translation text is empty")
        }

        return try await queryYoudaoDictAndTranslation(text: text, from: from, to: to)
    }

    /// Generate audio URL using Youdao TTS.
    override func textToAudio(
        _ text: String,
        fromLanguage from: Language,
        accent: String?
    ) async throws
        -> String? {
        guard !text.isEmpty else {
            throw QueryError(type: .parameter, message: "Translation text is empty")
        }

        /**
         It seems that the Youdao TTS audio will auto trim to 600 chars.
         https://dict.youdao.com/dictvoice?audio=Ukraine%20may%20get%20another%20Patriot%20battery.&le=en

         Sogou language codes are the same as Youdaos.
         https://fanyi.sogou.com/reventondc/synthesis?text=class&speed=1&lang=enS&from=translateweb&speaker=6
         */

        let language = getTTSLanguageCode(from, accent: accent)
        let encodedText = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        // uk: type=1, us: type=2
        let accentType = accent == "uk" ? "1" : "2"
        let audioURL = "\(kYoudaoDictURL)/dictvoice?audio=\(encodedText)&le=\(language)&type=\(accentType)"
        return audioURL
    }

    override func getTTSLanguageCode(_ language: Language, accent: String?) -> String {
        if language.isChinese {
            return "zh"
        }
        return super.getTTSLanguageCode(language, accent: accent)
    }

    /// Perform OCR using Youdao service.
    override func ocr(
        _ image: NSImage,
        from: Language,
        to: Language
    ) async throws
        -> EZOCRResult? {
        try await ocr(image: image, from: from, to: to)
    }

    /// Perform OCR and translation using Youdao service.
    override func ocrAndTranslate(
        _ image: NSImage,
        from: Language,
        to: Language,
        ocrSuccess: @escaping (EZOCRResult, Bool) -> ()
    ) async throws
        -> (EZOCRResult?, QueryResult?) {
        let result = try await ocrAndTranslate(
            image: image,
            from: from,
            to: to,
            ocrSuccess: ocrSuccess
        )
        return (result.ocrResult, result.queryResult)
    }

    // MARK: Private

    /// Note: The official Youdao API supports most languages, but its web page shows that only 15 languages are supported. https://fanyi.youdao.com/index.html#/
    private var languagesDictionary: [Language: String] {
        [
            .simplifiedChinese: "zh-CHS",
            .traditionalChinese: "zh-CHT",
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
            .thai: "th",
            .dutch: "nl",
            .indonesian: "id",
            .vietnamese: "vi",
        ]
    }

    private func queryYoudaoDictAndTranslation(
        text: String,
        from: Language,
        to: Language
    ) async throws
        -> QueryResult {
        guard !text.isEmpty else {
            throw QueryError(type: .parameter, message: "Translation text is empty")
        }

        do {
            async let dictResult = queryYoudaoDict(text: text, from: from, to: to)
            async let translateResult = webTranslate(text: text, from: from, to: to)

            _ = try await [dictResult, translateResult]
        } catch {
            // If result doesn't have translation or dictionary result, throw error
            if !result.hasTranslatedResult {
                throw error
            } else {
                logError("Youdao part success, but translation or dictionary failed: \(error)")
            }
        }

        return result
    }
}
