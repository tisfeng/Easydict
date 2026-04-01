//
//  ClaudeService.swift
//  Easydict
//
//  Created by zkbkb on 2026/4/1.
//  Copyright © 2026 izual. All rights reserved.
//

import Defaults
import Foundation

// MARK: - ClaudeService

/// Claude translation service using the Anthropic Messages API.
/// Documentation: https://docs.anthropic.com/en/api/messages
@objc(EZClaudeService)
public final class ClaudeService: StreamService {
    // MARK: Public

    public override func cancelStream() {
        currentTask?.cancel()
    }

    public override func serviceType() -> ServiceType {
        .claude
    }

    public override func link() -> String? {
        "https://claude.ai/"
    }

    public override func name() -> String {
        NSLocalizedString("claude_translate", comment: "The name of Claude Translate")
    }

    public override func configurationListItems() -> Any {
        StreamConfigurationView(service: self, temperatureMaxValue: 1)
    }

    // MARK: Internal

    override var defaultModels: [String] {
        ClaudeModel.allCases.map(\.rawValue)
    }

    override var defaultModel: String {
        ClaudeModel.claude_sonnet_4_6.rawValue
    }

    override var defaultEndpoint: String {
        "https://api.anthropic.com/v1/messages"
    }

    override var observeKeys: [Defaults.Key<String>] {
        [apiKeyKey, supportedModelsKey]
    }

    override func contentStreamTranslate(
        _ text: String,
        from: Language,
        to: Language
    )
        -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            continuation.onTermination = { @Sendable [weak self] _ in
                self?.currentTask?.cancel()
            }

            if let currentTask, !currentTask.isCancelled {
                currentTask.cancel()
            }

            let queryType = queryType(text: text, from: from, to: to)

            currentTask = Task {
                do {
                    guard !apiKey.isEmpty else {
                        throw QueryError(type: .missingSecretKey, message: "Claude API key is empty.")
                    }

                    let chatQueryParam = ChatQueryParam(
                        text: text,
                        sourceLanguage: from,
                        targetLanguage: to,
                        queryType: queryType,
                        enableSystemPrompt: true
                    )

                    let messages = chatMessageDicts(chatQueryParam)
                    let (systemPrompt, userMessages) = separateSystemMessages(messages)
                    let requestBody = buildRequestBody(
                        systemPrompt: systemPrompt,
                        messages: userMessages
                    )
                    let urlRequest = try createURLRequest(body: requestBody)

                    let (asyncBytes, response) = try await URLSession.shared.bytes(for: urlRequest)
                    try await validateHTTPResponse(response, asyncBytes: asyncBytes)

                    try await processStreamBytes(asyncBytes, continuation: continuation)
                    continuation.finish()
                } catch is CancellationError {
                    logInfo("Claude task was cancelled.")
                    continuation.finish()
                } catch {
                    logError("Claude translate error: \(error)")
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    override func serviceChatMessageModels(_ chatQuery: ChatQueryParam) -> [Any] {
        let messages = chatMessageDicts(chatQuery)
        let (_, userMessages) = separateSystemMessages(messages)
        return userMessages.map { ["role": $0.role.rawValue, "content": $0.content] }
    }

    // MARK: Private

    /// The Anthropic API version header value.
    private let anthropicVersion = "2023-06-01"

    /// The maximum number of tokens to generate in the response.
    private let maxTokens = 4096

    private var currentTask: Task<(), Never>?

    private let jsonDecoder = JSONDecoder()

    // MARK: - Message Construction

    /// Separates system messages from user/assistant messages.
    ///
    /// Anthropic requires system prompts as a top-level parameter, not in the messages array.
    /// This method extracts system-role messages and returns them separately.
    ///
    /// - Parameter messages: The full chat message list from `chatMessageDicts()`.
    /// - Returns: A tuple of (system prompt string, remaining user/assistant messages).
    private func separateSystemMessages(
        _ messages: [ChatMessage]
    )
        -> (String, [ChatMessage]) {
        var systemParts: [String] = []
        var otherMessages: [ChatMessage] = []

        for message in messages {
            if message.role == .system {
                systemParts.append(message.content)
            } else {
                otherMessages.append(message)
            }
        }

        return (systemParts.joined(separator: "\n\n"), otherMessages)
    }

    // MARK: - HTTP Request

    /// Builds the JSON request body for the Anthropic Messages API.
    private func buildRequestBody(
        systemPrompt: String,
        messages: [ChatMessage]
    )
        -> [String: Any] {
        var body: [String: Any] = [
            "model": model,
            "max_tokens": maxTokens,
            "temperature": min(max(temperature, 0), 1),
            "stream": true,
            "messages": messages.map { ["role": $0.role.rawValue, "content": $0.content] },
        ]

        if !systemPrompt.isEmpty {
            body["system"] = systemPrompt
        }

        return body
    }

    /// Creates and configures a URLRequest for the Anthropic Messages API.
    ///
    /// Uses the user-configured endpoint (defaults to `https://api.anthropic.com/v1/messages`).
    /// Authentication uses `x-api-key` header instead of Bearer token.
    private func createURLRequest(body: [String: Any]) throws -> URLRequest {
        guard let url = URL(string: endpoint) else {
            throw QueryError(
                type: .api,
                message: "Invalid Claude API endpoint: \(endpoint)"
            )
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        urlRequest.setValue(anthropicVersion, forHTTPHeaderField: "anthropic-version")
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body)

        return urlRequest
    }

    // MARK: - HTTP Response Validation

    /// Validates the HTTP response status code.
    ///
    /// When the API returns a non-2xx status, reads the error body to extract
    /// the actual error message from Anthropic's JSON error response.
    private func validateHTTPResponse(
        _ response: URLResponse,
        asyncBytes: URLSession.AsyncBytes
    ) async throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw QueryError(type: .api, message: "Invalid HTTP response from Claude API.")
        }

        guard !(200 ... 299).contains(httpResponse.statusCode) else {
            return
        }

        // Read the error response body (up to 4KB) to get the actual error message.
        let errorData = try await asyncBytes.prefix(4096).reduce(into: Data()) { $0.append($1) }

        var errorMessage = "Claude API error: HTTP \(httpResponse.statusCode)"
        if let errorBody = try? jsonDecoder.decode(ClaudeStreamError.self, from: errorData) {
            errorMessage = errorBody.error.message
        } else if let bodyString = String(data: errorData, encoding: .utf8), !bodyString.isEmpty {
            errorMessage = bodyString
        }

        throw QueryError(type: .api, errorDataMessage: errorMessage)
    }

