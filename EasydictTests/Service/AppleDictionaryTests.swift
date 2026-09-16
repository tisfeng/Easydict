//
//  AppleDictionaryTests.swift
//  EasydictTests
//
//  Created by Codex on 2026/9/16.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation
import Testing

@testable import Easydict

// MARK: - AppleDictionaryTests

@Suite("Apple Dictionary", .tags(.apple, .unit))
struct AppleDictionaryTests {
    @Test("Ignores unavailable dictionary names")
    func ignoresUnavailableDictionaryNames() {
        let service = AppleDictionary(dictionaryNames: ["com.easydict.missing-dictionary"])

        #expect(service.appleDictionaryNames.isEmpty)
    }

    @Test("Handles dictionaries without a resource URL")
    func handlesDictionaryWithoutResourceURL() {
        let service = AppleDictionary(dictionaryNames: [])

        let html = service.queryAllIframeHTMLResult(
            ofWord: "test",
            fromToLanguages: nil,
            inDictionaries: [MissingURLDictionary()]
        )

        #expect(html?.contains("Dictionary definition") == true)
    }
}

// MARK: - MissingURLDictionary

private final class MissingURLDictionary: TTTDictionary {
    override var name: String { "Missing URL Dictionary" }
    override var shortName: String { "Missing URL" }
    override var identifier: String? { "com.easydict.missing-url" }
    override var dictionaryURL: URL? { nil }

    override func entries(forSearchTerm term: String) -> [TTTDictionaryEntry] {
        [StubDictionaryEntry()]
    }
}

// MARK: - StubDictionaryEntry

private final class StubDictionaryEntry: TTTDictionaryEntry {
    override var headword: String { "test" }
    override var text: String { "Dictionary definition" }
    override var htmlWithAppCSS: String { "<div>Dictionary definition</div>" }
}
