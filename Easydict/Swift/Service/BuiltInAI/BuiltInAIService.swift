//
//  BuiltInAIService.swift
//  Easydict
//
//  Created by tisfeng on 2024/4/13.
//  Copyright © 2024 izual. All rights reserved.
//

import Defaults
import Foundation

@objc(EZBuiltInAIService)
class BuiltInAIService: BaseOpenAIService {
    // MARK: Public

    override public func name() -> String {
        NSLocalizedString("built_in_ai", comment: "")
    }

    // MARK: Internal

    override var apiKey: String {
        defaultAPIKey
    }

    override var endpoint: String {
        defaultEndpoint
    }

    override var model: String {
        get {
            Defaults[.builtInAIModel]
        }

        set {
            Defaults[.builtInAIModel] = newValue
        }
    }

    override var availableModels: [String] {
        [
            "gemini-pro",

            // DashScope 限时免费开放中 https://help.aliyun.com/zh/dashscope/developer-reference/tongyi-qianwen-7b-14b-72b-metering-and-billing
            "qwen1.5-32b-chat",
            "qwen-turbo",
            "qwen-plus",
            "yi-34b-chat",
            "deepseek-7b-chat",
            "internlm-7b-chat",

            // Groq https://console.groq.com/docs/models
            "mixtral-8x7b-32768",
        ]
    }

    override func serviceType() -> ServiceType {
        .builtInAI
    }

    override func intelligentQueryTextType() -> EZQueryTextType {
        Configuration.shared.intelligentQueryTextTypeForServiceType(serviceType())
    }

    override func queryTextType() -> EZQueryTextType {
        // Since some models are not good at dictionary, so we only use translation here.
        [.translation]
    }

    override func serviceUsageStatus() -> EZServiceUsageStatus {
        .default
    }
}
