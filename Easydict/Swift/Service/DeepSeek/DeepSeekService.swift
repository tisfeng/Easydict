//
//  DeepSeekService.swift
//  Easydict
//
//  Created by GarethNg on 2025/2/19.
//  Copyright © 2025 izual. All rights reserved.
//

import Alamofire
import Defaults
import Foundation
import OpenAI

// MARK: - DeepSeekService

/// DeepSeek translation service. Layers DeepSeek V4 reasoning parameters
/// (`thinking.type` and `reasoning_effort`) on top of the OpenAI-compatible
/// streaming pipeline as a model-agnostic per-service setting, so current
/// and future DeepSeek models opt in without code changes.
@objc(EZDeepSeekService)
class DeepSeekService: OpenAIService {
    // MARK: Public

    public override func supportsOCR() -> Bool { true }

    public override func cancelStream() {
        currentTask?.cancel()
    }

    public override func name() -> String {
        NSLocalizedString("deepseek_translate", comment: "")
    }

    public override func serviceType() -> ServiceType {
        .deepSeek
    }

    public override func link() -> String? {
        "https://www.deepseek.com/"
    }

    // MARK: Internal

    override var defaultModels: [String] {
        DeepSeekModel.allCases.map(\.rawValue)
    }

    override var defaultModel: String {
        DeepSeekModel.deepseekFlash.rawValue
    }

    override var observeKeys: [Defaults.Key<String>] {
        [apiKeyKey, supportedModelsKey]
    }

    override var defaultEndpoint: String {
        "https://api.deepseek.com/v1/chat/completions"
    }

    override var remoteModelsEndpoint: String? {
        "https://api.deepseek.com/models"
    }

    override var remoteModelFetchRequiresEndpoint: Bool {
        false
    }

    /// DeepSeek V4 supports reasoning effort, exposing the shared picker and
    /// sending `thinking` and `reasoning_effort` to the API.
    override var supportsReasoningEffort: Bool {
        true
    }

    override func recognizeImage(_ imageURL: String, prompt: String) async throws -> String {
        try Task.checkCancellation()
        let request = try imageRecognitionRequest(imageURL, prompt: prompt)
        let response = await AF.request(request).serializingData().response
        try Task.checkCancellation()
        let data = try response.result.get()
        guard let httpResponse = response.response else {
            throw QueryError(type: .api, message: "Invalid DeepSeek response")
        }
        if !(200 ... 299).contains(httpResponse.statusCode),
           let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
            throw apiError
        }
        try validateHTTPResponse(httpResponse)
        let result = try JSONDecoder().decode(ChatResult.self, from: data)
        guard let text = result.choices.first?.message.content, !text.isEmpty else {
            throw QueryError(type: .noResult)
        }
        return text
    }

    override func recognizeImage(
        _ imageURL: String, prompt: String, onDelta: @escaping @Sendable (String) -> ()
    ) async throws
        -> String {
        let request = try imageRecognitionRequest(imageURL, prompt: prompt, stream: true)
        return try await OpenAIStreamTransport().stream(request: request) { result in
            if let delta = result.choices.first?.delta.content { onDelta(delta) }
        }
    }

    override func contentStreamTranslate(
        _ text: String,
        from: Language,
        to: Language
    )
        -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            guard let url = URL(string: endpoint), url.isValid else {
                continuation.finish(
                    throwing: QueryError(
                        type: .parameter,
                        message: "`\(serviceType().rawValue)` endpoint is invalid"
                    )
                )
                return
            }

            guard !apiKey.isEmpty else {
                continuation.finish(
                    throwing: QueryError(type: .missingSecretKey, message: "API key is empty")
                )
                return
            }

            if let currentTask, !currentTask.isCancelled {
                currentTask.cancel()
            }

            let task = Task {
                do {
                    let queryType = queryType(text: text, from: from, to: to)
                    let chatQueryParam = ChatQueryParam(
                        text: text,
                        sourceLanguage: from,
                        targetLanguage: to,
                        queryType: queryType,
                        enableSystemPrompt: true
                    )
                    let request = try makeChatRequest(
                        url: url,
                        messages: chatMessageDicts(chatQueryParam).map(DeepSeekChatMessage.init)
                    )

                    let (asyncBytes, response) = try await URLSession.shared.bytes(for: request)
                    try validateHTTPResponse(response)
                    try await processStreamBytes(asyncBytes, continuation: continuation)
                    continuation.finish()
                } catch is CancellationError {
                    logInfo("DeepSeek task was cancelled.")
                    continuation.finish(throwing: CancellationError())
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            currentTask = task
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    /// Builds image requests with the same credentials and reasoning policy as text translation.
    @nonobjc
    func imageRecognitionRequest(_ imageURL: String, prompt: String, stream: Bool = false) throws -> URLRequest {
        let endpoint = try validateChatStreamRequest()
        let imageModels = ["deepseek-flash", "deepseek-v4-flash", "deepseek-v4-flash-vision-exp"]
        guard imageModels.contains(model) else {
            throw QueryError(
                type: .parameter,
                message: String(localized: "service.deepseek.ocr.image_model_required")
            )
        }
        return try makeChatRequest(
            url: endpoint,
            messages: [.init(imageURL: imageURL, prompt: prompt)],
            stream: stream
        )
    }

    // MARK: Private

    private var currentTask: Task<(), Never>?

    private func makeChatRequest(
        url: URL, messages: [DeepSeekChatMessage], stream: Bool = true
    ) throws
        -> URLRequest {
        let effort = configuredReasoningEffort
        let requestBody = DeepSeekChatRequest(
            messages: messages,
            model: model,
            stream: stream,
            thinking: .init(type: effort.isEnabled ? "enabled" : "disabled"),
            reasoningEffort: effort.requestValue
        )

        var request = URLRequest(
            url: url, timeoutInterval: AppConstants.llmRequestTimeoutInterval
        )
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(requestBody)
        return request
    }

    private func validateHTTPResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw QueryError(type: .api, message: "Invalid DeepSeek response")
        }

        guard (200 ... 299).contains(httpResponse.statusCode) else {
            throw QueryError(type: .api, message: "HTTP \(httpResponse.statusCode)")
        }
    }

    private func processStreamBytes(
        _ asyncBytes: URLSession.AsyncBytes,
        continuation: AsyncThrowingStream<String, Error>.Continuation
    ) async throws {
        var dataBuffer = Data()
        var textBuffer = ""

        for try await byte in asyncBytes {
            try Task.checkCancellation()
            dataBuffer.append(byte)

            guard byte == 0x0A else {
                continue
            }

            if let text = String(data: dataBuffer, encoding: .utf8) {
                textBuffer.append(text)
                dataBuffer.removeAll()
                processCompleteEvents(from: &textBuffer, continuation: continuation)
            }
        }

        if !dataBuffer.isEmpty, let text = String(data: dataBuffer, encoding: .utf8) {
            textBuffer.append(text)
        }
        processCompleteEvents(from: &textBuffer, continuation: continuation)
    }

    private func processCompleteEvents(
        from textBuffer: inout String,
        continuation: AsyncThrowingStream<String, Error>.Continuation
    ) {
        textBuffer = textBuffer.replacingOccurrences(of: "\r\n", with: "\n")
        let eventSeparator = "\n\n"
        guard textBuffer.contains(eventSeparator) else { return }

        let parts = textBuffer.split(separator: eventSeparator, omittingEmptySubsequences: false)
        textBuffer = String(parts.last ?? "")

        for event in parts.dropLast() where !event.isEmpty {
            guard let content = parseSSEEvent(String(event)) else { continue }
            continuation.yield(content)
        }
    }

    private func parseSSEEvent(_ event: String) -> String? {
        let dataPrefix = "data:"
        let doneFlag = "[DONE]"
        var dataString = ""

        for line in event.split(separator: "\n") where line.starts(with: dataPrefix) {
            let payload = line.dropFirst(dataPrefix.count).trimmingCharacters(in: .whitespaces)
            guard payload != doneFlag else { return nil }
            dataString += payload
        }

        guard !dataString.isEmpty,
              let data = dataString.data(using: .utf8)
        else {
            return nil
        }

        guard let chunk = try? JSONDecoder().decode(DeepSeekStreamChunk.self, from: data) else {
            logError("Failed to decode DeepSeek SSE data: \(dataString)")
            return nil
        }

        return chunk.choices.first?.delta.content
    }
}

