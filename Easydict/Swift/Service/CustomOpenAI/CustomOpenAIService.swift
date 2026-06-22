//
//  CustomOpenAIService.swift
//  Easydict
//
//  Created by phlpsong on 2024/2/16.
//  Copyright © 2024 izual. All rights reserved.
//

import Defaults
import Foundation
import OpenAI
import SwiftUI

// MARK: - CustomOpenAIService

@objc(EZCustomOpenAIService)
class CustomOpenAIService: BaseOpenAIService {
    // MARK: Public

    public override func name() -> String {
        let serviceName = Defaults[super.nameKey]
        return serviceName.isEmpty ? NSLocalizedString("custom_openai", comment: "") : serviceName
    }

    public override func serviceType() -> ServiceType {
        .customOpenAI
    }

    public override func cancelStream() {
        currentTask?.cancel()
        super.cancelStream()
    }

    // MARK: Internal

    override var supportsStreamingToggle: Bool { true }

    override func serviceTypeWithUniqueIdentifier() -> String {
        guard !uuid.isEmpty else {
            return ServiceType.customOpenAI.rawValue
        }
        return "\(ServiceType.customOpenAI.rawValue)#\(uuid)"
    }

    override func isDuplicatable() -> Bool {
        true
    }

    override func isDeletable(_ type: EZWindowType) -> Bool {
        !uuid.isEmpty
    }

    override func configurationListItems() -> Any {
        CustomOpenAIConfigurationView(service: self)
    }

    /// Extra top-level JSON fields the user wants merged into every request body.
    /// Empty string means "no extra fields" — the request falls back to the base
    /// OpenAI-compatible path verbatim.
    var extraBodyJSONKey: Defaults.Key<String> {
        stringDefaultsKey(.extraBodyJSON, defaultValue: "")
    }

    var extraBodyJSON: String {
        Defaults[extraBodyJSONKey]
    }

