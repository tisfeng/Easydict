//
//  OpenAIService.swift
//  Easydict
//
//  Created by tisfeng on 2023/12/31.
//  Copyright © 2023 izual. All rights reserved.
//

import Defaults
import Foundation
import OpenAI
import SwiftUI

// MARK: - OpenAIService

@objc(EZOpenAIService)
class OpenAIService: BaseOpenAIService {
    // MARK: Public

    public override func supportsOCR() -> Bool { serviceType() == .openAI }

    public override func serviceType() -> ServiceType {
        .openAI
    }

    public override func name() -> String {
        NSLocalizedString("openai_translate", comment: "")
    }

    public override func link() -> String? {
        "https://chatgpt.com"
    }

    override func recognizeImage(_ imageURL: String, prompt: String) async throws -> String {
        let endpoint = try validateChatStreamRequest()
        let message: ChatQuery.ChatCompletionMessageParam = .user(.init(content: .contentParts([
            .text(.init(text: prompt)),
            .image(.init(imageUrl: .init(url: imageURL, detail: nil))),
        ])))
        let query = makeChatQuery(messages: [message])
        return try await requestChatText(query: query, url: endpoint, apiKey: apiKey)
    }

    // MARK: Internal

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
