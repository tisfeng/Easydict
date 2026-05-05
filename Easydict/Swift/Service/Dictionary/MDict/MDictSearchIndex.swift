//
//  MDictSearchIndex.swift
//  Easydict
//
//  Created by Kuroda Kayn on 2026/05/05.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation

private let maxMDictFuzzyDistance = 2

// MARK: - MDictSearchIndex

/// Lightweight headword index for fallback MDict lookup.
///
/// The index stores unique words from key blocks and searches them by prefix,
/// substring, and small edit distance. It avoids indexing full record HTML so
/// exact lookup remains the fast path and large dictionaries do not decompress
/// every definition during import or first query.
struct MDictSearchIndex {
    // MARK: Lifecycle

    init(entries: [MDictKeyEntry], caseSensitive: Bool) {
        self.caseSensitive = caseSensitive

        var seen = Set<String>()
        var words: [String] = []
        var normalized: [String] = []
        words.reserveCapacity(entries.count)
        normalized.reserveCapacity(entries.count)

        for entry in entries {
            let key = Self.normalized(entry.word, caseSensitive: caseSensitive)
            guard seen.insert(key).inserted else { continue }
            words.append(entry.word)
            normalized.append(key)
        }

        self.words = words
        self.normalizedWords = normalized
    }

    // MARK: Internal

    func candidates(for query: String, limit: Int = 8) -> [String] {
        let normalizedQuery = Self.normalized(query, caseSensitive: caseSensitive)
        guard !normalizedQuery.isEmpty else { return [] }

        var results: [String] = []
        var seen = Set<String>()

        appendPrefixMatches(
            for: normalizedQuery,
            limit: limit,
            results: &results,
            seen: &seen
        )
        appendSubstringMatches(
            for: normalizedQuery,
            limit: limit,
            results: &results,
            seen: &seen
        )
        appendFuzzyMatches(
            for: normalizedQuery,
            limit: limit,
            results: &results,
            seen: &seen
        )

        return Array(results.prefix(limit))
    }

    // MARK: Private

    private let caseSensitive: Bool
    private let words: [String]
    private let normalizedWords: [String]

    private static func normalized(_ word: String, caseSensitive: Bool) -> String {
        let trimmed = word.trimmingCharacters(in: .whitespacesAndNewlines)
        return caseSensitive ? trimmed : trimmed.lowercased()
    }

    private func appendPrefixMatches(
        for query: String,
        limit: Int,
        results: inout [String],
        seen: inout Set<String>
    ) {
        for (index, word) in normalizedWords.enumerated()
            where word.hasPrefix(query) && seen.insert(word).inserted {
            results.append(words[index])
            if results.count >= limit { return }
        }
    }

    private func appendSubstringMatches(
        for query: String,
        limit: Int,
        results: inout [String],
        seen: inout Set<String>
    ) {
        for (index, word) in normalizedWords.enumerated()
            where word.contains(query) && seen.insert(word).inserted {
            results.append(words[index])
            if results.count >= limit { return }
        }
    }

    private func appendFuzzyMatches(
        for query: String,
        limit: Int,
        results: inout [String],
        seen: inout Set<String>
    ) {
        for (index, word) in normalizedWords.enumerated() {
            guard !seen.contains(word),
                  abs(word.count - query.count) <= maxMDictFuzzyDistance,
                  editDistance(query, word, maxDistance: maxMDictFuzzyDistance)
                  <= maxMDictFuzzyDistance,
                  seen.insert(word).inserted
            else { continue }

            results.append(words[index])
            if results.count >= limit { return }
        }
    }

    private func editDistance(_ lhs: String, _ rhs: String, maxDistance: Int) -> Int {
        let leftChars = Array(lhs)
        let rightChars = Array(rhs)
        if abs(leftChars.count - rightChars.count) > maxDistance {
            return maxDistance + 1
        }
        if rightChars.isEmpty { return leftChars.count }

        var previous = Array(0 ... rightChars.count)
        var current = Array(repeating: 0, count: rightChars.count + 1)

        for i in 1 ... leftChars.count {
            current[0] = i
            var rowMinimum = current[0]
            for j in 1 ... rightChars.count {
                let substitution = previous[j - 1] +
                    (leftChars[i - 1] == rightChars[j - 1] ? 0 : 1)
                current[j] = min(previous[j] + 1, current[j - 1] + 1, substitution)
                rowMinimum = min(rowMinimum, current[j])
            }
            if rowMinimum > maxDistance { return maxDistance + 1 }
            swap(&previous, &current)
        }

        return previous[rightChars.count]
    }
}

// MARK: - MDictInflection

/// Generates common English lookup variants before fuzzy search.
///
/// These transformations are deliberately conservative. They cover common
/// plural, past-tense, gerund, comparative, and superlative forms without
/// pretending to be a full morphology engine.
enum MDictInflection {
    // MARK: Internal

    static func candidates(for word: String) -> [String] {
        let trimmed = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 3 else { return [] }

        var candidates: [String] = []
        appendPluralBases(trimmed, to: &candidates)
        appendVerbBases(trimmed, to: &candidates)
        appendComparisonBases(trimmed, to: &candidates)

        var seen = Set<String>()
        return candidates.filter {
            $0 != trimmed && !$0.isEmpty && seen.insert($0).inserted
        }
    }

    // MARK: Private

    private static func appendPluralBases(_ word: String, to candidates: inout [String]) {
        if word.hasSuffix("ies") {
            candidates.append(String(word.dropLast(3)) + "y")
        }
        if word.hasSuffix("es") {
            candidates.append(String(word.dropLast(2)))
        }
        if word.hasSuffix("s"), !word.hasSuffix("ss") {
            candidates.append(String(word.dropLast()))
        }
    }

    private static func appendVerbBases(_ word: String, to candidates: inout [String]) {
        if word.hasSuffix("ied") {
            candidates.append(String(word.dropLast(3)) + "y")
        }
        if word.hasSuffix("ing") {
            let base = String(word.dropLast(3))
            candidates.append(base)
            candidates.append(base + "e")
            candidates.append(dropDoubledFinalConsonant(base))
        }
        if word.hasSuffix("ed") {
            let base = String(word.dropLast(2))
            candidates.append(base)
            candidates.append(base + "e")
            candidates.append(dropDoubledFinalConsonant(base))
        }
    }

    private static func appendComparisonBases(_ word: String, to candidates: inout [String]) {
        if word.hasSuffix("ier") {
            candidates.append(String(word.dropLast(3)) + "y")
        }
        if word.hasSuffix("iest") {
            candidates.append(String(word.dropLast(4)) + "y")
        }
        if word.hasSuffix("er") {
            let base = String(word.dropLast(2))
            candidates.append(base)
            candidates.append(base + "e")
            candidates.append(dropDoubledFinalConsonant(base))
        }
        if word.hasSuffix("est") {
            let base = String(word.dropLast(3))
            candidates.append(base)
            candidates.append(base + "e")
            candidates.append(dropDoubledFinalConsonant(base))
        }
    }

    private static func dropDoubledFinalConsonant(_ word: String) -> String {
        guard let last = word.last,
              word.dropLast().last == last,
              !"aeiou".contains(last)
        else { return word }

        return String(word.dropLast())
    }
}
