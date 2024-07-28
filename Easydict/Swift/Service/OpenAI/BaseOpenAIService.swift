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
        let url = URL(string: endpoint)
        let invalidURLError = EZError(type: .param, description: "`\(serviceType().rawValue)` endpoint is invalid")
        guard let url, url.isValid else {
            completion(result, invalidURLError)
            return
        }

        var resultText = ""
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
        guard let chatHistory = chatHistory as? [ChatMessage] else { return }

        let query = ChatQuery(messages: chatHistory, model: model, temperature: 0)
        let openAI = OpenAI(apiToken: apiKey)

        // FIXME: It seems that `control` will cause a memory leak, but it is not clear how to solve it.
        unowned let unownedControl = control

        // TODO: refactor chatsStream with await
        openAI.chatsStream(query: query, url: url, control: unownedControl) { [weak self] res in
            guard let self else { return }

            switch res {
            case let .success(chatResult):
                if let content = chatResult.choices.first?.delta.content {
                    resultText += content
                }
                updateResultText(resultText, queryType: queryType, error: nil, completion: completion)
            case let .failure(error):
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
            }

        } completion: { [weak self] error in
            guard let self else { return }

            if let error {
                updateResultText(nil, queryType: queryType, error: error, completion: completion)
                return
            }

            // If already has error, we do not need to update it.
            if result.error == nil {
                resultText = getFinalResultText(resultText)
//              log("\(name())-(\(model)): \(resultText)")
                updateResultText(resultText, queryType: queryType, error: nil, completion: completion)
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

    // TODO: Need to improve this code.
    override func streamTranslate(request: TranslationRequest) async throws
        -> AsyncThrowingStream<ChatStreamResult, Error> {
        let url = URL(string: endpoint)
        let invalidURLError = EZError(type: .param, description: "`\(serviceType().rawValue)` endpoint is invalid")
        guard let url, url.isValid else {
            return AsyncThrowingStream { continuation in
                continuation.finish(throwing: invalidURLError)
            }
        }

        result.isStreamFinished = false

        let text = request.text
        let from = Language(rawValue: request.sourceLanguage ?? "auto")
        let to = Language(rawValue: request.targetLanguage)

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
