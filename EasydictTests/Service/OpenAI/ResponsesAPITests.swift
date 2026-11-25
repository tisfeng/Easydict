//
//  ResponsesAPITests.swift
//  EasydictTests
//
//  Created by tisfeng on 2026/11/25.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation
import Testing

@testable import Easydict

/// Pure tests for the Responses API mapping, endpoint rewrite, and SSE classification.
@Suite("OpenAI Responses API", .tags(.unit))
struct ResponsesAPITests {
    // MARK: Internal

    @Test("Chat Completions leaves an existing chat endpoint unchanged")
    func chatEndpointStaysUnchanged() throws {
        let endpoint = try url("https://api.openai.com/v1/chat/completions")

        let adapted = OpenAIEndpointAdapter().requestURL(endpoint: endpoint, apiType: .chat)

        #expect(adapted == endpoint)
    }

    @Test("Chat Completions does not append a suffix to a bare or unrecognized URL")
    func chatEndpointPreservesBareAndUnrecognizedURLs() throws {
        let adapter = OpenAIEndpointAdapter()
        let bare = try url("https://opencode.ai/zen/go/v1")
        let unrecognized = try url("https://host/api/chat")

        #expect(adapter.requestURL(endpoint: bare, apiType: .chat) == bare)
        #expect(adapter.requestURL(endpoint: unrecognized, apiType: .responses) == unrecognized)
        #expect(adapter.requestURL(endpoint: unrecognized, apiType: .chat) == unrecognized)
    }

    @Test("Responses swaps a chat suffix and appends one to a bare versioned URL")
    func responsesAdaptsKnownSuffixesAndBareBaseURLs() throws {
        let adapter = OpenAIEndpointAdapter()

        let swapped = adapter.requestURL(
            endpoint: try url("https://api.openai.com/v1/chat/completions?api-version=2024-10-01"),
            apiType: .responses
        )
        #expect(swapped.absoluteString == "https://api.openai.com/v1/responses?api-version=2024-10-01")

        let appended = adapter.requestURL(
            endpoint: try url("https://opencode.ai/zen/go/v1"),
            apiType: .responses
        )
        #expect(appended.absoluteString == "https://opencode.ai/zen/go/v1/responses")

        let versioned = adapter.requestURL(
            endpoint: try url("http://localhost:11434/v1beta"),
            apiType: .responses
        )
        #expect(versioned.absoluteString == "http://localhost:11434/v1beta/responses")

        let origin = adapter.requestURL(endpoint: try url("https://api.openai.com"), apiType: .responses)
        #expect(origin.absoluteString == "https://api.openai.com/v1/responses")
    }

    @Test("Chat Completions restores a responses suffix")
    func chatRestoresResponsesSuffix() throws {
        let adapted = OpenAIEndpointAdapter().requestURL(
            endpoint: try url("https://opencode.ai/zen/go/v1/responses"),
            apiType: .chat
        )

        #expect(adapted.absoluteString == "https://opencode.ai/zen/go/v1/chat/completions")
    }

    @Test("Built-in OpenAI does not rewrite endpoints and custom OpenAI defaults to chat")
    func serviceGateKeepsBuiltInChatUnchanged() throws {
        let openAI = OpenAIService()
        let responsesURL = try url("https://api.openai.com/v1/responses")
        #expect(!openAI.supportsAPITypePicker)
        #expect(!openAI.usesResponsesAPI)
        #expect(openAI.resolvedRequestURL(from: responsesURL) == responsesURL)

        let custom = CustomOpenAIService()
        let chatURL = try url("https://example.com/v1/chat/completions")
        let unrecognized = try url("https://example.com/api/chat")
        #expect(custom.supportsAPITypePicker)
        #expect(custom.apiType == .chat)
        #expect(!custom.usesResponsesAPI)
        #expect(custom.resolvedRequestURL(from: chatURL) == chatURL)
        #expect(custom.resolvedRequestURL(from: unrecognized) == unrecognized)
    }

