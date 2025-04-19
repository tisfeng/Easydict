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
        OpenAIModel.gpt_4_1_mini.rawValue
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

// swiftlint:disable identifier_name
enum OpenAIModel: String, CaseIterable {
    // Models: https://platform.openai.com/docs/models
    // Pricing https://platform.openai.com/docs/pricing

    case gpt_4_1 = "gpt-4.1" // gpt-4.1-2025-04-14  Input: $2 | Output: $8
    case gpt_4_1_mini = "gpt-4.1-mini" // gpt-4.1-mini-2025-04-14  Input: $0.4 | Output: $1.6
    case gpt_4_1_nano = "gpt-4.1-nano" // gpt-4.1-nano-2025-04-14  Input: $0.1 | Output: $0.4

    case o3 // o3-2024-04-16  Input: $10 | Output: $40
    case o4_mini = "o4-mini" // o4-mini-2025-04-16  Input: $1.1 | Output: $4.4

    case gpt_4o = "gpt-4o" // gpt-4o-2024-08-06  Input: $2.5 | Output: $10
    case gpt_4o_mini = "gpt-4o-mini" // gpt-4o-mini-2024-07-18  Input: $0.15 | Output: $0.6
}

// swiftlint:enable identifier_name
