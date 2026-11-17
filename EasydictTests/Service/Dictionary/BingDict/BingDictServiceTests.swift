//
//  BingDictServiceTests.swift
//  EasydictTests
//
//  Created by wanzaiqidao on 2026/11/04.
//

@testable import Easydict
import Foundation
import Testing

// MARK: - BingDictServiceTests

@Suite("Bing Dict Service", .tags(.unit), .timeLimit(.minutes(1)))
struct BingDictServiceTests {
    @Test("Accepts single English headwords only")
    func singleWordGate() {
        #expect(DictionarySupport.isSingleEnglishWord("develop"))
        #expect(DictionarySupport.isSingleEnglishWord("well-known"))
        #expect(DictionarySupport.isSingleEnglishWord("don't"))
        #expect(DictionarySupport.isSingleEnglishWord("3D"))
        #expect(!DictionarySupport.isSingleEnglishWord("two words"))
        #expect(!DictionarySupport.isSingleEnglishWord("中文"))
        #expect(!DictionarySupport.isSingleEnglishWord("C++"))
        #expect(!DictionarySupport.isSingleEnglishWord(""))
    }

    @Test("Maps the entry into site-ordered native parts")
    func makeWordResultOrderAndLabels() {
        let entry = BingDictWordEntry(
            headword: "run",
            phoneticUS: "rʌn",
            phoneticUK: nil,
            quickText: "v. 跑； n. 奔跑；",
            quickRows: [
                BingDictQuickRow(label: "v.", values: "跑；奔跑"),
                BingDictQuickRow(label: "n.", values: "奔跑"),
            ],
            wordForms: [
                BingDictWordForm(label: "复数", value: "formulas"),
                BingDictWordForm(label: "复数", value: "formulae"),
            ],
            collocations: [BingDictCollocation(label: "v.+n.", items: ["run a business"])],
            synonyms: [BingDictCollocation(label: "v.", items: ["sprint"])],
            antonyms: [BingDictCollocation(label: "v.", items: ["walk"])],
            senseGroups: [
                BingDictSenseGroup(pos: "v.", senses: [
                    BingDictSense(
                        index: "1.",
                        grammar: "[t]",
                        complement: "~ sth",
                        chinese: "跑",
                        english: "to move fast"
                    ),
                ]),
                BingDictSenseGroup(pos: "n.", senses: [
                    BingDictSense(index: "1.", grammar: "", complement: "", chinese: "奔跑", english: "a run"),
                ]),
            ]
        )

        let wordResult = BingDictService().makeWordResult(entry: entry, word: "run")
        let parts = wordResult.parts ?? []

        #expect(parts.map(\.part) == ["v.", "n.", "v. 1.", "n. 1."])
        #expect(parts[2].means == ["[t] ~ sth  跑  to move fast"])
        #expect(wordResult.phonetics?.count == 1)

        #expect(wordResult.exchanges?.map(\.name) == ["复数"])
        #expect(wordResult.exchanges?.first?.words == ["formulas", "formulae"])
        #expect(wordResult.collocation?.map(\.part) == ["v.+n."])
        #expect(wordResult.collocation?.first?.means == ["run a business"])
        #expect(wordResult.synonyms?.map(\.part) == ["v."])
        #expect(wordResult.synonyms?.first?.means == ["sprint"])
        #expect(wordResult.antonyms?.map(\.part) == ["v."])
        #expect(wordResult.antonyms?.first?.means == ["walk"])
    }
}
