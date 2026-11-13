//
//  OCRTranslationResponse.swift
//  Easydict
//
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation

/// Validates the final pair without exposing response bodies in errors.
struct OCRTranslationResponse: Decodable {
    // MARK: Lifecycle

    init(original: String, translation: String) {
        self.original = original
        self.translation = translation
    }

    init(response: String) throws {
        var content = response.trimmingCharacters(in: .whitespacesAndNewlines)
        let lines = content.components(separatedBy: "\n")
        if let first = lines.first, ["```", "```json"].contains(first.lowercased()),
           lines.last == "```" {
            content = lines.dropFirst().dropLast().joined(separator: "\n")
        }
        do {
            let decoded = try JSONDecoder().decode(Self.self, from: Data(content.utf8))
            let original = decoded.original.trimmingCharacters(in: .whitespacesAndNewlines)
            let translation = decoded.translation.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !original.isEmpty, !translation.isEmpty else { throw QueryError(type: .noResult) }
            self.original = original
            self.translation = translation
        } catch {
            // Only a fixed failure category is logged, never output text or decoder context.
            logError("Combined image JSON or required-field validation failed")
            throw QueryError(type: .noResult)
        }
    }

    // MARK: Internal

    let original: String
    let translation: String
}
