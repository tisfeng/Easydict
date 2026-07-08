//
//  GoogleService.swift
//  Easydict
//
//  Created by tisfeng on 2025/11/27.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation
import JavaScriptCore

private let kGoogleTranslateURL = "https://translate.google.com"
private let kGoogleUSTTSURL = "https://translate.google.as"
private let kGoogleUKTTSURL = "https://translate.google.co.uk"

// MARK: - GoogleService

@objc(EZGoogleService)
class GoogleService: QueryService {
    // MARK: Internal

    // MARK: - JavaScript Context

    lazy var jsContext: JSContext = {
        let context = JSContext()
        if let jsPath = Bundle.main.path(forResource: "google-translate-sign", ofType: "js"),
           let jsString = try? String(contentsOfFile: jsPath, encoding: .utf8) {
            context?.evaluateScript(jsString)
        }
        return context!
    }()

    lazy var signFunction: JSValue = {
        jsContext.objectForKeyedSubscript("sign")
    }()

    lazy var windowObject: JSValue = {
        jsContext.objectForKeyedSubscript("window")
    }()

    // MARK: - QueryService Override

    /// Translate text using Google web or GTX APIs.
    override func translate(
        _ text: String,
        from: Language,
        to: Language
    ) async throws
        -> QueryResult {
        let processedText = maxTextLength(text, fromLanguage: from)

        // TODO: We should the Google web translate API instead.
        // Two APIs are hard to maintain, and they may differ with web translation.
        let queryDictionary = processedText.shouldQueryDictionary(
            withLanguage: from,
            maxWordCount: 1
        )

        return try await withCheckedThrowingContinuation { continuation in
            let completion: (QueryResult, Error?) -> () = { result, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: result)
                }
            }

