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

    required init() {
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

    public override func apiKeyRequirement() -> ServiceAPIKeyRequirement {
        .builtIn
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
            // GLM free models. The first entry is both the list order users see and the
            // fallback for a saved-but-removed model ID (`StreamService.model`), so it must
            // stay the declared `defaultModel` below.
            ZhipuModel.glm_4_flash_250414.rawValue,
            ZhipuModel.glm_4_5_flash.rawValue,
        ]
    }

    override var defaultModel: String {
        ZhipuModel.glm_4_flash_250414.rawValue
    }

    override var canFetchRemoteModels: Bool {
        false
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
