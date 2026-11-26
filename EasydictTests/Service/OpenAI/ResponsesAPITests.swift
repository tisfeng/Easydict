//
//  ResponsesAPITests.swift
//  EasydictTests
//
//  Created by tisfeng on 2026/11/25.
//  Copyright © 2026 izual. All rights reserved.
//

import Defaults
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

        // A fresh UUID reads a missing key. The default instance key
        // EZCustomOpenAIAPITypeKey can already be set to Responses on a developer machine.
        let custom = CustomOpenAIService()
        custom.uuid = UUID().uuidString
        let apiTypeKey = custom.apiTypeKey
        defer { Defaults.reset(apiTypeKey) }
        let chatURL = try url("https://example.com/v1/chat/completions")
        let unrecognized = try url("https://example.com/api/chat")
        #expect(apiTypeKey.name != "EZCustomOpenAIAPITypeKey")
        #expect(UserDefaults.standard.object(forKey: apiTypeKey.name) == nil)
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

        #expect(event == .delta("Hi", part: ResponsesOutputPartKey()))
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

        #expect(event == .completedText("Done"))
    }

    @Test("output_text.done keeps the output and content index of that part")
    func classifiesIndexedTerminalPart() {
        let event = ResponsesStreamClassifier().classify(
            eventName: "",
            payload: #"{"type":"response.output_text.done","output_index":1,"content_index":0,"item_id":"msg_1","text":" second"}"#
        )

        #expect(
            event == .terminalPart(
                " second",
                part: ResponsesOutputPartKey(outputIndex: 1, contentIndex: 0, itemID: "msg_1")
            )
        )
    }

    @Test("Terminal-only output parts are all kept and the completed aggregate is not repeated")
    func preservesEveryTerminalOnlyPart() {
        let texts = reducedTexts([
            donePart("First", output: 0, content: 0),
            donePart(" second", output: 1, content: 0),
            completed("First second"),
        ])

        #expect(texts == ["First", " second"])
    }

    @Test("A done event does not repeat a part that was already streamed by deltas")
    func skipsTerminalTextAlreadyStreamedByDeltas() {
        let part = ResponsesOutputPartKey(outputIndex: 0, contentIndex: 0)
        let texts = reducedTexts([
            .delta("Hel", part: part),
            .delta("lo", part: part),
            .terminalPart("Hello", part: part),
            .completedText("Hello"),
        ])

        #expect(texts == ["Hel", "lo"])
    }

    @Test("A completed payload is still used when the stream never sent deltas or done parts")
    func usesCompletedTextWhenNothingElseArrived() {
        let texts = reducedTexts([.completedText("Done")])

        #expect(texts == ["Done"])
    }

    @Test("Deltas for one part and a terminal-only later part are both kept")
    func keepsTerminalPartThatWasNotStreamed() {
        let streamed = ResponsesOutputPartKey(outputIndex: 0, contentIndex: 0)
        let terminalOnly = ResponsesOutputPartKey(outputIndex: 1, contentIndex: 0)
        let texts = reducedTexts([
            .delta("Hello", part: streamed),
            .terminalPart("Hello", part: streamed),
            .terminalPart(" world", part: terminalOnly),
            .completedText("Hello world"),
        ])

        #expect(texts == ["Hello", " world"])
    }

    @Test("Index-less done events stay separate parts and do not repeat streamed deltas")
    func preservesAnonymousTerminalPartsWithoutDuplicatingDeltas() {
        let anonymous = ResponsesOutputPartKey()
        let terminalOnly = reducedTexts([
            .terminalPart("First", part: anonymous),
            .terminalPart(" second", part: anonymous),
            .completedText("First second"),
        ])
        let streamed = reducedTexts([
            .delta("Hel", part: anonymous),
            .delta("lo", part: anonymous),
            .terminalPart("Hello", part: anonymous),
        ])

        #expect(terminalOnly == ["First", " second"])
        #expect(streamed == ["Hel", "lo"])
    }

    @Test("Item ids keep distinct terminal messages and skip a done that repeats streamed text")
    func tracksTerminalPartsByItemID() {
        let first = ResponsesOutputPartKey(itemID: "msg_1")
        let second = ResponsesOutputPartKey(itemID: "msg_2")
        let texts = reducedTexts([
            .delta("Hel", part: first),
            .delta("lo", part: first),
            .terminalPart("Hello", part: first),
            .terminalPart("!", part: second),
        ])

        #expect(texts == ["Hel", "lo", "!"])
    }

    @Test("Two content parts of one item are both kept")
    func keepsDistinctContentPartsOfTheSameItem() {
        let first = ResponsesOutputPartKey(outputIndex: 0, contentIndex: 0, itemID: "msg_1")
        let second = ResponsesOutputPartKey(outputIndex: 0, contentIndex: 1, itemID: "msg_1")
        let texts = reducedTexts([
            .terminalPart("First", part: first),
            .terminalPart(" second", part: second),
        ])

        #expect(texts == ["First", " second"])
    }

    @Test("An item-level done does not repeat deltas already streamed for that item")
    func skipsItemLevelDoneAfterIndexedDeltas() {
        let streamed = ResponsesOutputPartKey(outputIndex: 0, contentIndex: 0, itemID: "msg_1")
        let repeated = ResponsesOutputPartKey(itemID: "msg_1")
        let texts = reducedTexts([
            .delta("Hello", part: streamed),
            .terminalPart("Hello", part: repeated),
        ])

        #expect(texts == ["Hello"])
    }

    @Test("The same indexed done part is emitted once")
    func skipsDuplicateIndexedTerminalPart() {
        let part = ResponsesOutputPartKey(outputIndex: 0, contentIndex: 0)
        let texts = reducedTexts([
            .terminalPart("First", part: part),
            .terminalPart("First", part: part),
        ])

        #expect(texts == ["First"])
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

    @Test("SSE joins data lines of one event and still keeps the following event")
    func joinsDataLinesBeforeDecoding() {
        let texts = streamTexts([
            "event: response.output_text.delta",
            #"data: {"type":"response.output_text.delta","#,
            #"data: "delta":"Hi"}"#,
            "",
            #"data: {"type":"response.output_text.delta","delta":"!"}"#,
            "",
        ])

        #expect(texts == ["Hi", "!"])
    }

    @Test("A split terminal part and a later single-line part are both kept")
    func joinsSplitTerminalPartWithoutDroppingTheNextEvent() {
        let texts = streamTexts([
            #"data: {"type":"response.output_text.done","output_index":0,"#,
            #"data: "content_index":0,"text":"First"}"#,
            "",
            #"data: {"type":"response.output_text.done","output_index":1,"content_index":0,"text":" second"}"#,
            "",
            #"data: {"type":"response.completed","response":{"output_text":"First second"}}"#,
            "",
        ])

        #expect(texts == ["First", " second"])
    }

    @Test("CRLF events and comment or id lines decode at the blank line")
    func decodesCRLFEventsAndIgnoresNonDataFields() {
        let texts = streamTexts(
            [
                "event: response.output_text.delta",
                ": keep-alive",
                "id: 7",
                #"data: {"delta":"Hi"}"#,
                "",
            ],
            separator: "\r\n"
        )

        #expect(texts == ["Hi"])
    }

    @Test("The event name survives until the blank line when JSON omits type")
    func usesEventNameForJSONSplitAcrossDataLines() {
        let texts = streamTexts([
            "event: response.output_text.delta",
            #"data: {"delta":"#,
            #"data: "Hi"}"#,
            "",
        ])

        #expect(texts == ["Hi"])
    }

    @Test("A trailing SSE event without a blank line is still decoded")
    func finishesTrailingEventWithoutBlankLine() {
        var decoder = ResponsesSSEDecoder()
        let chunk = Data("data: {\"type\":\"response.output_text.delta\",\"delta\":\"Hi\"}\n".utf8)

        #expect(decoder.consume(chunk).isEmpty)
        #expect(decoder.finish() == [.delta("Hi", part: ResponsesOutputPartKey())])
    }

    @Test("Data lines split across chunks stay one event until the blank line")
    func waitsForEventBoundaryAcrossChunks() {
        var decoder = ResponsesSSEDecoder()
        let first = Data("data: {\"type\":\"response.output_text.delta\",\n".utf8)
        let second = Data("data: \"delta\":\"Hi\"}\n\n".utf8)

        #expect(decoder.consume(first).isEmpty)
        #expect(decoder.consume(second) == [.delta("Hi", part: ResponsesOutputPartKey())])
    }

    @Test("A failure payload split across data lines stays one failure")
    func joinsSplitFailurePayload() {
        let events = classifications([
            #"data: {"type":"response.failed","response":"#,
            #"data: {"error":{"message":"boom"}}}"#,
            "",
        ])
        let details = """
        {"type":"response.failed","response":
        {"error":{"message":"boom"}}}
        """

        #expect(events == [.failure(message: "boom", details: details)])
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

    private func donePart(_ text: String, output: Int, content: Int) -> ResponsesStreamClassification {
        .terminalPart(text, part: ResponsesOutputPartKey(outputIndex: output, contentIndex: content))
    }

    private func completed(_ text: String) -> ResponsesStreamClassification {
        .completedText(text)
    }

    private func reducedTexts(_ classifications: [ResponsesStreamClassification]) -> [String] {
        var reducer = ResponsesStreamTextReducer()
        return classifications.flatMap { reducer.texts(from: $0) }
    }

    /// Joins SSE lines and keeps a trailing blank line when `lines` ends with `""`.
    private func sseLines(_ lines: [String], separator: String = "\n") -> String {
        lines.joined(separator: separator) + separator
    }

    private func classifications(_ lines: [String], separator: String = "\n") -> [ResponsesStreamClassification] {
        var decoder = ResponsesSSEDecoder()
        let data = Data(sseLines(lines, separator: separator).utf8)
        return decoder.consume(data) + decoder.finish()
    }

    private func streamTexts(_ lines: [String], separator: String = "\n") -> [String] {
        var reducer = ResponsesStreamTextReducer()
        return classifications(lines, separator: separator).flatMap { reducer.texts(from: $0) }
    }
}
