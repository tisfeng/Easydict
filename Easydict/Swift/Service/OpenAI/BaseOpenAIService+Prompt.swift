//
//  BaseOpenAIService+Prompt.swift
//  Easydict
//
//  Created by tisfeng on 2024/6/5.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation
import OpenAI

// MARK: OpenAI chat messages

extension BaseOpenAIService {
    typealias ChatCompletionMessageParam = ChatQuery.ChatCompletionMessageParam

    func chatMessages(
        queryType: EZQueryTextType,
        text: String,
        from: Language,
        to: Language
    )
        -> [ChatCompletionMessageParam] {
        typealias Role = ChatCompletionMessageParam.Role

        var messages = [[String: String]]()

        switch queryType {
        case .sentence:
            messages = sentenceMessages(sentence: text, from: from, to: to, enableSystemPrompt: true)
        case .dictionary:
            messages = dictMessages(word: text, sourceLanguage: from, targetLanguage: to, enableSystemPrompt: true)
        default:
            messages = translationMessages(text: text, from: from, to: to, enableSystemPrompt: true)
        }

        var chats: [ChatCompletionMessageParam] = []
        for message in messages {
            if let roleRawValue = message["role"],
               let role = Role(rawValue: roleRawValue),
               let content = message["content"] {
                guard let chat = ChatCompletionMessageParam(role: role, content: content) else { return [] }
                chats.append(chat)
            }
        }

        return chats
    }
}
