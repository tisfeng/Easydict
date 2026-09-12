//
//  WordbookSnapshotValidator.swift
//  Easydict
//
//  Created by liangkaiwen on 2026/7/13.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation

// MARK: - WordbookValidationResult

/// Returns a validated snapshot together with whether dangling references were
/// repaired. Callers can persist repaired data without conflating repair with
/// rejection of unsafe or structurally invalid content.
struct WordbookValidationResult: Equatable {
    let snapshot: WordbookSnapshot
    let repairedReferences: Bool
}

// MARK: - WordbookValidationError

/// Identifies snapshot invariants that cannot be repaired without losing or
/// ambiguously merging user data. Values retain the offending schema,
/// entry, group, or duplicate pair for diagnostics.
enum WordbookValidationError: Error, Equatable {
    case unsupportedSchema(Int)
    case emptyEntry(UUID)
    case duplicateEntryID(UUID)
    case duplicateEntryKey(UUID, UUID)
    case invalidLanguage(UUID)
    case emptyGroupName(UUID)
    case duplicateGroupID(UUID)
    case duplicateGroupName(String)
}

// MARK: - WordbookSnapshotValidator

/// Validates persisted wordbook invariants before repository data is accepted.
/// It rejects unsafe content and repairs only references to missing
/// groups, which can be removed without changing valid entry or group values.
struct WordbookSnapshotValidator {
    /// Validates the snapshot and removes only dangling group references.
    /// - Parameter input: The decoded snapshot to inspect.
    /// - Returns: The safe snapshot and whether any references were repaired.
    /// - Throws: `WordbookValidationError` for unsupported or unsafe data.
    func validateAndRepair(_ input: WordbookSnapshot) throws -> WordbookValidationResult {
        guard input.schemaVersion == WordbookSnapshot.currentSchemaVersion else {
            throw WordbookValidationError.unsupportedSchema(input.schemaVersion)
        }

        var snapshot = input
        var entryIDs = Set<UUID>()
        var keys: [WordbookEntryKey: UUID] = [:]
        for entry in snapshot.entries {
            guard entryIDs.insert(entry.id).inserted else {
                throw WordbookValidationError.duplicateEntryID(entry.id)
            }
            guard Language.allCases.contains(entry.fromLanguage),
                  Language.allCases.contains(entry.toLanguage)
            else {
                throw WordbookValidationError.invalidLanguage(entry.id)
            }
            guard let key = WordbookEntryKey(
                text: entry.text,
                fromLanguage: entry.fromLanguage,
                toLanguage: entry.toLanguage
            ) else {
                throw WordbookValidationError.emptyEntry(entry.id)
            }
            if let firstID = keys.updateValue(entry.id, forKey: key) {
                throw WordbookValidationError.duplicateEntryKey(firstID, entry.id)
            }
        }

        var groupIDs = Set<UUID>()
        var groupNames = Set<String>()
        for group in snapshot.groups {
            guard groupIDs.insert(group.id).inserted else {
                throw WordbookValidationError.duplicateGroupID(group.id)
            }
            let name = group.name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else {
                throw WordbookValidationError.emptyGroupName(group.id)
            }
            let folded = name.folding(
                options: [.caseInsensitive],
                locale: Locale(identifier: "en_US_POSIX")
            )
            guard groupNames.insert(folded).inserted else {
                throw WordbookValidationError.duplicateGroupName(name)
            }
        }

        var repaired = false
        for index in snapshot.entries.indices
            where snapshot.entries[index].groupID.map({ !groupIDs.contains($0) }) == true {
            snapshot.entries[index].groupID = nil
            repaired = true
        }
        if snapshot.defaultGroupID.map({ !groupIDs.contains($0) }) == true {
            snapshot.defaultGroupID = nil
            repaired = true
        }

        return WordbookValidationResult(
            snapshot: snapshot,
            repairedReferences: repaired
        )
    }
}
