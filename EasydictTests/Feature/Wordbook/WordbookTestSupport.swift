//
//  WordbookTestSupport.swift
//  EasydictTests
//
//  Created by liangkaiwen on 2026/7/13.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation

@testable import Easydict

// MARK: - WordbookFixture

/// Supplies deterministic wordbook values shared by the domain model tests.
enum WordbookFixture {
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

// MARK: - Store Test Support

extension WordbookFixture {
    static func snapshot(note: String) -> WordbookSnapshot {
        var snapshot = snapshot()
        snapshot.entries[0].note = note
        return snapshot
    }

    /// Creates an isolated UUID-named directory for one storage test.
    static func temporaryDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        return directory
    }

    static func removeTemporaryDirectory(_ directory: URL) {
        try? FileManager.default.removeItem(at: directory)
    }

    static func encoded(_ snapshot: WordbookSnapshot) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(snapshot)
    }

    static func duplicateEntrySnapshot(note: String) -> WordbookSnapshot {
        var snapshot = snapshot(note: note)
        snapshot.entries.append(snapshot.entries[0])
        return snapshot
    }

    static func duplicateKeySnapshot(note: String) -> WordbookSnapshot {
        var snapshot = snapshot(note: note)
        var copied = snapshot.entries[0]
        copied.id = copiedEntryID
        copied.text = copied.text.uppercased()
        snapshot.entries.append(copied)
        return snapshot
    }

    static func danglingReferenceSnapshot(note: String) -> WordbookSnapshot {
        var snapshot = snapshot(note: note)
        snapshot.entries[0].groupID = missingGroupID
        return snapshot
    }

    static func futureData(version: Int = 99) -> Data {
        Data(#"{"schemaVersion":\#(version),"futureOnly":{"value":true}}"#.utf8)
    }

    /// Toggles the macOS user-immutable flag used to force replacement failure.
    static func setUserImmutable(_ immutable: Bool, at url: URL) throws {
        var fileURL = url
        var values = URLResourceValues()
        values.isUserImmutable = immutable
        try fileURL.setResourceValues(values)
    }
}
