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

    public override func isStream() -> Bool {
        true
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
        let url = URL(string: endpoint)
        let invalidURLError = EZError(type: .param, description: "\(serviceType().rawValue) URL is invalid")
        guard let url, url.isValid else {
            completion(result, invalidURLError)
            return
        }

        var resultText = ""

        result.from = from
        result.to = to
        result.isStreamFinished = false

        let queryType = queryTextType(text: text, from: from, to: to)
        let chats = chatMessages(queryType: queryType, text: text, from: from, to: to)
        let query = ChatQuery(messages: chats, model: model, temperature: 0)
        let openAI = OpenAI(apiToken: apiKey)

        openAI.chatsStream(query: query, url: url) { [weak self] res in
            guard let self else { return }

            if !result.isStreamFinished {
                switch res {
                case let .success(chatResult):
                    if let content = chatResult.choices.first?.delta.content {
                        resultText += content
                    }
                    handleResult(queryType: queryType, resultText: resultText, error: nil, completion: completion)
                case let .failure(error):
                    handleResult(queryType: queryType, resultText: nil, error: error, completion: completion)
                }
            }

        } completion: { [weak self] error in
            guard let self else { return }

            if !result.isStreamFinished {
                if let error {
                    handleResult(queryType: queryType, resultText: nil, error: error, completion: completion)
                } else {
                    // If already has error, we do not need to update it.
                    if result.error == nil {
                        // Since it is more difficult to accurately remove redundant quotes in streaming, we wait until the end of the request to remove the quotes.
                        let nsText = resultText as NSString
                        resultText = nsText.tryToRemoveQuotes()
                        log("\(name())-(\(model)): \(resultText)")
                        handleResult(queryType: queryType, resultText: resultText, error: nil, completion: completion)
                        result.isStreamFinished = true
                    }
                }
            }
        }
    }

    // swiftlint:enable identifier_name

    // MARK: Internal

    var model = ""

    var availableModels: [String] {
        [""]
    }

    var apiKey: String {
        ""
    }

    var endpoint: String {
        ""
    }

    // MARK: Private

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
        var normalResults: [String]?
        if let resultText {
            normalResults = [resultText.trimmingCharacters(in: .whitespacesAndNewlines)]
        }

        result.isStreamFinished = error != nil
        result.translatedResults = normalResults

        switch queryType {
        case .sentence, .translation:
            completion(result, error)

        case .dictionary:
            if let error {
                result.showBigWord = false
                result.translateResultsTopInset = 0
                completion(result, error)
                return
            }

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
