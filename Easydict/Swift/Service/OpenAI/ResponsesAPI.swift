//
//  ResponsesAPI.swift
//  Easydict
//
//  Created by tisfeng on 2026/11/25.
//  Copyright © 2026 izual. All rights reserved.
//

import Alamofire
import Foundation
import OpenAI

// MARK: - ResponsesInputItem

struct ResponsesInputItem: Codable, Equatable, Sendable {
    let role: String
    let content: String
}

// MARK: - ResponsesInputMapper

/// Maps Easydict chat messages onto Responses API input items.
struct ResponsesInputMapper {
    // MARK: Internal

    /// Converts chat messages to Responses input.
    ///
    /// `tool` has no equivalent input role in this translation flow, so those messages are omitted.
    func inputItems(from messages: [ChatMessage]) -> [ResponsesInputItem] {
        messages.compactMap { message in
            let role: String
            switch message.role {
            case .system:
                role = "system"
            case .user:
                role = "user"
            case .assistant, .model:
                role = "assistant"
            case .tool:
                return nil
            }
            return ResponsesInputItem(role: role, content: message.content)
        }
    }
}

// MARK: - ResponsesRequest

struct ResponsesRequest: Encodable, Sendable {
    let model: String
    let input: [ResponsesInputItem]
    let stream: Bool
    /// Official OpenAI stores response objects unless this is false. Other hosts omit it.
    let store: Bool?
}

// MARK: - ResponsesAPIErrorBody

struct ResponsesAPIErrorBody: Decodable, Equatable, Sendable {
    let message: String?
}

// MARK: - ResponsesIncompleteDetails

struct ResponsesIncompleteDetails: Decodable, Equatable, Sendable {
    let reason: String?
}

// MARK: - ResponsesOutputContent

struct ResponsesOutputContent: Decodable, Equatable, Sendable {
    let type: String?
    let text: String?
}

// MARK: - ResponsesOutputItem

struct ResponsesOutputItem: Decodable, Equatable, Sendable {
    let type: String?
    let content: [ResponsesOutputContent]?
}

// MARK: - ResponsesResponse

struct ResponsesResponse: Decodable, Equatable, Sendable {
    // MARK: Internal

    let status: String?
    let output: [ResponsesOutputItem]?
    let error: ResponsesAPIErrorBody?
    let incompleteDetails: ResponsesIncompleteDetails?
    let outputTextField: String?

    enum CodingKeys: String, CodingKey {
        case status
        case output
        case error
        case incompleteDetails = "incomplete_details"
        case outputTextField = "output_text"
    }

    /// Text from completed message items, or the top-level `output_text` when a gateway only sends that field.
    var aggregatedOutputText: String? {
        var texts: [String] = []
        for item in output ?? [] where item.type == "message" {
            for content in item.content ?? [] where content.type == "output_text" {
                if let text = content.text, !text.isEmpty {
                    texts.append(text)
                }
            }
        }
        let joined = texts.joined()
        if !joined.isEmpty {
            return joined
        }
        if let outputTextField, !outputTextField.isEmpty {
            return outputTextField
        }
        return nil
    }

    /// Returns completed output. A non-completed status is a failed translation even when partial text exists.
    func requireOutputText() throws -> String {
        if let status = status?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
           status != "completed" {
            throw QueryError(
                type: .api,
                message: "Responses status \(status)",
                errorDataMessage: error?.message ?? incompleteDetails?.reason
            )
        }
        guard let text = aggregatedOutputText else {
            throw QueryError(type: .noResult)
        }
        return text
    }
}

// MARK: - ResponsesStreamClassification

enum ResponsesStreamClassification: Equatable {
    case delta(String)
    case terminalText(String)
    case failure(message: String, details: String)
    case ignored
}

// MARK: - ResponsesStreamClassifier

