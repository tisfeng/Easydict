//
//  OpenAIService.swift
//  Easydict
//
//  Created by tisfeng on 2023/12/31.
//  Copyright © 2023 izual. All rights reserved.
//

import Defaults
import Foundation
import SwiftUI

// MARK: - OpenAIService

@objc(EZOpenAIService)
class OpenAIService: BaseOpenAIService {
    // MARK: Public

    public override func serviceType() -> ServiceType {
        .openAI
    }

    public override func name() -> String {
        NSLocalizedString("openai_translate", comment: "")
    }

    public override func link() -> String? {
        "https://chatgpt.com"
    }

    // MARK: Internal

    override var defaultModels: [String] {
        OpenAIModel.allCases.map(\.rawValue)
    }

    override var defaultModel: String {
        OpenAIModel.gpt_5_mini.rawValue
    }

    override var defaultEndpoint: String {
        "https://api.openai.com/v1/chat/completions"
    }

    override var apiKeyPlaceholder: LocalizedStringKey {
        "service.configuration.openai.api_key.placeholder"
    }

    override var observeKeys: [Defaults.Key<String>] {
        [apiKeyKey, supportedModelsKey]
    }
}

// MARK: - OpenAIModel

enum OpenAIModel: String, CaseIterable {
    // Models: https://platform.openai.com/docs/models
    // Pricing https://platform.openai.com/docs/pricing

    case gpt_5 = "gpt-5" // gpt-5-2025-08-07  Input: $1.25 | Output: $10
    case gpt_5_mini = "gpt-5-mini" // gpt-5-mini-2025-08-07  Input: $0.125 | Output: $2
    case gpt_5_nano = "gpt-5-nano" // gpt-5-nano-2025-08-07  Input: $0.05 | Output: $0.4

    case gpt_4_1 = "gpt-4.1" // gpt-4.1-2025-04-14  Input: $2 | Output: $8
}
