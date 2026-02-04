//
//  NiuTransService.swift
//  Easydict
//
//  Created by tisfeng on 2025/11/28.
//  Copyright © 2025 izual. All rights reserved.
//

import AFNetworking
import Defaults
import Foundation
import SwiftUI

private let kNiuTransURL = "https://niutrans.com"
private let kNiuTransAPIURL = "https://api.niutrans.com/NiuTransServer/translation"

// MARK: - NiuTransService

@objc(EZNiuTransTranslate)
@objcMembers
class NiuTransService: QueryService {
    // MARK: Open

    /// Returns configuration items for the NiuTrans service settings view.
    open override func configurationListItems() -> Any? {
        ServiceConfigurationSecretSectionView(service: self, observeKeys: [.niuTransAPIKey]) {
            SecureInputCell(
                textFieldTitleKey: "service.configuration.niutrans.api_key.title",
                key: .niuTransAPIKey
            )
        }
    }

    // MARK: Internal

    // MARK: - Service Type & Configuration

    override func serviceType() -> ServiceType {
        .niuTrans
    }

    override func name() -> String {
        NSLocalizedString("niuTrans_translate", comment: "")
    }

    override func link() -> String {
        kNiuTransURL
    }

    // MARK: - API Key

    override func apiKeyRequirement() -> ServiceAPIKeyRequirement {
        .builtIn
    }

    override func totalFreeQueryCharacterCount() -> Int {
        1000 * 10000
    }

    // MARK: - Supported Languages

    /// Niutrans translate supported languages: https://niutrans.com/documents/contents/trans_text#languageList
    override func supportLanguagesDictionary() -> MMOrderedDictionary {
        let languages: [Any] = [
            Language.auto, "auto",
            Language.simplifiedChinese, "zh",
            Language.traditionalChinese, "cht",
            Language.english, "en",
            Language.japanese, "ja",
            Language.korean, "ko",
            Language.french, "fr",
            Language.spanish, "es",
            Language.portuguese, "pt",
            Language.brazilianPortuguese, "pt-BR",
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
            Language.norwegian, "no",
            Language.serbian, "sr",
            Language.croatian, "hr",
            Language.mongolian, "mn",
            Language.hebrew, "he",
            Language.georgian, "jy",
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

    /// Translate text using NiuTrans API.
    override func translate(
        _ text: String,
        from: Language,
        to: Language
    ) async throws
        -> QueryResult {
        try await withCheckedThrowingContinuation { continuation in
            niuTransTranslate(text, from: from, to: to) { result, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: result)
                }
            }
        }
    }

    // MARK: Private

    // MARK: - Private Properties

    private var apiKey: String {
        // easydict://writeKeyValue?EZNiuTransAPIKey=
        let key = Defaults[.niuTransAPIKey]
        if key.isEmpty {
            return niutransAPIKey
        }
        return key
    }
}

// MARK: - NiuTransService + Translate

extension NiuTransService {
    // MARK: - NiuTrans API

    private func niuTransTranslate(
        _ text: String,
        from: Language,
        to: Language,
        completion: @escaping (QueryResult, (any Error)?) -> ()
    ) {
        let sourceLangCode = languageCode(forLanguage: from) ?? "auto"
        let targetLangCode = languageCode(forLanguage: to) ?? ""

        let params: [String: Any] = [
            "apikey": apiKey,
            "src_text": text.truncated(5000),
            "from": sourceLangCode,
            "to": targetLangCode,
            "source": "Easydict",
        ]

        let manager = AFHTTPSessionManager()
        // Response data is JSON format, but the response header is text/html,
        // so we have to add text/html
        // https://github.com/tisfeng/Easydict/pull/239#discussion_r1402998211
        manager.responseSerializer.acceptableContentTypes = ["application/json", "text/html"]
        manager.session.configuration.timeoutIntervalForRequest = EZNetWorkTimeoutInterval

        let task = manager.post(
            kNiuTransAPIURL,
            parameters: params,
            progress: nil,
            success: { [weak self] _, responseObject in
                guard let self = self else { return }

                if let responseDict = responseObject as? [String: Any] {
                    parseResponse(responseDict, completion: completion)
                } else {
                    completion(result, QueryError(type: .api, message: "Invalid response"))
                }
            },
            failure: { [weak self] _, error in
                guard let self = self else { return }

                if queryModel.isServiceStopped(serviceType().rawValue) {
                    return
                }

                if (error as NSError).code == NSURLErrorCancelled {
                    return
                }

                logError("NiuTransTranslate error: \(error)")
                completion(result, error)
            }
        )

        queryModel.setStop({
            task?.cancel()
        }, serviceType: serviceType().rawValue)
    }

    // MARK: - Response Parser

    private func parseResponse(
        _ responseDict: [String: Any],
        completion: @escaping (QueryResult, (any Error)?) -> ()
    ) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: responseDict)
            let response = try JSONDecoder().decode(NiuTransTranslateResponse.self, from: jsonData)

            if let translatedText = response.tgtText?.trimmingCharacters(in: .newlines),
               !translatedText.isEmpty {
                result.translatedResults = translatedText.toParagraphs()
                result.raw = responseDict as NSDictionary
                completion(result, nil)
            } else if let errorCode = response.errorCode {
                var message = errorCode
                if let errorMsg = response.errorMsg {
                    message = "\(errorCode), \(errorMsg)"
                }
                completion(result, QueryError(type: .api, message: message))
            } else {
                completion(result, QueryError(type: .api, message: "Unknown error"))
            }
        } catch {
            completion(result, QueryError(type: .api, message: "Failed to decode response"))
        }
    }
}
