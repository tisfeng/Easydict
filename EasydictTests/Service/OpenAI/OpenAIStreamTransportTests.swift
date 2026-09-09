//
//  OpenAIStreamTransportTests.swift
//  EasydictTests
//
//  Created by tisfeng on 2026/9/8.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation
import OpenAI
import Testing

@testable import Easydict

// MARK: - OpenAIStreamTransportTests

/// Tests Easydict's request and response compatibility around the upstream SDK models.
@Suite("OpenAI Stream Transport", .serialized, .tags(.unit))
struct OpenAIStreamTransportTests {
    // MARK: Internal

    @Test("Build stream request with exact endpoint and compatible authorization headers")
    func buildStreamRequest() throws {
        let endpoint = try #require(URL(string: "https://example.com/custom/chat?api-version=1"))
        let request = try OpenAIStreamTransport().makeRequest(
            query: try chatQuery(),
            url: endpoint,
            apiKey: "test-key"
        )

        #expect(request.url == endpoint)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer test-key")
        #expect(request.value(forHTTPHeaderField: "api-key") == "test-key")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")

        let body = try #require(request.httpBody)
        let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
        #expect(json["stream"] as? Bool == true)
        #expect(json["reasoning_effort"] == nil)
    }

    @Test("Omit authorization headers for keyless compatible services")
    func buildKeylessStreamRequest() throws {
        let endpoint = try #require(URL(string: "http://localhost:11434/v1/chat/completions"))
        let request = try OpenAIStreamTransport().makeRequest(
            query: try chatQuery(),
            url: endpoint,
            apiKey: ""
        )

        #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
        #expect(request.value(forHTTPHeaderField: "api-key") == nil)
    }

    @Test("Reject non-SSE response content type")
    func rejectIncorrectContentType() throws {
        let url = try #require(URL(string: "https://example.com/v1/chat/completions"))
        let response = try #require(
            HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )
        )

        #expect(throws: OpenAIStreamTransportError.self) {
            try OpenAIStreamTransport().validate(response: response)
        }
    }

    @Test("Decode separately framed SSE chunks and stop at done marker")
    func decodeFramedStream() async throws {
        let firstChunk = streamChunk(content: "first")
        let secondChunk = streamChunk(content: "second")
        URLProtocolStub.setResponse(
            statusCode: 200,
            contentType: "text/event-stream",
            body: "data: \(firstChunk)\r\n\r\ndata: \(secondChunk)\n\ndata: [DONE]\n\n"
        )
        defer { URLProtocolStub.reset() }

        let recorder = StreamContentRecorder()
        try await OpenAIStreamTransport(session: stubbedSession()).stream(
            query: try chatQuery(),
            url: try #require(URL(string: "https://example.com/v1/chat/completions")),
            apiKey: "test-key"
        ) { result in
            recorder.append(result.choices.first?.delta.content)
        }

        #expect(recorder.values == ["first", "second"])
    }

    @Test("Preserve API error details from non-success response body")
    func preserveAPIErrorResponse() async throws {
        URLProtocolStub.setResponse(
            statusCode: 429,
            contentType: "application/json",
            body: #"{"error":{"message":"quota exhausted","type":"rate_limit_error"}}"#
        )
        defer { URLProtocolStub.reset() }

        do {
            try await OpenAIStreamTransport(session: stubbedSession()).stream(
                query: try chatQuery(),
                url: try #require(URL(string: "https://example.com/v1/chat/completions")),
                apiKey: "test-key"
            ) { _ in }
            Issue.record("Expected APIErrorResponse")
        } catch let error as APIErrorResponse {
            #expect(error.error.message == "quota exhausted")
            #expect(error.error.type == "rate_limit_error")
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    // MARK: Private

    private func chatQuery() throws -> ChatQuery {
        let message = try #require(
            ChatQuery.ChatCompletionMessageParam(role: .user, content: "hello")
        )
        return ChatQuery(messages: [message], model: "test-model", temperature: 0.3)
    }

    private func streamChunk(content: String) -> String {
        """
        {"id":"chatcmpl-test","object":"chat.completion.chunk","created":1,"model":"test-model","choices":[{"index":0,"delta":{"content":"\(
            content
        )"}}]}
        """
    }

    private func stubbedSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        return URLSession(configuration: configuration)
    }
}

// MARK: - StreamContentRecorder

private final class StreamContentRecorder: @unchecked Sendable {
    // MARK: Internal

    var values: [String] {
        lock.lock()
        defer { lock.unlock() }
        return storage
    }

    func append(_ value: String?) {
        guard let value else { return }
        lock.lock()
        storage.append(value)
        lock.unlock()
    }

    // MARK: Private

    private let lock = NSLock()
    private var storage: [String] = []
}

// MARK: - URLProtocolStub

private final class URLProtocolStub: URLProtocol, @unchecked Sendable {
    // MARK: Internal

    override static func canInit(with _: URLRequest) -> Bool { true }

    override static func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let response = Self.lockedResponse()
        client?.urlProtocol(self, didReceive: response.http, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: response.body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

    static func setResponse(statusCode: Int, contentType: String, body: String) {
        let url = URL(string: "https://example.com/v1/chat/completions")!
        let http = HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: ["Content-Type": contentType]
        )!
        lock.lock()
        response = (http, Data(body.utf8))
        lock.unlock()
    }

    static func reset() {
        lock.lock()
        response = nil
        lock.unlock()
    }

    // MARK: Private

    private static let lock = NSLock()
    private nonisolated(unsafe) static var response: (http: HTTPURLResponse, body: Data)?

    private static func lockedResponse() -> (http: HTTPURLResponse, body: Data) {
        lock.lock()
        defer { lock.unlock() }
        return response!
    }
}
