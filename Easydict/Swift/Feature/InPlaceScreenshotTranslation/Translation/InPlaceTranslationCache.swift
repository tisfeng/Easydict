//
//  InPlaceTranslationCache.swift
//  Easydict
//
//  Created by Eric Pan on 2026/8/30.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation

// MARK: - InPlaceTranslationCacheKey

/// Isolates cached translations by normalized text, actual languages, and provider instance.
struct InPlaceTranslationCacheKey: Hashable, Sendable {
    // MARK: Lifecycle

    init(
        sourceText: String,
        sourceLanguage: Language,
        targetLanguage: Language,
        serviceIdentifier: String
    ) {
        self.sourceText = InPlaceTextNormalization.normalize(sourceText)
        self.sourceLanguageIdentifier = sourceLanguage.rawValue
        self.targetLanguageIdentifier = targetLanguage.rawValue
        self.serviceIdentifier = serviceIdentifier
    }

    // MARK: Internal

    let sourceText: String
    let sourceLanguageIdentifier: String
    let targetLanguageIdentifier: String
    let serviceIdentifier: String
}

// MARK: - InPlaceTranslationCache

/// A bounded in-memory LRU cache cleared when its owning translation session closes.
struct InPlaceTranslationCache: Sendable {
    // MARK: Lifecycle

    init(maximumEntryCount: Int = 256, maximumCharacterCount: Int = 2 * 1_024 * 1_024) {
        self.maximumEntryCount = max(1, maximumEntryCount)
        self.maximumCharacterCount = max(1, maximumCharacterCount)
    }

    // MARK: Internal

    private(set) var count = 0
    private(set) var characterCount = 0

    mutating func value(for key: InPlaceTranslationCacheKey) -> String? {
        guard var entry = entries[key] else { return nil }
        accessCounter &+= 1
        entry.lastAccess = accessCounter
        entries[key] = entry
        return entry.value
    }

    mutating func insert(_ value: String, for key: InPlaceTranslationCacheKey) {
        if let existing = entries.removeValue(forKey: key) {
            characterCount -= existing.characterCount
        }
        accessCounter &+= 1
        let entry = Entry(
            value: value,
            characterCount: key.sourceText.count + value.count,
            lastAccess: accessCounter
        )
        entries[key] = entry
        characterCount += entry.characterCount
        evictIfNeeded()
        count = entries.count
    }

    mutating func removeAll() {
        entries.removeAll(keepingCapacity: false)
        count = 0
        characterCount = 0
        accessCounter = 0
    }

    // MARK: Private

    /// One value plus its LRU accounting metadata.
    private struct Entry: Sendable {
        let value: String
        let characterCount: Int
        var lastAccess: UInt64
    }

    private let maximumEntryCount: Int
    private let maximumCharacterCount: Int
    private var entries: [InPlaceTranslationCacheKey: Entry] = [:]
    private var accessCounter: UInt64 = 0

    private mutating func evictIfNeeded() {
        while entries.count > maximumEntryCount || characterCount > maximumCharacterCount {
            guard let leastRecent = entries.min(by: { $0.value.lastAccess < $1.value.lastAccess })
            else {
                return
            }
            characterCount -= leastRecent.value.characterCount
            entries.removeValue(forKey: leastRecent.key)
        }
    }
}
