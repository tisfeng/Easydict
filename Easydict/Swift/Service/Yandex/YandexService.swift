//
//  YandexService.swift
//  Easydict
//
//  Created by Emil Batmanov on 2026/07/23.
//  Copyright © 2026 izual. All rights reserved.
//

import Alamofire
import Foundation

// MARK: - ServiceType

extension ServiceType {
    static let yandex = ServiceType(rawValue: "Yandex")
}

// MARK: - YandexService

/// Translates text through Yandex's unofficial mobile endpoint.
///
/// It follows the direct request contract used by the legacy Crow
/// Translate integration. No Yandex Cloud account or intermediary proxy is
/// required.
@objc(EZYandexService)
@objcMembers
final class YandexService: QueryService {
    // MARK: Lifecycle

    required init() {
        self.session = .default
        self.baseURL = URL(string: "https://translate.yandex.net")!
        super.init()
    }

    @nonobjc
    init(session: Session, baseURL: URL) {
        self.session = session
        self.baseURL = baseURL
        super.init()
    }

    // MARK: Internal

    override func serviceType() -> ServiceType {
        .yandex
    }

    override func name() -> String {
        NSLocalizedString("yandex_translate", comment: "")
    }

    override func link() -> String {
        "https://translate.yandex.com"
    }

    override func apiKeyRequirement() -> ServiceAPIKeyRequirement {
        .none
    }

    override func supportLanguagesDictionary() -> MMOrderedDictionary {
        let languages: [Any] = [
            Language.auto, "auto",
            Language.simplifiedChinese, "zh",
            Language.traditionalChinese, "zh-TW",
            Language.english, "en",
            Language.japanese, "ja",
            Language.korean, "ko",
            Language.french, "fr",
            Language.spanish, "es",
            Language.catalan, "ca",
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
            Language.georgian, "ka",
            Language.uyghur, "ug",
            NSNull(),
        ]

        let orderedDictionary = MMOrderedDictionary()
        for index in stride(from: 0, to: languages.count - 1, by: 2) {
            if let language = languages[index] as? NSObject,
               let code = languages[index + 1] as? NSObject {
                orderedDictionary.setObject(code, forKey: language)
            }
        }
        return orderedDictionary
    }

    /// Sends a cancellable Yandex request and maps its response or failure.
    override func translate(
        _ text: String,
        from: Language,
        to: Language
    ) async throws
        -> QueryResult {
        let currentResult = result ?? QueryResult()
        if result == nil {
            result = currentResult
        }

        let parameters = [
            "lang": languagePair(from: from, to: to),
            "text": text,
            "srv": "android",
            "sid": sessionIdentifier(),
        ]
        let request = session.request(
            baseURL.appendingPathComponent("api/v1/tr.json/translate"),
            method: .post,
            parameters: parameters,
            encoding: URLEncoding(destination: .queryString),
            headers: [
                .accept("application/json"),
                .contentType("application/json"),
            ],
            requestModifier: { request in
                request.timeoutInterval = EZNetWorkTimeoutInterval
            }
        )

        queryModel.setStop({
            request.cancel()
        }, serviceType: serviceType().rawValue)

        let dataTask = request
            .validate(statusCode: 200 ..< 300)
            .serializingDecodable(YandexResponse.self)

        do {
            let response = try await dataTask.value
            let translatedText = response.text.joined(separator: "\n")

            guard !translatedText.isEmpty else {
                throw QueryError(type: .noResult)
            }

            currentResult.translatedResults = translatedText.toParagraphs()
            return currentResult
        } catch let queryError as QueryError {
            throw queryError
        } catch {
            let response = await dataTask.response
            let responseBody = response.data.flatMap {
                String(data: $0, encoding: .utf8)
            }
            throw QueryError(
                type: .api,
                message: error.localizedDescription,
                errorDataMessage: responseBody
            )
        }
    }

    // MARK: Private

    private let session: Session
    private let baseURL: URL

    private func languagePair(from: Language, to: Language) -> String {
        let targetCode = languageCode(forLanguage: to) ?? ""
        guard from != .auto,
              let sourceCode = languageCode(forLanguage: from) else {
            return targetCode
        }
        return "\(sourceCode)-\(targetCode)"
    }

    private func sessionIdentifier() -> String {
        let identifier = UUID().uuidString
            .replacingOccurrences(of: "-", with: "")
            .lowercased()
        return "\(identifier)-0-0"
    }
}

// MARK: - YandexResponse

/// Decodes the translation fields returned by Yandex's mobile endpoint.
private struct YandexResponse: Decodable {
    let text: [String]
}
