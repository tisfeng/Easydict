//
//  ResponsesStreamParsing.swift
//  Easydict
//
//  Created by tisfeng on 2026/11/26.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation

// MARK: - ResponsesAPIErrorBody

struct ResponsesAPIErrorBody: Decodable, Equatable, Sendable {
    let message: String?
}

// MARK: - ResponsesIncompleteDetails

struct ResponsesIncompleteDetails: Decodable, Equatable, Sendable {
    let reason: String?
}

// MARK: - ResponsesOutputContent

struct ResponsesOutputContent: Decodable, Equatable, Sendable {
    let type: String?
    let text: String?
}

// MARK: - ResponsesOutputItem

struct ResponsesOutputItem: Decodable, Equatable, Sendable {
    let type: String?
    let content: [ResponsesOutputContent]?
}

// MARK: - ResponsesResponse

struct ResponsesResponse: Decodable, Equatable, Sendable {
    // MARK: Internal

    let status: String?
    let output: [ResponsesOutputItem]?
    let error: ResponsesAPIErrorBody?
    let incompleteDetails: ResponsesIncompleteDetails?
    let outputTextField: String?

    enum CodingKeys: String, CodingKey {
        case status
        case output
        case error
        case incompleteDetails = "incomplete_details"
        case outputTextField = "output_text"
    }

    /// Text from completed message items, or the top-level `output_text` when a gateway only sends that field.
    var aggregatedOutputText: String? {
        var texts: [String] = []
        for item in output ?? [] where item.type == "message" {
            for content in item.content ?? [] where content.type == "output_text" {
                if let text = content.text, !text.isEmpty {
                    texts.append(text)
                }
            }
        }
        let joined = texts.joined()
        if !joined.isEmpty {
            return joined
        }
        if let outputTextField, !outputTextField.isEmpty {
            return outputTextField
        }
        return nil
    }
}

// MARK: - ResponsesOutputPartKey

/// Identifies one Responses output content part inside a streamed response.
struct ResponsesOutputPartKey: Hashable, Equatable, Sendable {
    var outputIndex: Int?
    var contentIndex: Int?
    var itemID: String?

    /// Identity used to tell a repeated full-text event from a different part.
    ///
    /// Indices win when either is present, so a done event matches deltas that
    /// carry the same indices even if only one of them includes `item_id`.
    /// Otherwise `item_id` distinguishes messages. A payload with neither is anonymous.
    var identity: Identity {
        if outputIndex != nil || contentIndex != nil {
            return .indexed(outputIndex: outputIndex, contentIndex: contentIndex)
        }
        if let itemID = normalizedItemID {
            return .item(itemID)
        }
        return .anonymous
    }

    var normalizedItemID: String? {
        guard let itemID, !itemID.isEmpty else {
            return nil
        }
        return itemID
    }

    enum Identity: Hashable, Equatable, Sendable {
        case indexed(outputIndex: Int?, contentIndex: Int?)
        case item(String)
        case anonymous
    }
}

// MARK: - ResponsesStreamClassification

enum ResponsesStreamClassification: Equatable {
    case delta(String, part: ResponsesOutputPartKey)
    case terminalPart(String, part: ResponsesOutputPartKey)
    case completedText(String)
    case failure(message: String, details: String)
    case ignored
}

// MARK: - ResponsesStreamClassifier

/// Classifies one Responses SSE payload.
///
/// The JSON `type` decides the event. Gateways that remove the `event:` line still work,
/// and an `event:` name is only a fallback when the payload has no type.
struct ResponsesStreamClassifier {
    // MARK: Internal

    func classify(eventName: String, payload: String) -> ResponsesStreamClassification {
        let trimmedPayload = payload.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPayload.isEmpty, trimmedPayload != "[DONE]" else {
            return .ignored
        }

        guard let data = trimmedPayload.data(using: .utf8),
              let decoded = try? JSONDecoder().decode(ResponsesStreamPayload.self, from: data)
        else {
            return .ignored
        }

        let type = decoded.type ?? eventName
        if type == "response.output_text.delta", let delta = decoded.delta, !delta.isEmpty {
            return .delta(delta, part: decoded.partKey)
        }
        if type == "response.output_text.done", let text = decoded.text, !text.isEmpty {
            return .terminalPart(text, part: decoded.partKey)
        }
        if type == "response.completed", let text = decoded.response?.aggregatedOutputText {
            return .completedText(text)
        }
        if isFailure(type) {
            return .failure(
                message: failureMessage(type: type, payload: decoded),
                details: trimmedPayload
            )
        }
        return .ignored
    }

