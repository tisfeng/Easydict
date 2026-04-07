//
//  ClaudeSSEParser.swift
//  Easydict
//
//  Created by Codex on 2026/4/8.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation

/// Parser utilities for Claude SSE event normalization and payload extraction.
enum ClaudeSSEParser {
    /// Extracts complete Claude SSE events from a text buffer while preserving a trailing carriage return.
    ///
    /// SSE frames may use either LF or CRLF line endings. A trailing standalone `\r` cannot be normalized
    /// immediately because it may pair with the next chunk's leading `\n` to form a single CRLF sequence.
    ///
    /// - Parameter textBuffer: The accumulated text buffer from the SSE stream.
    /// - Returns: Complete normalized events and the remaining incomplete buffer.
    static func extractCompleteEvents(
        from textBuffer: String
    )
        -> (events: [String], remainingBuffer: String) {
        var normalizedBuffer = textBuffer
        let hasTrailingCarriageReturn = normalizedBuffer.last == "\r"

        if hasTrailingCarriageReturn {
            normalizedBuffer.removeLast()
        }

        normalizedBuffer = normalizedBuffer.replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")

        if hasTrailingCarriageReturn {
            normalizedBuffer.append("\r")
        }

        let eventSeparator = "\n\n"
        guard normalizedBuffer.contains(eventSeparator) else {
            return ([], normalizedBuffer)
        }

        let parts = normalizedBuffer.split(separator: eventSeparator, omittingEmptySubsequences: false)
        let events = parts.dropLast().filter { !$0.isEmpty }.map(String.init)
        let remainingBuffer = String(parts.last ?? "")

        return (events, remainingBuffer)
    }

    /// Parses a single Claude SSE event and extracts delta text content.
    ///
    /// - Parameters:
    ///   - event: A normalized SSE event string.
    ///   - jsonDecoder: The decoder used to parse SSE payloads.
    /// - Returns: The text delta for `content_block_delta` events, or `nil` for non-content events.
    /// - Throws: `QueryError` when the event represents an Anthropic stream error.
    static func parseEvent(_ event: String, jsonDecoder: JSONDecoder) throws -> String? {
        let eventPrefix = "event:"
        let dataPrefix = "data:"

        var eventType: String?
        var jsonDataString: String?

        for line in event.split(separator: "\n") {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedLine.starts(with: eventPrefix) {
                eventType = trimmedLine
                    .dropFirst(eventPrefix.count)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            } else if trimmedLine.starts(with: dataPrefix) {
                jsonDataString = trimmedLine
                    .dropFirst(dataPrefix.count)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        if eventType == "error",
           let dataString = jsonDataString,
           let data = dataString.data(using: .utf8),
           let streamError = try? jsonDecoder.decode(ClaudeStreamError.self, from: data) {
            throw QueryError(type: .api, errorDataMessage: streamError.error.message)
        }

        guard eventType == "content_block_delta",
              let dataString = jsonDataString,
              let data = dataString.data(using: .utf8)
        else {
            return nil
        }

        guard let streamDelta = try? jsonDecoder.decode(ClaudeStreamDelta.self, from: data) else {
            logError("Failed to decode Claude SSE data (\(data.count) bytes)")
            return nil
        }

        return streamDelta.delta?.text
    }
}
