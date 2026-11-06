//
//  BingDictHTMLParserTests.swift
//  EasydictTests
//
//  Created by wanzaiqidao on 2026/11/04.
//

@testable import Easydict
import Foundation
import Testing

// MARK: - BingDictHTMLParserTests

@Suite("Bing Dict HTML Parser", .tags(.unit), .timeLimit(.minutes(1)))
struct BingDictHTMLParserTests {
    // MARK: Internal

    @Test("Parses headword, phonetics and quick senses")
    func parsesHeader() throws {
        let entry = try #require(BingDictHTMLParser.parse(Self.plateauHTML))

        #expect(entry.headword == "plateau")
        #expect(entry.phoneticUS == "plæˈtoʊ")
        #expect(entry.phoneticUK == "ˈplætoʊ")
        #expect(entry.quickText?.contains("网络释义：") == true)
    }

    @Test("Splits quick senses into labeled rows")
    func parsesQuickRows() throws {
        let entry = try #require(BingDictHTMLParser.parse(Self.plateauHTML))

        let rows = entry.quickRows
        #expect(rows.map(\.label) == ["n.", "v.", "Web"])
        #expect(rows.first?.values == "高原；台地；平台期；高原期")
        #expect(rows.last?.values == "高地；坪；高原州")
    }

    @Test("Parses every word form and collocation group")
    func parsesFormsAndCollocations() throws {
        let entry = try #require(BingDictHTMLParser.parse(Self.plateauHTML))

        #expect(entry.wordForms.map(\.label) == ["一般现在时", "现在分词", "过去式", "复数"])
        #expect(entry.wordForms.map(\.value) == ["plateaus", "plateauing", "plateaued", "plateaux"])
        let collocation = try #require(entry.collocations.first)
        #expect(collocation.label == "Adj.+n.")
        #expect(collocation.items == ["northern plateau", "southern plateau"])
    }

    @Test("Keeps every value of a repeated form label")
    func keepsRepeatedFormLabels() throws {
        let entry = try #require(BingDictHTMLParser.parse(Self.repeatedFormHTML))

        #expect(entry.wordForms.map(\.label) == ["复数", "复数"])
        #expect(entry.wordForms.map(\.value) == ["formulas", "formulae"])
    }

    @Test("Parses synonyms and antonyms")
    func parsesThesaurus() throws {
        let plateau = try #require(BingDictHTMLParser.parse(Self.plateauHTML))
        let synonym = try #require(plateau.synonyms.first)
        #expect(synonym.label == "n.")
        #expect(synonym.items == ["table", "upland", "highland", "hill", "mesa"])

        let develop = try #require(BingDictHTMLParser.parse(Self.antonymHTML))
        let antonym = try #require(develop.antonyms.first)
        #expect(antonym.label == "v.")
        #expect(antonym.items == ["contract", "outline"])
    }

    @Test("Parses grammar labels, complement patterns and pos groups")
    func parsesGrammarAndComplement() throws {
        let entry = try #require(BingDictHTMLParser.parse(Self.plateauHTML))

        #expect(entry.senseGroups.map(\.pos) == ["n.", "v."])
        let sense = try #require(entry.senseGroups.last?.senses.first)
        #expect(sense.index == "1.")
        #expect(sense.grammar == "[i]")
        #expect(sense.complement == "~ out. ~ off")
        #expect(sense.chinese == "进入停滞期")
        #expect(sense.english == "to stay at a steady level")
        #expect(entry.bestTranslation == "高原")
    }

    @Test("Decodes numeric HTML references")
    func decodesNumericEntities() throws {
        let entry = try #require(BingDictHTMLParser.parse(Self.entityHTML))
        let sense = try #require(entry.senseGroups.first?.senses.first)

        #expect(sense.chinese == "花费")
        #expect(sense.english == "I paid £10 and left")
    }

    @Test("Plain text contains every layer for copy actions")
    func plainText() throws {
        let entry = try #require(BingDictHTMLParser.parse(Self.plateauHTML))
        let text = entry.plainText

        #expect(text.contains("美 [plæˈtoʊ]"))
        #expect(text.contains("一般现在时：plateaus"))
        #expect(text.contains("Adj.+n.：northern plateau, southern plateau"))
        #expect(text.contains("同义词：n. table, upland, highland, hill, mesa"))
        #expect(text.contains("v. 1. [i] ~ out. ~ off 进入停滞期 to stay at a steady level"))
    }

    @Test("Returns nil when the page has no bilingual senses")
    func returnsNilWithoutSenses() {
        let html = """
        <meta name="description" content="必应词典为您提供plateau的释义，美[plæˈtoʊ]，英[ˈplætoʊ]，n. 高原" />
        <div class="qdef"><a class="hw bd_clickable_text">plateau</a></div>
        """
        #expect(BingDictHTMLParser.parse(html) == nil)
    }

    // MARK: Private

