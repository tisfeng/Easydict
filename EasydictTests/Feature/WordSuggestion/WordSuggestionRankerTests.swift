//
//  WordSuggestionRankerTests.swift
//  EasydictTests
//
//  Created by Anson on 2026/11/20.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation
import Testing

@testable import Easydict

// MARK: - WordSuggestionRankerTests

@Suite("Word Suggestion Ranker", .tags(.utilities, .unit))
struct WordSuggestionRankerTests {
    // MARK: Internal

    @Test("Exact match always leads")
    func testExactMatchLeads() {
        #expect(ranker.similarity("modesty", "modesty") == 2)
        #expect(ranker.similarity("modesty", "modest") < 1)
    }

    @Test("Spell checker order breaks near ties")
    func testPreferredOrderBreaksTies() {
        let ranked = ranker.rank(["mycology", "psychology"], for: "sycology", preferred: ["psychology", "mycology"])
        #expect(ranked == ["psychology", "mycology"])
    }

    @Test("Ranking keeps case variants and drops possessives")
    func testRankDeduplicatesCaseSensitively() {
        let ranked = ranker.rank(["march", "March", "march", "March's"], for: "march")
        #expect(ranked == ["march", "March"])
    }

    @Test(
        "Recognizes plain inflections only",
        arguments: [
            ("promises", "promise", true),
            ("studies", "study", true),
            ("decided", "decide", true),
            ("stopping", "stop", true),
            ("decision", "decide", false),
            ("decide", "decide", false),
        ]
    )
    func testInflections(candidate: String, word: String, expected: Bool) {
        #expect(ranker.isInflection(candidate, of: word) == expected)
    }

    @Test("Damerau-Levenshtein counts a transposition as one edit")
    func testTransposition() {
        #expect(ranker.damerauLevenshteinDistance("recieve", "receive") == 1)
        #expect(ranker.damerauLevenshteinDistance("fonetic", "phonetic") == 2)
    }

    @Test("A completion matches its typed prefix")
    func testMatchedOffsetsForPrefix() {
        #expect(ranker.matchedOffsets(of: "investment", input: "inves") == IndexSet(integersIn: 0 ..< 5))
        #expect(ranker.matchedOffsets(of: "Anne", input: "anne") == IndexSet(integersIn: 0 ..< 4))
    }

    @Test("A correction matches the letters an edit alignment keeps")
    func testMatchedOffsetsForCorrection() {
        // fonetic → phonetic: `f` became `ph`, `onetic` is kept.
        #expect(ranker.matchedOffsets(of: "phonetic", input: "fonetic") == IndexSet(integersIn: 2 ..< 8))
        // recieve → receive: only one letter of the swapped `ie` pair can line up.
        let offsets = ranker.matchedOffsets(of: "receive", input: "recieve")
        #expect(offsets.isSuperset(of: [0, 1, 2, 5, 6]))
        #expect(offsets.count == 6)
    }

    @Test("Nothing matches when either side is empty")
    func testMatchedOffsetsForEmptyInput() {
        #expect(ranker.matchedOffsets(of: "test", input: "").isEmpty)
        #expect(ranker.matchedOffsets(of: "", input: "test").isEmpty)
    }

    // MARK: Private

    private let ranker = WordSuggestionRanker()
}
