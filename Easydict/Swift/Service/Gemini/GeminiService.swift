//
//  GeminiService.swift
//  Easydict
//
//  Created by Jerry on 2024-01-02.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation

// MARK: - GeminiService

/// Gemini OpenAI compatibility docs: https://ai.google.dev/gemini-api/docs/openai
@objc(EZGeminiService)
final class GeminiService: OpenAIService {
    // MARK: Public

    public override func serviceType() -> ServiceType {
        .gemini
    }

    public override func link() -> String? {
        "https://gemini.google.com/"
    }

    public override func name() -> String {
        NSLocalizedString("gemini_translate", comment: "The name of Gemini Translate")
    }

    public override func configurationListItems() -> Any {
        StreamConfigurationView(
            service: self,
            showEndpointSection: false
        )
    }

    // MARK: Internal

    override var defaultModels: [String] {
        GeminiModel.allCases.map(\.rawValue)
    }

    override var defaultModel: String {
        GeminiModel.gemini_flash_latest.rawValue
    }

    override var defaultEndpoint: String {
        "https://generativelanguage.googleapis.com/v1beta/openai/chat/completions"
    }

    // https://ai.google.dev/available_regions
    override var unsupportedLanguages: [Language] {
        [
            .persian,
            .filipino,
            .khmer,
            .lao,
            .malay,
            .mongolian,
            .burmese,
            .telugu,
            .tamil,
            .urdu,
        ]
    }

    override func normalizedRemoteModelIDs(_ ids: [String]) -> [String] {
        let modelIDs = ids.map { id in
            let trimmedID = id.trim()
            let prefix = "models/"
            return trimmedID.hasPrefix(prefix)
                ? String(trimmedID.dropFirst(prefix.count))
                : trimmedID
        }
        return super.normalizedRemoteModelIDs(modelIDs)
    }
}

// MARK: - GeminiModel

enum GeminiModel: String, CaseIterable {
    // Docs: https://ai.google.dev/gemini-api/docs/models
    // Pricing: https://ai.google.dev/gemini-api/docs/pricing
    // Rate limits: https://ai.google.dev/gemini-api/docs/rate-limits

    // MARK: - Free models

    case gemini_flash_lite_latest = "gemini-flash-lite-latest"
    case gemini_flash_latest = "gemini-flash-latest"

    // MARK: - Pro models, not available for free tier

    case gemini_pro_latest = "gemini-pro-latest"
}
