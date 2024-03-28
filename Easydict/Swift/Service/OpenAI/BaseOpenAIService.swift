//
//  BaseOpenAIService.swift
//  Easydict
//
//  Created by tisfeng on 2024/3/28.
//  Copyright © 2024 izual. All rights reserved.
//

import Defaults
import Foundation
import OpenAI

// MARK: - BaseOpenAIService

// In order to solve the problems caused by inheriting the OpenAI service for custom OpenAI services, we had to add a new base class. FIX https://github.com/tisfeng/Easydict/pull/473#issuecomment-2022587699

@objcMembers
@objc(EZBaseOpenAIService)
public class BaseOpenAIService: QueryService {
    // MARK: Public

    override public func serviceType() -> ServiceType {
        .openAI
    }

    override public func name() -> String {
        NSLocalizedString("openai_translate", comment: "")
    }

    override public func link() -> String? {
        "https://chat.openai.com"
    }

    override public func queryTextType() -> EZQueryTextType {
        var type: EZQueryTextType = []
        let enableTranslation = UserDefaults.standard.string(forKey: EZOpenAITranslationKey) ?? "0"
        if enableTranslation != "0" {
            type.insert(.translation)
        }

        let enableDictionary = UserDefaults.standard.string(forKey: EZOpenAIDictionaryKey) ?? "0"
        if enableDictionary != "0" {
            type.insert(.dictionary)
        }

        let enableSentence = UserDefaults.standard.string(forKey: EZOpenAISentenceKey) ?? "0"
        if enableSentence != "0" {
            type.insert(.sentence)
        }

        return type
    }

    override public func intelligentQueryTextType() -> EZQueryTextType {
        Configuration.shared.intelligentQueryTextTypeForServiceType(serviceType())
    }

    override public func supportLanguagesDictionary() -> MMOrderedDictionary<AnyObject, AnyObject> {
        let orderedDict = MMOrderedDictionary<AnyObject, AnyObject>()
        for language in EZLanguageManager.shared().allLanguages {
            var value = language.rawValue
            if language == .classicalChinese {
                value = Language.wenyanwen
            }

            if language != .burmese {
                orderedDict.setObject(value as NSString, forKey: language.rawValue as NSString)
            }
        }

        return orderedDict
    }

    // swiftlint:disable identifier_name
    override public func translate(
        _ text: String,
        from: Language,
        to: Language,
        completion: @escaping (EZQueryResult, Error?) -> ()
    ) {
        let url = URL(string: endPoint)
        let invalidURLError = EZError(type: .param, description: "\(serviceType().rawValue) URL is invalid")
        guard let url, url.isValid else { completion(result, invalidURLError); return }

        var resultText = ""

        result.from = from
        result.to = to

        let queryType = queryTextType(text: text, from: from, to: to)
        let chats = chatMessages(queryType: queryType, text: text, from: from, to: to)
        let query = ChatQuery(messages: chats, model: model, temperature: 0)
        let openAI = OpenAI(apiToken: apiKey)

        openAI.chatsStream(query: query, url: url) { [weak self] res in
            guard let self else { return }

            switch res {
            case let .success(chatResult):
                if let content = chatResult.choices.first?.delta.content {
                    resultText += content
                    handleResult(queryType: queryType, resultText: resultText, error: nil, completion: completion)
                }
            case let .failure(error):
                handleResult(queryType: queryType, resultText: nil, error: error, completion: completion)
            }
        } completion: { [weak self] error in
            guard let self else { return }

            if let error {
                print("chatsStream error: \(String(describing: error))")
                completion(result, error)
            } else {
                // If already has error, we do not need to update it.
                if result.error == nil {
                    // Since it is more difficult to accurately remove redundant quotes in streaming, we wait until the end of the request to remove the quotes.
                    let nsText = resultText as NSString
                    resultText = nsText.tryToRemoveQuotes()
                    handleResult(queryType: queryType, resultText: resultText, error: nil, completion: completion)
                }
            }
        }
    }

    // swiftlint:enable identifier_name

    // MARK: Internal

    var model: String {
        get {
            var model = Defaults[.openAIModel].rawValue
            if model.isEmpty {
                model = availableModels.first ?? OpenAIModel.gpt3_5_turbo_0125.rawValue
            }
            return model
        }

        set {
            // easydict://writeKeyValue?EZOpenAIModelKey=gpt-3.5-turbo
            let mode = OpenAIModel(rawValue: newValue) ?? .gpt3_5_turbo_0125
            Defaults[.openAIModel] = mode
        }
    }

    var apiKey: String {
        // easydict://writeKeyValue?EZOpenAIAPIKey=

        var apiKey = UserDefaults.standard.string(forKey: EZOpenAIAPIKey) ?? ""
        if apiKey.isEmpty, Configuration.shared.beta {
            apiKey = defaultAPIKey
        }

        return apiKey
    }

    var endPoint: String {
        // easydict://writeKeyValue?EZOpenAIEndPointKey=

        var endPoint = UserDefaults.standard.string(forKey: EZOpenAIEndPointKey) ?? ""
        if endPoint.isEmpty {
            endPoint = "https://\(host)/v1/chat/completions"
        }

        if !hasPrivateAPIKey() {
            endPoint = defaultEndPoint
        }

        return endPoint
    }

    var availableModels: [String] {
        OpenAIModel.allCases.map { $0.rawValue }
    }

    // MARK: Private

    private var host: String {
        // easydict://writeKeyValue?EZOpenAIDomainKey=
        var host = UserDefaults.standard.string(forKey: "EZOpenAIDomainKey") ?? ""
        if host.isEmpty {
            host = "api.openai.com"
        }
        return host
    }

    private func queryTextType(text: String, from: Language, to _: Language) -> EZQueryTextType {
        let enableDictionary = queryTextType().contains(.dictionary)
        var isQueryDictionary = false
        if enableDictionary {
            isQueryDictionary = (text as NSString).shouldQueryDictionary(withLanguage: from, maxWordCount: 2)
            if isQueryDictionary {
                return .dictionary
            }
        }

        let enableSentence = queryTextType().contains(.sentence)
        var isQueryEnglishSentence = false
        if !isQueryDictionary, enableSentence {
            let isEnglishText = from == .english
            if isEnglishText {
                isQueryEnglishSentence = (text as NSString).shouldQuerySentence(withLanguage: from)
                if isQueryEnglishSentence {
                    return .sentence
                }
            }
        }

        let enableTranslation = queryTextType().contains(.translation)
        if enableTranslation {
            return .translation
        }

        return []
    }

    private func handleResult(
        queryType: EZQueryTextType,
        resultText: String?,
        error: Error?,
        completion: @escaping (EZQueryResult, Error?) -> ()
    ) {
        let normalResults = [resultText?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""]

        switch queryType {
        case .sentence, .translation:
            result.translatedResults = normalResults
            completion(result, error)

        case .dictionary:
            if let error {
                result.showBigWord = false
                result.translateResultsTopInset = 0
                completion(result, error)
                return
            }

            result.translatedResults = normalResults
            result.showBigWord = true
            result.queryText = queryModel.queryText
            result.translateResultsTopInset = 6
            completion(result, error)

        default:
            completion(result, error)
        }
    }
}

extension Language {
    static var wenyanwen = "文言文"
}
