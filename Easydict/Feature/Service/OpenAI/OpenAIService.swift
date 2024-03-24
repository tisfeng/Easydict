//
//  OpenAIService.swift
//  Easydict
//
//  Created by phlpsong on 2024/3/17.
//  Copyright © 2024 izual. All rights reserved.
//

import Defaults
import Foundation

@objc(EZOpenAIService)
class OpenAIService: OpenAILikeService {
    // MARK: Lifecycle

    override init() {
        super.init()
        self.defaultModel = OpenAIModel.gpt3_5_turbo_0125.rawValue
    }

    // MARK: Public

    override public func name() -> String {
        NSLocalizedString("openai_translate", comment: "")
    }

    // MARK: Internal

    override var apiKey: String {
        Defaults[.openAIAPIKey] ?? ""
    }

    override var endPoint: String {
        let endPoint = Defaults[.openAIEndPoint] ?? ""
        if endPoint.isEmpty {
            return "https://api.openai.com/v1/chat/completions"
        }
        return endPoint
    }

    override var model: String {
        get {
            var model = Defaults[.openAIModel].rawValue
            if !hasPrivateAPIKey() {
                #if DEBUG
                model = defaultModel
                #endif
            }
            if model.isEmpty {
                model = defaultModel
            }
            return model
        }

        set {
            let new = OpenAIModel(rawValue: newValue) ?? .gpt3_5_turbo_0125
            Defaults[.openAIModel] = new
        }
    }

    override var availableModels: [String] {
        OpenAIModel.allCases.map { $0.rawValue }
    }

    override func link() -> String? {
        "https://chat.openai.com"
    }

    override func serviceType() -> ServiceType {
        .openAI
    }

    override func intelligentQueryTextType() -> EZQueryTextType {
        Configuration.shared.intelligentQueryTextTypeForServiceType(serviceType())
    }

    override func supportLanguagesDictionary() -> MMOrderedDictionary<AnyObject, AnyObject> {
        let orderedDict = MMOrderedDictionary<AnyObject, AnyObject>()
        for language in EZLanguageManager.shared().allLanguages {
            var value = language.rawValue
            if language == Language.classicalChinese {
                value = kEZLanguageWenYanWen
            }
            // OpenAI does not support Burmese 🥲
            if language != Language.burmese {
                orderedDict.setObject(value as NSString, forKey: language.rawValue as NSString)
            }
        }

        return orderedDict
    }

    override func queryTextType() -> EZQueryTextType {
        var typeOptions: EZQueryTextType = []
        let isTranslationEnabled = Defaults[.openAITranslation] == "1"
        let isDictionaryEnabled = Defaults[.openAIDictionary] == "1"
        let isSentenceEnabled = Defaults[.openAISentence] == "1"
        if isTranslationEnabled {
            typeOptions.insert(.translation)
        }
        if isDictionaryEnabled {
            typeOptions.insert(.dictionary)
        }
        if isSentenceEnabled {
            typeOptions.insert(.sentence)
        }
        if typeOptions == [] {
            typeOptions = [.translation]
        }
        return typeOptions
    }

    override func serviceUsageStatus() -> EZServiceUsageStatus {
        let usageStatus = Defaults[.openAIServiceUsageStatus]
        guard let value = UInt(usageStatus.rawValue) else { return .default }
        return EZServiceUsageStatus(rawValue: value) ?? .default
    }

    override func hasPrivateAPIKey() -> Bool {
        !apiKey.isEmpty && apiKey != defaultAPIKey
    }
}
