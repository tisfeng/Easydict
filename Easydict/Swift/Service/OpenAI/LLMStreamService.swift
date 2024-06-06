//
//  LLMStreamService.swift
//  Easydict
//
//  Created by tisfeng on 2024/5/20.
//  Copyright © 2024 izual. All rights reserved.
//

import Defaults
import Foundation

// MARK: - LLMStreamService

@objcMembers
@objc(EZLLMStreamService)
public class LLMStreamService: QueryService {
    // MARK: Public

    override public func isStream() -> Bool {
        true
    }

    override public func intelligentQueryTextType() -> EZQueryTextType {
        Configuration.shared.intelligentQueryTextTypeForServiceType(serviceType())
    }

    override public func supportLanguagesDictionary() -> MMOrderedDictionary<AnyObject, AnyObject> {
        let allLanguages = EZLanguageManager.shared().allLanguages
        let supportedLanguages = allLanguages.filter { language in
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

    // MARK: Internal

    let throttler = Throttler()

    let mustOverride = "This property or method must be overridden by a subclass"

    var unsupportedLanguages: [Language] {
        []
    }

    var model: String {
        get { fatalError(mustOverride) }
        set { _ = newValue; fatalError(mustOverride) }
    }

    var availableModels: [String] {
        fatalError(mustOverride)
    }

    var apiKey: String {
        fatalError(mustOverride)
    }

    var endpoint: String {
        fatalError(mustOverride)
    }

    /// Base on chat query, convert prompt dict to LLM service prompt model.
    func serviceChatMessageModels(_ chatQuery: ChatQueryParam)
        -> [Any] {
        fatalError(mustOverride)
    }

    func getFinalResultText(_ text: String) -> String {
        var resultText = text.trim()

        // Remove last </s>, fix Groq model mixtral-8x7b-32768
        let stopFlag = "</s>"
        if !queryModel.queryText.hasSuffix(stopFlag), resultText.hasSuffix(stopFlag) {
            resultText = String(resultText.dropLast(stopFlag.count)).trim()
        }

        // Since it is more difficult to accurately remove redundant quotes in streaming, we wait until the end of the request to remove the quotes
        let nsText = resultText as NSString
        resultText = nsText.tryToRemoveQuotes().trim()

        return resultText
    }

    /// Get query type by text and from && to language.
    func queryType(text: String, from: Language, to: Language) -> EZQueryTextType {
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
}

extension LLMStreamService {
    func updateResultText(
        _ resultText: String?,
        queryType: EZQueryTextType,
        error: Error?,
        completion: @escaping (EZQueryResult, Error?) -> ()
    ) {
        if result.isStreamFinished {
            return
        }

        var translatedTexts: [String]?
        if let resultText {
            translatedTexts = [resultText.trim()]
        }

        result.isStreamFinished = error != nil
        result.translatedResults = translatedTexts

        let updateCompletion = {
            self.throttler.throttle { [unowned self] in
                completion(result, error)
            }
        }

        switch queryType {
        case .dictionary:
            if error != nil {
                result.showBigWord = false
                result.translateResultsTopInset = 0
                updateCompletion()
                return
            }

            result.showBigWord = true
            result.queryText = queryModel.queryText
            result.translateResultsTopInset = 6
            updateCompletion()

        default:
            updateCompletion()
        }
    }
}

// MARK: - ChatQueryParam

struct ChatQueryParam {
    let text: String
    let sourceLanguage: Language
    let targetLanguage: Language
    let queryType: EZQueryTextType
    let enableSystemPrompt: Bool

    func unpack() -> (String, Language, Language, EZQueryTextType, Bool) {
        (text, sourceLanguage, targetLanguage, queryType, enableSystemPrompt)
    }
}
