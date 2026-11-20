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

    /// Spell-checker candidates in display order; available synchronously and offline.
    func localSuggestions(for input: String) -> [WordSuggestion] {
        let check = spellCheck(for: input)
        return orderedCandidates(for: input, check: check, onlineWords: [])
            .prefix(maxSimilar)
            .map { word in
                let definition = cachedDefinitions[word]
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
        let check = spellCheck(for: input)

        // While typing, complete what was typed; for a typo, Youdao's fuzzy matches
        // on the raw input are mostly noise, so complete the best correction instead.
        let onlineQuery = check.isTypingPrefix ? input : check.guesses.first
        let online = if let onlineQuery {
            await client.suggestions(for: onlineQuery, limit: onlineLimit)
        } else {
            [(word: String, definition: WordDefinition?)]()
        }
        let isOnline = !online.isEmpty
        for entry in online {
            if let definition = entry.definition {
                cachedDefinitions[entry.word] = definition
            }
        }

        // Youdao also returns rare or misspelled headwords; keep words the spell checker accepts.
        let onlineWords = online.map(\.word).filter(isCorrectlySpelled)
        let words = orderedCandidates(for: input, check: check, onlineWords: onlineWords).prefix(maxSimilar)

        let lookedUp = isOnline ? await fetchMissingDefinitions(for: Array(words)) : []

        var similar: [WordSuggestion] = []
        for word in words {
            let definition = cachedDefinitions[word]
            // A word Youdao was asked about but cannot gloss is usually a name or a rare form.
            if definition == nil, lookedUp.contains(word), word.lowercased() != input.lowercased() {
                continue
            }
            similar.append(WordSuggestion(
                word: word,
                partOfSpeech: definition?.partOfSpeech,
                meaning: definition?.meaning,
                origin: .similar
            ))
        }

        guard check.isCorrect, isOnline else { return similar }

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
    /// - Returns: The words that were looked up.
    private func fetchMissingDefinitions(for words: [String]) async -> Set<String> {
        let missing = words.filter { cachedDefinitions[$0] == nil }.prefix(maxDefinitionLookups)
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
                cachedDefinitions[word] = definition
            }
        }
        return Set(missing)
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

    private func spellCheck(for input: String) -> SpellCheck {
        let range = NSRange(location: 0, length: (input as NSString).length)
        let isCorrect = isCorrectlySpelled(input)
        let completions = spellChecker.completions(
            forPartialWordRange: range,
            in: input,
            language: language,
            inSpellDocumentWithTag: 0
        ) ?? []
        let guesses = isCorrect ? [] : spellChecker.guesses(
            forWordRange: range,
            in: input,
            language: language,
            inSpellDocumentWithTag: 0
        ) ?? []
        return SpellCheck(isCorrect: isCorrect, completions: completions, guesses: guesses)
    }

    /// Candidates in display order, before glosses are attached.
    ///
    /// While the input is a prefix being typed, the most frequent completions are
    /// kept and then ordered by how few letters they add (`inves` → `invest` before
    /// `investment`); equal lengths keep frequency order. Keeping only frequent ones
    /// first stops rare short words such as `testy` from pushing out common ones.
    /// Only a typo with no completions is ranked by similarity to the spell checker's
    /// corrections, so `upgr` leads with `upgrade`, not `upper`.
    private func orderedCandidates(for input: String, check: SpellCheck, onlineWords: [String]) -> [String] {
        guard check.isTypingPrefix else {
            let ranked = ranker.rank(check.guesses + onlineWords, for: input, preferred: check.guesses)
            return filter(ranked, input: input, isCorrect: check.isCorrect)
        }

        let query = input.lowercased()
        let onlineCompletions = onlineWords.filter { $0.lowercased().hasPrefix(query) }
        let frequencyOrdered = (check.isCorrect ? [input] : []) + check.completions + onlineCompletions
        var seen = Set<String>()
        let unique = frequencyOrdered.filter { seen.insert($0.lowercased()).inserted }
        let frequent = filter(unique, input: input, isCorrect: check.isCorrect).prefix(maxSimilar)

        return frequent.enumerated()
            .sorted { lhs, rhs in
                lhs.element.count == rhs.element.count
                    ? lhs.offset < rhs.offset
                    : lhs.element.count < rhs.element.count
            }
            .map(\.element)
    }

    /// Drops phrases, capitalized names for lowercase input, and plain inflections:
    /// of a correct input, or of another candidate such as `promises` next to `promise`.
    private func filter(_ words: [String], input: String, isCorrect: Bool) -> [String] {
        let inputIsLowercase = input == input.lowercased()
        let candidates = words.filter { word in
            guard !word.contains(" "), !word.hasSuffix("'"), !word.hasSuffix("'s"), !word.hasSuffix("’s")
            else { return false }
            if inputIsLowercase, word.first?.isUppercase == true { return false }
            if isCorrect, ranker.isInflection(word, of: input) { return false }
            return true
        }
        return candidates.filter { word in
            !candidates.contains { ranker.isInflection(word, of: $0) }
        }
    }
}

// MARK: - SpellCheck

/// What the spell checker says about the typed text.
private struct SpellCheck {
    let isCorrect: Bool
    let completions: [String]
    let guesses: [String]

    /// Completions exist, so the text is most likely an unfinished word rather than a typo.
    var isTypingPrefix: Bool {
        !completions.isEmpty
    }
}
