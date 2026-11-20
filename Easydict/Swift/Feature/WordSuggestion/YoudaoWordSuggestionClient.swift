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

        let response = await suggestResponse(for: query, limit: limit)
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
        // Only a real answer is cached; an error body would otherwise hide this prefix for the session.
        if response != nil {
            trimCachesIfNeeded()
            suggestionCache[cacheKey] = entries
        }
        return entries
    }

    /// The gloss for exactly `word`, if Youdao knows it.
    ///
    /// The suggest endpoint refuses some words outright (it answers `not found`
    /// for `dictator` and `democracy`), so the word detail endpoint is the fallback.
    func definition(for word: String) async -> WordDefinition? {
        if let cached = definitionCache[word] {
            return cached
        }
        // Exact spelling only: `john` (toilet) and `John` (a name) have different glosses.
        // The word detail endpoint below is queried with the exact spelling as well.
        let entries = await suggestions(for: word, limit: 1)
        if let definition = entries.first(where: { $0.word == word })?.definition {
            return definition
        }

        guard let translation = await wordDetail(for: word)?.ec?.word?.trs?.first,
              let text = translation.tran
        else { return nil }
        let meaning = mainMeaning(of: text)
        guard !meaning.isEmpty else { return nil }
        let definition = WordDefinition(partOfSpeech: translation.pos, meaning: meaning)
        definitionCache[word] = definition
        return definition
    }

    /// Words that share a root with `word` but are not just its inflections,
    /// such as `decision` and `decisive` for `decide`.
    func relatedWords(for word: String) async -> [WordSuggestion] {
        // Cached by exact spelling, like the detail request: `polish` and `Polish` differ.
        if let cached = relatedCache[word] {
            return cached
        }
        let key = word.lowercased()

        guard let response = await wordDetail(for: word) else {
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
        relatedCache[word] = related
        return related
    }

    /// Common phrases built on `word`, such as `give up` and `give in` for `give`.
    func phrases(for word: String) async -> [WordSuggestion] {
        guard let response = await wordDetail(for: word) else { return [] }
        let items = (response.phrs?.phrs ?? []).map { (headword: $0.headword, translation: $0.translation) }
        return rankPhrases(items, for: word)
    }

    /// Orders Youdao's phrases for `word` and turns them into suggestions.
    ///
    /// Youdao's order is not by frequency (`take some` comes first for `take`), so
    /// phrasal verbs (`take on`, `take up`) lead, then other two-word phrases, then longer
    /// ones; phrases with placeholders such as `one's` go last. Truncated, duplicate and
    /// unglossed phrases, and phrases not containing `word`, are dropped.
    func rankPhrases(_ items: [(headword: String, translation: String?)], for word: String) -> [WordSuggestion] {
        let key = word.lowercased()
        var seen = Set<String>()
        let candidates = items.compactMap { item -> (suggestion: WordSuggestion, tier: Int)? in
            let headword = item.headword.trimmingCharacters(in: .whitespaces)
            let parts = headword.lowercased().split(separator: " ").map(String.init)
            guard parts.count > 1, parts.contains(key), !headword.contains("…"), !headword.contains("..."),
                  let translation = item.translation, seen.insert(headword.lowercased()).inserted,
                  let definition = parseExplain(translation)
            else { return nil }
            let tier = if parts.contains(where: phrasePlaceholders.contains) {
                3
            } else if parts.count == 2, parts[0] == key, phraseParticles.contains(parts[1]) {
                0
            } else if parts.count == 2 {
                1
            } else {
                2
            }
            let suggestion = WordSuggestion(
                word: headword,
                partOfSpeech: definition.partOfSpeech,
                meaning: definition.meaning,
                origin: .phrase
            )
            return (suggestion, tier)
        }
        return candidates.enumerated()
            .sorted { lhs, rhs in
                lhs.element.tier == rhs.element.tier ? lhs.offset < rhs.offset : lhs.element.tier < rhs.element.tier
            }
            .map(\.element.suggestion)
    }

    /// English words for Chinese `text`, such as `obstinate` and `stubborn` for `固执`,
    /// each with its gloss for that Chinese sense when Youdao gives one.
    ///
    /// When the word detail endpoint has no Chinese-English entry, or fails, the suggest
    /// endpoint's exact entry lists the words.
    func translations(for text: String) async -> [(word: String, meaning: String?)] {
        if let detail = await wordDetail(for: text),
           let items = detail.ce?.word?.trs, !items.isEmpty {
            return items.compactMap { item in
                guard let word = item.text?.trimmingCharacters(in: .whitespaces), !word.isEmpty,
                      let translation = item.tran, !isSentence(word)
                else { return nil }
                let meaning = mainMeaning(of: translation)
                return (word, meaning.isEmpty ? nil : meaning)
            }
        }

        guard let response = await suggestResponse(for: text, limit: 1),
              let entry = response.data?.entries?.first(where: { $0.entry == text }),
              let explain = entry.explain
        else { return [] }
        return explain.components(separatedBy: ";")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !$0.hasSuffix("...") && !$0.hasSuffix("…") && !isSentence($0) }
            .map { (word: $0, meaning: nil) }
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

    /// Whether any request reached Youdao at or after `date`, even one that found nothing.
    ///
    /// Cached answers say nothing about the network right now, so callers that need to know
    /// whether Youdao is reachable check this instead of whether they got data.
    func hasReachedYoudao(since date: Date) -> Bool {
        lastReachedAt.map { $0 >= date } ?? false
    }

    // MARK: Private

    private let suggestURL = "https://dict.youdao.com/suggest"
    private let wordURL = "https://dict.youdao.com/jsonapi_s?doctype=json&jsonversion=4"
    private let timeout: TimeInterval = 4
    private let maxSenses = 2
    private let maxCachedAnswers = 500
    private let phraseParticles: Set = [
        "up", "out", "in", "on", "off", "away", "back", "down", "over", "for", "at", "into",
        "after", "through", "about", "around", "by", "with", "from", "to", "of",
    ]
    private let phrasePlaceholders: Set = [
        "one's", "oneself", "sb", "sb.", "sth", "sth.", "somebody", "something", "someone",
    ]

    private var suggestionCache: [String: [(word: String, definition: WordDefinition?)]] = [:]
    private var definitionCache: [String: WordDefinition] = [:]
    private var relatedCache: [String: [WordSuggestion]] = [:]
    private var wordDetailCache: [String: YoudaoWordResponse] = [:]
    private var wordDetailTasks: [String: Task<YoudaoWordResponse?, Never>] = [:]
    private var lastReachedAt: Date?

    private func suggestResponse(for query: String, limit: Int) async -> YoudaoSuggestResponse? {
        let parameters: [String: Any] = [
            "q": query, "num": limit, "ver": "3.0", "doctype": "json", "cache": "false", "le": "en",
        ]
        let response = await AF.request(
            suggestURL,
            parameters: parameters,
            requestModifier: { [timeout] in $0.timeoutInterval = timeout }
        )
        .serializingDecodable(YoudaoSuggestResponse.self)
        .response
        // `suggest` answers HTTP 200 with its own status: 200 with entries, 404 for an unknown word.
        // Anything else, such as a rate-limit body, is neither an answer nor proof of reachability.
        let value = (try? response.result.get()).flatMap { $0.isAnswer ? $0 : nil }
        noteReached(response.response, decoded: value != nil)
        return value
    }

    /// Keeps the session caches bounded; clearing them only costs a few repeated requests.
    private func trimCachesIfNeeded() {
        guard suggestionCache.count + wordDetailCache.count > maxCachedAnswers else { return }
        suggestionCache.removeAll()
        definitionCache.removeAll()
        relatedCache.removeAll()
        wordDetailCache.removeAll()
    }

    /// Records that Youdao answered, but only for a successful status with a body that decodes:
    /// rate limiting, server errors and captive portal pages also produce an HTTP response.
    private func noteReached(_ response: HTTPURLResponse?, decoded: Bool) {
        if let response, (200 ..< 300).contains(response.statusCode), decoded {
            lastReachedAt = Date()
        }
    }

    /// A whole sentence, such as Youdao's machine translation of a Chinese sentence, is not a
    /// suggestion; an idiom such as `kill two birds with one stone` is.
    private func isSentence(_ text: String) -> Bool {
        text.split(separator: " ").count > 8 || text.contains { ".!?,;".contains($0) }
    }

    /// The word detail response, shared by glosses, same-root words, phrases and Chinese lookups.
    ///
    /// Unsigned requests are answered with a random entry for many words (`modesty` comes back
    /// as `locoism` or `R`, `银行` as `convoy`), so the request is signed with
    /// `YoudaoService.webDictParameters`, like the dictionary service, and any answer for another word is dropped.
    private func wordDetail(for word: String) async -> YoudaoWordResponse? {
        if let cached = wordDetailCache[word] {
            return cached
        }
        // Same-root words and phrases ask for the same word at once; share one request, whose
        // value is already checked against the query, so every caller gets the same validated answer.
        if let pending = wordDetailTasks[word] {
            return await pending.value
        }
        // A lookup for text the user already changed should not start new requests.
        guard !Task.isCancelled else { return nil }
        let task = Task { [
            wordURL,
            timeout,
            parameters = YoudaoService.webDictParameters(text: word, foreignLanguage: "en")
        ] () -> YoudaoWordResponse? in
            let response = await AF.request(
                wordURL,
                method: .post,
                parameters: parameters,
                requestModifier: { $0.timeoutInterval = timeout }
            )
            .serializingDecodable(YoudaoWordResponse.self)
            .response
            let value = try? response.result.get()
            // Every section is optional, so an error body such as `{}` still decodes; a real
            // answer always echoes the query it answered, even when that is another word.
            noteReached(response.response, decoded: value?.input != nil)
            // An answer for another word is Youdao's random fallback, not this word's entry.
            guard let value, value.input?.lowercased() == word.lowercased() else { return nil }
            trimCachesIfNeeded()
            wordDetailCache[word] = value
            return value
        }
        wordDetailTasks[word] = task
        let answer = await task.value
        wordDetailTasks[word] = nil
        return answer
    }

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
    struct Status: Decodable {
        let code: Int?
    }

    struct Payload: Decodable {
        let entries: [Entry]?
    }

    struct Entry: Decodable {
        let entry: String
        let explain: String?
    }

    let result: Status?
    let data: Payload?

    /// A found (200) or not-found (404) answer, as opposed to an error body.
    var isAnswer: Bool {
        result?.code == 200 || result?.code == 404
    }
}

