//
//  LLMDerivService.swift
//  Easydict
//
//  Created by Jerry on 2024-07-12.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation

/// A class used for LLM derivatives such as summary and polishing
/// Based on `BuiltInAIService` and takes `llama3-70b-8192` as the LLM
class LLMDerivService: BuiltInAIService {
    // MARK: Public

    public override func configurationListItems() -> Any {
        StreamConfigurationView(
            service: self,
            showNameSection: false,
            showAPIKeySection: false,
            showEndpointSection: false,
            showSupportedModelsSection: false,
            showUsedModelSection: false,
            showTranslationToggle: false,
            showSentenceToggle: false,
            showDictionaryToggle: false,
            showUsageStatusPicker: true
        )
    }

    // MARK: Internal

    override var defaultModels: [String] {
        ["llama3-70b-8192"]
    }

    func serviceChatMessage(_ chatQuery: LLMDerivParam) -> [Any] {
        var chatModels: [ChatMessage] = []
        for message in llmDerivMessageDicts(chatQuery) {
            if let roleRawValue = message["role"],
               let role = ChatMessage.Role(rawValue: roleRawValue),
               let content = message["content"] {
                if let chat = ChatMessage(role: role, content: content) {
                    chatModels.append(chat)
                }
            }
        }
        return chatModels
    }
}
