//
//  GoogleService.swift
//  Easydict
//
//  Created by tisfeng on 2025/11/27.
//  Copyright © 2025 izual. All rights reserved.
//

import AFNetworking
import Foundation
import JavaScriptCore

private let kGoogleTranslateURL = "https://translate.google.com"

// MARK: - GoogleService

class GoogleService: QueryService {
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

    // MARK: - HTTP Session Managers

    lazy var htmlSession: AFHTTPSessionManager = {
        let session = AFHTTPSessionManager()

        let requestSerializer = AFHTTPRequestSerializer()
        requestSerializer.setValue(
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/77.0.3865.120 Safari/537.36",
            forHTTPHeaderField: "User-Agent"
        )
        session.requestSerializer = requestSerializer

        let responseSerializer = AFHTTPResponseSerializer()
        responseSerializer.acceptableContentTypes = ["text/html"]
        session.responseSerializer = responseSerializer

        return session
    }()

    lazy var jsonSession: AFHTTPSessionManager = {
        let session = AFHTTPSessionManager()

        let requestSerializer = AFHTTPRequestSerializer()
        requestSerializer.setValue(
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/77.0.3865.120 Safari/537.36",
            forHTTPHeaderField: "User-Agent"
        )
        session.requestSerializer = requestSerializer

        let responseSerializer = AFJSONResponseSerializer()
        responseSerializer.acceptableContentTypes = ["application/json"]
        session.responseSerializer = responseSerializer

        return session
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

    override func supportedQueryType() -> EZQueryTextType {
        [.dictionary, .sentence, .translation]
    }

    override func intelligentQueryTextType() -> EZQueryTextType {
        Configuration.shared.intelligentQueryTextTypeForServiceType(serviceType())
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
            let sign = signFunction.call(withArguments: [text])?.toString() ?? ""
            let url = getAudioURL(
                withText: text,
                language: getTTSLanguageCode(lang, accent: accent),
                sign: sign
            )
            return url
        }

        try await updateWebAppTKK()
        let sign = signFunction.call(withArguments: [text])?.toString() ?? ""
        let url = getAudioURL(
            withText: text,
            language: getTTSLanguageCode(fromLanguage, accent: accent),
            sign: sign
        )
        return url
    }

    // MARK: - Language Code Helpers

    internal override func languageEnum(fromCode code: String) -> Language {
        language(fromCode: code) ?? .auto
    }

    internal override func getTTSLanguageCode(_ language: Language, accent: String?) -> String {
        // TODO: Implement accent handling
        languageCode(for: language) ?? "en"
    }

    // MARK: - Audio URL

    func getAudioURL(withText text: String, language: String, sign: String) -> String {
        // TODO: text length must <= 200, maybe we can split it.
        let processedText = (text as NSString).trimmingToMaxLength(200)

        return
            "\(kGoogleTranslateURL)/translate_tts?ie=UTF-8&q=\(processedText.encode())&tl=\(language)&total=1&idx=0&textlen=\(processedText.count)&tk=\(sign)&client=webapp&prev=input"
    }
}
