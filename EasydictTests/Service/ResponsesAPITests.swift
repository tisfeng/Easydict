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

    @Test("Keeps endpoint unchanged when suffix already matches")
    func keepsMatchingEndpoint() {
        let chat = URL(string: "https://api.example.com/v1/chat/completions")!
        let responses = URL(string: "https://api.example.com/v1/responses")!

        #expect(normalizedRequestURL(endpoint: chat, apiType: .chat) == chat)
        #expect(normalizedRequestURL(endpoint: responses, apiType: .responses) == responses)
    }

    @Test("Appends wire format suffix to bare base URLs")
    func appendsSuffixToBareBaseURL() {
        let bare = URL(string: "https://opencode.ai/zen/go/v1")!

        #expect(
            normalizedRequestURL(endpoint: bare, apiType: .responses)
                == URL(string: "https://opencode.ai/zen/go/v1/responses")
        )
        #expect(
            normalizedRequestURL(endpoint: bare, apiType: .chat)
                == URL(string: "https://opencode.ai/zen/go/v1/chat/completions")
        )
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

    // MARK: - SSE Buffer

    @Test("SSE buffer reassembles lines split across chunks")
    func sseBufferReassemblesSplitLines() {
        var buffer = ResponsesSSEBuffer()
        #expect(buffer.append(Data("data: {\"a\"".utf8)) == [])
        #expect(buffer.append(Data(":1}\n".utf8)) == ["data: {\"a\":1}"])
    }

    @Test("SSE buffer returns multiple lines and strips CRLF")
    func sseBufferHandlesMultipleLinesAndCRLF() {
        var buffer = ResponsesSSEBuffer()
        #expect(buffer.append(Data("event: x\r\ndata: y\n".utf8)) == ["event: x", "data: y"])
    }

    @Test("SSE buffer keeps a trailing partial line pending")
    func sseBufferKeepsPartialLinePending() {
        var buffer = ResponsesSSEBuffer()
        #expect(buffer.append(Data("data: [DO".utf8)) == [])
        #expect(buffer.append(Data("NE]\n".utf8)) == ["data: [DONE]"])
    }

    @Test("SSE buffer reassembles multi-byte characters split across chunks")
    func sseBufferReassemblesSplitMultiByteCharacters() {
        let bytes = Data("data: 你好\n".utf8)
        var buffer = ResponsesSSEBuffer()
        #expect(buffer.append(bytes.prefix(8)) == [])
        #expect(buffer.append(bytes.suffix(bytes.count - 8)) == ["data: 你好"])
    }

    // MARK: - Custom Headers

    @Test("Parses custom headers from multi-line text")
    func parsesCustomHeaders() {
        let headers = parseCustomHeaders("""
        x-opencode-session: easydict-test
        A-Debug: 1
        """)
        #expect(headers.count == 2)
        #expect(headers["x-opencode-session"] == "easydict-test")
        #expect(headers["a-debug"] == "1")
    }

    @Test("Skips malformed and empty custom header lines")
    func skipsMalformedCustomHeaderLines() {
        let headers = parseCustomHeaders("""
        no-colon-line

        Empty-Value:
        :No-Name
        Valid: yes
        """)
        #expect(headers.count == 1)
        #expect(headers["valid"] == "yes")
    }

    // MARK: - Cancellation

    @Test("cancelStream cancels the in-flight stream task control")
    func cancelStreamCancelsStreamingTaskSlot() {
        let service = CustomOpenAIService()
        let identifier = UUID()
        service.streamTaskControl.begin(identifier: identifier)

        let task = Task<(), Never> {
            _ = try? await Task.sleep(for: .seconds(5))
        }

        service.streamTaskControl.install(task, identifier: identifier)
        service.cancelStream()

        #expect(task.isCancelled)
    }

    @Test("Beginning a replacement stream cancels the previous task")
    func beginningReplacementStreamCancelsPreviousTask() {
        let service = CustomOpenAIService()
        let firstIdentifier = UUID()
        service.streamTaskControl.begin(identifier: firstIdentifier)

        let firstTask = Task<(), Never> {
            _ = try? await Task.sleep(for: .seconds(5))
        }
        service.streamTaskControl.install(firstTask, identifier: firstIdentifier)

        let secondIdentifier = UUID()
        service.streamTaskControl.begin(identifier: secondIdentifier)
        defer { service.cancelStream() }

        #expect(firstTask.isCancelled)
    }
}
