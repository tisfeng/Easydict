//
//  OpenAIService.swift
//  Easydict
//
//  Created by tisfeng on 2023/12/31.
//  Copyright © 2023 izual. All rights reserved.
//

import Foundation
import OpenAI

@objc(EZOpenAIService)
public class OpenAIService: QueryService {
    private var apiKey: String {
        // easydict://writeKeyValue?EZOpenAIAPIKey=

        var apiKey = UserDefaults.standard.string(forKey: EZOpenAIAPIKey) ?? ""
        if apiKey.isEmpty, Configuration.shared.beta {
            apiKey = defaultAPIKey
        }

        return apiKey
    }

    private var endPoint: String {
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

    private var host: String {
        // easydict://writeKeyValue?EZOpenAIDomainKey=

        var host = UserDefaults.standard.string(forKey: EZOpenAIDomainKey) ?? ""
        if host.isEmpty {
            host = "api.openai.com"
        }
        return host
    }

    private var defaultModel: String {
        let defaultModel = hasPrivateAPIKey() ? "gpt-3.5-turbo" : "gemini-pro"
        return defaultModel
    }

    private var model: String {
        // easydict://writeKeyValue?EZOpenAIModelKey=

        var model = UserDefaults.standard.string(forKey: EZOpenAIModelKey) ?? ""
        if !hasPrivateAPIKey() {
            // Do not allow to modify model if user has not personal key in non-debug env.
            #if !DEBUG
                model = defaultModel
            #endif
        }

        if model.isEmpty {
            model = defaultModel
        }
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
        let type = Configuration.shared.intelligentQueryTextTypeForServiceType(serviceType())
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

    override public func translate(_ text: String, from: Language, to: Language, completion: @escaping (EZQueryResult, Error?) -> Void) {
        let host = URL(string: endPoint)?.host ?? host
        let configuration = OpenAI.Configuration(token: apiKey, host: host)
        let openAI = OpenAI(configuration: configuration)

        let chats = chatMessages(text: text, from: from, to: to)

        let query = ChatQuery(messages: chats, model: model)
        var resultText = ""

        openAI.chatsStream(query: query) { [weak self] res in
            guard let self else { return }

            switch res {
            case let .success(chatResult):
                if let content = chatResult.choices.first?.delta.content {
                    resultText += content
                    result.translatedResults = [resultText]
                    completion(result, nil)
                }
            case let .failure(error):
                completion(result, error)
            }
        } completion: { [weak self] error in
            guard let self else { return }

            if let error {
                print("chatsStream error: \(String(describing: error))")
                completion(result, error)
            } else {
                // Since it is more difficult to accurately remove redundant quotes in streaming, we wait until the end of the request to remove the quotes.
                let nsText = resultText as NSString
                resultText = nsText.tryToRemoveQuotes()
                result.translatedResults = [resultText]
                completion(result, nil)
            }
        }
    }
}

extension Language {
    static var wenyanwen = "文言文"
}
