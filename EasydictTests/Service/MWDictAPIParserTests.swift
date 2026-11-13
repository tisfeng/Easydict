//
//  MWDictAPIParserTests.swift
//  EasydictTests
//
//  Created by wanzaiqidao on 2026/11/09.
//

@testable import Easydict
import Foundation
import Testing

// MARK: - MWDictAPIParserTests

@Suite("Merriam-Webster API Parser", .tags(.unit), .timeLimit(.minutes(1)))
struct MWDictAPIParserTests {
    // MARK: Internal

    @Test("Parses headword, part of speech, pronunciation and inflections")
    func parsesHeader() throws {
        let data = Data(Self.developJSON.utf8)
        let entry = try #require(MWDictAPIParser.parse(data))

        #expect(entry.headword == "develop")
        #expect(entry.partOfSpeech == "verb")
        #expect(entry.pronunciations == ["di-ˈve-ləp"])
        #expect(entry.wordForms == ["developed", "developing", "develops"])
        #expect(entry.runOns == ["developable adjective"])
    }

    @Test("Parses verb sections, numbered senses, subsenses and examples")
    func parsesSections() throws {
        let data = Data(Self.developJSON.utf8)
        let entry = try #require(MWDictAPIParser.parse(data))

        #expect(entry.sections.map(\.label) == ["transitive verb", "intransitive verb"])
        let senses = try #require(entry.sections.first?.senses)
        #expect(senses.map(\.number) == ["1", "2", "2 a"])
        #expect(senses[0].definition == ": to work out the possibilities of")
        #expect(senses[0].examples == ["develop an idea"])
        #expect(senses[1].examples == ["develop software"])
        #expect(entry.sections.last?.senses.first?.definition.contains("→ used interjectionally in greeting") == true)
        #expect(entry.sections.last?.senses.first?.examples == ["hello there"])
    }

    @Test("Parses synonyms, first known use and best translation")
    func parsesMetadata() throws {
        let data = Data(Self.developJSON.utf8)
        let entry = try #require(MWDictAPIParser.parse(data))

        #expect(entry.synonyms == ["grow", "mature"])
        #expect(entry.firstKnownUse == "1653, in the meaning defined at sense 1")
        #expect(entry.bestTranslation == "to work out the possibilities of")
    }

    @Test("Plain text contains every layer")
    func plainText() throws {
        let data = Data(Self.developJSON.utf8)
        let entry = try #require(MWDictAPIParser.parse(data))
        let text = entry.plainText

        #expect(text.contains("develop"))
        #expect(text.contains("Inflections: developed; developing; develops"))
        #expect(text.contains("transitive verb"))
        #expect(text.contains("1 : to work out the possibilities of"))
        #expect(text.contains("— develop an idea"))
        #expect(text.contains("Synonyms: grow, mature"))
    }

    @Test("Returns nil for spelling suggestions")
    func suggestionsReturnNil() {
        let data = Data(#"["develope", "develops", "developed"]"#.utf8)
        #expect(MWDictAPIParser.parse(data) == nil)
    }

    @Test("Extracts learner sentence examples and ignores invalid responses")
    func extractSentences() {
        let learnersJSON = """
        [
          {
            "meta": { "id": "hello" },
            "def": [
              { "sseq": [ [ [ "sense", { "dt": [
                [ "text", "{bc}an expression of greeting" ],
                [ "vis", [
                  { "t": "They welcomed us with a warm {wi}hello{/wi}." },
                  { "t": "we said our {wi}hellos{/wi} and got right down to business" }
                ] ]
              ] } ] ] ] }
            ]
          }
        ]
        """
        #expect(MWDictAPIParser.extractSentences(Data(learnersJSON.utf8)) == [
            "They welcomed us with a warm hello.",
            "we said our hellos and got right down to business",
        ])

        let invalid = Data("Invalid API key. Not subscribed for this reference.".utf8)
        #expect(MWDictAPIParser.extractSentences(invalid).isEmpty)
    }

    @Test("Converts running-text markup to plain text")
    func stripMarkup() {
        let raw = "{bc}to {it}grow{/it} {sx|bigger|bigger||} and {a_link|stronger}"
        #expect(MWDictAPIParser.stripMarkup(raw) == ": to grow bigger and stronger")
    }

    // MARK: Private

    /// Trimmed response for `develop`, following the documented Collegiate
    /// schema: verb dividers, numbered senses, binding subsenses, verbal
    /// illustrations, synonyms and first known use.
    private static let developJSON = """
    [
      {
        "meta": { "id": "develop", "stems": ["develop", "developable", "developed", "developing", "develops"], "src": "collegiate" },
        "ins": [ { "if": "de*vel*oped" }, { "if": "de*vel*op*ing" }, { "if": "de*vel*ops" } ],
        "uros": [ { "ure": "de*vel*op*able", "fl": "adjective" } ],
        "hwi": { "hw": "de*vel*op", "prs": [ { "mw": "di-ˈve-ləp", "sound": { "audio": "develo01" } } ] },
        "fl": "verb",
        "def": [
          {
            "vd": "transitive verb",
            "sseq": [
              [
                [ "sense", { "sn": "1",
                  "dt": [
                    [ "text", " {bc}to work out the possibilities of" ],
                    [ "vis", [ { "t": "{wi}develop{/wi} an idea" } ] ]
                  ] } ]
              ],
              [
                [ "sense", { "sn": "2",
                  "dt": [
                    [ "text", " {bc}to create or produce especially by deliberate effort over time" ],
                    [ "vis", [ { "t": "{wi}develop{/wi} software" } ] ]
                  ] } ],
                [ "bs", { "sense": { "sn": "2 a",
                  "dt": [ [ "text", " {bc}to make active or promote the growth of" ] ] } } ]
              ]
            ]
          },
          {
            "vd": "intransitive verb",
            "sseq": [
              [
                [ "sense", { "sn": "1",
                  "dt": [
                    [ "text", " {bc}to become gradually apparent" ],
                    [ "uns", [
                      [
                        [ "text", "used interjectionally in greeting" ],
                        [ "vis", [ { "t": "{wi}hello{/wi} there" } ] ]
                      ]
                    ] ]
                  ] } ]
              ]
            ]
          }
        ],
        "syns": [ [ [ "sense", { "syn_list": [ [ { "wd": "grow" }, { "wd": "mature" } ] ] } ] ] ],
        "date": "1653, in the meaning defined at sense 1"
      }
    ]
    """
}

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
            "        │",
            "2",
            "",
            "1",
            "",
            "",
            "        │",
        ])
        #expect(parts[7].means == ["developable adjective"])
        #expect(parts[8].means == ["Examples in a Sentence"])
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
            "        │",
            "    b",
            "            │",
            "    b (1)",
            "            │",
            "        (2)",
            "                │",
        ])
        #expect(parts[2].means == ["top example"])
        #expect(parts[4].means == ["lettered example"])
        #expect(parts[6].means == ["parenthesized example"])
        #expect(parts[8].means == ["deeper example"])
    }
}