    // MARK: Private

    private func isFailure(_ type: String) -> Bool {
        type == "response.failed" || type == "response.incomplete" || type == "error" || type == "response.error"
    }

    private func failureMessage(type: String, payload: ResponsesStreamPayload) -> String {
        if let message = payload.message?.trimmingCharacters(in: .whitespacesAndNewlines), !message.isEmpty {
            return message
        }
        if let message = payload.response?.error?.message, !message.isEmpty {
            return message
        }
        if let reason = payload.response?.incompleteDetails?.reason, !reason.isEmpty {
            return "Responses status incomplete: \(reason)"
        }
        return "Responses stream \(type)"
    }
}

// MARK: - ResponsesStreamPayload

private struct ResponsesStreamPayload: Decodable {
    // MARK: Internal

    let type: String?
    let delta: String?
    let text: String?
    let message: String?
    let outputIndex: Int?
    let contentIndex: Int?
    let itemID: String?
    let response: ResponsesResponse?

    enum CodingKeys: String, CodingKey {
        case type
        case delta
        case text
        case message
        case outputIndex = "output_index"
        case contentIndex = "content_index"
        case itemID = "item_id"
        case response
    }

    var partKey: ResponsesOutputPartKey {
        ResponsesOutputPartKey(
            outputIndex: outputIndex,
            contentIndex: contentIndex,
            itemID: itemID
        )
    }
}

// MARK: - ResponsesStreamTextReducer

/// Decides which Responses stream events become user-visible text.
///
/// Deltas are emitted as they arrive. A later `response.output_text.done` for a part that
/// already streamed deltas repeats that part and is skipped. Done events for other parts are
/// kept, so several terminal-only parts survive. `response.completed` is used only when the
/// stream has not already produced text.
struct ResponsesStreamTextReducer {
    // MARK: Internal

    mutating func texts(from classification: ResponsesStreamClassification) -> [String] {
        switch classification {
        case let .delta(text, part):
            guard !emittedAggregate else {
                return []
            }
            recordDelta(part)
            return [text]
        case let .terminalPart(text, part):
            guard !emittedAggregate else {
                return []
            }
            guard shouldEmitTerminalPart(part) else {
                return []
            }
            return [text]
        case let .completedText(text):
            guard !emittedText else {
                return []
            }
            emittedText = true
            emittedAggregate = true
            return [text]
        case .failure, .ignored:
            return []
        }
    }

    // MARK: Private

    private var covered: Set<ResponsesOutputPartKey.Identity> = []
    private var unindexedDeltaItems: Set<String> = []
    private var sawDelta = false
    private var emittedIdentifiedTerminal = false
    private var emittedText = false
    private var emittedAggregate = false

    private mutating func recordDelta(_ part: ResponsesOutputPartKey) {
        sawDelta = true
        emittedText = true
        covered.insert(part.identity)
        guard let itemID = part.normalizedItemID else {
            return
        }
        covered.insert(.item(itemID))
        if part.outputIndex == nil, part.contentIndex == nil {
            unindexedDeltaItems.insert(itemID)
        }
    }

    /// Terminal-only parts are kept. A part already produced by deltas is not repeated.
    private mutating func shouldEmitTerminalPart(_ part: ResponsesOutputPartKey) -> Bool {
        switch part.identity {
        case .anonymous:
            // Index-less done events after streamed deltas, or after an identified part,
            // repeat text already kept. Distinct index-less parts are kept when nothing
            // identified them.
            guard !sawDelta, !emittedIdentifiedTerminal else {
                return false
            }
            emittedText = true
            return true
        case let .item(itemID):
            guard covered.insert(.item(itemID)).inserted else {
                return false
            }
            emittedIdentifiedTerminal = true
            emittedText = true
            return true
        case .indexed:
            if let itemID = part.normalizedItemID, unindexedDeltaItems.contains(itemID) {
                return false
            }
            guard covered.insert(part.identity).inserted else {
                return false
            }
            if let itemID = part.normalizedItemID {
                covered.insert(.item(itemID))
            }
            emittedIdentifiedTerminal = true
            emittedText = true
            return true
        }
    }
}

// MARK: - ResponsesSSEBuffer

