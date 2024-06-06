//
//  GeminiService+Prompt.swift
//  Easydict
//
//  Created by tisfeng on 2024/6/5.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation
import GoogleGenerativeAI

extension GeminiService {
    func promptContent(
        queryType: EZQueryTextType,
        text: String,
        from sourceLanguage: Language,
        to targetLanguage: Language,
        systemPrompt: Bool
    )
        -> [ModelContent] {
        var prompts = [[String: String]]()

        switch queryType {
        case .dictionary:
            prompts = dictMessages(
                word: text,
                sourceLanguage: sourceLanguage,
                targetLanguage: targetLanguage,
                enableSystemPrompt: systemPrompt
            )
        case .sentence:
            prompts = sentenceMessages(
                sentence: text,
                from: sourceLanguage,
                to: targetLanguage,
                enableSystemPrompt: systemPrompt
            )
        case .translation:
            fallthrough
        default:
            prompts = translationMessages(
                text: text,
                from: sourceLanguage,
                to: targetLanguage,
                enableSystemPrompt: systemPrompt
            )
        }

        var chats: [ModelContent] = []
        for prompt in prompts {
            if let openAIRole = prompt["role"],
               let parts = prompt["content"] {
                let role = getGeminiRole(from: openAIRole)
                let chat = ModelContent(role: role, parts: parts)
                chats.append(chat)
            }
        }

        return chats
    }

    /// Given a roleRaw, currently only support "user" and "model", "model" is equal to "assistant". https://ai.google.dev/gemini-api/docs/get-started/tutorial?lang=swift&hl=zh-cn#multi-turn-conversations-chat
    private func getGeminiRole(from openAIRole: String) -> String {
        if openAIRole == "assistant" {
            "model"
        } else if openAIRole == "system" {
            "user"
        } else {
            openAIRole
        }
    }
}
