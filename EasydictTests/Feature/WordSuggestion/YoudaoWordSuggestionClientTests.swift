//
//  YoudaoWordSuggestionClientTests.swift
//  EasydictTests
//
//  Created by Anson on 2026/11/20.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation
import Testing

@testable import Easydict

// MARK: - YoudaoWordSuggestionClientTests

@Suite("Youdao Word Suggestion Client", .tags(.utilities))
@MainActor
struct YoudaoWordSuggestionClientTests {
    // MARK: Internal

    @Test("Takes the first part of speech and its first senses", .tags(.unit))
    func testParseExplain() {
        let definition = client.parseExplain("v. 促使，导致；鼓励，提示；提醒; adj. 迅速的")
        #expect(definition == WordDefinition(partOfSpeech: "v.", meaning: "促使，导致；鼓励，提示"))
    }

    @Test("Drops register labels and only a trailing ellipsis", .tags(.unit))
    func testParseExplainCleansMeaning() {
        #expect(client.parseExplain("n. <美>电梯…")?.meaning == "电梯")
        #expect(client.parseExplain("prep. 在……之上")?.meaning == "在……之上")
        #expect(client.parseExplain("一箭双雕") == WordDefinition(partOfSpeech: nil, meaning: "一箭双雕"))
    }

    @Test("Phrasal verbs lead and placeholder phrases go last", .tags(.unit))
    func testRankPhrases() {
        let items: [(headword: String, translation: String?)] = [
            ("take some", "不大容易"),
            ("take care of oneself", "照顾自己"),
            ("take part", "参与"),
            ("take part in", "参加"),
            ("take on", "承担；呈现"),
            ("take up", "拿起；开始从事"),
            ("take…away", "拿走"),
            ("take on", "重复"),
            ("take off", nil),
            ("make up", "弥补"),
        ]
        let phrases = client.rankPhrases(items, for: "take").map(\.word)
        #expect(phrases == ["take on", "take up", "take some", "take part", "take part in", "take care of oneself"])
    }

    @Test("Same-root words come from the signed word detail request", .tags(.integration))
    func testRelatedWordsMatchTheQuery() async {
        // Unsigned requests answered `modesty` with another word's entry, such as `indignant`.
        let related = await client.relatedWords(for: "modesty").map(\.word)
        #expect(related.contains("modest"))
        #expect(!related.contains("indignant"))
    }

    @Test("Chinese input lists English words", .tags(.integration))
    func testTranslations() async {
        let stubborn = await client.translations(for: "固执").map(\.word)
        #expect(stubborn.contains("stubborn"))
        // Unsigned requests answered `银行` with entries such as `R` or `convoy`.
        let bank = await client.translations(for: "银行").map(\.word)
        #expect(bank.contains("bank"))
    }

    // MARK: Private

    private let client = YoudaoWordSuggestionClient()
}