/// Classifies one Responses SSE payload.
///
/// The JSON `type` decides the event. Gateways that remove the `event:` line still work,
/// and an `event:` name is only a fallback when the payload has no type.
struct ResponsesStreamClassifier {
    // MARK: Internal

    func classify(eventName: String, payload: String) -> ResponsesStreamClassification {
        let trimmedPayload = payload.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPayload.isEmpty, trimmedPayload != "[DONE]" else {
            return .ignored
        }

        guard let data = trimmedPayload.data(using: .utf8),
              let decoded = try? JSONDecoder().decode(ResponsesStreamPayload.self, from: data)
        else {
            return .ignored
        }

        let type = decoded.type ?? eventName
        if type == "response.output_text.delta", let delta = decoded.delta, !delta.isEmpty {
            return .delta(delta)
        }
        if let terminalText = terminalText(type: type, payload: decoded) {
            return .terminalText(terminalText)
        }
        if isFailure(type) {
            return .failure(
                message: failureMessage(type: type, payload: decoded),
                details: trimmedPayload
            )
        }
        return .ignored
    }

    // MARK: Private

    private func isFailure(_ type: String) -> Bool {
        type == "response.failed" || type == "response.incomplete" || type == "error" || type == "response.error"
    }

    private func terminalText(type: String, payload: ResponsesStreamPayload) -> String? {
        if type == "response.output_text.done", let text = payload.text, !text.isEmpty {
            return text
        }
        if type == "response.completed" {
            return payload.response?.aggregatedOutputText
        }
        return nil
    }

    private func failureMessage(type: String, payload: ResponsesStreamPayload) -> String {
        if let message = payload.message?.trimmingCharacters(in: .whitespacesAndNewlines), !message.isEmpty {
            return message
        }
        if let message = payload.response?.error?.message, !message.isEmpty {
            return message
        }
        if let reason = payload.response?.incompleteDetails?.reason, !reason.isEmpty {
            return "Responses status incomplete: \(reason)"
        }
        return "Responses stream \(type)"
    }
}

// MARK: - ResponsesStreamPayload

private struct ResponsesStreamPayload: Decodable {
    let type: String?
    let delta: String?
    let text: String?
    let message: String?
    let response: ResponsesResponse?
}

// MARK: - ResponsesSSEBuffer

/// Splits a byte stream into SSE lines.
///
/// Chunks may divide a line inside a multibyte UTF-8 character, so a line is decoded only after its newline byte.
struct ResponsesSSEBuffer {
    // MARK: Internal

    /// Appends one chunk and returns each complete line without its terminator.
    mutating func append(_ data: Data) -> [String] {
        pending.append(data)
        var lines: [String] = []
        while let newlineIndex = pending.firstIndex(of: 0x0A) {
            var lineData = pending[..<newlineIndex]
            pending.removeSubrange(...newlineIndex)
            if lineData.last == 0x0D {
                lineData = lineData.dropLast()
            }
            lines.append(String(decoding: Data(lineData), as: UTF8.self))
        }
        return lines
    }

    // MARK: Private

    private var pending = Data()
}

// MARK: - ResponsesAPITransport

/// Sends one Responses API request through Alamofire.
struct ResponsesAPITransport {
    // MARK: Internal

