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

// MARK: - ResponsesResponse + Output

extension ResponsesResponse {
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

    /// Streams Responses SSE events, yielding each new piece of output text once.
    ///
    /// Deltas are forwarded as they arrive. `response.output_text.done` is forwarded only for
    /// parts that were not already streamed, so several terminal-only parts are preserved and a
    /// repeated full-text done does not duplicate deltas. `response.completed` is used only when
    /// the stream has not already produced text.
    func stream(
        _ request: URLRequest,
        onText: @escaping @Sendable (String) -> ()
    ) async throws {
        let streamRequest = AF.streamRequest(request)
        let dataStream = streamRequest.streamTask().streamingData(automaticallyCancelling: true)
        var lineBuffer = ResponsesSSEBuffer()
        var eventName = ""
        var errorBody = Data()
        var reducer = ResponsesStreamTextReducer()
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
                            reducer: &reducer,
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
        reducer: inout ResponsesStreamTextReducer,
        onText: @Sendable (String) -> ()
    ) throws {
        if case let .failure(message, details) = classification {
            throw QueryError(type: .api, message: message, errorDataMessage: details)
        }
        for text in reducer.texts(from: classification) {
            onText(text)
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
