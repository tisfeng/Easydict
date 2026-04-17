//
//  ClaudeSSEParserTests.swift
//  EasydictTests
//
//  Created by tisfeng on 2026/4/8.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation
import Testing

@testable import Easydict

/// Unit tests for Claude SSE event normalization and parsing.
@Suite("Claude SSE Parser", .tags(.unit))
struct ClaudeSSEParserTests {
    // MARK: Internal

    /// Verifies that a single LF-delimited SSE event is extracted successfully.
    @Test("Extracts a single LF-delimited event")
    func extractsSingleLFEvent() {
        let buffer = contentDeltaEvent(text: "Hello", lineSeparator: "\n")

        let extracted = ClaudeSSEParser.extractCompleteEvents(from: buffer)

        #expect(extracted.events == [normalizedContentDeltaEvent(text: "Hello")])
        #expect(extracted.remainingBuffer.isEmpty)
    }

    /// Verifies that a single CRLF-delimited SSE event is normalized and extracted successfully.
    @Test("Extracts a single CRLF-delimited event")
    func extractsSingleCRLFEvent() {
        let buffer = contentDeltaEvent(text: "Hello", lineSeparator: "\r\n")

        let extracted = ClaudeSSEParser.extractCompleteEvents(from: buffer)

        #expect(extracted.events == [normalizedContentDeltaEvent(text: "Hello")])
        #expect(extracted.remainingBuffer.isEmpty)
    }

    /// Verifies that a chunk boundary between `\\r` and `\\n` does not split one event into two.
    @Test("Preserves a trailing carriage return across chunk boundaries")
    func preservesTrailingCarriageReturnAcrossChunks() {
        let firstChunk = "event: content_block_delta\r"
        let secondChunk = "\ndata: \(contentDeltaPayload(text: "Hello"))\r\n\r\n"

        let firstPass = ClaudeSSEParser.extractCompleteEvents(from: firstChunk)
        #expect(firstPass.events.isEmpty)
        #expect(firstPass.remainingBuffer == firstChunk)

        let secondPass = ClaudeSSEParser.extractCompleteEvents(from: firstPass.remainingBuffer + secondChunk)

        #expect(secondPass.events == [normalizedContentDeltaEvent(text: "Hello")])
        #expect(secondPass.remainingBuffer.isEmpty)
    }

    /// Verifies that multiple CRLF-delimited events in one buffer are all extracted.
    @Test("Extracts multiple CRLF-delimited events from one buffer")
    func extractsMultipleCRLFEvents() {
        let buffer = contentDeltaEvent(text: "Hello", lineSeparator: "\r\n")
            + contentDeltaEvent(text: "World", lineSeparator: "\r\n")

        let extracted = ClaudeSSEParser.extractCompleteEvents(from: buffer)

        #expect(
            extracted.events == [
                normalizedContentDeltaEvent(text: "Hello"),
                normalizedContentDeltaEvent(text: "World"),
            ]
        )
        #expect(extracted.remainingBuffer.isEmpty)
    }

    /// Verifies that an error event still throws a `QueryError` after CRLF normalization.
    @Test("Recognizes error events after CRLF normalization")
    func recognizesErrorEventsAfterNormalization() {
        let buffer = errorEvent(message: "Claude request failed", lineSeparator: "\r\n")
        let extracted = ClaudeSSEParser.extractCompleteEvents(from: buffer)

        #expect(extracted.events.count == 1)
        #expect(extracted.remainingBuffer.isEmpty)

        do {
            _ = try ClaudeSSEParser.parseEvent(extracted.events[0])
            Issue.record("Expected Claude SSE error event to throw QueryError.")
        } catch let error as QueryError {
            #expect(error.type == .api)
            #expect(error.errorDataMessage == "Claude request failed")
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    // MARK: Private

    /// Builds a content delta payload for a Claude SSE event.
    /// - Parameter text: The incremental text content.
    /// - Returns: A JSON payload string for `content_block_delta`.
    private func contentDeltaPayload(text: String) -> String {
        """
        {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"\(text)"}}
        """
    }

    /// Builds a single content delta SSE event with the requested line separator.
    /// - Parameters:
    ///   - text: The incremental text content.
    ///   - lineSeparator: The line separator used in the event.
    /// - Returns: A complete SSE event buffer terminated by a blank line.
    private func contentDeltaEvent(text: String, lineSeparator: String) -> String {
        "event: content_block_delta\(lineSeparator)data: \(contentDeltaPayload(text: text))\(lineSeparator)\(lineSeparator)"
    }

    /// Builds the normalized event string expected after CRLF conversion.
    /// - Parameter text: The incremental text content.
    /// - Returns: A normalized LF-delimited SSE event string.
    private func normalizedContentDeltaEvent(text: String) -> String {
        "event: content_block_delta\ndata: \(contentDeltaPayload(text: text))"
    }

    /// Builds a Claude SSE error event with the requested line separator.
    /// - Parameters:
    ///   - message: The error message from Anthropic.
    ///   - lineSeparator: The line separator used in the event.
    /// - Returns: A complete SSE error event buffer terminated by a blank line.
    private func errorEvent(message: String, lineSeparator: String) -> String {
        let payload = """
        {"type":"error","error":{"type":"invalid_request_error","message":"\(message)"}}
        """
        return "event: error\(lineSeparator)data: \(payload)\(lineSeparator)\(lineSeparator)"
    }
}
