//
//  OpenAIService.swift
//  Easydict
//
//  Created by tisfeng on 2023/12/31.
//  Copyright © 2023 izual. All rights reserved.
//

import Defaults
import Foundation

// MARK: - OpenAIService

@objc(EZOpenAIService)
class OpenAIService: BaseOpenAIService {
    // MARK: Public

    override public func serviceType() -> ServiceType {
        .openAI
    }

    override public func name() -> String {
        NSLocalizedString("openai_translate", comment: "")
    }

    override public func link() -> String? {
        "https://chatgpt.com"
    }

    // MARK: Internal

    override var defaultModels: [String] {
        OpenAIModel.allCases.map(\.rawValue)
    }

    override var endpoint: String {
        super.endpoint.isEmpty ? "https://api.openai.com/v1/chat/completions" : super.endpoint
    }

    override func configurationListItems() -> Any {
        StreamConfigurationView(service: self)
    }
}

// MARK: - OpenAIModel

// swiftlint:disable identifier_name
enum OpenAIModel: String, CaseIterable {
    // Docs: https://platform.openai.com/docs/models

    case gpt_3_5_turbo = "gpt-3.5-turbo" // Currently points to gpt-3.5-turbo-0125. Input: $0.50 | Output: $1.50  (16k)
    case gpt_4_turbo = "gpt-4-turbo" // Currently points to gpt-4-turbo-2024-04-09. Input: $10 | Output: $30  (128k)
    case gpt_4o = "gpt-4o" // Currently points to gpt-4o-2024-05-13. Input: $5 | Output: $15  (128k context length)
}

// swiftlint:enable identifier_name
