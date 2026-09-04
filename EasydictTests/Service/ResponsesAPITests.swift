//
//  ResponsesAPITests.swift
//  EasydictTests
//

import Foundation
import Testing

@testable import Easydict

/// Unit tests for the Responses wire format helpers.
@Suite("Responses API", .tags(.unit))
struct ResponsesAPITests {
    // MARK: - Input Mapping

    @Test("Maps chat roles to Responses input items and drops tool")
    func mapsRoles() {
        let messages: [ChatMessage] = [
            .init(role: .system, content: "sys"),
            .init(role: .user, content: "hello"),
            .init(role: .model, content: "hi"),
            .init(role: .assistant, content: "hey"),
            .init(role: .tool, content: "ignored"),
        ]

        let items = responsesInputItems(from: messages)

        #expect(items.map(\.role) == ["system", "user", "assistant", "assistant"])
        #expect(items.map(\.content) == ["sys", "hello", "hi", "hey"])
    }

    // MARK: - outputText

    @Test("outputText filters message items by type and joins parts")
    func outputTextJoinsMessageParts() throws {
        let json = """
        {
          "status": "completed",
          "output": [
            { "type": "reasoning", "summary": [] },
            { "type": "message", "content": [
              { "type": "output_text", "text": "你好" },
              { "type": "output_text", "text": "世界" }
            ]}
          ]
        }
        """
        let response = try JSONDecoder().decode(ResponsesResponse.self, from: Data(json.utf8))

        #expect(response.outputText == "你好世界")
    }

    @Test("outputText returns nil for empty or missing output")
    func outputTextEmptyIsNil() throws {
        let empty = """
        { "status": "completed", "output": [
          { "type": "reasoning" },
          { "type": "message", "content": [{ "type": "output_text", "text": "" }] }
        ]}
        """
        let missing = """
        { "status": "completed" }
        """
        let emptyResponse = try JSONDecoder().decode(ResponsesResponse.self, from: Data(empty.utf8))
        let missingResponse = try JSONDecoder().decode(ResponsesResponse.self, from: Data(missing.utf8))

        #expect(emptyResponse.outputText == nil)
        #expect(missingResponse.outputText == nil)
    }

    // MARK: - Endpoint Normalization

    @Test("Swaps endpoint suffix per API type")
    func swapsEndpointSuffix() {
        let chat = URL(string: "https://api.example.com/v1/chat/completions")!
        let responses = URL(string: "https://api.example.com/v1/responses")!

        #expect(
            normalizedRequestURL(endpoint: chat, apiType: .responses)
                == URL(string: "https://api.example.com/v1/responses")
        )
        #expect(
            normalizedRequestURL(endpoint: responses, apiType: .chat)
                == URL(string: "https://api.example.com/v1/chat/completions")
        )
    }

    @Test("Keeps endpoint unchanged when suffix already matches or is unknown")
    func keepsUnrecognizedEndpoint() {
        let chat = URL(string: "https://api.example.com/v1/chat/completions")!
        let responses = URL(string: "https://api.example.com/v1/responses")!
        let bare = URL(string: "https://api.example.com/v1")!

        #expect(normalizedRequestURL(endpoint: chat, apiType: .chat) == chat)
        #expect(normalizedRequestURL(endpoint: responses, apiType: .responses) == responses)
        #expect(normalizedRequestURL(endpoint: bare, apiType: .responses) == bare)
        #expect(normalizedRequestURL(endpoint: bare, apiType: .chat) == bare)
    }

    @Test("Normalizes bare completions suffix")
    func normalizesBareCompletions() {
        let completions = URL(string: "https://api.example.com/v1/completions")!

        #expect(
            normalizedRequestURL(endpoint: completions, apiType: .responses)
                == URL(string: "https://api.example.com/v1/responses")
        )
    }

    // MARK: - Stream Events

    @Test("Classifies delta events with and without event line")
    func classifiesDeltaEvents() {
        let payload = #"{"type":"response.output_text.delta","delta":"你好"}"#

        if case let .delta(text) = responsesStreamEvent(
            eventName: "response.output_text.delta", payload: payload
        ) {
            #expect(text == "你好")
        } else {
            Issue.record("expected delta")
        }

        // Data-only stream: no `event:` line, eventName empty.
        if case let .delta(text) = responsesStreamEvent(eventName: "", payload: payload) {
            #expect(text == "你好")
        } else {
            Issue.record("expected delta from decoded type")
        }
    }

    @Test("Classifies failure events")
    func classifiesFailureEvents() {
        if case .failure = responsesStreamEvent(
            eventName: "", payload: #"{"type":"response.failed","error":{"message":"boom"}}"#
        ) {
            // expected
        } else {
            Issue.record("expected failure")
        }

        if case .failure = responsesStreamEvent(
            eventName: "error", payload: "plain error body"
        ) {
            // expected
        } else {
            Issue.record("expected failure by event name")
        }
    }

    @Test("Ignores lifecycle events and DONE sentinel")
    func ignoresLifecycleEvents() {
        if case .ignored = responsesStreamEvent(
            eventName: "response.created",
            payload: #"{"type":"response.created"}"#
        ) {
            // expected
        } else {
            Issue.record("expected ignored")
        }

        if case .ignored = responsesStreamEvent(eventName: "", payload: "[DONE]") {
            // expected
        } else {
            Issue.record("expected ignored")
        }
    }
}
