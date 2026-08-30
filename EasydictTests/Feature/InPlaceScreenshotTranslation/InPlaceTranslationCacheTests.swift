//
//  InPlaceTranslationCacheTests.swift
//  EasydictTests
//
//  Created by Eric Pan on 2026/8/30.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation
import Testing

@testable import Easydict

/// Verifies cache-key isolation, bounded LRU behavior, and explicit session cleanup.
@Suite("In-place Translation Cache", .tags(.inPlaceTranslation, .unit))
struct InPlaceTranslationCacheTests {
    // MARK: Internal

    @Test("Keys normalize source text but preserve language and provider boundaries")
    func isolatesTranslationContexts() {
        let composed = key(text: "Café\nready", source: .english, target: .simplifiedChinese)
        let decomposed = key(text: "  Cafe\u{301}  ready ", source: .english, target: .simplifiedChinese)
        let anotherTarget = key(text: "Café ready", source: .english, target: .japanese)
        let anotherProvider = key(
            text: "Café ready",
            source: .english,
            target: .simplifiedChinese,
            service: "provider-b"
        )

        #expect(composed == decomposed)
        #expect(composed != anotherTarget)
        #expect(composed != anotherProvider)
    }

    @Test("Reading an entry promotes it before entry-count eviction")
    func evictsLeastRecentlyUsedEntry() {
        var cache = InPlaceTranslationCache(maximumEntryCount: 2, maximumCharacterCount: 1_000)
        let first = key(text: "first")
        let second = key(text: "second")
        let third = key(text: "third")
        cache.insert("one", for: first)
        cache.insert("two", for: second)

        #expect(cache.value(for: first) == "one")
        cache.insert("three", for: third)

        #expect(cache.value(for: first) == "one")
        #expect(cache.value(for: second) == nil)
        #expect(cache.value(for: third) == "three")
        #expect(cache.count == 2)
    }

    @Test("Character budget evicts old entries and rejects one oversized entry")
    func enforcesCharacterBudget() {
        var cache = InPlaceTranslationCache(maximumEntryCount: 10, maximumCharacterCount: 10)
        let first = key(text: "a")
        let second = key(text: "b")
        let third = key(text: "c")
        cache.insert("1234", for: first)
        cache.insert("5678", for: second)
        cache.insert("12", for: third)

        #expect(cache.value(for: first) == nil)
        #expect(cache.value(for: second) == "5678")
        #expect(cache.value(for: third) == "12")
        #expect(cache.count == 2)
        #expect(cache.characterCount == 8)

        let oversized = key(text: "oversized")
        cache.insert("value", for: oversized)

        #expect(cache.value(for: oversized) == nil)
        #expect(cache.characterCount <= 10)
    }

    @Test("Replacing a key updates accounting without adding an entry")
    func replacesExistingValue() {
        var cache = InPlaceTranslationCache(maximumEntryCount: 3, maximumCharacterCount: 100)
        let cacheKey = key(text: "source")
        cache.insert("old", for: cacheKey)
        let oldCount = cache.characterCount

        cache.insert("replacement", for: cacheKey)

        #expect(cache.value(for: cacheKey) == "replacement")
        #expect(cache.count == 1)
        #expect(cache.characterCount == oldCount - 3 + 11)
    }

    @Test("Closing-session cleanup removes values and accounting state")
    func clearsSessionCache() {
        var cache = InPlaceTranslationCache(maximumEntryCount: 3, maximumCharacterCount: 100)
        let cacheKey = key(text: "source")
        cache.insert("translation", for: cacheKey)

        cache.removeAll()

        #expect(cache.value(for: cacheKey) == nil)
        #expect(cache.count == .zero)
        #expect(cache.characterCount == 0)
    }

    // MARK: Private

    private func key(
        text: String,
        source: Language = .english,
        target: Language = .simplifiedChinese,
        service: String = "provider-a"
    )
        -> InPlaceTranslationCacheKey {
        InPlaceTranslationCacheKey(
            sourceText: text,
            sourceLanguage: source,
            targetLanguage: target,
            serviceIdentifier: service
        )
    }
}
