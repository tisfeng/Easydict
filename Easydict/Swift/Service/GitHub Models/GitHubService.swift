//
//  GitHubService.swift
//  Easydict
//
//  Created by tisfeng on 2025/4/17.
//  Copyright © 2025 izual. All rights reserved.
//

import Defaults
import Foundation

// MARK: - GitHubService

@objc(EZGitHubService)
class GitHubService: OpenAIService {
    // MARK: Public

    public override func name() -> String {
        NSLocalizedString("github_models", comment: "")
    }

    public override func serviceType() -> ServiceType {
        .gitHub
    }

    public override func link() -> String? {
        "https://github.com/marketplace/models"
    }

    // MARK: Internal

    override var defaultModels: [String] {
        GitHubModel.allCases.map(\.rawValue)
    }

    override var defaultModel: String {
        GitHubModel.gpt_4_1_mini.rawValue
    }

    override var observeKeys: [Defaults.Key<String>] {
        [apiKeyKey, supportedModelsKey]
    }

    override var defaultEndpoint: String {
        "https://models.inference.ai.azure.com/chat/completions"
    }
}

// MARK: - GitHubModel

// swiftlint:disable identifier_name
enum GitHubModel: String, CaseIterable {
    // Models: https://github.com/marketplace?type=models
    // Rate limit: https://docs.github.com/zh/github-models/prototyping-with-ai-models#rate-limits

    case gpt_4_1 = "gpt-4.1" // Rate limit tier: High: 10 RPM | 50 RPD
    case gpt_4_1_mini = "gpt-4.1-mini" // Low: 15 RPM | 150 RPD
    case gpt_4_1_nano = "gpt-4.1-nano" // Low

    /**
     o-series models are not good for translation, since they are expensive and slow,
     and can only use temperature 1.0 which is not consistent with the other models.

     case o3 // Custom: 2 RPM | 12 RPD
     case o4_mini = "o4-mini" // Custom
     */

    case gpt_4o = "gpt-4o" // High
    case gpt_4o_mini = "gpt-4o-mini" // Low

    case deepseek_v3_0324 = "deepseek-v3-0324" // High

    case llama_4_maverick_17b_128e_instruct_fp8 = "llama-4-maverick-17b-128e-instruct-fp8" // High

    case cohere_command_a = "cohere-command-a" // Low

    // Mistral Medium 3 (25.05)
    case mistral_small_2503 = "mistral-medium-2505" // Low

    case phi_4 = "phi-4" // Low
}

// swiftlint:enable identifier_name
