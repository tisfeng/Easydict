//
//  ServiceTests.swift
//  EasydictTests
//
//  Created by tisfeng on 2025/12/20.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation
import OpenAI
import Testing

@testable import Easydict

// MARK: - ServiceTests

/// Integration tests that verify each registered service can translate a sample input.
@Suite("Service Translation Validation", .tags(.integration))
struct ServiceTests {
    // MARK: Internal

    /// Validates that every registered service returns a successful translation result.
    @Test("Validate All Services Translation", .tags(.integration))
    func testAllServicesValidateTranslation() async throws {
        let factory = QueryServiceFactory.shared
        let serviceTypes = factory.allServiceTypes

        #expect(!serviceTypes.isEmpty, "QueryServiceFactory returned no registered services.")

        for serviceType in serviceTypes {
            try await validate(serviceType: serviceType, factory: factory)
        }
    }

    // MARK: Private

    /// Validates a single service type and records a failure if translation fails.
    private func validate(serviceType: ServiceType, factory: QueryServiceFactory) async throws {
        let service = try #require(factory.service(withTypeId: serviceType.rawValue))

        let result = await validationResult(for: service)
        #expect(
            result.error == nil,
            "Service [\(serviceType.rawValue)] failed validation: \(result.error?.localizedDescription ?? "unknown error")"
        )
    }

    /// Returns the validation result for a service, using dictionary-friendly input when needed.
    private func validationResult(for service: QueryService) async -> QueryResult {
        if service is AppleDictionary {
            return await validateTranslation(
                service,
                text: "good",
                from: .english,
                to: .english
            )
        }

        return await service.validate()
    }

    /// Runs a translation request and returns the final query result.
    private func validateTranslation(
        _ service: QueryService,
        text: String,
        from: Language,
        to: Language
    ) async
        -> QueryResult {
        let currentResult = service.resetServiceResult()

        do {
            return try await service.translate(text, from: from, to: to)
        } catch {
            let result = service.result ?? currentResult
            if result.error == nil {
                result.error = QueryError.queryError(from: error)
            }
            return result
        }
    }
}

// MARK: - OpenAIStreamResultTests

/// Tests compatibility helpers for the upstream OpenAI SDK response models.
@Suite("OpenAI Stream Result", .tags(.unit))
struct OpenAIStreamResultTests {
    @Test("Create text-only chat completion chunk")
    func createTextOnlyChunk() throws {
        let result = try ChatStreamResult.create(content: "translated text", model: "test-model")

        #expect(result.id.hasPrefix("chatcmpl-"))
        #expect(result.object == "chat.completion.chunk")
        #expect(result.created == result.created.rounded(.towardZero))
        #expect(result.model == "test-model")
        #expect(result.choices.count == 1)
        #expect(result.choices[0].index == 0)
        #expect(result.content == "translated text")
    }
}

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

// MARK: - OpenAIReasoningEffortTests

/// Tests the default and subclass-overridable reasoning mode used by OpenAI-compatible services.
@Suite("OpenAI Reasoning Effort", .tags(.unit))
struct OpenAIReasoningEffortTests {
    // MARK: Internal

    @Test("Default stream service sends reasoning effort none")
    func defaultReasoningEffort() throws {
        let service = OpenAIService()
        let body = try encodedQueryBody(service: service)

        #expect(body["reasoning_effort"] as? String == "none")
    }

    @Test("Subclass can override the default reasoning effort")
    func overriddenReasoningEffort() throws {
        let service = HighReasoningOpenAIService()
        let body = try encodedQueryBody(service: service)

        #expect(body["reasoning_effort"] as? String == "high")
    }

    // MARK: Private

    private func encodedQueryBody(service: BaseOpenAIService) throws -> [String: Any] {
        let message = try #require(
            ChatQuery.ChatCompletionMessageParam(role: .user, content: "hello")
        )
        let query = service.openAIChatQuery(messages: [message])
        let data = try JSONEncoder().encode(query)
        return try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }
}

// MARK: - HighReasoningOpenAIService

private final class HighReasoningOpenAIService: OpenAIService {
    override var reasoningEffort: ChatQuery.ReasoningEffort {
        .high
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
