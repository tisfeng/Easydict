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
            "llama3-70b-8192", // 30 RPM
            "mixtral-8x7b-32768",

            // Google Gemini https://ai.google.dev/pricing?hl=zh-cn
            "gemini-pro",
            "gemini-1.5-flash-latest", // free 15 RPM

            /**
                阿里通义千问 DashScope

                https://help.aliyun.com/zh/dashscope/developer-reference/tongyi-qianwen-7b-14b-72b-metering-and-billing
                */
            "qwen1.5-110b-chat", // 有效期：2024-05-28
            "qwen1.5-32b-chat", // 有效期：2024-06-19
            "qwen-turbo", // free total 2,000,000 tokens, until 8.12
            "baichuan2-13b-chat-v1", // free until 8.12, total 1,000,000 tokens
            "deepseek-7b-chat", // 开通DashScope即获赠总计 1,000,000 tokens 限时免费使用额度，有效期180天。
            "internlm-7b-chat", // 开通DashScope即获赠总计 1,000,000 tokens 限时免费使用额度，有效期180天。

            /**
                百度千帆大模型

                5月21日起，百度智能云千帆大模型平台ModelBuilder中ERNIE-Speed、ERNIE-Lite、ERNIE-Tiny系列模型Tokens后付费的服务对客户免费开放使用，具体包括ERNIE-Speed-8K、ERNIE-Speed-128K、ERNIE-Speed-AppBuilder专用版、ERNIE-Lite-8K、ERNIE-Lite-8K-0922、ERNIE-Lite-128K（即将上线）、ERNIE-Tiny共计7款模型的预置服务

                https://cloud.baidu.com/doc/WENXINWORKSHOP/s/wlwg8f1i3
                */
            "ernie_speed", // ERNIE-Speed-8K, it has a higher RPM(300) than ERNIE-Speed-128K(RPM=60)
            "ernie-lite-8k",
        ]
    }
}
