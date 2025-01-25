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
            // SiliconFlow free models https://cloud.siliconflow.cn/models
            "yi-1.5-9b", // 01-ai/Yi-1.5-9B-Chat-16K, 1,000 RPM,  50,000 TPM

            // zhipu free model https://bigmodel.cn/dev/howuse/model
            "glm-4-flash", // glm-4-flash, 128k context, 4k output, 200 QoS | THUDM/glm-4-9b-chat(SiliconFlow)

            // Groq free models https://console.groq.com/docs/models
            "gemma-2-9b-it",
            // gemma2-9b-it, 8k, 30 RPM, 14,400 RPD, 15,000 TPM, 500,000 TPD | google/gemma-2-9b-it(SiliconFlow)
            "llama-3-70b", // llama3-70b-8192, 8k, 30 RPM, 14,400 RPD, 6,000 TPM, 500,000 TPD
            "llama-3.1-70b", // llama-3.1-70b-versatile, 128k, 30 RPM, 14,400 RPD, 6,000 TPM, 200,000 TPD

            // Google Gemini https://ai.google.dev/gemini-api/docs/models/gemini
            "gemini-1.5-flash", // Free: 15 RPM, 1,000,000 TPM, 1,500 RPD
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
