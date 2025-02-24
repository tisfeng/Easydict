//
//  DeepSeekService.swift
//  Easydict
//
//  Created by GarethNg on 2025/2/19.
//  Copyright © 2025 izual. All rights reserved.
//

import Defaults
import Foundation

// MARK: - DeepSeekService

@objc(EZDeepSeekService)
class DeepSeekService: OpenAIService {
    // MARK: Public

    public override func name() -> String {
        NSLocalizedString("deepseek_translate", comment: "")
    }

    public override func serviceType() -> ServiceType {
        .deepSeek
    }

    public override func link() -> String? {
        "https://www.deepseek.com/"
    }

    public override func configurationListItems() -> Any {
        StreamConfigurationView(
            service: self,
            showEndpointSection: false
        )
    }

    // MARK: Internal

    override var defaultModels: [String] {
        DeepSeekModel.allCases.map(\.rawValue)
    }

    override var defaultModel: String {
        DeepSeekModel.deepseekChat.rawValue
    }

    override var observeKeys: [Defaults.Key<String>] {
        [apiKeyKey, supportedModelsKey]
    }

    override var endpoint: String {
        "https://api.deepseek.com/v1/chat/completions"
    }
}

// MARK: - DeepSeekModel

enum DeepSeekModel: String, CaseIterable {
    // Docs: https://api-docs.deepseek.com
    // Pricing https://api-docs.deepseek.com/quick_start/pricing
    case deepseekChat = "deepseek-chat" // Input: $0.07(CACHE HIT)/$0.27(CACHE MISS) | Output: $1.10  (8k)
    case deepseekReasoner = "deepseek-reasoner" // Input: $0.14(CACHE HIT)/$0.55(CACHE MISS) | Output: $2.19  (8k)
}
