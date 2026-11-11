//
//  OCRTranslationStream.swift
//  Easydict
//
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation

/// Separates one image response into incremental original and translated Markdown.
struct OCRTranslationStream {
    // MARK: Lifecycle

    init(identifier: String = String(UUID().uuidString.prefix(6))) {
        self.sourceMarker = "<S\(identifier)>"
        self.translationMarker = "<T\(identifier)>"
        self.endMarker = "<X\(identifier)>"
    }

    // MARK: Internal

    struct Update: Sendable, Equatable {
        let source: String
        let translation: String
        let sourceComplete: Bool
        let complete: Bool
    }

    let sourceMarker: String
    let translationMarker: String
    let endMarker: String

    var update: Update {
        Update(
            source: joined(sourceParts),
            translation: joined(translationParts),
            sourceComplete: sourceComplete,
            complete: complete
        )
    }

    /// Holds incomplete control markers across provider chunks, including one-character chunks.
    mutating func append(_ delta: String) throws {
        pending += delta
        let markers = [sourceMarker, translationMarker, endMarker]
        while !pending.isEmpty {
            let next = markers.compactMap { marker in
                pending.range(of: marker).map { (marker, $0) }
            }.min { $0.1.lowerBound < $1.1.lowerBound }
            if let (marker, range) = next {
                try appendContent(String(pending[..<range.lowerBound]))
                pending.removeSubrange(..<range.upperBound)
                try transition(marker)
            } else {
                let maximum = min(pending.count, markers.map(\.count).max() ?? 0)
                let held = (0 ... maximum).reversed().first { count in
                    markers.contains { $0.hasPrefix(pending.suffix(count)) }
                } ?? 0
                try appendContent(String(pending.dropLast(held)))
                pending = String(pending.suffix(held))
                break
            }
        }
    }

    func finish() throws -> Update {
        guard complete, pending.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !update.source.isEmpty, !update.translation.isEmpty else { throw QueryError(type: .noResult) }
        return update
    }

    // MARK: Private

    private enum Channel { case waiting, source, translation, ended }

    private var channel = Channel.waiting
    private var sourceParts: [String] = []
    private var translationParts: [String] = []
    private var pending = ""
    private var sourceComplete = false
    private var complete = false

    private func joined(_ parts: [String]) -> String {
        parts.map { $0.trimmingCharacters(in: .newlines) }.joined(separator: "\n\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private mutating func appendContent(_ text: String) throws {
        switch channel {
        case .source: sourceParts[sourceParts.count - 1] += text
        case .translation: translationParts[translationParts.count - 1] += text
        default:
            guard text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw QueryError(type: .noResult)
            }
        }
    }

    private mutating func transition(_ marker: String) throws {
        if marker == sourceMarker {
            guard !sourceComplete, channel == .waiting || channel == .translation,
                  sourceParts.count == translationParts.count,
                  translationParts.last?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != true else {
                throw QueryError(type: .noResult)
            }
            sourceParts.append("")
            channel = .source
        } else if marker == translationMarker {
            guard channel == .source,
                  sourceParts.last?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else {
                throw QueryError(type: .noResult)
            }
            translationParts.append("")
            channel = .translation
        } else {
            guard channel == .translation,
                  sourceParts.count == translationParts.count,
                  translationParts.last?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else {
                throw QueryError(type: .noResult)
            }
            sourceComplete = true
            complete = true
            channel = .ended
        }
    }
}
