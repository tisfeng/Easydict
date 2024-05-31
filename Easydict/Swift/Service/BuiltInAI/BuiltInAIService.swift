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

            "ernie_speed",
            "ernie-lite-8k"
        ]
    }
}
