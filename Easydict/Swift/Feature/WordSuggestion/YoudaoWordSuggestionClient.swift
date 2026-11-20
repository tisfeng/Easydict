//
//  YoudaoWordSuggestionClient.swift
//  Easydict
//
//  Created by Anson on 2026/11/20.
//  Copyright © 2026 izual. All rights reserved.
//

import Alamofire
import Foundation

// MARK: - YoudaoWordSuggestionClient

/// Fetches short English-Chinese glosses and same-root words from Youdao's web dictionary.
///
/// Both endpoints are the ones the Youdao website uses and are not a
/// documented public API, so every failure is treated as "no data" and the
/// suggestion list falls back to the spell checker's words without glosses.
@MainActor
final class YoudaoWordSuggestionClient {
    // MARK: Internal

    /// Prefix suggestions for `query`, each with its first part of speech and main meaning.
    func suggestions(for query: String, limit: Int) async -> [(word: String, definition: WordDefinition?)] {
        let cacheKey = "\(query.lowercased())#\(limit)"
        if let cached = suggestionCache[cacheKey] {
            return cached
        }

        let parameters: [String: Any] = [
            "q": query, "num": limit, "ver": "3.0", "doctype": "json", "cache": "false", "le": "en",
        ]
        let response = try? await AF.request(
            suggestURL,
            parameters: parameters,
            requestModifier: { [timeout] in $0.timeoutInterval = timeout }
        )
        .serializingDecodable(YoudaoSuggestResponse.self)
        .value

        let entries = (response?.data?.entries ?? []).map { entry in
            (word: entry.entry, definition: entry.explain.flatMap(parseExplain))
        }
        // Keyed by exact spelling: `Upper` (a surname) and `YES` (an acronym)
        // must not overwrite the glosses of `upper` and `yes`.
        for entry in entries {
            if let definition = entry.definition {
                definitionCache[entry.word] = definition
            }
        }
        if response != nil {
            suggestionCache[cacheKey] = entries
        }
        return entries
    }

    /// The gloss for exactly `word`, if Youdao knows it.
    func definition(for word: String) async -> WordDefinition? {
        if let cached = definitionCache[word] {
            return cached
        }
        let entries = await suggestions(for: word, limit: 1)
        return entries.first { $0.word == word }?.definition
    }

    /// Words that share a root with `word` but are not just its inflections,
    /// such as `decision` and `decisive` for `decide`.
    func relatedWords(for word: String) async -> [WordSuggestion] {
        let key = word.lowercased()
        if let cached = relatedCache[key] {
            return cached
        }

        let parameters: [String: Any] = ["q": word, "doctype": "json", "jsonversion": "4", "le": "en"]
        guard let response = try? await AF.request(
            wordURL,
            parameters: parameters,
            requestModifier: { [timeout] in $0.timeoutInterval = timeout }
        )
        .serializingDecodable(YoudaoWordResponse.self)
        .value
        else {
            return []
        }

        var seen: Set<String> = [key]
        var related: [WordSuggestion] = []
        for group in response.relWord?.rels ?? [] {
            for item in group.rel.words ?? [] {
                let relatedKey = item.word.lowercased()
                guard let translation = item.tran,
                      !isInflectionNote(translation, of: key),
                      seen.insert(relatedKey).inserted
                else { continue }
                related.append(WordSuggestion(
                    word: item.word,
                    partOfSpeech: group.rel.pos,
                    meaning: mainMeaning(of: translation),
                    origin: .related
                ))
            }
        }
        relatedCache[key] = related
        return related
    }

    /// Splits Youdao's `explain` text, such as
    /// `v. 促使，导致；鼓励，提示; adj. 迅速的…`, into the first part of speech and its main meaning.
    func parseExplain(_ explain: String) -> WordDefinition? {
        guard let firstSegment = explain.components(separatedBy: "; ").first?
            .trimmingCharacters(in: .whitespaces),
            !firstSegment.isEmpty
        else { return nil }

        let pattern = #"^([a-z]+\.(?:\s*&\s*[a-z]+\.)?)\s*(.*)$"#
        let range = NSRange(firstSegment.startIndex..., in: firstSegment)
        if let match = try? NSRegularExpression(pattern: pattern).firstMatch(in: firstSegment, range: range),
           let posRange = Range(match.range(at: 1), in: firstSegment),
           let meaningRange = Range(match.range(at: 2), in: firstSegment) {
            let meaning = mainMeaning(of: String(firstSegment[meaningRange]))
            return meaning.isEmpty ? nil : WordDefinition(
                partOfSpeech: String(firstSegment[posRange]),
                meaning: meaning
            )
        }
        let meaning = mainMeaning(of: firstSegment)
        return meaning.isEmpty ? nil : WordDefinition(partOfSpeech: nil, meaning: meaning)
    }

    // MARK: Private

    private let suggestURL = "https://dict.youdao.com/suggest"
    private let wordURL = "https://dict.youdao.com/jsonapi_s"
    private let timeout: TimeInterval = 4
    private let maxSenses = 2

    private var suggestionCache: [String: [(word: String, definition: WordDefinition?)]] = [:]
    private var definitionCache: [String: WordDefinition] = [:]
    private var relatedCache: [String: [WordSuggestion]] = [:]

    /// Keeps the first senses and drops register labels such as `<美>`.
    /// Only a trailing truncation ellipsis is removed; `……` inside a sense is a placeholder.
    private func mainMeaning(of text: String) -> String {
        let cleaned = text
            .replacingOccurrences(of: #"<[^>]*>"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"(\.\.\.|…)$"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
        var seen = Set<String>()
        let senses = cleaned
            .components(separatedBy: "；")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && seen.insert($0).inserted }
        return senses.prefix(maxSenses).joined(separator: "；")
    }

    /// Youdao marks inflections like `决定（decide的过去式）`.
    private func isInflectionNote(_ translation: String, of word: String) -> Bool {
        let lowercased = translation.lowercased()
        return lowercased.contains("（\(word)的") || lowercased.contains("(\(word)的")
    }
}

// MARK: - YoudaoSuggestResponse

private struct YoudaoSuggestResponse: Decodable {
    struct Payload: Decodable {
        let entries: [Entry]?
    }

    struct Entry: Decodable {
        let entry: String
        let explain: String?
    }

    let data: Payload?
}

// MARK: - YoudaoWordResponse

private struct YoudaoWordResponse: Decodable {
    struct RelatedWords: Decodable {
        let rels: [RelationGroup]?
    }

    struct RelationGroup: Decodable {
        let rel: Relation
    }

    struct Relation: Decodable {
        let pos: String?
        let words: [Item]?
    }

    struct Item: Decodable {
        let word: String
        let tran: String?
    }

    enum CodingKeys: String, CodingKey {
        case relWord = "rel_word"
    }

    let relWord: RelatedWords?
}
