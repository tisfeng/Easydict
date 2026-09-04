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
}
