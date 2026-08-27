//
//  QueryReplayRequestTests.swift
//  EasydictTests
//
//  Created by Eric Pan on 2026/8/26.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation
import Testing

@testable import Easydict

/// Verifies that history and favorite records retain the complete language pair used for replay.
@Suite("Query Replay Requests", .tags(.unit))
struct QueryReplayRequestTests {
    @Test("Replay request preserves text and explicit language pair")
    func replayRequestPreservesExplicitLanguagePair() {
        let record = QueryRecord(
            queryText: "hello",
            queryFromLanguage: .english,
            queryToLanguage: .simplifiedChinese
        )

        let request = QueryReplayRequest(record: record)

        #expect(request.text == "hello")
        #expect(request.sourceLanguage == .english)
        #expect(request.targetLanguage == .simplifiedChinese)
    }

    @Test("Replay request preserves automatic source language")
    func replayRequestPreservesAutomaticSourceLanguage() {
        let record = QueryRecord(
            queryText: "bonjour",
            queryFromLanguage: .auto,
            queryToLanguage: .english
        )

        let request = QueryReplayRequest(record: record)

        #expect(request.sourceLanguage == .auto)
        #expect(request.targetLanguage == .english)
    }
}
