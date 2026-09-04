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

import Foundation
import OpenAI

// MARK: - ResponsesInputItem

struct ResponsesInputItem: Encodable {
    let role: String
    let content: String
}

// MARK: - ResponsesRequest

struct ResponsesRequest: Encodable {
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
        let apiKey = apiKey

        return AsyncThrowingStream(String.self) { [weak self] continuation in
            guard let self else {
                continuation.finish(throwing: CancellationError())
                return
            }

            let task = Task {
                defer { self.nonStreamingTask = nil }

                do {
                    let request = try self.makeResponsesRequest(
                        messages: messages,
                        model: model,
                        temperature: temperature,
                        stream: false,
                        url: url,
                        apiKey: apiKey
                    )
                    let (data, response) = try await URLSession.shared.data(for: request)
                    try Task.checkCancellation()
                    try self.throwIfResponsesError(data: data, response: response)

                    let result = try JSONDecoder().decode(ResponsesResponse.self, from: data)
                    if let content = result.outputText {
                        continuation.yield(content)
                        continuation.finish()
                    } else {
                        throw QueryError(type: .noResult)
                    }
                } catch let urlError as URLError where urlError.code == .cancelled {
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
                do {
                    let request = try self.makeResponsesRequest(
                        messages: messages,
                        model: model,
                        temperature: temperature,
                        stream: true,
                        url: url,
                        apiKey: apiKey
                    )
                    let (bytes, response) = try await URLSession.shared.bytes(for: request)
                    try Task.checkCancellation()
                    guard let http = response as? HTTPURLResponse,
                          (200 ... 299).contains(http.statusCode) else {
                        var body: String?
                        var collected = Data()
                        for try await byte in bytes.prefix(4096) {
                            collected.append(byte)
                        }
                        body = String(data: collected, encoding: .utf8)
                        throw QueryError(
                            type: .api,
                            message: "HTTP \((response as? HTTPURLResponse)?.statusCode ?? -1)",
                            errorDataMessage: body
                        )
                    }

                    var eventName = ""
                    for try await line in bytes.lines {
                        try Task.checkCancellation()
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
                    continuation.finish()
                } catch let urlError as URLError where urlError.code == .cancelled {
                    continuation.finish(throwing: CancellationError())
                } catch is CancellationError {
                    continuation.finish(throwing: CancellationError())
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }

    /// Builds the HTTP request for an OpenAI Responses call.
    func makeResponsesRequest(
        messages: [ChatMessage],
        model: String,
        temperature: Double,
        stream: Bool,
        url: URL,
        apiKey: String
    ) throws
        -> URLRequest {
        let query = ResponsesRequest(
            model: model,
            input: responsesInputItems(from: messages),
            temperature: temperature,
            stream: stream
        )

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

    /// Throws for non-2xx Responses results, mirroring chat error handling.
    func throwIfResponsesError(data: Data, response: URLResponse) throws {
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
    }
}
