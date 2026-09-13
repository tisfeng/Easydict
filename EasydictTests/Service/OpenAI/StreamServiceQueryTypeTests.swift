//
//  StreamServiceQueryTypeTests.swift
//  EasydictTests
//
//  Created by rosyouu on 2026/09/13.
//  Copyright © 2026 izual. All rights reserved.
//

import Defaults
@testable import Easydict
import Foundation
import Testing

/// Tests how `StreamService.queryType(text:from:to:)` routes text to the
/// dictionary, sentence-analysis and translation prompts.
///
/// `ClaudeCodeService` is used as the concrete `StreamService`: it has no API key
/// or network dependency, and the routing under test lives in the base class.
@Suite("StreamService Query Type", .serialized)
struct StreamServiceQueryTypeTests {
    // MARK: Internal

    @Test("Japanese words and sentences are routed to the dictionary and sentence prompts")
    func japaneseRouting() {
        let service = makeService()
        defer { restore(service) }
        Defaults[service.dictionaryKey] = "1"
        Defaults[service.sentenceKey] = "1"

        #expect(queryType(service, "見つめる") == .dictionary)
        #expect(queryType(service, "見つめた") == .dictionary)
        #expect(queryType(service, "見つめ直す") == .dictionary)
        #expect(queryType(service, "行きます") == .dictionary)
        #expect(queryType(service, "励ます") == .dictionary)
        #expect(queryType(service, "私は学生です") == .sentence)
        #expect(queryType(service, "お元気ですか") == .sentence)
        #expect(queryType(service, "東京に行きます") == .sentence)
        #expect(queryType(service, "日本文化を外から見つめ直す。") == .sentence)
        #expect(queryType(service, "英語を、日本文化を外から見つめ直す手段と捉えている") == .sentence)
    }

    @Test("Japanese routing falls back to translation when the modes are off")
    func japaneseRoutingRespectsDisabledModes() {
        let service = makeService()
        defer { restore(service) }
        Defaults[service.dictionaryKey] = "0"
        Defaults[service.sentenceKey] = "0"

        #expect(queryType(service, "見つめる") == .translation)
        #expect(queryType(service, "私は学生です") == .translation)
    }

    @Test("English routing is unchanged")
    func englishRouting() {
        let service = makeService()
        defer { restore(service) }
        Defaults[service.dictionaryKey] = "1"
        Defaults[service.sentenceKey] = "1"

        #expect(queryType(service, "resilient", from: .english) == .dictionary)
        #expect(queryType(service, "It is hard to say.", from: .english) == .sentence)
    }

    @Test("The shared classifier still treats Japanese as translation for other services")
    func sharedClassifierUnchangedForJapanese() {
        #expect("見つめる".queryType(language: .japanese, maxWordCount: 1) == .translation)
        #expect("私は学生です".queryType(language: .japanese, maxWordCount: 1) == .translation)
    }

    // MARK: Private

    private func makeService() -> ClaudeCodeService {
        let service = ClaudeCodeService()
        service.uuid = "test-\(UUID().uuidString)"
        return service
    }

    /// Removes the per-instance keys written by a test so they do not accumulate.
    private func restore(_ service: ClaudeCodeService) {
        Defaults.reset(service.dictionaryKey, service.sentenceKey)
    }

    private func queryType(
        _ service: ClaudeCodeService,
        _ text: String,
        from: Language = .japanese
    )
        -> EZQueryTextType {
        service.queryType(text: text, from: from, to: .simplifiedChinese)
    }
}