// MARK: - DeepSeekModel

enum DeepSeekModel: String, CaseIterable {
    // Docs: https://api-docs.deepseek.com
    // Pricing: https://api-docs.deepseek.com/quick_start/pricing
    case deepseekFlash = "deepseek-flash"
    case deepseekV4Pro = "deepseek-v4-pro"
}

// MARK: - DeepSeekChatRequest

/// Encodable chat-completions payload for DeepSeek. Mirrors the OpenAI-
/// compatible fields Easydict already uses and adds DeepSeek V4's `thinking`
/// and `reasoning_effort` parameters.
private struct DeepSeekChatRequest: Encodable {
    // MARK: Internal

    let messages: [DeepSeekChatMessage]
    let model: String
    let stream: Bool
    let thinking: DeepSeekThinking
    let reasoningEffort: String?

    // MARK: Private

    private enum CodingKeys: String, CodingKey {
        case messages
        case model
        case stream
        case thinking
        case reasoningEffort = "reasoning_effort"
    }
}

// MARK: - DeepSeekChatMessage

/// Preserves plain-text translation messages while encoding OCR as image content parts.
private struct DeepSeekChatMessage: Encodable {
    // MARK: Lifecycle

    init(_ message: ChatMessage) {
        self.role = message.role.rawValue
        self.content = message.content
        self.imageURL = nil
    }

    init(imageURL: String, prompt: String) {
        self.role = "user"
        self.content = prompt
        self.imageURL = imageURL
    }

    // MARK: Internal

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(role, forKey: .role)
        if let imageURL {
            let parts = [
                ContentPart(type: "text", text: content, imageURL: nil),
                ContentPart(type: "image_url", text: nil, imageURL: .init(url: imageURL)),
            ]
            try container.encode(parts, forKey: .content)
        } else {
            try container.encode(content, forKey: .content)
        }
    }

    // MARK: Private

    private struct ImageURL: Encodable {
        let url: String
    }

    private struct ContentPart: Encodable {
        // MARK: Internal

        let type: String
        let text: String?
        let imageURL: ImageURL?

        // MARK: Private

        private enum CodingKeys: String, CodingKey {
            case type, text
            case imageURL = "image_url"
        }
    }

    private enum CodingKeys: String, CodingKey {
        case role, content
    }

    private let role: String
    private let content: String
    private let imageURL: String?
}

// MARK: - DeepSeekThinking

/// DeepSeek V4 thinking mode switch. The effort level is encoded separately
/// because the API keeps `thinking.type` and `reasoning_effort` as sibling
/// parameters.
private struct DeepSeekThinking: Encodable {
    let type: String
}

// MARK: - DeepSeekStreamChunk

/// Streaming chat-completions chunk returned by DeepSeek. Only the assistant
/// content delta is needed for Easydict's text output pipeline.
private struct DeepSeekStreamChunk: Decodable {
    struct Choice: Decodable {
        let delta: Delta
    }

    struct Delta: Decodable {
        let content: String?
    }

    let choices: [Choice]
}