    /// Builds the JSON request shared by the streaming and non-streaming calls.
    func makeRequest(
        messages: [ChatMessage],
        model: String,
        url: URL,
        apiKey: String,
        stream: Bool
    ) throws
        -> URLRequest {
        let body = ResponsesRequest(
            model: model,
            input: ResponsesInputMapper().inputItems(from: messages),
            stream: stream,
            store: disablesStorage(for: url) ? false : nil
        )
        var request = URLRequest(url: url, timeoutInterval: AppConstants.llmRequestTimeoutInterval)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !apiKey.isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.setValue(apiKey, forHTTPHeaderField: "api-key")
        }
        request.httpBody = try JSONEncoder().encode(body)
        return request
    }

    /// Performs a non-streaming Responses request and returns its completed text.
    func requestText(_ request: URLRequest) async throws -> String {
        let response = await AF.request(request)
            .serializingData(automaticallyCancelling: true)
            .response
        try Task.checkCancellation()
        if let error = response.error {
            throw cancellationOrRequestError(error)
        }
        let data = response.data ?? Data()
        try throwIfHTTPError(data: data, statusCode: response.response?.statusCode)
        let decoded = try JSONDecoder().decode(ResponsesResponse.self, from: data)
        return try decoded.requireOutputText()
    }

    /// Streams Responses SSE events, yielding each text delta once.
    ///
    /// A terminal text event is used only when the stream never emitted a delta, so a gateway that
    /// sends only `response.completed` still produces a translation without duplicating streamed text.
    func stream(
        _ request: URLRequest,
        onText: @escaping @Sendable (String) -> ()
    ) async throws {
        let streamRequest = AF.streamRequest(request)
        let dataStream = streamRequest.streamTask().streamingData(automaticallyCancelling: true)
        var lineBuffer = ResponsesSSEBuffer()
        var eventName = ""
        var errorBody = Data()
        var sawDelta = false
        let classifier = ResponsesStreamClassifier()

        // `streamingData` uses `Never` as its stream failure type. HTTP and cancellation
        // errors arrive on the completion event, not as a stream failure.
        for await element in dataStream {
            if let data = element.value {
                appendErrorBody(data, to: &errorBody)
                for line in lineBuffer.append(data) {
                    if line.hasPrefix("event:") {
                        eventName = String(line.dropFirst("event:".count))
                            .trimmingCharacters(in: .whitespaces)
                    } else if line.hasPrefix("data:") {
                        let payload = String(line.dropFirst("data:".count))
                            .trimmingCharacters(in: .whitespaces)
                        try consumeStreamPayload(
                            classifier.classify(eventName: eventName, payload: payload),
                            sawDelta: &sawDelta,
                            onText: onText
                        )
                        eventName = ""
                    }
                }
            }
            if let completion = element.completion {
                try throwIfHTTPError(data: errorBody, statusCode: completion.response?.statusCode)
                if let error = completion.error {
                    throw cancellationOrRequestError(error)
                }
                if let response = completion.response {
                    try validateStreamContentType(response)
                }
            }
        }
    }

    // MARK: Private

    private static let maximumErrorBodySize = 64 * 1024

    /// Official Responses storage keeps request text for 30 days unless `store` is false.
    private func disablesStorage(for url: URL) -> Bool {
        url.host?.lowercased() == "api.openai.com"
    }

    private func appendErrorBody(_ data: Data, to body: inout Data) {
        guard body.count < Self.maximumErrorBodySize else {
            return
        }
        body.append(data.prefix(Self.maximumErrorBodySize - body.count))
    }

    private func throwIfHTTPError(data: Data, statusCode: Int?) throws {
        guard let statusCode, !(200 ... 299).contains(statusCode) else {
            return
        }
        if let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
            throw apiError
        }
        throw QueryError(
            type: .api,
            message: "HTTP \(statusCode)",
            errorDataMessage: String(data: data, encoding: .utf8)
        )
    }

    /// Reuses the Chat Completions content-type error so validation can fall back to non-streaming.
    private func validateStreamContentType(_ response: HTTPURLResponse) throws {
        guard (200 ... 299).contains(response.statusCode) else {
            return
        }
        let mimeType = response.mimeType?.lowercased() ?? "unknown"
        guard mimeType == "text/event-stream" else {
            throw OpenAIStreamTransportError.incorrectContentType(
                mimeType,
                url: response.url?.absoluteString
            )
        }
    }

    private func consumeStreamPayload(
        _ classification: ResponsesStreamClassification,
        sawDelta: inout Bool,
        onText: @Sendable (String) -> ()
    ) throws {
        switch classification {
        case let .delta(text):
            sawDelta = true
            onText(text)
        case let .terminalText(text):
            if !sawDelta {
                sawDelta = true
                onText(text)
            }
        case let .failure(message, details):
            throw QueryError(type: .api, message: message, errorDataMessage: details)
        case .ignored:
            break
        }
    }

    private func cancellationOrRequestError(_ error: AFError) -> Error {
        if error.isExplicitlyCancelledError {
            return CancellationError()
        }
        if case let .sessionTaskFailed(underlying) = error {
            if underlying is CancellationError {
                return CancellationError()
            }
            if let urlError = underlying as? URLError, urlError.code == .cancelled {
                return CancellationError()
            }
            let nsError = underlying as NSError
            if nsError.domain == NSURLErrorDomain, nsError.code == NSURLErrorCancelled {
                return CancellationError()
            }
        }
        return error
    }
}

