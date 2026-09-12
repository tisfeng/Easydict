//
//  StreamService+AsyncStream.swift
//  Easydict
//
//  Created by tisfeng on 2025/1/18.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation
import OpenAI

// MARK: - Stream Translate

extension StreamService {
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
    /// - Note: This func does not throttle result.
    func streamTranslate(
        text: String,
        from: Language,
        to: Language,
        targetResult: QueryResult,
        targetGeneration: UInt
    )
        -> AsyncThrowingStream<QueryResult, Error> {
        AsyncThrowingStream { continuation in
            Task {
                let isActiveStream = updateResultLock.withLock {
                    // The stream may start after the result has already been
                    // reset by a new query. Do not revive stale result state.
                    let isActiveStream = targetGeneration == resultGeneration
                    if isActiveStream {
                        targetResult.isStreamFinished = false
                    }
                    return isActiveStream
                }

                guard isActiveStream else {
                    continuation.finish()
                    return
                }

                var resultText = ""
                let queryType = queryType(text: text, from: from, to: to)

                do {
                    let contentStream = contentStreamTranslate(text, from: from, to: to)
                    for try await content in contentStream {
                        try Task.checkCancellation()

                        resultText += content
                        updateResultText(
                            resultText,
                            queryType: queryType,
                            error: nil,
                            targetResult: targetResult,
                            targetGeneration: targetGeneration
                        ) { result in
                            continuation.yield(result)
                        }
                    }

                    resultText = getFinalResultText(resultText)
                    // Pass markStreamFinished: true so that isStreamFinished is set atomically
                    // with the translatedResults update inside the lock. Setting it outside the
                    // lock first would allow a concurrent throttle delivery of an earlier
                    // snapshot to overwrite the final value before the lock is re-acquired.
                    updateResultText(
                        resultText,
                        queryType: queryType,
                        error: nil,
                        markStreamFinished: true,
                        targetResult: targetResult,
                        targetGeneration: targetGeneration
                    ) { result in
                        continuation.yield(result)
                    }
                } catch is CancellationError {
                    // User canceled the request; still emit a terminal state so UI can stop loading.
                    let isActiveStream = updateResultLock.withLock {
                        // Only the currently active stream should clear loading state.
                        let isActiveStream = targetGeneration == resultGeneration
                        if isActiveStream {
                            targetResult.isStreamFinished = true
                            targetResult.error = nil
                        }
                        return isActiveStream
                    }

                    guard isActiveStream else {
                        continuation.finish()
                        return
                    }
                    if !resultText.isEmpty {
                        updateResultText(
                            resultText,
                            queryType: queryType,
                            error: nil,
                            targetResult: targetResult,
                            targetGeneration: targetGeneration
                        ) { result in
                            continuation.yield(result)
                        }
                        continuation.finish()
                    } else {
                        // The outer pipeline only forwards results with translated text, so an
                        // empty terminal result would be dropped before UI consumers see it.
                        continuation.finish(throwing: CancellationError())
                    }
                    return
                } catch {
                    // Handle the error and notify the user.
                    // error != nil causes updateResultText to set isStreamFinished = true
                    // inside the lock, so no separate outside-lock assignment is needed.
                    updateResultText(
                        resultText,
                        queryType: queryType,
                        error: error,
                        targetResult: targetResult,
                        targetGeneration: targetGeneration
                    ) { result in
                        continuation.yield(result)
                    }
                    continuation.finish(throwing: error)
                    return
                }

                continuation.finish()
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
                        let chatStreamResult = try ChatStreamResult.create(
                            content: content,
                            model: model
                        )
                        continuation.yield(chatStreamResult)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    /// Convert AsyncThrowingStream<EZQueryResult> to AsyncThrowingStream<String, Error>
    func queryResultStreamToTextStream(
        _ queryResultStream: AsyncThrowingStream<QueryResult, Error>
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
}

extension ChatStreamResult {
    static func create(content: String, model: String) throws -> ChatStreamResult {
        let payload = OpenAIChatStreamChunkPayload(content: content, model: model)
        let data = try JSONEncoder().encode(payload)
        return try JSONDecoder().decode(ChatStreamResult.self, from: data)
    }

    var content: String? {
        choices.first?.delta.content
    }
}

// MARK: - OpenAIChatStreamChunkPayload

/// Encodes a text-only chunk that can be decoded by the upstream SDK result type.
private struct OpenAIChatStreamChunkPayload: Encodable {
    // MARK: Lifecycle

    init(content: String, model: String) {
        self.id = "chatcmpl-\(UUID().uuidString)"
        self.created = TimeInterval(Int(Date().timeIntervalSince1970))
        self.model = model
        self.choices = [.init(content: content)]
    }

    // MARK: Internal

    struct Choice: Encodable {
        // MARK: Lifecycle

        init(content: String) {
            self.delta = .init(content: content)
        }

        // MARK: Internal

        let index = 0
        let delta: Delta
    }

    struct Delta: Encodable {
        let content: String
    }

    let id: String
    let object = "chat.completion.chunk"
    let created: TimeInterval
    let model: String
    let choices: [Choice]
}
