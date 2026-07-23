//
//  YandexService.swift
//  Easydict
//
//  Created by Emil Batmanov on 2026/07/23.
//  Copyright © 2026 izual. All rights reserved.
//

import Alamofire
import Defaults
import Foundation
import SwiftUI

// MARK: - ServiceType

extension ServiceType {
    static let yandex = ServiceType(rawValue: "Yandex")
}

// MARK: - Defaults.Keys

extension Defaults.Keys {
    static let yandexMozhiEndpoint = Key<String>(
        "EZYandexMozhiEndpointKey",
        default: "https://mozhi.aryak.me"
    )
}

// MARK: - YandexService

/// Translates text with Yandex through a Mozhi proxy instance.
///
/// The service follows the public Mozhi API contract used by Crow
/// Translate. It avoids a Yandex Cloud account while allowing the proxy
/// endpoint to be replaced.
@objc(EZYandexService)
@objcMembers
final class YandexService: QueryService {
    // MARK: Lifecycle

    required init() {
        self.session = .default
        self.baseURLOverride = nil
        super.init()
    }

    @nonobjc
    init(session: Session, baseURL: URL) {
        self.session = session
        self.baseURLOverride = baseURL
        super.init()
    }

    // MARK: Internal

    override func configurationListItems() -> Any? {
        ServiceConfigurationSecretSectionView(
            service: self,
            observeKeys: [.yandexMozhiEndpoint]
        ) {
            InputCell(
                textFieldTitleKey: "service.configuration.yandex.endpoint.title",
                key: .yandexMozhiEndpoint,
                placeholder: "service.configuration.yandex.endpoint.placeholder"
            )
        }
    }

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
            "engine": "yandex",
            "from": languageCode(forLanguage: from) ?? "auto",
            "to": languageCode(forLanguage: to) ?? "",
            "text": text,
        ]
        let baseURL = try mozhiBaseURL()
        let request = session.request(
            baseURL.appendingPathComponent("api/translate"),
            parameters: parameters,
            requestModifier: { request in
                request.timeoutInterval = EZNetWorkTimeoutInterval
            }
        )

        queryModel.setStop({
            request.cancel()
        }, serviceType: serviceType().rawValue)

        let dataTask = request
            .validate(statusCode: 200 ..< 300)
            .serializingDecodable(MozhiResponse.self)

        do {
            let response = try await dataTask.value

            guard !response.translatedText.isEmpty else {
                throw QueryError(type: .noResult)
            }

            currentResult.translatedResults = response.translatedText.toParagraphs()
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
    private let baseURLOverride: URL?

    /// Resolves and validates the configured Mozhi instance root URL.
    private func mozhiBaseURL() throws -> URL {
        if let baseURLOverride {
            return baseURLOverride
        }

        let endpoint = Defaults[.yandexMozhiEndpoint].trim()
        guard let url = URL(string: endpoint),
              let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              url.host != nil
        else {
            throw QueryError(
                type: .parameter,
                errorDataMessage: endpoint
            )
        }
        return url
    }
}

// MARK: - MozhiResponse

/// Decodes the translation fields returned by Mozhi's provider-neutral API.
private struct MozhiResponse: Decodable {
    // MARK: Internal

    let translatedText: String

    // MARK: Private

    private enum CodingKeys: String, CodingKey {
        case translatedText = "translated-text"
    }
}
