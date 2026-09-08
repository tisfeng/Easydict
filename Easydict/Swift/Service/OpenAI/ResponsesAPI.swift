//
//  ResponsesAPI.swift
//  Easydict
//
//  Minimal client for the OpenAI Responses API (`/v1/responses`).
//  Used by OpenAI-compatible services when `OpenAIAPIType` is `responses`.
//  Verified against https://opencode.ai/zen/go/v1/responses with
//  `muse-spark-1.3-contributor`: request uses `input`, non-streaming
//  responses carry `output` items, and streaming emits SSE events such as
//  `response.output_text.delta` whose `data.delta` holds the text.

import Alamofire
import Foundation
import OpenAI

// MARK: - ResponsesInputItem

struct ResponsesInputItem: Encodable, Sendable {
    let role: String
    let content: String
}

// MARK: - ResponsesRequest

struct ResponsesRequest: Encodable, Sendable {
    let model: String
    let input: [ResponsesInputItem]
    let temperature: Double?
    let stream: Bool
}

// MARK: - ResponsesResponse

struct ResponsesResponse: Decodable {
    let status: String?
    let output: [ResponsesOutputItem]?
}

// MARK: - ResponsesOutputItem

struct ResponsesOutputItem: Decodable {
    let type: String
    let content: [ResponsesOutputContent]?
}

// MARK: - ResponsesOutputContent

struct ResponsesOutputContent: Decodable {
    let type: String
    let text: String?
}

extension ResponsesResponse {
    /// Concatenated `output_text` of all message items.
    /// Reasoning items have no `content`, so they are skipped.
    /// Items are filtered by `type` instead of array index because the
    /// message item is not always the first output item.
    var outputText: String? {
        guard let output else { return nil }
        var texts: [String] = []
        for item in output where item.type == "message" {
            for content in item.content ?? [] where content.type == "output_text" {
                if let text = content.text, !text.isEmpty {
                    texts.append(text)
                }
            }
        }
        let joined = texts.joined()
        return joined.isEmpty ? nil : joined
    }
}

// MARK: - ResponsesStreamDelta

struct ResponsesStreamDelta: Decodable {
    let type: String?
    let delta: String?
}

// MARK: - ResponsesStreamEvent

enum ResponsesStreamEvent {
    case delta(String)
    case failure(QueryError)
    case ignored
}

/// Classifies one Responses SSE event by its `event:` name and `data:` payload.
/// The decoded `type` field wins over the event name so data-only streams
/// (no `event:` line) still resolve.
func responsesStreamEvent(eventName: String, payload: String) -> ResponsesStreamEvent {
    guard !payload.isEmpty, payload != "[DONE]",
          let payloadData = payload.data(using: .utf8)
    else { return .ignored }

    let decoded = try? JSONDecoder().decode(ResponsesStreamDelta.self, from: payloadData)
    let type = decoded?.type ?? eventName

    if type == "response.output_text.delta", let text = decoded?.delta, !text.isEmpty {
        return .delta(text)
    }
    if type.contains("failed") || type.contains("error") {
        return .failure(
            QueryError(
                type: .api,
                message: "Responses stream \(type)",
                errorDataMessage: payload
            )
        )
    }
    return .ignored
}

// MARK: - ResponsesSSEBuffer

/// Accumulates raw SSE bytes and returns complete lines as they arrive.
/// Chunks may split lines at arbitrary byte boundaries (even inside
/// multi-byte UTF-8 characters), so lines are only split on the `0x0A`
/// newline byte and decoded once complete.
struct ResponsesSSEBuffer {
    // MARK: Internal

    /// Appends raw chunk data and returns every complete line without its
    /// terminator. A trailing `\r` (CRLF) is stripped.
    mutating func append(_ data: Data) -> [String] {
        pending.append(data)
        var lines: [String] = []
        while let newlineIndex = pending.firstIndex(of: 0x0A) {
            var lineData = pending[..<newlineIndex]
            pending.removeSubrange(...newlineIndex)
            if lineData.last == 0x0D {
                lineData = lineData.dropLast()
            }
            if let line = String(data: Data(lineData), encoding: .utf8) {
                lines.append(line)
            }
        }
        return lines
    }

    // MARK: Private

    private var pending = Data()
}

// MARK: - Input Builder

/// Convert repo chat messages to Responses input items.
/// Roles map to `system`, `user`, and `assistant`. `tool` messages have no
/// Responses equivalent, so they are dropped.
func responsesInputItems(from messages: [ChatMessage]) -> [ResponsesInputItem] {
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

// MARK: - Endpoint Normalization

/// Returns the request URL for `apiType` by swapping the endpoint path suffix
/// between wire formats, so switching `OpenAIAPIType` works without editing
/// the endpoint manually. Unrecognized paths are returned unchanged.
func normalizedRequestURL(endpoint: URL, apiType: OpenAIAPIType) -> URL {
    guard var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false) else {
        return endpoint
    }
    var parts = components.path.split(separator: "/", omittingEmptySubsequences: true).map(String.init)
    let lowered = parts.map { $0.lowercased() }

    if apiType == .responses {
        if Array(lowered.suffix(2)) == ["chat", "completions"] {
            parts.removeLast(2)
            parts.append("responses")
        } else if lowered.last == "completions" {
            parts.removeLast()
            parts.append("responses")
        } else {
            return endpoint
        }
    } else {
        guard lowered.last == "responses" else { return endpoint }
        parts.removeLast()
        parts.append(contentsOf: ["chat", "completions"])
    }

    components.path = "/" + parts.joined(separator: "/")
    return components.url ?? endpoint
}

