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

    override public func serviceType() -> ServiceType {
        .builtInAI
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
            var model = Defaults[.builtInAIModel]
            if model.isEmpty {
                model = availableModels.first!
            }
            return model
        }

        set {
            Defaults[.builtInAIModel] = newValue
        }
    }

    override var availableModels: [String] {
        [
            // Groq free models https://console.groq.com/docs/models
            "llama3-70b-8192",
            "mixtral-8x7b-32768",

            // It seems that 5.2 will start charging 😥 https://ai.google.dev/pricing?hl=zh-cn
            "gemini-pro",

            /**
                阿里通义千问 DashScope 限时免费开放中 https://help.aliyun.com/zh/dashscope/developer-reference/tongyi-qianwen-7b-14b-72b-metering-and-billing

                通义千问开源系列，开通DashScope即获赠总计 1,000,000 tokens 限时免费使用额度，有效期30天。(qwen1.5-32b-chat模型目前限时免费开放中)
                */
            "qwen1.5-32b-chat", // 目前限时免费开放中
            "qwen-turbo", // free total 2,000,000 tokens, until 8.12
            "baichuan2-13b-chat-v1", // free until 8.12, total 1,000,000 tokens
            "deepseek-7b-chat", // 开通DashScope即获赠总计 1,000,000 tokens 限时免费使用额度，有效期180天。
            "internlm-7b-chat", // 开通DashScope即获赠总计 1,000,000 tokens 限时免费使用额度，有效期180天。
        ]
    }
}
