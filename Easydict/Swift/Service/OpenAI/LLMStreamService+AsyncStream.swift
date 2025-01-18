//
//  LLMStreamService+Stream.swift
//  Easydict
//
//  Created by tisfeng on 2025/1/18.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation
import OpenAI

// MARK: - Stream Translate

extension LLMStreamService {
    func chatStreamTranslate(
        _ text: String,
        from: Language,
        to: Language
    )
        -> AsyncThrowingStream<ChatStreamResult, Error> {
        let contentStream = contentStreamTranslate(text, from: from, to: to)
        return contentStreamToChatStream(contentStream)
    }

    /// Stream translate text, return EZQueryResult stream.
    /// - Note: This func do not throttle result.
    func streamTranslate(text: String, from: Language, to: Language) -> AsyncStream<EZQueryResult> {
        AsyncStream { continuation in
            Task {
                var resultText = ""
                let queryType = queryType(text: text, from: from, to: to)
                result.isStreamFinished = false

                do {
                    let contentStream = contentStreamTranslate(text, from: from, to: to)
                    for try await content in contentStream {
                        try Task.checkCancellation()

                        resultText += content
                        updateResultText(resultText, queryType: queryType, error: nil) { result in
                            continuation.yield(result)
                        }
                    }

                    result.isStreamFinished = true
                    resultText = getFinalResultText(resultText)
                    updateResultText(resultText, queryType: queryType, error: nil) { result in
                        continuation.yield(result)
                    }
                } catch {
                    // Handle the error and notify the user
                    result.isStreamFinished = true
                    updateResultText(resultText, queryType: queryType, error: error) { result in
                        continuation.yield(result)
                    }
                }

                continuation.finish()
            }
        }
    }

    /// Convert AsyncThrowingStream<ChatStreamResult> to AsyncThrowingStream<String, Error>
    func chatStreamToContentStream(
        _ chatStream: AsyncThrowingStream<ChatStreamResult, Error>
    )
        -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream<String, Error> { continuation in
            Task {
                do {
                    for try await chatStreamResult in chatStream {
                        if let content = chatStreamResult.choices.first?.delta.content {
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

    /// Convert AsyncThrowingStream<String, Error> to AsyncThrowingStream<ChatStreamResult, Error>
    func contentStreamToChatStream(
        _ contentStream: AsyncThrowingStream<String, Error>
    )
        -> AsyncThrowingStream<ChatStreamResult, Error> {
        AsyncThrowingStream<ChatStreamResult, Error> { continuation in
            Task {
                do {
                    for try await content in contentStream {
                        let chatStreamResult = try textToChatStreamResult(content, model: model)
                        continuation.yield(chatStreamResult)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    /// Convert AsyncStream<EZQueryResult> to AsyncThrowingStream<String, Error>
    func queryResultStreamToTextStream(
        _ queryResultStream: AsyncStream<EZQueryResult>
    )
        -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream<String, Error> { continuation in
            Task {
                do {
                    for try await queryResult in queryResultStream {
                        if let error = queryResult.error {
                            throw error
                        }
                        if let translatedText = queryResult.translatedText {
                            continuation.yield(translatedText)
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    func textToChatStreamResult(_ text: String, model: String) throws -> ChatStreamResult {
        let json: [String: Any] = [
            "id": "chatcmpl-\(UUID().uuidString)",
            "object": "chat.completion.chunk",
            "created": Date().timeIntervalSince1970,
            "model": model,
            "choices": [
                [
                    "index": 0,
                    "delta": [
                        "content": text,
                    ],
                ],
            ],
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: json, options: [])
        return try JSONDecoder().decode(ChatStreamResult.self, from: jsonData)
    }
}
