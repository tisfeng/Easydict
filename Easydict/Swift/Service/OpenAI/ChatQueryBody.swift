//
//  ChatQueryBody.swift
//  Easydict
//
//  Created by fang63625 on 2026/10/15.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation
import OpenAI

// MARK: - ChatQueryBody

/// One assembled OpenAI-compatible chat-completions request body.
///
/// The MacPaw OpenAI SDK's `ChatQuery` cannot carry provider-specific fields, and Swift
/// cannot add stored properties to an external type. `ChatQueryBody` therefore owns the
/// request fields Easydict sends, encodes them into a single JSON object, and is shared by
/// the streaming and non-streaming transports.
struct ChatQueryBody: Sendable {
    // MARK: Internal

    let messages: [ChatQuery.ChatCompletionMessageParam]
    let model: String
    let temperature: Double?
    /// Value for the `reasoning_effort` request field; `nil` omits it.
    let reasoningEffort: String?
    let stream: Bool
    let extraBody: ExtraBody

    /// Encodes the request fields and, when configured, merges the extra body fields into
    /// the top-level request object without overriding the keys Easydict already set.
    func encoded() throws -> Data {
        let payload = Payload(
            messages: messages,
            model: model,
            temperature: temperature,
            reasoningEffort: reasoningEffort,
            stream: stream
        )
        // The wire format uses snake_case keys, so camelCase properties are converted here
        // instead of relying on a per-field `CodingKeys` mapping.
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let payloadData = try encoder.encode(payload)

        guard extraBody.isConfigured else {
            return payloadData
        }

        guard let fields = extraBody.fields else {
            return payloadData
        }

        // An empty object configures no fields, so keep the untouched payload.
        guard !fields.isEmpty else {
            return payloadData
        }

        guard var object = try JSONSerialization.jsonObject(with: payloadData) as? [String: Any] else {
            throw QueryError(type: .api, message: "Invalid chat request body")
        }

        // Fill in only the keys the assembled request does not already own, so a configured
        // field never overrides `model`, `stream`, or an explicit temperature and reasoning
        // effort.
        for (key, value) in fields where object[key] == nil {
            object[key] = value
        }

        return try JSONSerialization.data(withJSONObject: object)
    }

    // MARK: Private

    /// Explicit wire shape of the request fields, so the emitted keys do not depend on
    /// the SDK query type.
    private struct Payload: Encodable {
        let messages: [ChatQuery.ChatCompletionMessageParam]
        let model: String
        let temperature: Double?
        let reasoningEffort: String?
        let stream: Bool
    }
}

// MARK: - ExtraBody

/// User-configured extra JSON fields merged into the top-level object of a chat request
/// body, as siblings of `model`. Keys Easydict already set are kept.
///
/// Only the raw JSON text is stored so the value stays `Sendable` and `Equatable`.
struct ExtraBody: Equatable, Sendable {
    // MARK: Lifecycle

    init(json: String = "") {
        self.json = json
    }

    // MARK: Internal

    let json: String

    /// Whether the user configured any extra body JSON.
    var isConfigured: Bool {
        !json.trim().isEmpty
    }

    /// Whether the configured JSON is a top-level object. Blank text counts as valid.
    var isValid: Bool {
        !isConfigured || fields != nil
    }

    /// Parsed top-level JSON object, or `nil` when unconfigured or invalid.
    var fields: [String: Any]? {
        guard isConfigured, let data = json.data(using: .utf8) else {
            return nil
        }
        return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    }
}
