//
//  WordbookModelsTests.swift
//  EasydictTests
//
//  Created by liangkaiwen on 2026/7/13.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation
import Testing

@testable import Easydict

// MARK: - WordbookModelsTests

/// Verifies the wordbook snapshot, entry-key normalization, and repair contract.
@Suite("Wordbook Models", .tags(.wordbook, .unit))
struct WordbookModelsTests {
    @Test("Snapshot v1 round trips through JSON")
    func roundTrip() throws {
        let snapshot = WordbookFixture.snapshot()
        let data = try JSONEncoder().encode(snapshot)
        #expect(try JSONDecoder().decode(WordbookSnapshot.self, from: data) == snapshot)
    }

    @Test("Unique key folds case and edge whitespace but preserves inner whitespace and accents")
    func uniqueKey() throws {
        let first = try #require(WordbookEntryKey(
            text: "  Café  au lait\n",
            fromLanguage: .english,
            toLanguage: .simplifiedChinese
        ))
        let same = try #require(WordbookEntryKey(
            text: "cafe\u{301}  au lait",
            fromLanguage: .english,
            toLanguage: .simplifiedChinese
        ))
        let oneSpace = try #require(WordbookEntryKey(
            text: "café au lait",
            fromLanguage: .english,
            toLanguage: .simplifiedChinese
        ))
        let noAccent = try #require(WordbookEntryKey(
            text: "cafe  au lait",
            fromLanguage: .english,
            toLanguage: .simplifiedChinese
        ))
        let otherPair = try #require(WordbookEntryKey(
            text: "CAFÉ  AU LAIT",
            fromLanguage: .english,
            toLanguage: .traditionalChinese
        ))

        #expect(first == same)
        #expect(first != oneSpace)
        #expect(first != noAccent)
        #expect(first != otherPair)
        #expect(WordbookEntryKey(
            text: " \n ",
            fromLanguage: .english,
            toLanguage: .simplifiedChinese
        ) == nil)
    }

    @Test("Validator repairs dangling group references only")
    func repairsReferences() throws {
        let validator = WordbookSnapshotValidator()
        var snapshot = WordbookFixture.snapshot()

        let validResult = try validator.validateAndRepair(snapshot)
        #expect(!validResult.repairedReferences)
        #expect(validResult.snapshot.groups[0].sortOrder == validResult.snapshot.groups[1].sortOrder)

        snapshot.entries[0].groupID = WordbookFixture.missingGroupID
        snapshot.defaultGroupID = WordbookFixture.missingGroupID

        let result = try validator.validateAndRepair(snapshot)
        #expect(result.repairedReferences)
        #expect(result.snapshot.entries[0].groupID == nil)
        #expect(result.snapshot.defaultGroupID == nil)
    }

    @Test("Validator rejects unknown languages and duplicate unique keys")
    func rejectsUnsafeData() throws {
        var invalidLanguage = WordbookFixture.snapshot()
        invalidLanguage.entries[0].fromLanguage = Language(rawValue: "Not-A-Language")
        #expect(throws: WordbookValidationError.self) {
            try WordbookSnapshotValidator().validateAndRepair(invalidLanguage)
        }

        var duplicate = WordbookFixture.snapshot()
        var copied = duplicate.entries[0]
        copied.id = WordbookFixture.copiedEntryID
        copied.text = duplicate.entries[0].text.uppercased()
        duplicate.entries.append(copied)
        #expect(throws: WordbookValidationError.self) {
            try WordbookSnapshotValidator().validateAndRepair(duplicate)
        }
    }
}

// MARK: - WordbookFixture

/// Supplies deterministic wordbook values shared by the domain model tests.
private enum WordbookFixture {
    static let missingGroupID = UUID(uuidString: "00000000-0000-0000-0000-000000000099")!
    static let copiedEntryID = UUID(uuidString: "00000000-0000-0000-0000-000000000098")!

    static func snapshot() -> WordbookSnapshot {
        let firstGroup = WordbookGroup(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            name: "Favorites",
            sortOrder: 0,
            createdAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let secondGroup = WordbookGroup(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            name: "Travel",
            sortOrder: 0,
            createdAt: Date(timeIntervalSince1970: 1_700_000_060)
        )
        let entry = WordbookEntry(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000010")!,
            text: "Café  au lait",
            fromLanguage: .english,
            toLanguage: .simplifiedChinese,
            groupID: firstGroup.id,
            note: "Coffee with milk",
            createdAt: Date(timeIntervalSince1970: 1_700_000_120),
            updatedAt: Date(timeIntervalSince1970: 1_700_000_180)
        )

        return WordbookSnapshot(
            schemaVersion: WordbookSnapshot.currentSchemaVersion,
            entries: [entry],
            groups: [firstGroup, secondGroup],
            defaultGroupID: firstGroup.id
        )
    }
}
