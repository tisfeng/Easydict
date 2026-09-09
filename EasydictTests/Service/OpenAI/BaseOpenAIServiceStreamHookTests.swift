//
//  BaseOpenAIServiceStreamHookTests.swift
//  EasydictTests
//
//  Created by tisfeng on 2026/9/9.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation
import OpenAI
import Testing

@testable import Easydict

// MARK: - BaseOpenAIServiceStreamHookTests

/// Verifies that the shared stream runner delegates transport behavior through its hooks.
@Suite("Base OpenAI Stream Hooks", .tags(.unit))
struct BaseOpenAIServiceStreamHookTests {
    @Test("Maps transport chunks through the shared query and stream runner")
    func mapsTransportChunks() async throws {
        let service = RecordingOpenAIService()
        service.result = QueryResult()
        service.chatResults = [
            try ChatStreamResult.create(content: "first", model: "test-model"),
            try ChatStreamResult.create(content: "second", model: "test-model"),
        ]

        let stream = service.contentStreamTranslate(
            "Translate this",
            from: .english,
            to: .simplifiedChinese
        )
        var contents: [String] = []
        for try await content in stream {
            contents.append(content)
        }

        #expect(contents == ["first", "second"])
        #expect(service.didValidateRequest)
        #expect(service.lastQuery?.model == "test-model")
    }

    @Test("Routes transport errors through the specialized hook")
    func routesTransportErrorsThroughHook() async {
        let service = RecordingOpenAIService()
        service.result = QueryResult()
        service.streamError = RecordingOpenAIService.StreamError.expected

        do {
            for try await _ in service.contentStreamTranslate(
                "Translate this",
                from: .english,
                to: .simplifiedChinese
            ) {}
            Issue.record("Expected the recording transport to fail.")
        } catch {
            #expect(service.didHandleStreamError)
        }
    }

    @Test("Treats URLSession cancellation as a normal stream finish")
    func ignoresURLSessionCancellation() async throws {
        let service = RecordingOpenAIService()
        service.result = QueryResult()
        service.streamError = URLError(.cancelled)

        for try await _ in service.contentStreamTranslate(
            "Translate this",
            from: .english,
            to: .simplifiedChinese
        ) {}

        #expect(!service.didHandleStreamError)
    }

    @Test("Validation failure does not start the transport")
    func validationFailureSkipsTransport() async {
        let service = RecordingOpenAIService()
        service.result = QueryResult()
        service.validationError = QueryError(type: .parameter, message: "Invalid endpoint")

        do {
            for try await _ in service.contentStreamTranslate(
                "Translate this",
                from: .english,
                to: .simplifiedChinese
            ) {}
            Issue.record("Expected stream validation to fail.")
        } catch {
            #expect(!service.didStartTransport)
        }
    }
}

// MARK: - RecordingOpenAIService

/// Provides deterministic results for testing the BaseOpenAIService stream hooks.
private final class RecordingOpenAIService: OpenAIService {
    // MARK: Internal

    enum StreamError: Error {
        case expected
    }

    override var model: String {
        get { testModel }
        set { testModel = newValue }
    }

    var chatResults: [ChatStreamResult] = []
    var didHandleStreamError = false
    var didStartTransport = false
    var didValidateRequest = false
    var lastQuery: ChatQuery?
    var streamError: Error?
    var validationError: Error?

    override func validateChatStreamRequest() throws -> URL {
        didValidateRequest = true
        if let validationError {
            throw validationError
        }
        return try #require(URL(string: "https://example.com/v1/chat/completions"))
    }

    override func makeChatQuery(messages: [OpenAIChatMessage]) -> ChatQuery {
        let query = super.makeChatQuery(messages: messages)
        lastQuery = query
        return query
    }

    override func performChatResultStream(
        query _: ChatQuery,
        endpoint _: URL,
        onResult: @escaping @Sendable (ChatStreamResult) -> ()
    ) async throws {
        didStartTransport = true
        for result in chatResults {
            onResult(result)
        }
        if let streamError {
            throw streamError
        }
    }

    override func handleChatStreamError(_: Error) async {
        didHandleStreamError = true
    }

    // MARK: Private

    private var testModel = "test-model"
}
