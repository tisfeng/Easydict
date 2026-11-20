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

        // While typing or for a real word, look up what was typed; for a typo, Youdao's
        // fuzzy matches on the raw input are mostly noise, so use the best correction instead.
        let onlineQuery = check.isTypingPrefix || check.isCorrect ? input : check.corrections.first
        let online = if let onlineQuery {
            await client.suggestions(for: onlineQuery, limit: onlineLimit)
        } else {
            [(word: String, definition: WordDefinition?)]()
        }
        for entry in online {
            if let definition = entry.definition {
                cachedDefinitions[entry.word] = definition
            }
        }

        // Youdao also returns rare or misspelled headwords; keep words the spell checker accepts,
        // except spellings of the input itself, such as `anne` for a name.
        let onlineWords = online.map(\.word).filter { word in
            word.lowercased() == input.lowercased() || isCorrectlySpelled(word)
        }
        let words = orderedCandidates(for: input, check: check, onlineWords: onlineWords).prefix(maxSimilar)

        // Always try: the suggest endpoint returns nothing for some words Youdao still defines.
        let lookedUp = await fetchMissingDefinitions(for: Array(words))
        // Some gloss arrived, so Youdao is reachable and a missing one means a rare word, not an outage.
        let isYoudaoReachable = !online.isEmpty || words.contains { cachedDefinitions[$0] != nil }

        var similar: [WordSuggestion] = []
        for word in words {
            let definition = cachedDefinitions[word]
            // A word Youdao was asked about but cannot gloss is usually a rare form; spellings
            // of the input itself stay, since names are often missing from the dictionary.
            if definition == nil, isYoudaoReachable, lookedUp.contains(word), word.lowercased() != input.lowercased() {
                continue
            }
            similar.append(WordSuggestion(
                word: word,
                partOfSpeech: definition?.partOfSpeech,
                meaning: definition?.meaning,
                origin: .similar
            ))
        }

        guard check.isCorrect else { return similar }

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
        // The spell checker capitalizes completions to match capitalized input
        // (`Anne` → `Annex`); use the ordinary lowercase word when there is one.
        let isCapitalized = input.first?.isUppercase == true && input.dropFirst() == input.dropFirst().lowercased()
        let completions = (spellChecker.completions(
            forPartialWordRange: range,
            in: input,
            language: language,
            inSpellDocumentWithTag: 0
        ) ?? []).map { word in
            let lowercased = word.lowercased()
            return isCapitalized && isCorrectlySpelled(lowercased) ? lowercased : word
        }
        let guesses = spellChecker.guesses(
            forWordRange: range,
            in: input,
            language: language,
            inSpellDocumentWithTag: 0
        ) ?? []
        return SpellCheck(isCorrect: isCorrect, completions: completions, guesses: guesses, input: input)
    }

    /// Candidates in display order, before glosses are attached.
    ///
    /// Spellings of the input that differ only in case come first, the exact one
    /// leading: `anne` → `anne`, `Anne`; `march` → `march`, `March`. Then, while the
    /// input is a prefix being typed, the most frequent completions are kept and
    /// ordered by how few letters they add (`inves` → `invest` before `investment`);
    /// equal lengths keep frequency order, and keeping only frequent ones first stops
    /// rare short words such as `testy` from pushing out common ones. Only a typo with
    /// no completions is ranked by similarity to the spell checker's corrections, so
    /// `upgr` leads with `upgrade`, not `upper`.
    private func orderedCandidates(for input: String, check: SpellCheck, onlineWords: [String]) -> [String] {
        let key = input.lowercased()
        let spellings = ([input] + check.caseVariants + onlineWords)
            .filter { $0.lowercased() == key }
        let isKnownSpelling = { (word: String) in
            word != input || check.isCorrect || onlineWords.contains(input)
        }
        var seen = Set<String>()
        let head = spellings.filter { isKnownSpelling($0) && seen.insert($0).inserted }

        let rest: [String]
        if check.isTypingPrefix {
            let onlineCompletions = onlineWords.filter { $0.lowercased().hasPrefix(key) }
            let frequencyOrdered = (check.completions + onlineCompletions).filter { !seen.contains($0) }
            var restSeen = seen
            let unique = frequencyOrdered.filter { restSeen.insert($0).inserted }
            let frequent = filter(unique, input: input, isCorrect: check.isCorrect)
                .prefix(max(maxSimilar - head.count, 0))
            rest = frequent.enumerated()
                .sorted { lhs, rhs in
                    lhs.element.count == rhs.element.count
                        ? lhs.offset < rhs.offset
                        : lhs.element.count < rhs.element.count
                }
                .map(\.element)
        } else {
            let pool = (check.corrections + onlineWords).filter { !seen.contains($0) }
            let ranked = ranker.rank(pool, for: input, preferred: check.corrections)
            rest = filter(ranked, input: input, isCorrect: check.isCorrect)
        }
        return head + rest
    }

    /// Drops phrases, unrelated capitalized names for lowercase input, and plain inflections:
    /// of a correct input, or of another candidate such as `promises` next to `promise`.
    /// A capitalized word that the input spells out, like `Warcraft` for `warcraf`, is kept.
    private func filter(_ words: [String], input: String, isCorrect: Bool) -> [String] {
        let inputIsLowercase = input == input.lowercased()
        let candidates = words.filter { word in
            guard !word.contains(" "), !word.hasSuffix("'"), !word.hasSuffix("'s"), !word.hasSuffix("’s")
            else { return false }
            if inputIsLowercase, word.first?.isUppercase == true,
               !word.lowercased().hasPrefix(input) {
                return false
            }
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
    let input: String

    /// Corrections for a misspelled input; a correct word needs none.
    var corrections: [String] {
        isCorrect ? [] : guesses.filter { $0.lowercased() != input.lowercased() }
    }

    /// Spellings of the input that differ only in case, such as `Anne` for `anne`.
    var caseVariants: [String] {
        guesses.filter { $0 != input && $0.lowercased() == input.lowercased() }
    }

    /// Completions exist, so the text is most likely an unfinished word rather than a typo.
    var isTypingPrefix: Bool {
        !completions.isEmpty
    }
}
