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

    override public func isStream() -> Bool {
        true
    }

    override public func intelligentQueryTextType() -> EZQueryTextType {
        Configuration.shared.intelligentQueryTextTypeForServiceType(serviceType())
    }

    override public func supportLanguagesDictionary() -> MMOrderedDictionary<AnyObject, AnyObject> {
        let allLangauges = EZLanguageManager.shared().allLanguages
        let supportedLanguages = allLangauges.filter { language in
            !unsupportedLanguages.contains(language)
        }

        let orderedDict = MMOrderedDictionary<AnyObject, AnyObject>()
        for language in supportedLanguages {
            orderedDict.setObject(language.rawValue as NSString, forKey: language.rawValue as NSString)
        }
        return orderedDict
    }

    override public func queryTextType() -> EZQueryTextType {
        var typeOptions: EZQueryTextType = []

        let isTranslationEnabled = UserDefaults.bool(forKey: EZTranslationKey, serviceType: serviceType())
        let isSentenceEnabled = UserDefaults.bool(forKey: EZSentenceKey, serviceType: serviceType())
        let isDictionaryEnabled = UserDefaults.bool(forKey: EZDictionaryKey, serviceType: serviceType())

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

    override public func serviceUsageStatus() -> EZServiceUsageStatus {
        let usageStatus = UserDefaults.string(forKey: EZServiceUsageStatusKey, serviceType: serviceType()) ?? ""
        guard let value = UInt(usageStatus) else { return .default }
        return EZServiceUsageStatus(rawValue: value) ?? .default
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

        let queryType = queryType(text: text, from: from, to: to)
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
                    // For stream requests, certain special cases may be normal for the first part of the data transfer, but the final parsing is incorrect.
                    var text: String?
                    var err: Error? = error
                    if !resultText.isEmpty {
                        text = resultText
                        err = nil

                        logError("\(name())-(\(model)) error: \(error.localizedDescription)")
                        logError(String(describing: error))
                    }
                    handleResult(
                        queryType: queryType,
                        resultText: text,
                        error: err,
                        completion: completion
                    )
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
                        resultText = getFinalResultText(text: resultText)

//                        log("\(name())-(\(model)): \(resultText)")
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

    var unsupportedLanguages: [Language] = []

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

    /// Get query type by text and from && to langauge.
    private func queryType(text: String, from: Language, to _: Language) -> EZQueryTextType {
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

        return .translation
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

    private func getFinalResultText(text: String) -> String {
        // Since it is more difficult to accurately remove redundant quotes in streaming, we wait until the end of the request to remove the quotes
        let nsText = text as NSString
        var resultText = nsText.tryToRemoveQuotes()

        // Remove last </s>, fix Groq mixtral-8x7b-32768
        let stopFlag = "</s>"
        if !queryModel.queryText.hasSuffix(stopFlag), resultText.hasSuffix(stopFlag) {
            resultText = String(resultText.dropLast(stopFlag.count))
        }

        return resultText
    }
}
