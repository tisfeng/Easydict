//
//  MWDictServiceTests.swift
//  EasydictTests
//
//  Created by wanzaiqidao on 2026/11/09.
//

@testable import Easydict
import Foundation
import Testing

// MARK: - MWDictServiceTests

@Suite("Merriam-Webster Service", .tags(.unit), .timeLimit(.minutes(1)))
struct MWDictServiceTests {
    @Test("Accepts single English headwords only")
    func singleWordGate() {
        #expect(DictionarySupport.isSingleEnglishWord("develop"))
        #expect(DictionarySupport.isSingleEnglishWord("well-known"))
        #expect(!DictionarySupport.isSingleEnglishWord("two words"))
        #expect(!DictionarySupport.isSingleEnglishWord("中文"))
    }

    @Test("Maps the entry into site-ordered native parts")
    func makeWordResultOrder() {
        let entry = MWDictEntry(
            headword: "develop",
            partOfSpeech: "verb",
            pronunciations: ["di-ˈve-ləp"],
            wordForms: ["developed", "developing", "develops"],
            sections: [
                MWDictSection(label: "transitive verb", senses: [
                    MWDictSense(
                        number: "1",
                        definition: ": to work out the possibilities of",
                        examples: ["develop an idea"]
                    ),
                    MWDictSense(number: "2", definition: ": to create or produce", examples: []),
                ]),
                MWDictSection(label: "intransitive verb", senses: [
                    MWDictSense(number: "1", definition: ": to become apparent", examples: []),
                ]),
            ],
            synonyms: ["grow", "mature"],
            firstKnownUse: nil,
            etymology: nil,
            runOns: ["developable adjective"]
        )

        let wordResult = MWDictService().makeWordResult(
            entry: entry,
            word: "develop",
            sentences: ["They welcomed us with a warm hello."]
        )
        let parts = wordResult.parts ?? []

        #expect(parts.map(\.part) == [
            "",
            "",
            "1",
            "        ⦁",
            "2",
            "",
            "1",
            "",
            "",
            "        ⦁",
        ])
        #expect(parts[7].means == ["developable adjective"])
        #expect(parts[8].means == ["𝗘𝘅𝗮𝗺𝗽𝗹𝗲𝘀 𝗶𝗻 𝗮 𝗦𝗲𝗻𝘁𝗲𝗻𝗰𝗲"])
        #expect(parts[9].means == ["They welcomed us with a warm hello."])
        #expect(parts[0].means == ["developed; developing; develops"])
        #expect(parts[1].means == ["transitive verb"])
        #expect(parts[2].means == [": to work out the possibilities of"])
        #expect(parts[3].means == ["develop an idea"])
        #expect(wordResult.phonetics?.first?.value == "di-ˈve-ləp")
        #expect(wordResult.synonyms?.first?.means == ["grow", "mature"])
    }

    @Test("Indents subsenses and examples like the official page")
    func nestedSenseLayout() {
        let entry = MWDictEntry(
            headword: "absorb",
            partOfSpeech: "verb",
            pronunciations: [],
            wordForms: [],
            sections: [
                MWDictSection(label: "transitive verb", senses: [
                    MWDictSense(number: "1 a", definition: ": top level", examples: ["top example"]),
                    MWDictSense(number: "1 b", definition: ": lettered", examples: ["lettered example"]),
                    MWDictSense(number: "2 b (1)", definition: ": parenthesized", examples: ["parenthesized example"]),
                    MWDictSense(number: "2 b (2)", definition: ": deeper", examples: ["deeper example"]),
                ]),
            ],
            synonyms: [],
            firstKnownUse: nil,
            etymology: nil,
            runOns: []
        )

        let parts = MWDictService().makeWordResult(entry: entry, word: "absorb").parts ?? []

        #expect(parts.map(\.part) == [
            "",
            "1 a",
            "        ⦁",
            "    b",
            "            ⦁",
            "    b (1)",
            "            ⦁",
            "        (2)",
            "                ⦁",
        ])
        #expect(parts[2].means == ["top example"])
        #expect(parts[4].means == ["lettered example"])
        #expect(parts[6].means == ["parenthesized example"])
        #expect(parts[8].means == ["deeper example"])
    }
}
