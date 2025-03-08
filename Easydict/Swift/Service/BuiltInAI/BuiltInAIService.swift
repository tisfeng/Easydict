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
    // MARK: Lifecycle

    override init() {
        super.init()

        // Set default supported models, disable user to change it.
        // Generally, it should be updated only when the app is updated.
        supportedModels = defaultModels.joined(separator: ", ")
    }

    // MARK: Public

    public override func name() -> String {
        NSLocalizedString("built_in_ai", comment: "")
    }

    public override func serviceType() -> ServiceType {
        .builtInAI
    }

    public override func configurationListItems() -> Any {
        StreamConfigurationView(
            service: self,
            showAPIKeySection: false,
            showEndpointSection: false
        )
    }

    // MARK: Internal

    override var defaultModels: [String] {
        [
            // Mistral free models https://docs.mistral.ai/getting-started/models/models_overview/#free-models
            "mistral-small-latest", // 32k, 1 RPS, 500,000 TPM,  [≈ Llama 3.3 70B or Qwen 32B]

            // Groq free models https://console.groq.com/docs/models
            "gemma-2-9b", // gemma2-9b-it, 30 RPM, 14,400 RPD, 15,000 TPM, 500,000 TPD
            "llama-3-70b", // llama3-70b-8192, 30 RPM, 14,400 RPD, 6,000 TPM, 500,000 TPD
            "llama-3.3-70b", // llama-3.3-70b-versatile, 30 RPM, 1,00 RPD, 6,000 TPM, 100,000 TPD
            "qwen-2.5-32b", // 30 RPM, 1,000 RPD, 6,000 TPM,

            // Google free models https://ai.google.dev/gemini-api/docs/models/gemini#gemini-2.0-flash-lite
            "gemini-2.0-flash-lite", // 30 RPM, 1,500 RPD, 1,000,000 TPM

            // zhipu free model https://bigmodel.cn/dev/howuse/model
            "glm-4-flash", // glm-4-flash, 128k context, 4k output, 200 QoS | THUDM/glm-4-9b-chat(SiliconFlow)
        ]
    }

    override var apiKey: String {
        builtInAIAPIKey
    }

    override var endpoint: String {
        builtInAIEndpoint
    }

    override var observeKeys: [Defaults.Key<String>] {
        [supportedModelsKey]
    }
}