    // MARK: - SSE Stream Parsing

    /// Processes SSE byte stream and yields translated text chunks.
    private func processStreamBytes(
        _ asyncBytes: URLSession.AsyncBytes,
        continuation: AsyncThrowingStream<String, Error>.Continuation
    ) async throws {
        var dataBuffer = Data()
        var textBuffer = ""
        let bufferThreshold = 1024

        for try await byte in asyncBytes {
            try Task.checkCancellation()

            dataBuffer.append(byte)

            guard dataBuffer.count >= bufferThreshold || byte == 0x0A else {
                continue
            }

            if let text = String(data: dataBuffer, encoding: .utf8) {
                textBuffer.append(text)
                dataBuffer.removeAll()
                try processCompleteEvents(from: &textBuffer, continuation: continuation)
            }
        }

        if !dataBuffer.isEmpty, let text = String(data: dataBuffer, encoding: .utf8) {
            textBuffer.append(text)
        }
        try processCompleteEvents(from: &textBuffer, continuation: continuation)
    }

    /// Splits the text buffer on double-newlines and processes complete SSE events.
    private func processCompleteEvents(
        from textBuffer: inout String,
        continuation: AsyncThrowingStream<String, Error>.Continuation
    ) throws {
        let eventSeparator = "\n\n"
        guard textBuffer.contains(eventSeparator) else { return }

        let parts = textBuffer.split(separator: eventSeparator, omittingEmptySubsequences: false)
        textBuffer = String(parts.last ?? "")

        for event in parts.dropLast() where !event.isEmpty {
            if let content = try parseSSEEvent(String(event)) {
                continuation.yield(content)
            }
        }
    }

    /// Parses a single SSE event and extracts delta text content.
    ///
    /// Anthropic SSE format:
    /// ```
    /// event: content_block_delta
    /// data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"Hello"}}
    /// ```
    private func parseSSEEvent(_ event: String) throws -> String? {
        let eventPrefix = "event:"
        let dataPrefix = "data:"

        var eventType: String?
        var jsonDataString: String?

        for line in event.split(separator: "\n") {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedLine.starts(with: eventPrefix) {
                eventType = trimmedLine
                    .dropFirst(eventPrefix.count)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            } else if trimmedLine.starts(with: dataPrefix) {
                jsonDataString = trimmedLine
                    .dropFirst(dataPrefix.count)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        // Handle stream-level errors by throwing to terminate the stream immediately.
        if eventType == "error",
           let dataString = jsonDataString,
           let data = dataString.data(using: .utf8),
           let streamError = try? jsonDecoder.decode(ClaudeStreamError.self, from: data) {
            throw QueryError(type: .api, errorDataMessage: streamError.error.message)
        }

        // Extract text delta from content_block_delta events.
        guard eventType == "content_block_delta",
              let dataString = jsonDataString,
              let data = dataString.data(using: .utf8)
        else {
            return nil
        }

        guard let streamDelta = try? jsonDecoder.decode(ClaudeStreamDelta.self, from: data) else {
            logError("Failed to decode Claude SSE data (\(data.count) bytes)")
            return nil
        }

        return streamDelta.delta?.text
    }
}

// MARK: - ClaudeModel

enum ClaudeModel: String, CaseIterable {
    // Docs: https://docs.anthropic.com/en/docs/about-claude/models
    // Pricing: https://www.anthropic.com/pricing

    case claude_sonnet_4_6 = "claude-sonnet-4-6"
    case claude_haiku_4_5 = "claude-haiku-4-5"
    case claude_opus_4_6 = "claude-opus-4-6"
}
