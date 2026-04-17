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
    // MARK: Open

    /// Whether this service exposes a streaming toggle in the settings UI.
    /// Only services with a visible toggle should persist streaming auto-disable after fallback validation.
    open var supportsStreamingToggle: Bool { false }

    open override func cancelStream() {
        control.cancel()
        nonStreamingTask?.cancel()
        nonStreamingTask = nil
    }

    // MARK: Internal

    typealias OpenAIChatMessage = ChatQuery.ChatCompletionMessageParam

    /// Whether the current request should use streaming transport.
    ///
    /// Validation may temporarily override the persisted toggle so transport choice must read
    /// from the effective runtime state instead of the stored configuration alone.
    override var usesStreamingTransport: Bool {
        streamingOverride ?? enableStreaming
    }

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

        // Check API key if required
        if apiKeyRequirement().requiresKeyForRequest, apiKey.isEmpty {
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

        let query = ChatQuery(messages: chatHistory, model: model, temperature: temperature)

        if usesStreamingTransport {
            let openAI = OpenAI(apiToken: apiKey)

            // FIXME: It seems that `control` will cause a memory leak, but it is not clear how to solve it.
            unowned let unownedControl = control

            let chatStream: AsyncThrowingStream<ChatStreamResult, Error> = openAI.chatsStream(
                query: query,
                url: url,
                control: unownedControl
            )
            return chatStreamToContentStream(chatStream)
        } else {
            return nonStreamingTranslate(query: query, url: url)
        }
    }

    /// Validates the service, automatically falling back to non-streaming if the endpoint
    /// returns an incorrect Content-Type (e.g. `application/json` instead of `text/event-stream`).
    override func validate() async -> QueryResult {
        let firstPassResult = await super.validate()
        // Snapshot uses cloned errors so the second `super.validate()` pass cannot mutate
        // first-pass diagnostics in place (`resetServiceResult()` reuses `self.result`).
        let firstPassSnapshot = ValidationResultSnapshot(result: firstPassResult)

        guard let firstPassError = firstPassSnapshot.error,
              firstPassError.type == .contentTypeMismatch,
              enableStreaming,
              supportsStreamingToggle
        else {
            return firstPassResult
        }

        // Retry without streaming using a temporary override (not persisted yet).
        // Only Custom OpenAI (and similar) exposes a streaming toggle; otherwise validation
        // must reflect streaming reality — a silent non-streaming retry would report success
        // while normal queries still use streaming and fail with the same mismatch.
        logInfo("Streaming validation failed with content-type mismatch, retrying without streaming...")
        streamingOverride = false
        let retryResult = await super.validate()
        streamingOverride = nil

        if let retryError = retryResult.error {
            // Non-streaming also failed — keep the original mismatch diagnostics unless
            // the retry error is clearly more actionable than a content-type mismatch.
            if !shouldPreferRetryError(retryError) {
                firstPassSnapshot.apply(to: retryResult)
            }
            return retryResult
        }

        // Non-streaming succeeded — `supportsStreamingToggle` was required to enter the retry path.
        enableStreaming = false
        logInfo("Non-streaming validation succeeded, streaming auto-disabled.")
        retryResult.validationMessage = String(
            localized: "service.configuration.validation_success.streaming_disabled"
        )
        return retryResult
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

    // MARK: Private

    /// Snapshot of first-pass validation context to avoid in-place mutation from `resetServiceResult()`.
    private struct ValidationResultSnapshot {
        // MARK: Lifecycle

        init(result: QueryResult) {
            self.error = result.error.map { error in
                QueryError(
                    type: error.type,
                    message: error.message,
                    errorDataMessage: error.errorDataMessage
                )
            }
            self.validationMessage = result.validationMessage
        }

        // MARK: Internal

        let error: QueryError?
        let validationMessage: String?

        func apply(to result: QueryResult) {
            result.error = error
            result.validationMessage = validationMessage
        }
    }

    /// Temporary override for streaming during validate retry. `nil` means use the persisted value.
    private var streamingOverride: Bool?

    /// Reference to the in-flight non-streaming task so `cancelStream()` can cancel it.
    private var nonStreamingTask: Task<(), Never>?

    /// Whether the retry error should replace the original streaming mismatch diagnostics.
    private func shouldPreferRetryError(_ retryError: QueryError) -> Bool {
        let preferredTypes: [QueryError.ErrorType] = [
            .missingSecretKey,
            .parameter,
            .unsupportedLanguage,
            .unsupportedQueryType,
            .api,
            .timeout,
        ]
        return preferredTypes.contains(retryError.type)
    }

    /// Perform a non-streaming chat completion, yielding the full response as a single chunk.
    private func nonStreamingTranslate(
        query: ChatQuery,
        url: URL
    )
        -> AsyncThrowingStream<String, Error> {
        let apiKey = apiKey

        return AsyncThrowingStream(String.self) { [weak self] continuation in
            guard let self else {
                continuation.finish(throwing: CancellationError())
                return
            }

            let task = Task {
                defer { self.nonStreamingTask = nil }

                do {
                    let request = try self.makeNonStreamingChatRequest(
                        query: query,
                        url: url,
                        apiKey: apiKey
                    )
                    let (data, response) = try await URLSession.shared.data(for: request)
                    try Task.checkCancellation()

                    if let http = response as? HTTPURLResponse,
                       !(200 ... 299).contains(http.statusCode) {
                        if let apiError = try? JSONDecoder().decode(
                            APIErrorResponse.self, from: data
                        ) {
                            throw apiError
                        }
                        throw QueryError(
                            type: .api,
                            message: "HTTP \(http.statusCode)",
                            errorDataMessage: String(data: data, encoding: .utf8)
                        )
                    }

                    let chatResult = try JSONDecoder().decode(ChatResult.self, from: data)
                    if let content = chatResult.choices.first?.message.content?.string,
                       !content.isEmpty {
                        continuation.yield(content)
                        continuation.finish()
                    } else {
                        throw QueryError(type: .noResult)
                    }
                } catch let urlError as URLError where urlError.code == .cancelled {
                    // Task cancellation often surfaces as URLError.cancelled from URLSession.
                    continuation.finish(throwing: CancellationError())
                } catch let nsError as NSError
                    where nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
                    continuation.finish(throwing: CancellationError())
                } catch is CancellationError {
                    continuation.finish(throwing: CancellationError())
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            nonStreamingTask = task
            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }

    /// Builds the HTTP request for a non-streaming OpenAI-compatible chat completion.
    /// - Parameters:
    ///   - query: The chat completion query to encode.
    ///   - url: The provider endpoint URL.
    ///   - apiKey: The API token used by OpenAI-compatible providers.
    /// - Returns: A configured `URLRequest` ready for `URLSession`.
    private func makeNonStreamingChatRequest(
        query: ChatQuery,
        url: URL,
        apiKey: String
    ) throws
        -> URLRequest {
        var query = query
        query.stream = false

        var request = URLRequest(url: url, timeoutInterval: EZNetWorkTimeoutInterval)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !apiKey.isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.setValue(apiKey, forHTTPHeaderField: "api-key")
        }
        request.httpBody = try JSONEncoder().encode(query)
        return request
    }
}
