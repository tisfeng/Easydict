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

    override var supportsTemperature: Bool {
        serviceType() != .openAI
    }

    override var defaultModels: [String] {
        OpenAIModel.allCases.map(\.rawValue)
    }

    override var defaultModel: String {
        OpenAIModel.gpt_6_luna.rawValue
    }

    override var defaultEndpoint: String {
        "https://api.openai.com/v1/chat/completions"
    }

    override var observeKeys: [Defaults.Key<String>] {
        [apiKeyKey, supportedModelsKey]
    }
}

// MARK: - OpenAIModel

enum OpenAIModel: String, CaseIterable {
    // Models: https://platform.openai.com/docs/models
    // Pricing https://platform.openai.com/docs/pricing

    case gpt_6_luna = "gpt-6-luna" // Input: $0.10 | Output: $0.50
    case gpt_6_1_sol = "gpt-6.1-sol" // Input: $2 | Output: $10
    case gpt_6_astra = "gpt-6-astra" // Input: $10 | Output: $50
}
