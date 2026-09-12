//
//  WordbookMigration.swift
//  Easydict
//
//  Created by liangkaiwen on 2026/7/13.
//  Copyright © 2026 izual. All rights reserved.
//

import Defaults
import Foundation

// MARK: - WordbookMigrationPersisting

/// Provides the migration marker and legacy Favorites without exposing their
/// persistence mechanism to repository bootstrap logic.
protocol WordbookMigrationPersisting: Sendable {
    func currentVersion() async -> Int
    func legacyFavorites() async -> [QueryRecord]
    func setCurrentVersion(_ version: Int) async
}

// MARK: - DefaultsWordbookMigrationStore

/// Bridges repository migration to the existing Defaults values. It only adds
/// a completion marker and deliberately leaves legacy records unchanged.
actor DefaultsWordbookMigrationStore: WordbookMigrationPersisting {
    func currentVersion() async -> Int {
        Defaults[.wordbookMigrationVersion]
    }

    func legacyFavorites() async -> [QueryRecord] {
        Defaults[.favorites]
    }

    func setCurrentVersion(_ version: Int) async {
        Defaults[.wordbookMigrationVersion] = version
    }
}

// MARK: - WordbookMigrationError

/// Identifies legacy records that cannot be merged without creating invalid or
/// ambiguous wordbook data.
enum WordbookMigrationError: Error, Equatable {
    case emptyLegacyEntry(UUID)
    case collidingID(UUID)
}

// MARK: - WordbookMigrator

/// Converts legacy Favorites into wordbook entries while preserving identity,
/// language direction, and timestamps. Existing normalized entries always win
/// so rerunning an interrupted migration cannot overwrite user metadata.
struct WordbookMigrator {
    static let targetVersion = 1

    /// Produces an idempotent candidate without mutating the legacy source.
    func makeCandidate(
        from input: WordbookSnapshot,
        favorites: [QueryRecord]
    ) throws
        -> WordbookSnapshot {
        var snapshot = input
        var keys = Dictionary(uniqueKeysWithValues: snapshot.entries.compactMap { entry in
            WordbookEntryKey(
                text: entry.text,
                fromLanguage: entry.fromLanguage,
                toLanguage: entry.toLanguage
            ).map { ($0, entry.id) }
        })
        var ids = Set(snapshot.entries.map(\.id))

        for record in favorites {
            guard let key = WordbookEntryKey(
                text: record.queryText,
                fromLanguage: record.queryFromLanguage,
                toLanguage: record.queryToLanguage
            ) else {
                throw WordbookMigrationError.emptyLegacyEntry(record.id)
            }
            if keys[key] != nil {
                continue
            }
            guard ids.insert(record.id).inserted else {
                throw WordbookMigrationError.collidingID(record.id)
            }
            let entry = WordbookEntry(
                id: record.id,
                text: record.queryText,
                fromLanguage: record.queryFromLanguage,
                toLanguage: record.queryToLanguage,
                groupID: nil,
                note: "",
                createdAt: record.timestamp,
                updatedAt: record.timestamp
            )
            snapshot.entries.append(entry)
            keys[key] = entry.id
        }
        return snapshot
    }
}
