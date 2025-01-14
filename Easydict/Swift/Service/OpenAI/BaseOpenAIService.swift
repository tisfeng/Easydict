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
public class BaseOpenAIService: LLMStreamService {
    // MARK: Public

    public override func translate(
        _ text: String,
        from: Language,
        to: Language,
        completion: @escaping (EZQueryResult, (any Error)?) -> ()
    ) {
        Task {
            for try await result in translate(text: text, from: from, to: to) {
                completion(result, result.error)
            }
        }
    }

    // MARK: Internal

    typealias OpenAIChatMessage = ChatQuery.ChatCompletionMessageParam

    let control = StreamControl()

    func translate(text: String, from: Language, to: Language) -> AsyncStream<EZQueryResult> {
        AsyncStream { continuation in
            var resultText = ""
            let queryType = queryType(text: text, from: from, to: to)

            Task {
                do {
                    result.isStreamFinished = false
                    result.isLoading = true

                    let stream = resultTextStreamTranslate(text, from: from, to: to)

                    // Throttle to avoid update UI too frequently.
                    for try await text in stream._throttle(for: .seconds(0.2)) {
                        resultText = text

                        updateResultText(resultText, queryType: queryType, error: nil) { result, error in
                            result.error = error
                            continuation.yield(result)
                        }
                    }

                    // Handle final result text
                    resultText = getFinalResultText(resultText)
                    result.isLoading = false
                    result.isStreamFinished = true

                    updateResultText(resultText, queryType: queryType, error: nil) { result, error in
                        result.error = error
                        continuation.yield(result)
                    }

                } catch {
                    // For stream requests, certain special cases may be normal for the first part of the data transfer, but the final parsing is incorrect.
                    var text: String?
                    var err: Error? = error
                    if !resultText.isEmpty {
                        text = resultText
                        err = nil
                    }

                    logError("\(name())-(\(model)) error: \(error.localizedDescription)")
                    logError(String(describing: error))

                    result.isLoading = false
                    result.isStreamFinished = true

                    updateResultText(text, queryType: queryType, error: err) { result, err in
                        result.error = err
                        continuation.yield(result)
                    }
                }

                continuation.finish()
            }
        }
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

    override func streamTranslate(
        _ text: String,
        from: Language,
        to: Language
    )
        -> AsyncThrowingStream<ChatStreamResult, Error> {
        let url = URL(string: endpoint)

        guard let url, url.isValid else {
            let invalidURLError = QueryError(
                type: .parameter, message: "`\(serviceType().rawValue)` endpoint is invalid"
            )
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

        return openAI.chatsStream(query: query, url: url, control: unownedControl)
    }

    /// Convert chat stream to content stream
    func contentStreamTranslate(
        _ text: String,
        from: Language,
        to: Language
    )
        -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    for try await result in streamTranslate(text, from: from, to: to) {
                        if let content = result.choices.first?.delta.content {
                            continuation.yield(content)
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    /// Convert content stream to result text stream
    func resultTextStreamTranslate(
        _ text: String,
        from: Language,
        to: Language
    )
        -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    var resultText = ""
                    for try await content in contentStreamTranslate(text, from: from, to: to) {
                        resultText += content
                        continuation.yield(resultText)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
