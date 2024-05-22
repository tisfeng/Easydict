//
//  LLMStreamService.swift
//  Easydict
//
//  Created by tisfeng on 2024/5/20.
//  Copyright © 2024 izual. All rights reserved.
//

import Defaults
import Foundation
import OpenAI

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

    // MARK: Internal

    let throttler = Throttler()
    var updateCompletion: ((EZQueryResult, Error?) -> ())?

    var model = ""

    var unsupportedLanguages: [Language] {
        []
    }

    var availableModels: [String] {
        [""]
    }

    var apiKey: String {
        ""
    }

    var endpoint: String {
        ""
    }

    func getFinalResultText(text: String) -> String {
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

    /// Get query type by text and from && to langauge.
    func queryType(text: String, from: Language, to _: Language) -> EZQueryTextType {
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
