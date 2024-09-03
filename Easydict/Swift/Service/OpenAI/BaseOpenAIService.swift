//
//  BaseOpenAIService.swift
//  Easydict
//
//  Created by tisfeng on 2024/3/28.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation
import OpenAI

// MARK: - BaseOpenAIService

@objcMembers
@objc(EZBaseOpenAIService)
public class BaseOpenAIService: LLMStreamService {
    // MARK: Public

    public override func translate(
        _ text: String,
        from: Language,
        to: Language,
        completion: @escaping (EZQueryResult, Error?) -> ()
    ) {
        Task {
            result.isStreamFinished = false

            var resultText = ""
            let queryType = self.queryType(text: text, from: from, to: to)

            do {
                let chatStreamResults = try await self.streamTranslate(text, from: from, to: to)
                for try await streamResult in chatStreamResults {
                    if let content = streamResult.choices.first?.delta.content {
                        resultText += content
                    }
                    updateResultText(resultText, queryType: queryType, error: nil, completion: completion)
                }

                // Get final result text
                resultText = getFinalResultText(resultText)
                updateResultText(resultText, queryType: queryType, error: nil, completion: completion)
                result.isStreamFinished = true
            } catch {
                // For stream requests, certain special cases may be normal for the first part of the data transfer, but the final parsing is incorrect.
                var text: String?
                var err: Error? = error
                if !resultText.isEmpty {
                    text = resultText
                    err = nil

                    logError("\(name())-(\(model)) error: \(error.localizedDescription)")
                    logError(String(describing: error))
                }
                updateResultText(text, queryType: queryType, error: err, completion: completion)
                result.isStreamFinished = true
            }
        }
    }

    // MARK: Internal

    typealias ChatMessage = ChatQuery.ChatCompletionMessageParam

    let control = StreamControl()

    override func serviceChatMessageModels(_ chatQuery: ChatQueryParam) -> [Any] {
        var chatModels: [ChatMessage] = []
        for message in chatMessageDicts(chatQuery) {
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

    override func cancelStream() {
        control.cancel()
    }

    override func streamTranslate(
        _ text: String,
        from: Language,
        to: Language
    ) async throws
        -> AsyncThrowingStream<ChatStreamResult, Error> {
        let url = URL(string: endpoint)
        let invalidURLError = EZError(type: .param, description: "`\(serviceType().rawValue)` endpoint is invalid")
        guard let url, url.isValid else {
            return AsyncThrowingStream { continuation in
                continuation.finish(throwing: invalidURLError)
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
        guard let chatHistory = chatHistory as? [ChatMessage] else {
            return AsyncThrowingStream { continuation in
                continuation.finish(throwing: invalidURLError)
            }
        }

        let query = ChatQuery(messages: chatHistory, model: model, temperature: 0)
        let openAI = OpenAI(apiToken: apiKey)

        // FIXME: It seems that `control` will cause a memory leak, but it is not clear how to solve it.
        unowned let unownedControl = control

        return openAI.chatsStream(query: query, url: url, control: unownedControl)
    }
}
