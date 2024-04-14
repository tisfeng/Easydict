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
class CustomOpenAIService: BaseOpenAIService {
    // MARK: Lifecycle

    override init() {
        super.init()
    }

    // MARK: Public

    override public func name() -> String {
        let name = Defaults[.customOpenAINameKey]
        if let name, !name.isEmpty {
            return name
        }
        return NSLocalizedString("custom_openai", comment: "The name of Custom OpenAI Translate")
    }

    // MARK: Internal

    override var apiKey: String {
        Defaults[.customOpenAIAPIKey] ?? ""
    }

    override var endpoint: String {
        Defaults[.customOpenAIEndPoint] ?? ""
    }

    override var model: String {
        get {
            Defaults[.customOpenAIModel]
        }

        set {
            Defaults[.customOpenAIModel] = newValue
        }
    }

    override var availableModels: [String] {
        Defaults[.customOpenAIVaildModels]
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
                value = Language.wenyanwen
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

    override func hasPrivateAPIKey() -> Bool {
        !apiKey.isEmpty
    }
}