    /// Parses the user-provided extra JSON into a top-level fields dictionary.
    /// Returns nil when empty, not an object, or invalid JSON so the request
    /// silently degrades to the standard body instead of failing.
    private func parsedExtraFields() -> [String: Any]? {
        let raw = extraBodyJSON.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty,
              let data = raw.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data),
              let dict = object as? [String: Any]
        else {
            if !raw.isEmpty {
                logError("Custom OpenAI extra body JSON is invalid, ignored: \(raw)")
            }
            return nil
        }
        return dict
    }

    /// Encodes the standard OpenAI-compatible body from `ChatQuery`, then shallow-
    /// merges the user's extra fields on top (user keys overwrite built-in ones
    /// such as `model` / `temperature`). When there are no extra fields, returns
    /// the verbatim `ChatQuery` encoding so behavior is unchanged.
    private func makeMergedBody(messages: [OpenAIChatMessage], stream: Bool) throws -> Data {
        var query = ChatQuery(messages: messages, model: model, temperature: temperature)
        query.stream = stream

        let encoded = try JSONEncoder().encode(query)
        guard let extra = parsedExtraFields() else { return encoded }
        guard var base = try JSONSerialization.jsonObject(with: encoded) as? [String: Any] else {
            return encoded
        }
        for (key, value) in extra {
            base[key] = value
        }
        return try JSONSerialization.data(withJSONObject: base)
    }

    private func makeURLRequest(url: URL, body: Data) -> URLRequest {
        var request = URLRequest(url: url, timeoutInterval: EZNetWorkTimeoutInterval)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !apiKey.isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            // Azure OpenAI compatibility, mirrors BaseOpenAIService.
            request.setValue(apiKey, forHTTPHeaderField: "api-key")
        }
        request.httpBody = body
        return request
    }

    /// Translates with extra request-body fields merged in. When the extra JSON
    /// is empty, fully delegates to the base implementation (the SPM `chatsStream`
    /// path with its validate fallback), so users who don't use this feature see
    /// no behavior change.
    override func contentStreamTranslate(
        _ text: String,
        from: Language,
        to: Language
    )
        -> AsyncThrowingStream<String, Error> {
        guard parsedExtraFields() != nil else {
            return super.contentStreamTranslate(text, from: from, to: to)
        }

        return AsyncThrowingStream { continuation in
            guard let url = URL(string: endpoint), url.isValid else {
                continuation.finish(
                    throwing: QueryError(
                        type: .parameter,
                        message: "`\(serviceType().rawValue)` endpoint is invalid"
                    )
                )
                return
            }

            if apiKeyRequirement().requiresKeyForRequest, apiKey.isEmpty {
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

                    guard let chatHistory = serviceChatMessageModels(chatQueryParam) as? [OpenAIChatMessage]
                    else {
                        throw QueryError(type: .parameter, message: "Failed to convert chat messages")
                    }

                    if usesStreamingTransport {
                        let body = try makeMergedBody(messages: chatHistory, stream: true)
                        let request = makeURLRequest(url: url, body: body)
                        let (asyncBytes, response) = try await URLSession.shared.bytes(for: request)
                        try validateStreamResponse(response)
                        try await processStreamBytes(asyncBytes, continuation: continuation)
                    } else {
                        let body = try makeMergedBody(messages: chatHistory, stream: false)
                        let request = makeURLRequest(url: url, body: body)
                        try await runNonStreaming(request: request, continuation: continuation)
                    }

                    continuation.finish()
                } catch is CancellationError {
                    logInfo("Custom OpenAI task was cancelled.")
                    continuation.finish(throwing: CancellationError())
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            currentTask = task
            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }

    // MARK: Private

    private var currentTask: Task<(), Never>?

    /// Validates the streaming response. A non-`text/event-stream` Content-Type
    /// surfaces as `.contentTypeMismatch` so `BaseOpenAIService.validate()` can
    /// auto-fall back to the non-streaming transport, matching the base path.
    private func validateStreamResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw QueryError(type: .api, message: "Invalid Custom OpenAI response")
        }

        guard (200 ... 299).contains(httpResponse.statusCode) else {
            throw QueryError(type: .api, message: "HTTP \(httpResponse.statusCode)")
        }

        if let mimeType = httpResponse.mimeType, mimeType != "text/event-stream" {
            throw QueryError(
                type: .contentTypeMismatch,
                message: "Expected text/event-stream, got \(mimeType)"
            )
        }
    }

    /// Non-streaming completion. Decodes the OpenAI-compatible `ChatResult` and
    /// yields the full message content as a single chunk.
    private func runNonStreaming(
        request: URLRequest,
        continuation: AsyncThrowingStream<String, Error>.Continuation
    ) async throws {
        let (data, response) = try await URLSession.shared.data(for: request)
        try Task.checkCancellation()

        if let http = response as? HTTPURLResponse, !(200 ... 299).contains(http.statusCode) {
            if let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                throw apiError
            }
            throw QueryError(
                type: .api,
                message: "HTTP \(http.statusCode)",
                errorDataMessage: String(data: data, encoding: .utf8)
            )
        }

        let chatResult = try JSONDecoder().decode(ChatResult.self, from: data)
        guard let content = chatResult.choices.first?.message.content?.string, !content.isEmpty else {
            throw QueryError(type: .noResult)
        }
        continuation.yield(content)
    }

    /// Processes the SSE byte stream and yields translated text chunks.
    private func processStreamBytes(
        _ asyncBytes: URLSession.AsyncBytes,
        continuation: AsyncThrowingStream<String, Error>.Continuation
    ) async throws {
        var dataBuffer = Data()
        var textBuffer = ""

        for try await byte in asyncBytes {
            try Task.checkCancellation()
            dataBuffer.append(byte)

            guard byte == 0x0A else { continue }

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

    /// Splits the text buffer on double-newlines and processes complete SSE events.
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

    /// Extracts the delta content from a single SSE `data:` payload.
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

        guard let chunk = try? JSONDecoder().decode(ChatStreamResult.self, from: data) else {
            logError("Failed to decode Custom OpenAI SSE data: \(dataString)")
            return nil
        }

        return chunk.choices.first?.delta.content
    }
}

// MARK: - CustomOpenAIConfigurationView

/// Configuration UI for Custom OpenAI. Reuses the standard stream service form
/// and adds an extra request-body JSON editor so users can inject fields such as
/// `{"thinking":{"type":"disabled"}}` to disable thinking on compatible backends.
private struct CustomOpenAIConfigurationView: View {
    let service: CustomOpenAIService

    var body: some View {
        StreamConfigurationView(
            service: service,
            showCustomNameSection: true,
            showStreamingToggle: true
        )
        Section {
            TextEditorCell(
                titleKey: "service.configuration.custom_openai.extra_body.title",
                storedValueKey: service.extraBodyJSONKey,
                placeholder: "service.configuration.custom_openai.extra_body.placeholder",
                footnote: "service.configuration.custom_openai.extra_body.footnote",
                minHeight: 55,
                maxHeight: 120
            )
        }
    }
}
