//
//  WordSuggestionRanker.swift
//  Easydict
//
//  Created by Anson on 2026/11/20.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation

// MARK: - WordSuggestionRanker

/// Orders candidate words by how closely they match what the user typed.
///
/// Similarity is the normalized Damerau-Levenshtein distance, with a small
/// bonus for completions of the input. Ties keep the candidates' original
/// order, which carries frequency information from the spell checker and
/// the online dictionary.
struct WordSuggestionRanker {
    // MARK: Internal

    /// Returns unique candidates sorted from most to least similar.
    /// - Parameter preferred: Spell-checker corrections in their own order; they also weigh how a
    ///   word sounds, so earlier ones get a small boost (`sycology` → `psychology` over `mycology`).
    func rank(_ candidates: [String], for input: String, preferred: [String] = []) -> [String] {
        let query = input.lowercased()
        var seen = Set<String>()
        let unique = candidates.filter { candidate in
            let key = candidate.lowercased()
            guard !key.isEmpty, !isPossessive(key), seen.insert(key).inserted else { return false }
            return true
        }

        let preferredOrder = preferred.map { $0.lowercased() }
        let scored: [(word: String, score: Double, order: Int)] = unique.enumerated().map { order, word in
            let key = word.lowercased()
            var score = similarity(query, key)
            if let index = preferredOrder.firstIndex(of: key) {
                score += preferredBonus / Double(index + 1)
            }
            return (word, score, order)
        }
        let sorted = scored.sorted { lhs, rhs in
            lhs.score == rhs.score ? lhs.order < rhs.order : lhs.score > rhs.score
        }
        return sorted.map(\.word)
    }

    /// Similarity in `0...1.1`, or `2` for an exact match so it always leads.
    func similarity(_ input: String, _ candidate: String) -> Double {
        if input == candidate { return 2 }
        let longest = max(input.count, candidate.count)
        guard longest > 0 else { return 0 }

        let distance = damerauLevenshteinDistance(input, candidate)
        var score = 1 - Double(distance) / Double(longest)
        if candidate.hasPrefix(input) {
            score += completionBonus
        }
        return score
    }

    /// Whether `candidate` is only an inflected form of `word`,
    /// such as a plural, past tense or present participle.
    func isInflection(_ candidate: String, of word: String) -> Bool {
        let word = word.lowercased()
        let candidate = candidate.lowercased()
        guard candidate != word else { return false }

        var forms = ["s", "es", "ed", "d", "ing", "er", "est"].map { word + $0 }
        if word.hasSuffix("e") {
            let stem = String(word.dropLast())
            forms += ["ing", "ed", "er", "est"].map { stem + $0 }
        }
        if word.hasSuffix("y") {
            let stem = String(word.dropLast())
            forms += ["ies", "ied", "ier", "iest"].map { stem + $0 }
        }
        if let last = word.last, !"aeiouy".contains(last) {
            let doubled = word + String(last)
            forms += ["ed", "ing", "er", "est"].map { doubled + $0 }
        }
        return forms.contains(candidate)
    }

    /// Optimal string alignment distance: insertions, deletions,
    /// substitutions and adjacent transpositions each cost 1.
    func damerauLevenshteinDistance(_ lhs: String, _ rhs: String) -> Int {
        let source = Array(lhs)
        let target = Array(rhs)
        if source.isEmpty { return target.count }
        if target.isEmpty { return source.count }

        var matrix = Array(
            repeating: Array(repeating: 0, count: target.count + 1),
            count: source.count + 1
        )
        for row in 0 ... source.count { matrix[row][0] = row }
        for column in 0 ... target.count { matrix[0][column] = column }

        for row in 1 ... source.count {
            for column in 1 ... target.count {
                let cost = source[row - 1] == target[column - 1] ? 0 : 1
                var value = min(
                    matrix[row - 1][column] + 1,
                    matrix[row][column - 1] + 1,
                    matrix[row - 1][column - 1] + cost
                )
                if row > 1, column > 1,
                   source[row - 1] == target[column - 2],
                   source[row - 2] == target[column - 1] {
                    value = min(value, matrix[row - 2][column - 2] + 1)
                }
                matrix[row][column] = value
            }
        }
        return matrix[source.count][target.count]
    }

    // MARK: Private

    private let completionBonus = 0.1
    private let preferredBonus = 0.2

    private func isPossessive(_ word: String) -> Bool {
        word.hasSuffix("'s") || word.hasSuffix("’s")
    }
}
