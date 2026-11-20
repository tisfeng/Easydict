//
//  WordSuggestionProvider.swift
//  Easydict
//
//  Created by Anson on 2026/11/20.
//  Copyright © 2026 izual. All rights reserved.
//

import AppKit

// MARK: - WordSuggestionProvider

/// Builds the suggestion list for a typed word.
///
/// Candidates come from the macOS spell checker (corrections and
/// completions, available offline) merged with Youdao's prefix suggestions.
/// Glosses and same-root words come from Youdao; when it is unreachable the
/// list still shows the spell checker's words without glosses.
@MainActor
final class WordSuggestionProvider {
    // MARK: Internal

    /// Whether `text` looks like one English word worth suggesting for.
    func isSuggestible(_ text: String) -> Bool {
        text.range(of: #"^[A-Za-z][A-Za-z'\-]{1,39}$"#, options: .regularExpression) != nil
    }

    /// Spell-checker candidates ranked by similarity; available synchronously and offline.
    func localSuggestions(for input: String) -> [WordSuggestion] {
        let isCorrect = isCorrectlySpelled(input)
        let local = spellCheckerCandidates(for: input)
        let candidates = filter(
            ranker.rank(local.words, for: input, preferred: local.corrections),
            input: input,
            isCorrect: isCorrect
        )
        return candidates.prefix(maxSimilar).map { word in
            let definition = cachedDefinitions[word.lowercased()]
            return WordSuggestion(
                word: word,
                partOfSpeech: definition?.partOfSpeech,
                meaning: definition?.meaning,
                origin: .similar
            )
        }
    }

    /// Full list with glosses and, for correctly spelled input, same-root words.
    func suggestions(for input: String) async -> [WordSuggestion] {
        let isCorrect = isCorrectlySpelled(input)
        let local = spellCheckerCandidates(for: input)

        // For a typo, Youdao's fuzzy matches on the raw input are mostly noise,
        // so complete the spell checker's best correction instead.
        let online: [(word: String, definition: WordDefinition?)]
        if isCorrect {
            online = await client.suggestions(for: input, limit: onlineLimit)
        } else if let correction = local.corrections.first {
            online = await client.suggestions(for: correction, limit: onlineLimit)
        } else {
            online = []
        }
        let isOnline = !online.isEmpty
        for entry in online {
            if let definition = entry.definition {
                cachedDefinitions[entry.word.lowercased()] = definition
            }
        }

        // Youdao's fuzzy matches for a typo include rare or misspelled headwords;
        // keep only words the spell checker accepts.
        let onlineWords = online.map(\.word).filter(isCorrectlySpelled)
        let ranked = ranker.rank(local.words + onlineWords, for: input, preferred: local.corrections)
        let words = filter(ranked, input: input, isCorrect: isCorrect).prefix(maxSimilar)

        let lookedUp = isOnline ? await fetchMissingDefinitions(for: Array(words)) : []

        var similar: [WordSuggestion] = []
        for word in words {
            let definition = cachedDefinitions[word.lowercased()]
            // A word Youdao was asked about but cannot gloss is usually a name or a rare form.
            if definition == nil, lookedUp.contains(word.lowercased()), word.lowercased() != input.lowercased() {
                continue
            }
            similar.append(WordSuggestion(
                word: word,
                partOfSpeech: definition?.partOfSpeech,
                meaning: definition?.meaning,
                origin: .similar
            ))
        }

        guard isCorrect, isOnline else { return similar }

        let shown = Set(similar.map { $0.word.lowercased() })
        let related = await client.relatedWords(for: input)
            .filter { !shown.contains($0.word.lowercased()) && !ranker.isInflection($0.word, of: input) }
            .prefix(maxRelated)
        let similarLimit = max(maxCount - related.count, 1)
        return Array(similar.prefix(similarLimit)) + related
    }

    // MARK: Private

    private let ranker = WordSuggestionRanker()
    private let client = YoudaoWordSuggestionClient()
    private let spellChecker = NSSpellChecker.shared
    private let language = "en"
    private let maxCount = 8
    private let maxSimilar = 8
    private let maxRelated = 4
    private let onlineLimit = 8
    /// Caps extra gloss requests per lookup; prefix suggestions usually cover most rows.
    private let maxDefinitionLookups = 5

    private var cachedDefinitions: [String: WordDefinition] = [:]

    /// Looks up glosses for the top words the prefix suggestions did not cover, concurrently.
    /// - Returns: The lowercased words that were looked up.
    private func fetchMissingDefinitions(for words: [String]) async -> Set<String> {
        let missing = words.filter { cachedDefinitions[$0.lowercased()] == nil }.prefix(maxDefinitionLookups)
        guard !missing.isEmpty else { return [] }

        let client = client
        let fetched = await withTaskGroup(of: (String, WordDefinition?).self) { group in
            for word in missing {
                group.addTask { @MainActor in
                    await (word, client.definition(for: word))
                }
            }
            var results: [(String, WordDefinition?)] = []
            for await result in group {
                results.append(result)
            }
            return results
        }
        for (word, definition) in fetched {
            if let definition {
                cachedDefinitions[word.lowercased()] = definition
            }
        }
        return Set(missing.map { $0.lowercased() })
    }

    private func isCorrectlySpelled(_ word: String) -> Bool {
        let range = spellChecker.checkSpelling(
            of: word,
            startingAt: 0,
            language: language,
            wrap: false,
            inSpellDocumentWithTag: 0,
            wordCount: nil
        )
        return range.location == NSNotFound
    }

    /// Candidate words, plus the corrections among them when the input is misspelled.
    private func spellCheckerCandidates(for input: String) -> (words: [String], corrections: [String]) {
        let range = NSRange(location: 0, length: (input as NSString).length)
        let guesses = spellChecker.guesses(
            forWordRange: range,
            in: input,
            language: language,
            inSpellDocumentWithTag: 0
        ) ?? []
        let completions = spellChecker.completions(
            forPartialWordRange: range,
            in: input,
            language: language,
            inSpellDocumentWithTag: 0
        ) ?? []
        // A correctly spelled input is usually a prefix being typed; near-miss
        // corrections such as `decade` for `decide` would crowd out completions.
        if isCorrectlySpelled(input) {
            return ([input] + completions, [])
        }
        return (guesses + completions, guesses)
    }

    /// Drops phrases, capitalized names for lowercase input, and plain inflections:
    /// of a correct input, or of another candidate such as `promises` next to `promise`.
    private func filter(_ words: [String], input: String, isCorrect: Bool) -> [String] {
        let inputIsLowercase = input == input.lowercased()
        let candidates = words.filter { word in
            guard !word.contains(" ") else { return false }
            if inputIsLowercase, word.first?.isUppercase == true { return false }
            if isCorrect, ranker.isInflection(word, of: input) { return false }
            return true
        }
        return candidates.filter { word in
            !candidates.contains { ranker.isInflection(word, of: $0) }
        }
    }
}
