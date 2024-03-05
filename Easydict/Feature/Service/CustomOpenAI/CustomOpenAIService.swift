//
//  CustomOpenAIService.swift
//  Easydict
//
//  Created by phlpsong on 2024/2/16.
//  Copyright © 2024 izual. All rights reserved.
//

import Alamofire
import CryptoKit
import Defaults
import Foundation

@objc(EZCustomOpenAIService)
class CustomOpenAIService: OpenAILikeService {
    // MARK: Lifecycle

    override init() {
        super.init()
        #if DEBUG
        defaultAPIKey = "NnZp/jV9prt5empCOJIM8LmzHmFdTiVa4i+mURU8t+uGpT+nDt/JTdf14JglJLEwpXkkSw+uGgiE8n5skqDdjQ=="
            .decryptAES()
        #else
        defaultAPIKey = "NnZp/jV9prt5empCOJIM8LmzHmFdTiVa4i+mURU8t+uGpT+nDt/JTdf14JglJLEwVm8Sup83uzJjMANeEvyPcw=="
            .decryptAES()
        #endif
    }

    // MARK: Public

    override public func name() -> String {
        NSLocalizedString("one_api", comment: "The name of One API Translate")
    }

    override public func link() -> String? {
        "https://chat.openai.com"
    }

    // MARK: Internal

    override var apiKey: String {
        let key = Defaults[.customOpenAIAPIKey]
        if let key, !key.isEmpty {
            return key
        }
        return defaultAPIKey
    }

    override var endPoint: String {
        let endPoint = Defaults[.customOpenAIEndPoint]
        if let endPoint, !endPoint.isEmpty {
            return endPoint
        }
        return ""
    }

    override var model: String {
        let model = Defaults[.customOpenAIModel]
        if let model, !model.isEmpty {
            return model
        }
        return hasPrivateAPIKey() ? "gpt-3.5-turbo-1106" : "gemini-pro"
    }

    override func hasPrivateAPIKey() -> Bool {
        apiKey != defaultAPIKey
    }

    override func serviceType() -> ServiceType {
        .customOpenAI
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

            if language != Language.burmese {
                orderedDict.setObject(value as NSString, forKey: language.rawValue as NSString)
            }
        }

        return orderedDict
    }

    override func queryTextType() -> EZQueryTextType {
        var typeOptions: EZQueryTextType = []
        let isTranslationEnabled = Defaults[.customOpenAITranslation] == "1"
        let isDictionaryEnabled = Defaults[.customOpenAIDictionary] == "1"
        let isSentenceEnabled = Defaults[.customOpenAISentence] == "1"
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
        let customOpenAIServiceUsageStatus = Defaults[.customOpenAIServiceUsageStatus]
        guard let value = UInt(customOpenAIServiceUsageStatus.rawValue) else { return .default }
        return EZServiceUsageStatus(rawValue: value) ?? .default
    }
}