// MARK: - BaseOpenAIService + Responses

extension BaseOpenAIService {
    /// Translates through the Responses API using the same cancellation slots as Chat Completions.
    func responsesContentStream(
        messages: [ChatMessage]
    )
        -> AsyncThrowingStream<String, any Error> {
        do {
            let endpoint = try validateChatStreamRequest()
            let url = OpenAIEndpointAdapter().requestURL(endpoint: endpoint, apiType: .responses)
            result.isStreamFinished = false
            let transport = ResponsesAPITransport()
            let request = try transport.makeRequest(
                messages: messages,
                model: model,
                url: url,
                apiKey: apiKey,
                stream: usesStreamingTransport
            )
            if usesStreamingTransport {
                return responsesResultStream(transport: transport, request: request)
            }
            return responsesNonStreamingResult(transport: transport, request: request)
        } catch {
            return failedContentStream(error: error)
        }
    }

    // MARK: Private

    private func responsesResultStream(
        transport: ResponsesAPITransport,
        request: URLRequest
    )
        -> AsyncThrowingStream<String, any Error> {
        let taskControl = streamTaskControl
        return AsyncThrowingStream { continuation in
            let identifier = UUID()
            responsesNonStreamingControl.cancel()
            nonStreamingTask?.cancel()
            nonStreamingTask = nil
            taskControl.begin(identifier: identifier)
            let task = Task {
                defer { taskControl.finish(identifier: identifier) }
                do {
                    try await transport.stream(request) { text in
                        continuation.yield(text)
                    }
                    continuation.finish()
                } catch is CancellationError {
                    continuation.finish()
                } catch let error as URLError where error.code == .cancelled {
                    continuation.finish()
                } catch let error as NSError
                    where error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled {
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            taskControl.install(task, identifier: identifier)
            continuation.onTermination = { @Sendable _ in
                taskControl.cancel(identifier: identifier)
            }
        }
    }

    private func responsesNonStreamingResult(
        transport: ResponsesAPITransport,
        request: URLRequest
    )
        -> AsyncThrowingStream<String, any Error> {
        let taskControl = responsesNonStreamingControl
        return AsyncThrowingStream { continuation in
            let identifier = UUID()
            streamTaskControl.cancel()
            nonStreamingTask?.cancel()
            nonStreamingTask = nil
            taskControl.begin(identifier: identifier)
            let task = Task {
                defer { taskControl.finish(identifier: identifier) }
                do {
                    let text = try await transport.requestText(request)
                    continuation.yield(text)
                    continuation.finish()
                } catch is CancellationError {
                    continuation.finish(throwing: CancellationError())
                } catch let error as URLError where error.code == .cancelled {
                    continuation.finish(throwing: CancellationError())
                } catch let error as NSError
                    where error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled {
                    continuation.finish(throwing: CancellationError())
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            taskControl.install(task, identifier: identifier)
            continuation.onTermination = { @Sendable _ in
                taskControl.cancel(identifier: identifier)
            }
        }
    }
}
