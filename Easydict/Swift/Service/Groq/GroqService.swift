//
//  GroqService.swift
//  Easydict
//
//  Created by tisfeng on 2025/4/19.
//  Copyright © 2025 izual. All rights reserved.
//

import Defaults
import Foundation
import SwiftUI

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

enum GroqModel: String, CaseIterable {
    // Docs: https://console.groq.com/docs/models
    // Pricing: https://groq.com/pricing/

    // Production Models
    case gemma2_9b = "gemma2-9b-it" // 30 RPM, 14.4k RPD, 15k TPM, 500k TPD
    case llama3_70b = "llama3-70b-8192" // 30 RPM, 14.4k RPD, 6k TPM, 500k TPD

    // Preview Models
    case gpt_oss_120b = "openai/gpt-oss-120b" // 30 RPM, 1k RPD, 8k TPM, 200k TPD
    case gpt_oss_20b = "openai/gpt-oss-20b" // 30 RPM, 1k RPD, 8k TPM, 200k TPD

    case llama4_maverick_17b =
        "meta-llama/llama-4-maverick-17b-128e-instruct" // 30 RPM, 1,000 RPD, 6,000 TPM
}