            if queryDictionary {
                // This API can get word info, like pronunciation.
                webAppTranslate(processedText, from: from, to: to, completion: completion)
            } else {
                gtxTranslate(processedText, from: from, to: to, completion: completion)
            }
        }
    }

    // MARK: - Service Type & Configuration

    override func serviceType() -> ServiceType {
        .google
    }

    override func apiKeyRequirement() -> ServiceAPIKeyRequirement {
        .none
    }

    override func supportedQueryType() -> EZQueryTextType {
        [.dictionary, .sentence, .translation]
    }

    override func intelligentQueryTextType() -> EZQueryTextType {
        MyConfiguration.shared.intelligentQueryTextTypeForServiceType(serviceType())
    }

    override func name() -> String {
        NSLocalizedString("google_translate", comment: "")
    }

    override func link() -> String {
        kGoogleTranslateURL
    }

    // MARK: - Word Link

    /// https://translate.google.com/?sl=en&tl=zh-CN&text=good&op=translate
    override func wordLink(_ queryModel: QueryModel) -> String? {
        guard let from = languageCode(for: queryModel.queryFromLanguage),
              let to = languageCode(for: queryModel.queryTargetLanguage)
        else { return nil }

        let maxText = maxTextLength(
            queryModel.queryText,
            fromLanguage: queryModel.queryFromLanguage
        )
        let text = maxText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        return "\(kGoogleTranslateURL)/?sl=\(from)&tl=\(to)&text=\(text)&op=translate"
    }

    // MARK: - Supported Languages

    /// Google translate support languages: https://cloud.google.com/translate/docs/languages?hl=zh-cn
    override func supportLanguagesDictionary() -> MMOrderedDictionary {
        let languages: [Any] = [
            Language.auto, "auto",
            Language.simplifiedChinese, "zh-CN",
            Language.traditionalChinese, "zh-TW",
            Language.english, "en",
            Language.japanese, "ja",
            Language.korean, "ko",
            Language.french, "fr",
            Language.spanish, "es",
            Language.catalan, "ca",
            Language.portuguese, "pt-PT",
            Language.brazilianPortuguese, "pt",
            Language.italian, "it",
            Language.german, "de",
            Language.russian, "ru",
            Language.arabic, "ar",
            Language.swedish, "sv",
            Language.romanian, "ro",
            Language.thai, "th",
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
            Language.malay, "ms",
            Language.slovenian, "sl",
            Language.estonian, "et",
            Language.vietnamese, "vi",
            Language.persian, "fa",
            Language.hindi, "hi",
            Language.telugu, "te",
            Language.tamil, "ta",
            Language.urdu, "ur",
            Language.filipino, "tl",
            Language.khmer, "km",
            Language.lao, "lo",
            Language.bengali, "bn",
            Language.burmese, "my",
            Language.norwegian, "no",
            Language.serbian, "sr",
            Language.croatian, "hr",
            Language.mongolian, "mn",
            Language.hebrew, "iw",
            Language.georgian, "ka",
            Language.uyghur, "ug",
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

    // MARK: - Language Detection

    /// Detect language using Google web detection.
    @nonobjc
    override func detectText(_ text: String) async throws -> Language {
        try await withCheckedThrowingContinuation { continuation in
            webAppDetect(text) { language, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: language)
                }
            }
        }
    }

    /// Detect language for Objective-C callers without spawning a Task bridge.
    override func detectText(
        _ text: String,
        completionHandler: @escaping (Language, Error?) -> ()
    ) {
        webAppDetect(text) { language, error in
            DispatchQueue.main.async {
                completionHandler(language, error)
            }
        }
    }

    // MARK: - Text to Audio

    /// Generate audio URL using Google TTS.
    override func textToAudio(
        _ text: String,
        fromLanguage: Language,
        accent: String?
    ) async throws
        -> String? {
        guard !text.isEmpty else {
            throw QueryError(type: .parameter, message: "获取音频的文本为空")
        }

        // TODO: need to optimize, Ref: https://github.com/florabtw/google-translate-tts/blob/master/src/synthesize.js

        if fromLanguage == .auto {
            let lang = try await detectText(text)
            let language = getTTSLanguageCode(lang, accent: accent)
            let sign = ttsSign(for: text, language: language)
            let url = getAudioURL(
                withText: text,
                language: language,
                sign: sign,
                accent: accent
            )
            return url
        }

        let language = getTTSLanguageCode(fromLanguage, accent: accent)
        if !isEnglishTTSLanguageCode(language) {
            try await updateWebAppTKK()
        }
        let sign = ttsSign(for: text, language: language)
        let url = getAudioURL(
            withText: text,
            language: language,
            sign: sign,
            accent: accent
        )
        return url
    }

    // MARK: - Language Code Helpers

    internal override func languageEnum(fromCode code: String) -> Language {
        language(fromCode: code) ?? .auto
    }

    internal override func getTTSLanguageCode(_ language: Language, accent _: String?) -> String {
        if language == .english {
            // Google TTS rejects regional English codes such as en-US/en-GB.
            // Accent selection is handled by the translate host instead.
            return "en"
        }

        return languageCode(for: language) ?? "en"
    }

    /// Converts a Google response language code into a TTS language code.
    func ttsLanguageCode(for language: Language, fallbackCode: String? = nil) -> String {
        if language == .english || fallbackCode?.hasPrefix("en") == true {
            return getTTSLanguageCode(.english, accent: nil)
        }

        if language == .auto, let fallbackCode, !fallbackCode.isEmpty {
            return fallbackCode
        }

        let languageCode = getTTSLanguageCode(language, accent: nil)
        return languageCode.isEmpty ? fallbackCode ?? "en" : languageCode
    }

    func englishTTSAccent(_ accent: String? = nil) -> String {
        let normalizedAccent = accent?.lowercased()
        if normalizedAccent == "uk" || normalizedAccent == "us" {
            return normalizedAccent ?? "us"
        }

        return MyConfiguration.shared.pronunciation == .uk ? "uk" : "us"
    }

    // MARK: - Audio URL

    func getAudioURL(
        withText text: String,
        language: String,
        sign: String,
        accent: String? = nil
    )
        -> String {
        // TODO: text length must <= 200, maybe we can split it.
        let processedText = (text as NSString).trimmingToMaxLength(200)
        let baseURL = ttsBaseURL(languageCode: language, accent: accent)
        if isEnglishTTSLanguageCode(language) {
            return
                "\(baseURL)/translate_tts?ie=UTF-8&q=\(processedText.encode())&tl=\(language)&client=tw-ob"
        }

        let audioURL =
            "\(baseURL)/translate_tts?ie=UTF-8&q=\(processedText.encode())&tl=\(language)&total=1&idx=0&textlen=\(processedText.count)&tk=\(sign)&client=webapp&prev=input"
        return audioURL
    }

    // MARK: Private

    private func ttsBaseURL(languageCode: String, accent: String?) -> String {
        guard languageCode.hasPrefix("en") else {
            return kGoogleTranslateURL
        }

        let selectedAccent = englishTTSAccent(accent)
        return selectedAccent == "uk" ? kGoogleUKTTSURL : kGoogleUSTTSURL
    }

    private func ttsSign(for text: String, language: String) -> String {
        if isEnglishTTSLanguageCode(language) {
            return ""
        }

        return signFunction.call(withArguments: [text])?.toString() ?? ""
    }

    private func isEnglishTTSLanguageCode(_ languageCode: String) -> Bool {
        languageCode.hasPrefix("en")
    }
}
