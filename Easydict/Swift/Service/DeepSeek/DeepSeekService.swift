//
//  DeepSeekService.swift
//  Easydict
//
//  Created by GarethNg on 2025/2/19.
//  Copyright © 2025 izual. All rights reserved.
//

import Defaults
import Foundation
import SwiftUI

// MARK: - DeepSeekService

/// DeepSeek translation service. Layers DeepSeek V4 reasoning parameters
/// (`thinking.type` and `reasoning_effort`) on top of the OpenAI-compatible
/// streaming pipeline as a model-agnostic per-service setting, so current
/// and future DeepSeek models opt in without code changes.
@objc(EZDeepSeekService)
class DeepSeekService: OpenAIService {
    // MARK: Public

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

    public override func configurationListItems() -> Any {
        DeepSeekConfigurationView(service: self)
    }

    // MARK: Internal

    override var defaultModels: [String] {
        DeepSeekModel.allCases.map(\.rawValue)
    }

    override var defaultModel: String {
        DeepSeekModel.deepseekV4Flash.rawValue
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

    /// Per-service reasoning effort. Defaults to off because Easydict's
    /// translation workflows prioritize lower latency; users can still choose
    /// high or max when quality needs outweigh response speed.
    var reasoningEffortKey: Defaults.Key<DeepSeekReasoningEffort> {
        serviceDefaultsKey(.reasoningEffort, defaultValue: .off)
    }

    var reasoningEffort: DeepSeekReasoningEffort {
        Defaults[reasoningEffortKey]
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
                        messages: chatMessageDicts(chatQueryParam)
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

    // MARK: Private

    private var currentTask: Task<(), Never>?

    private func makeChatRequest(url: URL, messages: [ChatMessage]) throws -> URLRequest {
        let effort = reasoningEffort
        let requestBody = DeepSeekChatRequest(
            messages: messages.map(DeepSeekChatMessage.init),
            model: model,
            temperature: temperature,
            stream: true,
            thinking: .init(type: effort.thinkingType),
            reasoningEffort: effort.reasoningEffortValue
        )

        var request = URLRequest(url: url, timeoutInterval: EZNetWorkTimeoutInterval)
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
    case deepseekV4Flash = "deepseek-v4-flash"
    case deepseekV4Pro = "deepseek-v4-pro"
}

// MARK: - DeepSeekReasoningEffort

/// User-selectable reasoning effort for DeepSeek V4. Stays orthogonal to the
/// model identifier so the same setting applies across `deepseek-v4-flash`,
/// `deepseek-v4-pro`, and any future DeepSeek-compatible model.
enum DeepSeekReasoningEffort: String, CaseIterable, Defaults.Serializable {
    case off
    case high
    case max

    // MARK: Internal

    /// Value for the `thinking.type` request field.
    var thinkingType: String {
        switch self {
        case .off:
            "disabled"
        case .high, .max:
            "enabled"
        }
    }

    /// Value for the `reasoning_effort` request field. Returns `nil` when
    /// thinking is disabled, because the API rejects an effort level in that
    /// mode.
    var reasoningEffortValue: String? {
        switch self {
        case .off:
            nil
        case .high:
            "high"
        case .max:
            "max"
        }
    }
}

// MARK: EnumLocalizedStringConvertible

extension DeepSeekReasoningEffort: EnumLocalizedStringConvertible {
    var title: LocalizedStringKey {
        switch self {
        case .off:
            "service.deepseek.reasoning_effort.off"
        case .high:
            "service.deepseek.reasoning_effort.high"
        case .max:
            "service.deepseek.reasoning_effort.max"
        }
    }
}

// MARK: - DeepSeekConfigurationView

/// Configuration UI for DeepSeek. Reuses the standard stream service form and
/// adds a reasoning effort picker so the level can be tuned independently of
/// the chosen model.
private struct DeepSeekConfigurationView: View {
    let service: DeepSeekService

    var body: some View {
        StreamConfigurationView(service: service)
        Section {
            StaticPickerCell(
                titleKey: "service.configuration.deepseek.reasoning_effort.title",
                key: service.reasoningEffortKey,
                values: DeepSeekReasoningEffort.allCases
            )
        }
    }
}

// MARK: - DeepSeekChatRequest

/// Encodable chat-completions payload for DeepSeek. Mirrors the OpenAI-
/// compatible fields Easydict already uses and adds DeepSeek V4's `thinking`
/// and `reasoning_effort` parameters.
private struct DeepSeekChatRequest: Encodable {
    // MARK: Internal

    let messages: [DeepSeekChatMessage]
    let model: String
    let temperature: Double
    let stream: Bool
    let thinking: DeepSeekThinking
    let reasoningEffort: String?

    // MARK: Private

    private enum CodingKeys: String, CodingKey {
        case messages
        case model
        case temperature
        case stream
        case thinking
        case reasoningEffort = "reasoning_effort"
    }
}

// MARK: - DeepSeekChatMessage

/// Minimal chat message shape accepted by DeepSeek's OpenAI-compatible
/// endpoint, built from Easydict's provider-agnostic prompt messages.
private struct DeepSeekChatMessage: Encodable {
    // MARK: Lifecycle

    init(_ message: ChatMessage) {
        self.role = message.role.rawValue
        self.content = message.content
    }

    // MARK: Internal

    let role: String
    let content: String
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