    @Test("Input mapping keeps system, user, and assistant roles and drops tool messages")
    func mapsInputRoles() {
        let messages = [
            ChatMessage(role: .system, content: "system"),
            ChatMessage(role: .user, content: "user"),
            ChatMessage(role: .assistant, content: "assistant"),
            ChatMessage(role: .model, content: "model"),
            ChatMessage(role: .tool, content: "tool"),
        ]

        let input = ResponsesInputMapper().inputItems(from: messages)

        #expect(
            input == [
                ResponsesInputItem(role: "system", content: "system"),
                ResponsesInputItem(role: "user", content: "user"),
                ResponsesInputItem(role: "assistant", content: "assistant"),
                ResponsesInputItem(role: "assistant", content: "model"),
            ]
        )
    }

    @Test("Responses request uses input and only disables storage on api.openai.com")
    func encodesResponsesRequest() throws {
        let transport = ResponsesAPITransport()
        let messages = [ChatMessage(role: .user, content: "Hello")]

        let gateway = try transport.makeRequest(
            messages: messages,
            model: "muse-spark",
            url: try url("https://opencode.ai/zen/go/v1/responses"),
            apiKey: "test-key",
            stream: true
        )
        let gatewayBody = try decodeBody(gateway)
        #expect(gatewayBody.model == "muse-spark")
        #expect(gatewayBody.stream)
        #expect(gatewayBody.store == nil)
        #expect(gatewayBody.input == [ResponsesInputItem(role: "user", content: "Hello")])
        #expect(gateway.value(forHTTPHeaderField: "Authorization") == "Bearer test-key")
        #expect(gateway.value(forHTTPHeaderField: "api-key") == "test-key")
        #expect(!String(decoding: gateway.httpBody ?? Data(), as: UTF8.self).contains("\"messages\""))

        let official = try transport.makeRequest(
            messages: messages,
            model: "gpt-5",
            url: try url("https://api.openai.com/v1/responses"),
            apiKey: "",
            stream: false
        )
        let officialBody = try decodeBody(official)
        #expect(officialBody.store == false)
        #expect(!officialBody.stream)
        #expect(official.value(forHTTPHeaderField: "Authorization") == nil)
    }

    @Test("Completed output joins message text and skips reasoning items")
    func aggregatesCompletedOutput() throws {
        let response = try decodeResponse(
            """
            {
              "status": "completed",
              "output": [
                {"type": "reasoning", "content": [{"type": "output_text", "text": "hidden"}]},
                {"type": "message", "content": [
                  {"type": "output_text", "text": "Hello"},
                  {"type": "output_text", "text": " world"}
                ]}
              ]
            }
            """
        )

        #expect(try response.requireOutputText() == "Hello world")
    }

    @Test("A missing status can use top-level output_text")
    func acceptsGatewayOutputText() throws {
        let response = try decodeResponse(#"{"output_text":"translated"}"#)

        #expect(try response.requireOutputText() == "translated")
    }

    @Test("Incomplete output is not returned as a successful translation")
    func rejectsIncompleteOutput() throws {
        let response = try decodeResponse(
            """
            {
              "status": "incomplete",
              "incomplete_details": {"reason": "max_output_tokens"},
              "output_text": "partial"
            }
            """
        )

        do {
            _ = try response.requireOutputText()
            Issue.record("Incomplete Responses output was treated as success")
        } catch let error as QueryError {
            #expect(error.type == .api)
            #expect(error.errorDataMessage == "max_output_tokens")
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test("Data-only SSE deltas are classified by the payload type")
    func classifiesDataOnlyDelta() {
        let event = ResponsesStreamClassifier().classify(
            eventName: "",
            payload: #"{"type":"response.output_text.delta","delta":"Hi"}"#
        )

        #expect(event == .delta("Hi"))
    }

    @Test("Terminal text is available when a gateway sends only response.completed")
    func classifiesCompletedText() {
        let event = ResponsesStreamClassifier().classify(
            eventName: "response.completed",
            payload: """
            {"type":"response.completed","response":{"status":"completed","output":[
              {"type":"message","content":[{"type":"output_text","text":"Done"}]}
            ]}}
            """
        )

        #expect(event == .terminalText("Done"))
    }

    @Test("Failed and incomplete stream events stay failures without an event line")
    func classifiesFailures() {
        let classifier = ResponsesStreamClassifier()
        let failed = classifier.classify(
            eventName: "",
            payload: #"{"type":"response.failed","response":{"error":{"message":"boom"}}}"#
        )
        let incomplete = classifier.classify(
            eventName: "",
            payload: #"{"type":"response.incomplete","response":{"incomplete_details":{"reason":"max_output_tokens"}}}"#
        )

        #expect(failed == .failure(message: "boom", details: #"{"type":"response.failed","response":{"error":{"message":"boom"}}}"#))
        #expect(
            incomplete == .failure(
                message: "Responses status incomplete: max_output_tokens",
                details: #"{"type":"response.incomplete","response":{"incomplete_details":{"reason":"max_output_tokens"}}}"#
            )
        )
        #expect(classifier.classify(eventName: "", payload: "[DONE]") == .ignored)
    }

    @Test("SSE buffering waits for a newline split inside a multibyte character")
    func buffersSplitUTF8() {
        var buffer = ResponsesSSEBuffer()
        let encoded = Data("你\n".utf8)

        let first = buffer.append(Data([encoded[0]]))
        let second = buffer.append(encoded.dropFirst())

        #expect(first.isEmpty)
        #expect(second == ["你"])
    }

    // MARK: Private

    private struct RequestBody: Decodable {
        let model: String
        let input: [ResponsesInputItem]
        let stream: Bool
        let store: Bool?
    }

    private func url(_ string: String) throws -> URL {
        try #require(URL(string: string))
    }

    private func decodeBody(_ request: URLRequest) throws -> RequestBody {
        try JSONDecoder().decode(RequestBody.self, from: #require(request.httpBody))
    }

    private func decodeResponse(_ json: String) throws -> ResponsesResponse {
        try JSONDecoder().decode(ResponsesResponse.self, from: Data(json.utf8))
    }
}
