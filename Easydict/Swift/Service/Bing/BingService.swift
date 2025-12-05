//
//  BingService.swift
//  Easydict
//
//  Created by tisfeng on 2025/11/28.
//  Copyright © 2025 izual. All rights reserved.
//

import AFNetworking
import Foundation

// MARK: - BingService

@objc(EZBingService)
@objcMembers
class BingService: QueryService {
    // MARK: - Internal Properties (for extension)

    lazy var bingRequest = BingRequest()
    var canRetry = true
    var isDictQueryResult = false

    // MARK: - Service Type & Configuration

    override func serviceType() -> ServiceType {
        .bing
    }

    override func name() -> String {
        NSLocalizedString("bing_translate", comment: "")
    }

    // MARK: - Query Text Type

    override func intelligentQueryTextType() -> EZQueryTextType {
        Configuration.shared.intelligentQueryTextTypeForServiceType(serviceType())
    }

    // MARK: - Word Link

    override func wordLink(_ queryModel: EZQueryModel) -> String? {
        let textLanguage = queryModel.queryFromLanguage
        let from = languageCode(forLanguage: textLanguage) ?? ""
        let to = languageCode(forLanguage: queryModel.queryTargetLanguage) ?? ""
        let maxText = maxTextLength(queryModel.queryText, fromLanguage: textLanguage)

        var text = maxText

        // If Chinese text too long, web link page will report error.
        if EZLanguageManager.shared().isChineseLanguage(textLanguage) {
            text = maxText.trimToMaxLength(450)
        }

        if isDictQueryResult {
            let encodedText = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? text
            return "https://\(bingRequest.bingConfig.host ?? BingConfig.chinaHost)/dict/search?q=\(encodedText)"
        }

        let encodedText = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? text
        return "\(bingRequest.bingConfig.translatorURLString)/?text=\(encodedText)&from=\(from)&to=\(to)"
    }

    // MARK: - Supported Languages

    /// Azure translate supported languages: https://learn.microsoft.com/zh-cn/azure/ai-services/translator/language-support
    override func supportLanguagesDictionary() -> MMOrderedDictionary {
        let languages: [Any] = [
            Language.auto, "auto-detect",
            Language.simplifiedChinese, "zh-Hans",
            Language.traditionalChinese, "zh-Hant",
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
            Language.filipino, "fil",
            Language.khmer, "km",
            Language.lao, "lo",
            Language.bengali, "bn",
            Language.burmese, "my",
            Language.norwegian, "nb",
            Language.serbian, "sr-Cyrl",
            Language.croatian, "hr",
            Language.mongolian, "mn-Mong",
            Language.hebrew, "he",
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

    // MARK: - Translate

    override func translate(
        _ text: String,
        from: Language,
        to: Language,
        completion: @escaping (EZQueryResult, (any Error)?) -> ()
    ) {
        bingTranslate(
            text,
            useDictQuery: isEnglishWordToChinese(text, from: from, to: to),
            from: from,
            to: to,
            completion: completion
        )
    }

    // MARK: - Text to Audio

    override func text(
        toAudio text: String,
        fromLanguage from: Language,
        accent: String?,
        completion: @escaping (String?, (any Error)?) -> ()
    ) {
        var language = from
        if from == .classicalChinese {
            language = .simplifiedChinese
        }

        let filePath = audioPlayer.getWordAudioFilePath(
            text,
            language: language,
            accent: accent,
            serviceType: serviceType()
        )

        // If file path already exists.
        if FileManager.default.fileExists(atPath: filePath) {
            completion(filePath, nil)
            return
        }

        logInfo("Bing is fetching text audio: \(text)")

        bingRequest.fetchTextToAudio(
            text: text,
            fromLanguage: language,
            accent: accent
        ) { audioData, error in
            if let error = error {
                completion(nil, error)
                return
            }

            guard let audioData = audioData else {
                completion(nil, nil)
                return
            }

            try? audioData.write(to: URL(fileURLWithPath: filePath))
            completion(filePath, nil)
        }
    }

    // MARK: - Internal Methods (for extension)

    func maxTextLength(_ text: String, fromLanguage: Language) -> String {
        if text.count > 1000 {
            return String(text.prefix(1000))
        }
        return text
    }

    func isEnglishWordToChinese(_ text: String, from: Language, to: Language) -> Bool {
        if from == .english, to == .simplifiedChinese,
           (text as NSString).shouldQueryDictionary(withLanguage: from, maxWordCount: 1) {
            return true
        }
        return false
    }
}
