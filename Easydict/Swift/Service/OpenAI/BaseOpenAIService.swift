//
//  BaseOpenAIService.swift
//  Easydict
//
//  Created by tisfeng on 2024/3/28.
//  Copyright © 2024 izual. All rights reserved.
//

import AsyncAlgorithms
import Foundation
import OpenAI

// MARK: - BaseOpenAIService

@objcMembers
@objc(EZBaseOpenAIService)
public class BaseOpenAIService: StreamService {
    typealias OpenAIChatMessage = ChatQuery.ChatCompletionMessageParam

    let control = StreamControl()

    override func contentStreamTranslate(
        _ text: String,
        from: Language,
        to: Language
    )
        -> AsyncThrowingStream<String, any Error> {
        let url = URL(string: endpoint)

        // Check endpoint
        guard let url, url.isValid else {
            let invalidURLError = QueryError(
                type: .parameter, message: "`\(serviceType().rawValue)` endpoint is invalid"
            )
            return AsyncThrowingStream { continuation in
                continuation.finish(throwing: invalidURLError)
            }
        }

        // Check API key
        guard !apiKey.isEmpty else {
            let error = QueryError(type: .missingSecretKey, message: "API key is empty")
            return AsyncThrowingStream { continuation in
                continuation.finish(throwing: error)
            }
        }

        result.isStreamFinished = false

        let queryType = queryType(text: text, from: from, to: to)
        let chatQueryParam = ChatQueryParam(
            text: text,
            sourceLanguage: from,
            targetLanguage: to,
            queryType: queryType,
            enableSystemPrompt: true
        )

        let chatHistory = serviceChatMessageModels(chatQueryParam)
        guard let chatHistory = chatHistory as? [OpenAIChatMessage] else {
            let error = QueryError(
                type: .parameter, message: "Failed to convert chat messages"
            )
            return AsyncThrowingStream { continuation in
                continuation.finish(throwing: error)
            }
        }

        let query = ChatQuery(messages: chatHistory, model: model, temperature: 0)
        let openAI = OpenAI(apiToken: apiKey)

        // FIXME: It seems that `control` will cause a memory leak, but it is not clear how to solve it.
        unowned let unownedControl = control

        let chatStream: AsyncThrowingStream<ChatStreamResult, Error> = openAI.chatsStream(
            query: query,
            url: url,
            control: unownedControl
        )
        return chatStreamToContentStream(chatStream)
    }

    override func serviceChatMessageModels(_ chatQuery: ChatQueryParam) -> [Any] {
        var chatMessages: [OpenAIChatMessage] = []
        for message in chatMessageDicts(chatQuery) {
            let openAIRole = message.role.rawValue
            let content = message.content

            if let role = OpenAIChatMessage.Role(rawValue: openAIRole),
               let chat = OpenAIChatMessage(role: role, content: content) {
                chatMessages.append(chat)
            }
        }
        return chatMessages
    }

    override func cancelStream() {
        control.cancel()
    }
}