// MARK: - YoudaoWordResponse

private struct YoudaoWordResponse: Decodable {
    // MARK: Lifecycle

    /// Every section is optional and some change shape between queries (`ec.word` is
    /// sometimes an array), so a section that fails to decode is treated as missing.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.relWord = try? container.decodeIfPresent(RelatedWords.self, forKey: .relWord)
        self.ec = try? container.decodeIfPresent(Glossary.self, forKey: .ec)
        self.ce = try? container.decodeIfPresent(ChineseGlossary.self, forKey: .ce)
        self.phrs = try? container.decodeIfPresent(Phrases.self, forKey: .phrs)
        self.input = try? container.decodeIfPresent(String.self, forKey: .input)
    }

    // MARK: Internal

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

    struct Glossary: Decodable {
        let word: GlossaryWord?
    }

    struct GlossaryWord: Decodable {
        let trs: [Translation]?
    }

    struct Translation: Decodable {
        let pos: String?
        let tran: String?
    }

    struct Phrases: Decodable {
        let phrs: [Phrase]?
    }

    struct Phrase: Decodable {
        let headword: String
        let translation: String?
    }

    /// Chinese-English entry; its `trs` items are English words for the Chinese query.
    struct ChineseGlossary: Decodable {
        let word: ChineseGlossaryWord?
    }

    struct ChineseGlossaryWord: Decodable {
        let trs: [ChineseTranslation]?
    }

    struct ChineseTranslation: Decodable {
        enum CodingKeys: String, CodingKey {
            case text = "#text"
            case tran = "#tran"
        }

        let text: String?
        let tran: String?
    }

    enum CodingKeys: String, CodingKey {
        case relWord = "rel_word"
        case ec, ce, phrs, input
    }

    let relWord: RelatedWords?
    let ec: Glossary?
    let ce: ChineseGlossary?
    let phrs: Phrases?
    let input: String?
}
