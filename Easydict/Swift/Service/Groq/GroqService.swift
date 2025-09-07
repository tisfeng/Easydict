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
        GroqModel.gpt_oss_120b.rawValue
    }

    override var observeKeys: [Defaults.Key<String>] {
        [apiKeyKey, supportedModelsKey]
    }

    override var defaultEndpoint: String {
        "https://api.groq.com/openai/v1/chat/completions"
    }

    override var apiKeyPlaceholder: LocalizedStringKey {
        "gsk_xxxxxxxxxx"
    }
}

// MARK: - GroqModel

enum GroqModel: String, CaseIterable {
    // Docs: https://console.groq.com/docs/models
    // Limits: https://console.groq.com/settings/limits

    // Production Models
    case gpt_oss_120b = "openai/gpt-oss-120b" // 30 RPM, 1k RPD, 8k TPM, 200k TPD
    case gpt_oss_20b = "openai/gpt-oss-20b" // 30 RPM, 1k RPD, 8k TPM, 200k TPD

    case llama3_1_8b_instant = "llama-3.1-8b-instant" // 30 RPM, 14.4k RPD, 6k TPM, 500k TPD

    // Preview Models
    case kimi_k2_instruct_0905 = "moonshotai/kimi-k2-instruct-0905" // 60 RPM, 1k RPD, 10k TPM, 300k TPD

    case llama4_maverick_17b_128e =
        "meta-llama/llama-4-maverick-17b-128e-instruct" // 30 RPM, 1k RPD, 6k TPM, 500k TPD

    case qwen3_32b = "qwen/qwen3-32b" // 60 RPM, 1k RPD, 6k TPM, 300k TPD
}