/// Splits a byte stream into SSE lines.
///
/// Chunks may divide a line inside a multibyte UTF-8 character, so a line is decoded only after its newline byte.
struct ResponsesSSEBuffer {
    // MARK: Internal

    /// Appends one chunk and returns each complete line without its terminator.
    mutating func append(_ data: Data) -> [String] {
        pending.append(data)
        var lines: [String] = []
        while let newlineIndex = pending.firstIndex(of: 0x0A) {
            var lineData = pending[..<newlineIndex]
            pending.removeSubrange(...newlineIndex)
            if lineData.last == 0x0D {
                lineData = lineData.dropLast()
            }
            lines.append(String(decoding: Data(lineData), as: UTF8.self))
        }
        return lines
    }

    /// Returns bytes that never received a newline, so the final event can still be decoded.
    mutating func takeRemainder() -> String? {
        guard !pending.isEmpty else {
            return nil
        }
        if pending.last == 0x0D {
            pending.removeLast()
        }
        guard !pending.isEmpty else {
            return nil
        }
        let line = String(decoding: pending, as: UTF8.self)
        pending.removeAll(keepingCapacity: true)
        return line
    }

    // MARK: Private

    private var pending = Data()
}

// MARK: - ResponsesSSEEvent

struct ResponsesSSEEvent: Equatable, Sendable {
    var eventName: String
    var data: String
}

// MARK: - ResponsesSSEEventAssembler

/// Joins the `data:` lines of one SSE event.
///
/// The SSE spec dispatches an event at the blank line. Multiple `data:` lines are one
/// payload separated by `\n`, matching the Chat Completions stream parser. A trailing
/// event with no blank line is available from `finish()`.
struct ResponsesSSEEventAssembler {
    // MARK: Internal

    /// Accepts one line without its terminator. A blank line dispatches the accumulated event.
    mutating func consume(line: String) -> ResponsesSSEEvent? {
        if line.isEmpty {
            return dispatch()
        }
        if line.hasPrefix(":") {
            return nil
        }
        if let value = fieldValue("event:", in: line) {
            eventName = value
            return nil
        }
        if let value = fieldValue("data:", in: line) {
            dataLines.append(value)
            return nil
        }
        return nil
    }

    /// Dispatches a final event when the stream ends without a blank line.
    mutating func finish() -> ResponsesSSEEvent? {
        dispatch()
    }

    // MARK: Private

    private var eventName = ""
    private var dataLines: [String] = []

    private mutating func dispatch() -> ResponsesSSEEvent? {
        let name = eventName
        let lines = dataLines
        eventName = ""
        dataLines.removeAll(keepingCapacity: true)
        guard !lines.isEmpty else {
            return nil
        }
        return ResponsesSSEEvent(eventName: name, data: lines.joined(separator: "\n"))
    }

    /// Reads an SSE field the way the Chat Completions parser does, trimming surrounding spaces.
    private func fieldValue(_ name: String, in line: String) -> String? {
        guard line.hasPrefix(name) else {
            return nil
        }
        return String(line.dropFirst(name.count)).trimmingCharacters(in: .whitespaces)
    }
}

// MARK: - ResponsesSSEDecoder

/// Turns a Responses SSE byte stream into classified events.
struct ResponsesSSEDecoder {
    // MARK: Internal

    /// Classifies every event whose blank-line boundary arrived in this chunk.
    mutating func consume(_ data: Data) -> [ResponsesStreamClassification] {
        classifications(from: buffer.append(data))
    }

    /// Classifies a trailing event that the stream ended without a blank line.
    mutating func finish() -> [ResponsesStreamClassification] {
        var lines: [String] = []
        if let remainder = buffer.takeRemainder() {
            lines.append(remainder)
        }
        var results = classifications(from: lines)
        if let event = assembler.finish() {
            results.append(classify(event))
        }
        return results
    }

    // MARK: Private

    private var buffer = ResponsesSSEBuffer()
    private var assembler = ResponsesSSEEventAssembler()
    private let classifier = ResponsesStreamClassifier()

    private mutating func classifications(from lines: [String]) -> [ResponsesStreamClassification] {
        var results: [ResponsesStreamClassification] = []
        for line in lines {
            guard let event = assembler.consume(line: line) else {
                continue
            }
            results.append(classify(event))
        }
        return results
    }

    private func classify(_ event: ResponsesSSEEvent) -> ResponsesStreamClassification {
        classifier.classify(eventName: event.eventName, payload: event.data)
    }
}
