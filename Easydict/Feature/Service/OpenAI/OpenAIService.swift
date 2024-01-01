//
//  OpenAIService.swift
//  Easydict
//
//  Created by tisfeng on 2023/12/31.
//  Copyright © 2023 izual. All rights reserved.
//

import Foundation

@objc(EZOpenAIService)
public class OpenAIService: QueryService {
    private var defaultAPIKey: String {
        var apiKey = "NnZp/jV9prt5empCOJIM8LmzHmFdTiVa4i+mURU8t+uGpT+nDt/JTdf14JglJLEwVm8Sup83uzJjMANeEvyPcw==".decryptAES()
        #if DEBUG
            apiKey = "NnZp/jV9prt5empCOJIM8LmzHmFdTiVa4i+mURU8t+uGpT+nDt/JTdf14JglJLEwpXkkSw+uGgiE8n5skqDdjQ==".decryptAES()
        #endif
        return apiKey
    }

    private var apiKey: String {
        var apiKey = UserDefaults.standard.string(forKey: EZOpenAIAPIKey) ?? ""
        if apiKey.count == 0, EZConfiguration.shared().isBeta {
            apiKey = defaultAPIKey
        }

        return apiKey
    }

    private var defaultEndPoint = "gTYTMVQTyMU0ogncqcMNRo/TDhten/V4TqX4IutuGNcYTLtxjgl/aXB/Y1NXAjz2".decryptAES()
    private var endPoint: String {
        var endPoint = UserDefaults.standard.string(forKey: EZOpenAIEndPointKey) ?? ""
        if endPoint.count == 0 {
            endPoint = "https://\(domain)/v1/chat/completions"
        }

        if !hasPrivateAPIKey() {
            endPoint = defaultEndPoint
        }

        return endPoint
    }

    private var domain: String {
        var domain = UserDefaults.standard.string(forKey: EZOpenAIDomainKey) ?? ""
        if domain.count == 0 {
            domain = "api.openai.com"
        }
        return domain
    }

    private var defaultModel: String {
        let model = hasPrivateAPIKey() ? "gpt.3.5-turbo" : "gemini-pro"
        return model
    }

    override public func hasPrivateAPIKey() -> Bool {
        if apiKey == defaultAPIKey {
            return false
        }
        return true
    }

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
        let type = EZConfiguration.shared().intelligentQueryTextType(forServiceType: serviceType())
        return type
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

    override public func translate(_ text: String, from _: Language, to _: Language, completion: @escaping (EZQueryResult, Error?) -> Void) {
        let result = result
        result.translatedResults = [text]

        completion(result, nil)
    }
}

extension Language {
    static var wenyanwen = "文言文"
}
