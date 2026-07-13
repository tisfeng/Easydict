//
//  WordbookModels.swift
//  Easydict
//
//  Created by liangkaiwen on 2026/7/13.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation

// MARK: - WordbookEntry

/// Represents one saved wordbook item and its translation direction. The stable
/// identifier and timestamps support persistence, while the optional group and
/// note retain the user's organization without coupling the model to UI state.
struct WordbookEntry: Codable, Identifiable, Equatable, Sendable {
    var id: UUID
    var text: String
    var fromLanguage: Language
    var toLanguage: Language
    var groupID: UUID?
    var note: String
    var createdAt: Date
    var updatedAt: Date
}

// MARK: - WordbookGroup

/// Represents a user-defined collection for organizing saved entries. Its
/// explicit sort value is persisted independently from creation time so
/// consumers can provide stable ordering when multiple groups share a rank.
struct WordbookGroup: Codable, Identifiable, Equatable, Sendable {
    var id: UUID
    var name: String
    var sortOrder: Int
    var createdAt: Date
}

// MARK: - WordbookSnapshot

/// Captures the complete persisted wordbook state for one schema version. The
/// snapshot keeps entries, groups, and the optional default group together so
/// validation and repository updates can operate on one coherent value.
struct WordbookSnapshot: Codable, Equatable, Sendable {
    static let currentSchemaVersion = 1
    static let empty = WordbookSnapshot(
        schemaVersion: currentSchemaVersion,
        entries: [],
        groups: [],
        defaultGroupID: nil
    )

    var schemaVersion: Int
    var entries: [WordbookEntry]
    var groups: [WordbookGroup]
    var defaultGroupID: UUID?
}

// MARK: - WordbookEntryKey

/// Defines the normalized identity of an entry across text and language
/// direction. Normalization ignores edge whitespace and case while preserving
/// meaningful inner whitespace and accent differences.
struct WordbookEntryKey: Hashable, Sendable {
    // MARK: Lifecycle

    init?(text: String, fromLanguage: Language, toLanguage: Language) {
        let trimmed = text.precomposedStringWithCanonicalMapping
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        self.normalizedText = trimmed
            .folding(
                options: [.caseInsensitive],
                locale: Locale(identifier: "en_US_POSIX")
            )
            .precomposedStringWithCanonicalMapping
        self.fromLanguage = fromLanguage
        self.toLanguage = toLanguage
    }

    // MARK: Internal

    let normalizedText: String
    let fromLanguage: Language
    let toLanguage: Language
}

// MARK: - WordbookGroupScope

/// Selects all entries, ungrouped entries, or entries from one group.
enum WordbookGroupScope: Hashable, Sendable {
    case all
    case ungrouped
    case group(UUID)
}

// MARK: - WordbookSortOrder

/// Describes the supported ordering modes for saved entries.
enum WordbookSortOrder: String, Codable, CaseIterable, Sendable {
    case newest
    case oldest
    case text
}

// MARK: - WordbookSection

/// Identifies the primary saved-word and query-history sections.
enum WordbookSection: String, Codable, CaseIterable, Sendable {
    case wordbook
    case history
}

// MARK: - WordbookHistorySortOrder

/// Describes the supported ordering modes for query history.
enum WordbookHistorySortOrder: String, Codable, CaseIterable, Sendable {
    case newest
    case oldest
}

// MARK: - WordbookAddResult

/// Reports whether an add inserted a new entry or found an existing one.
enum WordbookAddResult: Equatable, Sendable {
    case inserted(WordbookEntry)
    case existing(WordbookEntry)
}

// MARK: - WordbookRemoveDecision

/// Describes the outcome or required confirmation for removing an entry.
enum WordbookRemoveDecision: Equatable, Sendable {
    case removed
    case notFound
    case confirmationRequired
}

// MARK: - WordbookGroupDeleteDecision

/// Describes group deletion or the number of entries requiring confirmation.
enum WordbookGroupDeleteDecision: Equatable, Sendable {
    case deleted
    case confirmationRequired(Int)
}

// MARK: - WordbookProtection

/// Preserves file locations when repository data cannot be opened safely.
enum WordbookProtection: Equatable, Sendable {
    case corrupt(mainURL: URL, backupURL: URL?)
    case newerSchema(version: Int, fileURL: URL)
}

// MARK: - WordbookRecoveryNotice

/// Records a successful recovery that should be surfaced to the user once.
enum WordbookRecoveryNotice: Equatable, Sendable {
    case restoredBackup(corruptURL: URL?)
}

// MARK: - WordbookFailure

/// Categorizes repository failures without exposing storage details.
enum WordbookFailure: String, Equatable, Sendable {
    case read
    case write
    case validation
}

// MARK: - WordbookRepositoryState

/// Represents repository readiness, its latest snapshot, and persistence state.
/// Protection and recovery details remain explicit so consumers do not mistake
/// unsafe data for an empty wordbook or lose a recoverable user-facing notice.
struct WordbookRepositoryState: Equatable, Sendable {
    /// Describes repository loading, readiness, protection, or failure.
    enum Phase: Equatable, Sendable {
        case loading
        case ready
        case protected(WordbookProtection)
        case failed(WordbookFailure)
    }

    static let loading = WordbookRepositoryState(
        phase: .loading,
        snapshot: nil,
        isPersisting: false,
        recoveryNotice: nil,
        lastFailure: nil
    )

    var phase: Phase
    var snapshot: WordbookSnapshot?
    var isPersisting: Bool
    var recoveryNotice: WordbookRecoveryNotice?
    var lastFailure: WordbookFailure?
}