// MARK: - BaseOpenAIService + Responses

extension BaseOpenAIService {
    /// Non-streaming Responses translation, yielding the full text as one chunk.
    /// Mirrors `nonStreamingTranslate` transport and error handling.
    func responsesNonStreamingTranslate(
        messages: [ChatMessage],
        model: String,
        temperature: Double,
        url: URL,
        apiKey: String
    )
        -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream(String.self) { continuation in
            let task = Task {
                defer { nonStreamingTask = nil }

                do {
                    let response = await AF.request(
                        url,
                        method: .post,
                        parameters: makeResponsesQuery(
                            messages: messages,
                            model: model,
                            temperature: temperature,
                            stream: false
                        ),
                        encoder: JSONParameterEncoder.default,
                        headers: responsesHeaders(apiKey: apiKey),
                        requestModifier: { $0.timeoutInterval = EZNetWorkTimeoutInterval }
                    )
                    .serializingData(automaticallyCancelling: true)
                    .response
                    try Task.checkCancellation()
                    try throwIfResponsesError(
                        data: response.data ?? Data(),
                        statusCode: response.response?.statusCode
                    )

                    let result = try JSONDecoder().decode(
                        ResponsesResponse.self, from: response.data ?? Data()
                    )
                    if let content = result.outputText {
                        continuation.yield(content)
                        continuation.finish()
                    } else {
                        throw QueryError(type: .noResult)
                    }
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

    /// Streaming Responses translation over SSE.
    /// Yields each `response.output_text.delta` payload as it arrives.
    func responsesStreamTranslate(
        messages: [ChatMessage],
        model: String,
        temperature: Double,
        url: URL,
        apiKey: String
    )
        -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream<String, Error> { continuation in
            let task = Task {
                defer { responsesStreamingTask = nil }
                do {
                    let streamRequest = AF.streamRequest(
                        url,
                        method: .post,
                        parameters: makeResponsesQuery(
                            messages: messages,
                            model: model,
                            temperature: temperature,
                            stream: true
                        ),
                        encoder: JSONParameterEncoder.default,
                        headers: responsesHeaders(apiKey: apiKey),
                        requestModifier: { $0.timeoutInterval = EZNetWorkTimeoutInterval }
                    )
                    let dataStream = streamRequest.streamTask()
                        .streamingData(automaticallyCancelling: true)

                    var sseBuffer = ResponsesSSEBuffer()
                    var eventName = ""
                    var errorBody = Data()

                    for await element in dataStream {
                        switch element.event {
                        case let .stream(.success(data)):
                            if errorBody.count < 4096 {
                                errorBody.append(data.prefix(4096 - errorBody.count))
                            }
                            for line in sseBuffer.append(data) {
                                if line.hasPrefix("event:") {
                                    eventName = line.dropFirst("event:".count)
                                        .trimmingCharacters(in: .whitespaces)
                                } else if line.hasPrefix("data:") {
                                    let payload = line.dropFirst("data:".count)
                                        .trimmingCharacters(in: .whitespaces)
                                    switch responsesStreamEvent(eventName: eventName, payload: payload) {
                                    case let .delta(text):
                                        continuation.yield(text)
                                    case let .failure(error):
                                        throw error
                                    case .ignored:
                                        continue
                                    }
                                }
                            }
                        case let .complete(completion):
                            try throwIfResponsesError(
                                data: errorBody,
                                statusCode: completion.response?.statusCode
                            )
                            if let afError = completion.error {
                                if case let .sessionTaskFailed(error) = afError,
                                   let urlError = error as? URLError,
                                   urlError.code == .cancelled {
                                    throw CancellationError()
                                }
                                throw afError
                            }
                        }
                    }

                    if Task.isCancelled {
                        throw CancellationError()
                    }
                    continuation.finish()
                } catch is CancellationError {
                    continuation.finish(throwing: CancellationError())
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            responsesStreamingTask = task
            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }

    /// Builds the request body for an OpenAI Responses call.
    func makeResponsesQuery(
        messages: [ChatMessage],
        model: String,
        temperature: Double,
        stream: Bool
    )
        -> ResponsesRequest {
        ResponsesRequest(
            model: model,
            input: responsesInputItems(from: messages),
            temperature: temperature,
            stream: stream
        )
    }

    /// Auth headers shared by the Responses Alamofire calls.
    func responsesHeaders(apiKey: String) -> HTTPHeaders {
        guard !apiKey.isEmpty else { return [] }
        return [
            .authorization(bearerToken: apiKey),
            HTTPHeader(name: "api-key", value: apiKey),
        ]
    }

    /// Throws for non-2xx Responses results, mirroring chat error handling.
    func throwIfResponsesError(data: Data, statusCode: Int?) throws {
        guard let statusCode, !(200 ... 299).contains(statusCode) else { return }
        if let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
            throw apiError
        }
        throw QueryError(
            type: .api,
            message: "HTTP \(statusCode)",
            errorDataMessage: String(data: data, encoding: .utf8)
        )
    }
}
