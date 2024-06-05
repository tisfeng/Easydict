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
                systemPrompt: systemPrompt
            )
        case .sentence:
            prompts = sentenceMessages(
                sentence: text,
                from: sourceLanguage,
                to: targetLanguage,
                systemPrompt: systemPrompt
            )
        case .translation:
            fallthrough
        default:
            prompts = translationMessages(
                text: text,
                from: sourceLanguage,
                to: targetLanguage,
                systemPrompt: systemPrompt
            )
        }

        var chats: [ModelContent] = []
        for prompt in prompts {
            if let roleRaw = prompt["role"],
               let parts = prompt["content"] {
                let role = getCorrectParts(from: roleRaw)
                let chat = ModelContent(role: role, parts: parts)
                chats.append(chat)
            }
        }

        return chats
    }

    /// Given a roleRaw, currently only support "user" and "model", "model" is equal to "assistant". https://ai.google.dev/gemini-api/docs/get-started/tutorial?lang=swift&hl=zh-cn#multi-turn-conversations-chat
    private func getCorrectParts(from roleRaw: String) -> String {
        if roleRaw == "assistant" {
            "model"
        } else if roleRaw == "system" {
            "user"
        } else {
            roleRaw
        }
    }
}