    /// Trimmed slice of the live `plateau` page (2026-11-04,
    /// https://cn.bing.com/dict/search?q=plateau): meta description, headword,
    /// word forms, one collocation group, the thesaurus block and two sense
    /// rows under two part-of-speech markers.
    private static let plateauHTML = """
    <meta name="description" content="必应词典为您提供plateau的释义，美[plæˈtoʊ]，英[ˈplætoʊ]，n. 高原；台地；平台期；高原期； v. 进入停滞期；达到平稳状态； 网络释义： 高地；坪；高原州； " />
    <div class="qdef"><a class="hw bd_clickable_text" href="/dict/search?q=plateau">plateau</a></div>
    <div class="hd_if"><span class="b_primtxt">一般现在时：</span><a class="p1-5">plateaus</a>&#160;&#160;<span class="b_primtxt">现在分词：</span><a class="p1-5">plateauing</a>&#160;&#160;<span class="b_primtxt">过去式：</span><a class="p1-5">plateaued</a>&#160;&#160;<span class="b_primtxt">复数：</span><a class="p1-5">plateaux</a>&#160;&#160;</div>
    <div class="de_title2 b_dictHighlight">Adj.+n.</div><div class="col_fl"><a><span>northern plateau</span></a><span>,</span><a><span>southern plateau</span></a></div>
    <div id="synoid" style="display:none;"><div class="df_div2"><div class="de_title1 b_dictHighlight">n.</div><div class="col_fl"><a><span>table</span></a><span>,</span><a><span>upland</span></a><span>,</span><a><span>highland</span></a><span>,</span><a><span>hill</span></a><span>,</span><a><span>mesa</span></a></div></div></div>
    <div class="li_sen" id="newLeId">
      <div class="each_seg">
        <div class="li_pos"><div class="pos_lin"><div class="pos">n.</div></div></div>
        <div class="de_seg" id="pos_0"><div class="se_lis"><table>
          <tr class="def_row"><td><div class="se_d b_primtxt">1.</div></td><td><div class="de_co">
            <div class="def_pa"><span class="bil b_primtxt"><a>高原</a></span><span class="val b_regtxt"><a>an</a><span> </span><a>area</a><span> </span><a>of</a><span> </span><a>flat</a><span> </span><a>land</a></span></div>
          </div></td></tr>
        </table></div></div>
        <div class="li_pos"><div class="pos_lin"><div class="pos">v.</div></div></div>
        <div class="de_seg" id="pos_1"><div class="se_lis"><table>
          <tr class="def_row"><td><div class="se_d b_primtxt">1.</div></td><td><div class="de_co">
            <div class="au_def"><span class="gra b_regtxt">[i]</span></div>
            <div class="sen_com"><span class="comple b_regtxt"><span>~</span><span> </span><a>out</a></span><span class="com_sep b_regtxt">.</span><span class="comple b_regtxt"><span>~</span><span> </span><a>off</a></span></div>
            <div class="def_pa"><span class="bil b_primtxt"><a>进入停滞期</a></span><span class="val b_regtxt"><a>to</a><span> </span><a>stay</a><span> </span><a>at</a><span> </span><a>a</a><span> </span><a>steady</a><span> </span><a>level</a></span></div>
          </div></td></tr>
        </table></div></div>
      </div>
    </div>
    """

    /// Repeated form label: live `formula` lists `复数：formulas` and
    /// `复数：formulae`.
    private static let repeatedFormHTML = """
    <div class="hd_if"><span class="b_primtxt">复数：</span><a class="p1-5">formulas</a>&#160;&#160;<span class="b_primtxt">复数：</span><a class="p1-5">formulae</a>&#160;&#160;</div>
    <div class="pos">n.</div>
    <tr class="def_row"><td><div class="se_d b_primtxt">1.</div></td><td><div class="de_co"><div class="def_pa"><span class="bil b_primtxt"><a>公式</a></span><span class="val b_regtxt"><a>a</a><span> </span><a>rule</a></span></div></div></td></tr>
    """

    /// Antonym block from the live `develop` page.
    private static let antonymHTML = """
    <div id="antoid" style="display:none;"><div class="df_div2"><div class="de_title1 b_dictHighlight">v.</div><div class="col_fl"><a><span>contract</span></a><span>,</span><a><span>outline</span></a></div></div></div>
    <div class="pos">v.</div>
    <tr class="def_row"><td><div class="se_d b_primtxt">1.</div></td><td><div class="de_co"><div class="def_pa"><span class="bil b_primtxt"><a>发展</a></span><span class="val b_regtxt"><a>to</a><span> </span><a>grow</a></span></div></div></td></tr>
    """

    /// Numeric references the page emits (`&#163;` = £, `&#160;` = nbsp).
    private static let entityHTML = """
    <div class="pos">v.</div>
    <tr class="def_row"><td><div class="se_d b_primtxt">1.</div></td><td><div class="de_co"><div class="def_pa"><span class="bil b_primtxt"><a>花费</a></span><span class="val b_regtxt"><a>I</a><span> </span><a>paid</a><span> </span><a>&#163;10</a><span> </span><a>and</a><span> </span><a>&#160;</a><span> </span><a>left</a></span></div></div></td></tr>
    """
}

// MARK: - BingDictServiceTests

@Suite("Bing Dict Service", .tags(.unit), .timeLimit(.minutes(1)))
struct BingDictServiceTests {
    @Test("Accepts single English headwords only")
    func singleWordGate() {
        #expect(BingDictService.isSingleEnglishWord("develop"))
        #expect(BingDictService.isSingleEnglishWord("well-known"))
        #expect(BingDictService.isSingleEnglishWord("don't"))
        #expect(BingDictService.isSingleEnglishWord("3D"))
        #expect(!BingDictService.isSingleEnglishWord("two words"))
        #expect(!BingDictService.isSingleEnglishWord("中文"))
        #expect(!BingDictService.isSingleEnglishWord("C++"))
        #expect(!BingDictService.isSingleEnglishWord(""))
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

        #expect(parts.map(\.part) == ["v.", "n.", "变形", "v.+n.", "同义词", "反义词", "v. 1.", "n. 1."])
        #expect(parts[2].means == ["复数: formulas, formulae"])
        #expect(parts[6].means == ["[t] ~ sth  跑  to move fast"])
        #expect(wordResult.phonetics?.count == 1)
    }
}
