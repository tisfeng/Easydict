//
//  OpenAIService.swift
//  Easydict
//
//  Created by tisfeng on 2023/12/31.
//  Copyright © 2023 izual. All rights reserved.
//

import Defaults
import Foundation

// MARK: - OpenAIService

@objc(EZOpenAIService)
class OpenAIService: BaseOpenAIService {
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
        if Defaults[.openAITranslation] != "0" {
            type.insert(.translation)
        }
        if Defaults[.openAIDictionary] != "0" {
            type.insert(.dictionary)
        }
        if Defaults[.openAISentence] != "0" {
            type.insert(.sentence)
        }
        return type
    }

    public override func serviceUsageStatus() -> EZServiceUsageStatus {
        // swiftlint:disable:next todo
        // TODO: Later, we need to support all services to use usage status.
        let usageStatus = Defaults[.openAIServiceUsageStatus]
        guard let value = UInt(usageStatus.rawValue) else { return .default }
        return EZServiceUsageStatus(rawValue: value) ?? .default
    }

    // MARK: Internal

    override var availableModels: [String] {
        Defaults[.openAIVaildModels]
    }

    override var model: String {
        get {
            Defaults[.openAIModel]
        }

        set {
            // easydict://writeKeyValue?EZOpenAIModelKey=gpt-3.5-turbo

            Defaults[.openAIModel] = newValue
        }
    }

    override var apiKey: String {
        // easydict://writeKeyValue?EZOpenAIAPIKey=

        var apiKey = Defaults[.openAIAPIKey] ?? ""
        if apiKey.isEmpty, Configuration.shared.beta {
            apiKey = defaultAPIKey
        }

        return apiKey
    }

    override var endpoint: String {
        // easydict://writeKeyValue?EZOpenAIEndPointKey=

        var endPoint = Defaults[.openAIEndPoint] ?? ""
        if endPoint.isEmpty {
            endPoint = "https://api.openai.com/v1/chat/completions"
        }

        return endPoint
    }
}
