//
//  AppleDictionaryGlossClientTests.swift
//  EasydictTests
//
//  Created by Anson on 2026/11/20.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation
import Testing

@testable import Easydict

// MARK: - AppleDictionaryGlossClientTests

@Suite("Apple Dictionary Gloss Client", .tags(.apple))
@MainActor
struct AppleDictionaryGlossClientTests {
    // MARK: Internal

    @Test("Keeps Chinese terms of the first senses without pinyin, notes or examples", .tags(.unit))
    func testParseNumberedSenses() {
        let text = """
        stubborn | BrE ˈstʌb(ə)n, AmE ˈstəbərn | adjective ① (difficult to influence) 执拗的 zhíniù de ‹person›; \
        倔强的 juéjiàng de ‹animal›; 固执的 gùzhí de ‹government, attitude, behaviour›▸ stubborn resistance/refusal \
        顽强的抵抗/顽固的拒绝 ② (difficult to remove) 难开的 nán kāi de ‹door, lock›; 难去除的 nán qùchú de ‹stain›\
        ▸ a stubborn cough/fever 久治不愈的咳嗽/发烧 ③ 第三义 dì sān yì
        """
        #expect(client.parse(text) == WordDefinition(
            partOfSpeech: "adj.",
            meaning: "执拗的，倔强的，固执的；难开的，难去除的"
        ))
    }

    @Test("Reads an unnumbered sense and a part of speech after the headword", .tags(.unit))
    func testParseSingleSenseAndHeadFieldPartOfSpeech() {
        let single = "makeshift | BrE ˈmeɪkʃɪft, AmE ˈmeɪkˌʃɪft | adjective 临时替代的 línshí tìdài de▸ a makeshift bed 临时的床"
        #expect(client.parse(single) == WordDefinition(partOfSpeech: "adj.", meaning: "临时替代的"))

        let headPartOfSpeech = """
        upgrade A. transitive verb | BrE ˌʌpˈɡreɪd, AmE ˈəpˌɡreɪd | ① (improve) 改进 gǎijìn ‹product, machinery›\
        ② (raise level of) 提升 tíshēng ‹post›; 提高 tígāo ‹skill›
        """
        #expect(client.parse(headPartOfSpeech) == WordDefinition(partOfSpeech: "v.", meaning: "改进；提升，提高"))
    }

    @Test("Rejects text without an entry body or Chinese terms", .tags(.unit))
    func testParseRejectsUnusableText() {
        #expect(client.parse("modesty") == nil)
        #expect(client.parse("word | BrE wɜːd | noun (English only)") == nil)
    }

    @Test(
        "Looks up the installed Oxford English-Chinese dictionary",
        .tags(.integration, .requiresLocalEnvironment)
    )
    func testInstalledDictionary() throws {
        try #require(client.isAvailable, "Enable 牛津英汉汉英词典 in Dictionary > Settings")
        let definition = client.definition(for: "stubborn")
        #expect(definition?.partOfSpeech == "adj.")
        #expect(definition?.meaning.contains("固执的") == true)
    }

    // MARK: Private

    private let client = AppleDictionaryGlossClient()
}
