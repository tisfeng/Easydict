//
//  OpenAIStreamTransport.swift
//  Easydict
//
//  Created by tisfeng on 2026/9/8.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation
import OpenAI

// MARK: - OpenAIStreamTransport

/// Sends OpenAI-compatible chat streams while preserving Easydict's response validation.
/// The transport keeps the configured endpoint and Azure-compatible headers, validates
/// the SSE MIME type before consuming bytes, and decodes chunks with the upstream SDK models.
struct OpenAIStreamTransport: Sendable {
    // MARK: Lifecycle

    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: Internal

    func stream(
        query: ChatQuery,
        url: URL,
        apiKey: String,
        onResult: @escaping @Sendable (ChatStreamResult) -> ()
    ) async throws {
        let request = try makeRequest(query: query, url: url, apiKey: apiKey)
        let (bytes, response) = try await session.bytes(for: request)

        if let httpResponse = response as? HTTPURLResponse,
           !(200 ... 299).contains(httpResponse.statusCode) {
            var errorBody = Data()
            for try await byte in bytes {
                guard errorBody.count < Self.maximumErrorBodySize else {
                    break
                }
                errorBody.append(byte)
            }
            try validate(response: response, errorBody: errorBody)
        }

        try validate(response: response)

        var eventBuffer = Data()
        for try await byte in bytes {
            try Task.checkCancellation()
            eventBuffer.append(byte)
            if let eventData = completedEvent(from: &eventBuffer),
               try emitEvent(eventData, onResult: onResult) {
                return
            }
        }

        if !eventBuffer.isEmpty {
            _ = try emitEvent(eventBuffer, onResult: onResult)
        }
    }

    func makeRequest(query: ChatQuery, url: URL, apiKey: String) throws -> URLRequest {
        var query = query
        query.stream = true

        var request = URLRequest(
            url: url, timeoutInterval: SharedConstants.llmRequestTimeoutInterval
        )
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !apiKey.isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.setValue(apiKey, forHTTPHeaderField: "api-key")
        }
        request.httpBody = try JSONEncoder().encode(query)
        return request
    }

    func validate(response: URLResponse, errorBody: Data? = nil) throws {
        guard let response = response as? HTTPURLResponse else {
            throw QueryError(type: .api, message: "Invalid OpenAI stream response")
        }

        guard (200 ... 299).contains(response.statusCode) else {
            if let errorBody,
               let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: errorBody) {
                throw apiError
            }
            throw QueryError(
                type: .api,
                message: "HTTP \(response.statusCode)",
                errorDataMessage: errorBody.flatMap { String(data: $0, encoding: .utf8) }
            )
        }

        let mimeType = response.mimeType?.lowercased() ?? "unknown"
        guard mimeType == "text/event-stream" else {
            throw OpenAIStreamTransportError.incorrectContentType(
                mimeType,
                url: response.url?.absoluteString
            )
        }
    }

    func decodeEvent(dataLines: [String]) throws -> ChatStreamResult? {
        let payload = dataLines.joined(separator: "\n").trim()
        guard !payload.isEmpty, payload != "[DONE]" else {
            return nil
        }

        let data = Data(payload.utf8)
        do {
            return try JSONDecoder().decode(ChatStreamResult.self, from: data)
        } catch {
            if let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                throw apiError
            }
            throw error
        }
    }

    // MARK: Private

    private static let maximumErrorBodySize = 64 * 1024

    private let session: URLSession

    private func completedEvent(from buffer: inout Data) -> Data? {
        let delimiterLength: Int
        if buffer.suffix(4).elementsEqual([13, 10, 13, 10]) {
            delimiterLength = 4
        } else if buffer.suffix(2).elementsEqual([10, 10])
            || buffer.suffix(2).elementsEqual([13, 13]) {
            delimiterLength = 2
        } else {
            return nil
        }

        let event = buffer.dropLast(delimiterLength)
        buffer.removeAll(keepingCapacity: true)
        return Data(event)
    }

    private func eventData(from line: String) -> String? {
        guard line.hasPrefix("data:") else {
            return nil
        }
        return line.dropFirst("data:".count).trimmingCharacters(in: .whitespaces)
    }

    /// Emits one complete SSE event and returns whether it was the terminal `[DONE]` event.
    private func emitEvent(
        _ event: Data,
        onResult: @escaping @Sendable (ChatStreamResult) -> ()
    ) throws
        -> Bool {
        guard let eventString = String(data: event, encoding: .utf8) else {
            throw QueryError(type: .api, message: "Invalid UTF-8 in OpenAI stream response")
        }
        let dataLines = eventString.components(separatedBy: .newlines).compactMap(eventData)
        let payload = dataLines.joined(separator: "\n").trim()
        if payload == "[DONE]" {
            return true
        }
        if let result = try decodeEvent(dataLines: dataLines) {
            onResult(result)
        }
        return false
    }
}

// MARK: - OpenAIStreamTransportError

/// Reports a non-SSE response using the error wording consumed by Easydict's classifier.
enum OpenAIStreamTransportError: LocalizedError, Equatable {
    case incorrectContentType(String, url: String?)

    // MARK: Internal

    var errorDescription: String? {
        switch self {
        case let .incorrectContentType(mimeType, url):
            var message =
                "Incorrect Content-Type: \(mimeType), acceptable type is text/event-stream."
            if let url {
                message += " This may be caused by a wrong endpoint: \(url)"
            }
            return message
        }
    }
}
