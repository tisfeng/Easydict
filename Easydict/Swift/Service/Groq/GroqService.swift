//
//  GroqService.swift
//  Easydict
//
//  Created by tisfeng on 2025/4/19.
//  Copyright © 2025 izual. All rights reserved.
//

import Defaults
import Foundation

// MARK: - GroqService

@objc(EZGroqService)
class GroqService: OpenAIService {
    // MARK: Public

    public override func name() -> String {
        NSLocalizedString("groq_translate", comment: "")
    }

    public override func serviceType() -> ServiceType {
        .groq
    }

    public override func link() -> String? {
        "https://groq.com/"
    }

    // MARK: Internal

    override var defaultModels: [String] {
        GroqModel.allCases.map(\.rawValue)
    }

    override var defaultModel: String {
        GroqModel.gemma2_9b.rawValue
    }

    override var observeKeys: [Defaults.Key<String>] {
        [apiKeyKey, supportedModelsKey]
    }

    override var defaultEndpoint: String {
        "https://api.groq.com/openai/v1/chat/completions"
    }
}

// MARK: - GroqModel

// swiftlint:disable identifier_name
enum GroqModel: String, CaseIterable {
    // Docs: https://console.groq.com/docs/models
    // Pricing: https://groq.com/pricing/

    // Production Models
    case gemma2_9b = "gemma2-9b-it" // 30 RPM, 14,400 RPD, 15,000 TPM, 500,000 TPD
    case llama3_70b = "llama3-70b-8192" // 30 RPM, 14,400 RPD, 6,000 TPM, 500,000 TPD

    // Preview Models
    case llama4_maverick_17b =
        "meta-llama/llama-4-maverick-17b-128e-instruct" // 30 RPM, 1,000 RPD, 6,000 TPM
    case mistral_saba_24b = "mistral-saba-24b" // 30 RPM, 1,000 RPD, 6,000 TPM, 500,000 TPD
    case qwen_qwq_32b = "qwen-qwq-32b" // 30 RPM, 1,000 RPD, 6,000 TPM
}

// swiftlint:enable identifier_name
