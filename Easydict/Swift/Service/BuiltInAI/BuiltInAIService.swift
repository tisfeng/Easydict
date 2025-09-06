//
//  BuiltInAIService.swift
//  Easydict
//
//  Created by tisfeng on 2024/4/13.
//  Copyright © 2024 izual. All rights reserved.
//

import Defaults
import Foundation

// MARK: - BuiltInAIService

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
            // GML free models
            GLMModel.glm_4_flash_250414.rawValue,
            GLMModel.glm_4_flash.rawValue,

            // Groq free models
            GroqModel.llama3_1_8b_instant.rawValue,
        ]
    }

    override var defaultModel: String {
        GLMModel.glm_4_flash_250414.rawValue
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

// MARK: - GLMModel

enum GLMModel: String, CaseIterable {
    // zhipu free model https://docs.bigmodel.cn/cn/guide/start/model-overview
    // rate-limits: https://www.bigmodel.cn/usercenter/proj-mgmt/rate-limits

    case glm_4_5 = "glm-4.5" // 128K context, 96K output, 20 QoS
    case glm_4_5_x = "glm-4.5-x" // 128K context, 96K output, 1 QoS
    case glm_4_5_air = "glm-4.5-air" // 128K context, 96K output, 30 QoS
    case glm_4_5_airx = "glm-4.5-airx" // 128K context, 96K output, 5 QoS

    // GLM free models https://docs.bigmodel.cn/cn/guide/start/model-overview
    case glm_4_5_flash = "glm-4.5-flash" // 128K context, 96K output, 2 QoS
    case glm_4_flash_250414 = "glm-4-flash-250414" // 128K context, 16k output, 30 QoS
    case glm_4_flash = "glm-4-flash" // glm-4-flash, 128K context, 4k output, 200 QoS
}
