//
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation

/// Decodes only the two JSON string values. Incomplete escapes never reach the UI.
struct OCRTranslationProgress {
    // MARK: Lifecycle

    init(_ response: String) {
        let text = response.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.first == "{" else { return }
        var cursor = text.index(after: text.startIndex)
        var seen: Set<String> = []
        while cursor < text.endIndex {
            skipWhitespace(text, cursor: &cursor)
            guard cursor < text.endIndex, text[cursor] != "}" else { return }
            guard let key = readString(text, cursor: &cursor), key.closed,
                  ["original", "translation"].contains(key.value), seen.insert(key.value).inserted
            else { return }
            skipWhitespace(text, cursor: &cursor)
            guard cursor < text.endIndex, text[cursor] == ":" else { return }
            cursor = text.index(after: cursor)
            skipWhitespace(text, cursor: &cursor)
            guard let value = readString(text, cursor: &cursor) else { return }
            if key.value == "original" { self.original = value.value }
            else { self.translation = value.value }
            guard value.closed else { return }
            skipWhitespace(text, cursor: &cursor)
            guard cursor < text.endIndex, text[cursor] == "," || text[cursor] == "}" else { return }
            if key
                .value ==
                "original" {
                self.originalComplete = !value.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
            if text[cursor] == "}" { return }
            cursor = text.index(after: cursor)
        }
    }

    // MARK: Internal

    var original = ""
    var translation = ""
    var originalComplete = false

    // MARK: Private

    private func skipWhitespace(_ text: String, cursor: inout String.Index) {
        while cursor < text.endIndex, text[cursor].isWhitespace { cursor = text.index(after: cursor) }
    }

    private func readString(_ text: String, cursor: inout String.Index) -> (value: String, closed: Bool)? {
        guard cursor < text.endIndex, text[cursor] == "\"" else { return nil }
        cursor = text.index(after: cursor)
        let start = cursor
        var escaped = false
        while cursor < text.endIndex {
            let character = text[cursor]
            if character == "\"", !escaped {
                let body = String(text[start ..< cursor])
                cursor = text.index(after: cursor)
                guard let decoded = decode(body) else { return nil }
                return (decoded, true)
            }
            escaped = character == "\\" && !escaped
            cursor = text.index(after: cursor)
        }
        var body = String(text[start...])
        // A chunk can end inside an escape or UTF-16 surrogate pair (at most 12 ASCII characters).
        for _ in 0 ... 12 {
            if let decoded = decode(body) { return (decoded, false) }
            guard !body.isEmpty else { break }
            body.removeLast()
        }
        return nil
    }

    private func decode(_ body: String) -> String? {
        try? JSONDecoder().decode(String.self, from: Data(("\"" + body + "\"").utf8))
    }
}
