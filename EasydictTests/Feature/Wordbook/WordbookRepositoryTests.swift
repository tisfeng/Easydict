//
//  WordbookRepositoryTests.swift
//  EasydictTests
//
//  Created by liangkaiwen on 2026/7/13.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation
import Testing

@testable import Easydict

// MARK: - WordbookRepositoryTests

/// Verifies serialized entry and group mutations through public repository
/// state and durable candidates. It covers confirmation boundaries, runtime
/// storage failures, future-schema protection, and reset crash windows.
@Suite("Wordbook Repository", .tags(.wordbook, .unit))
struct WordbookRepositoryTests {
    /// Selects the group-name mutation exercised by a parameterized test.
    enum GroupNameMutation: CaseIterable, Sendable {
        case create
        case rename
    }

    /// Maps fatal runtime storage failures to their public retryable state.
    enum RuntimeFailure: CaseIterable, Sendable {
        case rollbackFailed
        case invalidPrimary

        // MARK: Internal

        var storeError: WordbookStoreError {
            switch self {
            case .rollbackFailed:
                .rollbackFailed
            case .invalidPrimary:
                .invalidPrimary
            }
        }

        var failure: WordbookFailure {
            switch self {
            case .rollbackFailed:
                .write
            case .invalidPrimary:
                .read
            }
        }
    }

    @Test("Duplicate add returns existing entry without replacing note or group")
    func duplicateDoesNotOverwrite() async throws {
        let group = WordbookFixture.group()
        var existing = WordbookFixture.entry(text: "Hello", note: "keep")
        existing.groupID = group.id
        let snapshot = WordbookSnapshot(
            schemaVersion: 1,
            entries: [existing],
            groups: [group],
            defaultGroupID: nil
        )
        let (repository, storage) = WordbookFixture.repository(snapshot: snapshot)
        _ = await repository.loadIfNeeded()

        let result = try await repository.add(
            text: " hello ",
            fromLanguage: existing.fromLanguage,
            toLanguage: existing.toLanguage
        )

        #expect(result == .existing(existing))
        #expect(await storage.savedSnapshots().isEmpty)
        #expect(await repository.currentState().snapshot == snapshot)
    }

    @Test("New entries use the current default group")
    func addUsesDefaultGroup() async throws {
        let group = WordbookFixture.group()
        let snapshot = WordbookSnapshot(
            schemaVersion: 1,
            entries: [],
            groups: [group],
            defaultGroupID: group.id
        )
        let now = Date(timeIntervalSince1970: 2_000_000_000)
        let (repository, storage) = WordbookFixture.repository(
            snapshot: snapshot,
            now: { now }
        )
        _ = await repository.loadIfNeeded()

        let result = try await repository.add(
            text: "new term",
            fromLanguage: .english,
            toLanguage: .simplifiedChinese
        )
        guard case let .inserted(entry) = result else {
            Issue.record("Expected a newly inserted entry")
            return
        }

        #expect(entry.groupID == group.id)
        #expect(entry.createdAt == now)
        #expect(entry.updatedAt == now)
        #expect(await repository.currentState().snapshot?.entries == [entry])
        #expect(await storage.savedSnapshots().last?.entries == [entry])
    }

    @Test("Empty entry text is rejected", arguments: ["", " \n\t "])
    func emptyTextIsRejected(_ text: String) async {
        let (repository, storage) = WordbookFixture.repository(snapshot: .empty)
        _ = await repository.loadIfNeeded()

        await #expect(throws: WordbookRepositoryError.emptyText) {
            try await repository.add(
                text: text,
                fromLanguage: .english,
                toLanguage: .simplifiedChinese
            )
        }

        #expect(await repository.currentState().snapshot == .empty)
        #expect(await storage.savedSnapshots().isEmpty)
    }

    @Test("Creating a group compacts duplicate sparse and maximum orders")
    func createGroupCompactsOrder() async throws {
        let sharedDate = Date(timeIntervalSince1970: 1_700_000_000)
        let first = WordbookFixture.group(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            name: "First",
            sortOrder: 8,
            createdAt: sharedDate
        )
        let second = WordbookFixture.group(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            name: "Second",
            sortOrder: 8,
            createdAt: sharedDate
        )
        let last = WordbookFixture.group(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
            name: "Last",
            sortOrder: .max,
            createdAt: sharedDate.addingTimeInterval(-100)
        )
        var snapshot = WordbookSnapshot.empty
        snapshot.groups = [last, second, first]
        let (repository, storage) = WordbookFixture.repository(snapshot: snapshot)
        _ = await repository.loadIfNeeded()

        let created = try await repository.createGroup(name: "  Added  ")
        let state = try #require(await repository.currentState().snapshot)
        let ordered = state.groups.sorted { $0.sortOrder < $1.sortOrder }

        #expect(created.name == "Added")
        #expect(created.sortOrder == 3)
        #expect(ordered.map(\.id) == [first.id, second.id, last.id, created.id])
        #expect(ordered.map(\.sortOrder) == Array(0 ..< 4))
        #expect(await storage.savedSnapshots().count == 1)
    }

    @Test(
        "Create and rename reject case-insensitive duplicate group names",
        arguments: GroupNameMutation.allCases
    )
    func duplicateGroupNameIsRejected(_ mutation: GroupNameMutation) async {
        let existing = WordbookFixture.group(name: " Travel ")
        let target = WordbookFixture.group(name: "Work", sortOrder: 1)
        var snapshot = WordbookSnapshot.empty
        snapshot.groups = [existing, target]
        let (repository, storage) = WordbookFixture.repository(snapshot: snapshot)
        _ = await repository.loadIfNeeded()

        await #expect(throws: WordbookRepositoryError.duplicateGroupName) {
            switch mutation {
            case .create:
                _ = try await repository.createGroup(name: " travel ")
            case .rename:
                try await repository.renameGroup(id: target.id, name: "TRAVEL")
            }
        }

        #expect(await repository.currentState().snapshot == snapshot)
        #expect(await storage.savedSnapshots().isEmpty)
    }

    @Test("Renaming a group trims and persists its new name")
    func renameGroup() async throws {
        let group = WordbookFixture.group(name: "Travel")
        var snapshot = WordbookSnapshot.empty
        snapshot.groups = [group]
        let (repository, storage) = WordbookFixture.repository(snapshot: snapshot)
        _ = await repository.loadIfNeeded()

        try await repository.renameGroup(id: group.id, name: "  Journeys\n")

        #expect(await repository.currentState().snapshot?.groups[0].name == "Journeys")
        #expect(await storage.savedSnapshots().last?.groups[0].name == "Journeys")
    }

    @Test("The default group can be set and cleared")
    func setAndClearDefaultGroup() async throws {
        let first = WordbookFixture.group(name: "First")
        let second = WordbookFixture.group(name: "Second", sortOrder: 1)
        var snapshot = WordbookSnapshot.empty
        snapshot.groups = [first, second]
        let (repository, storage) = WordbookFixture.repository(snapshot: snapshot)
        _ = await repository.loadIfNeeded()

        try await repository.setDefaultGroup(id: second.id)
        #expect(await repository.currentState().snapshot?.defaultGroupID == second.id)

        try await repository.setDefaultGroup(id: nil)
        let saved = await storage.savedSnapshots()
        #expect(await repository.currentState().snapshot?.defaultGroupID == nil)
        #expect(saved.map(\.defaultGroupID) == [second.id, nil])
    }

    @Test("Complete group reorder assigns the requested compact order")
    func reorderGroups() async throws {
        let first = WordbookFixture.group(name: "First")
        let second = WordbookFixture.group(name: "Second", sortOrder: 1)
        let third = WordbookFixture.group(name: "Third", sortOrder: 2)
        var snapshot = WordbookSnapshot.empty
        snapshot.groups = [first, second, third]
        let (repository, storage) = WordbookFixture.repository(snapshot: snapshot)
        _ = await repository.loadIfNeeded()

        try await repository.reorderGroups(ids: [third.id, first.id, second.id])
        let state = try #require(await repository.currentState().snapshot)
        let ordered = state.groups.sorted { $0.sortOrder < $1.sortOrder }

        #expect(ordered.map(\.id) == [third.id, first.id, second.id])
        #expect(ordered.map(\.sortOrder) == [0, 1, 2])
        #expect(await storage.savedSnapshots().count == 1)
    }

    @Test("Group reorder requires every ID exactly once")
    func incompleteGroupOrderIsRejected() async {
        let first = WordbookFixture.group(name: "First")
        let second = WordbookFixture.group(name: "Second", sortOrder: 1)
        var snapshot = WordbookSnapshot.empty
        snapshot.groups = [first, second]
        let (repository, storage) = WordbookFixture.repository(snapshot: snapshot)
        _ = await repository.loadIfNeeded()

        await #expect(throws: WordbookRepositoryError.invalidGroupOrder) {
            try await repository.reorderGroups(ids: [first.id])
        }
        await #expect(throws: WordbookRepositoryError.invalidGroupOrder) {
            try await repository.reorderGroups(ids: [first.id, first.id])
        }

        #expect(await repository.currentState().snapshot == snapshot)
        #expect(await storage.savedSnapshots().isEmpty)
    }

    @Test("Display-order reorder still compacts sparse numeric orders")
    func reorderCompactsMatchingDisplayOrder() async throws {
        let first = WordbookFixture.group(
            name: "First",
            sortOrder: 5,
            createdAt: Date(timeIntervalSince1970: 100)
        )
        let second = WordbookFixture.group(
            name: "Second",
            sortOrder: 5,
            createdAt: Date(timeIntervalSince1970: 200)
        )
        let third = WordbookFixture.group(name: "Third", sortOrder: .max)
        var snapshot = WordbookSnapshot.empty
        snapshot.groups = [third, second, first]
        let (repository, storage) = WordbookFixture.repository(snapshot: snapshot)
        _ = await repository.loadIfNeeded()

        try await repository.reorderGroups(ids: [first.id, second.id, third.id])
        let state = try #require(await repository.currentState().snapshot)
        let ordered = state.groups.sorted { $0.sortOrder < $1.sortOrder }

        #expect(ordered.map(\.id) == [first.id, second.id, third.id])
        #expect(ordered.map(\.sortOrder) == [0, 1, 2])
        #expect(await storage.savedSnapshots().count == 1)
    }

    @Test("Ten thousand loaded entries are indexed", .tags(.performance))
    func tenThousandIndex() async throws {
        var snapshot = WordbookSnapshot.empty
        snapshot.entries = (0 ..< 10_000).map { WordbookFixture.entry(id: UUID(), text: "indexed \($0)") }
        let (repository, storage) = WordbookFixture.repository(snapshot: snapshot)
        #expect(await repository.loadIfNeeded().snapshot?.entries.count == 10_000)
        for item in [snapshot.entries[0], snapshot.entries[4_999], snapshot.entries[9_999]] {
            let key = WordbookEntryKey(text: item.text, fromLanguage: item.fromLanguage, toLanguage: item.toLanguage)!
            #expect(await repository.entry(for: key)?.id == item.id)
        }
        #expect(await storage.loadCount() == 1)
    }
}

// MARK: - Entry and Transaction Mutations

extension WordbookRepositoryTests {
    @Test("Deleting the default group requires confirmation and moves entries")
    func deleteGroup() async throws {
        let group = WordbookFixture.group(name: "Delete", sortOrder: 4)
        let survivor = WordbookFixture.group(name: "Keep", sortOrder: 9)
        var entry = WordbookFixture.entry(groupID: group.id)
        let originalUpdatedAt = entry.updatedAt
        let snapshot = WordbookSnapshot(
            schemaVersion: 1,
            entries: [entry],
            groups: [group, survivor],
            defaultGroupID: group.id
        )
        let now = Date(timeIntervalSince1970: 2_000_000_000)
        let (repository, storage) = WordbookFixture.repository(
            snapshot: snapshot,
            now: { now }
        )
        _ = await repository.loadIfNeeded()

        let pending = try await repository.deleteGroup(id: group.id, confirmed: false)
        #expect(pending == .confirmationRequired(1))
        #expect(await repository.currentState().snapshot == snapshot)
        #expect(await storage.savedSnapshots().isEmpty)

        #expect(try await repository.deleteGroup(id: group.id, confirmed: true) == .deleted)
        let state = try #require(await repository.currentState().snapshot)
        entry.groupID = nil
        entry.updatedAt = now
        #expect(state.entries == [entry])
        #expect(state.entries[0].updatedAt != originalUpdatedAt)
        #expect(state.groups.count == 1)
        #expect(state.groups[0].id == survivor.id)
        #expect(state.groups[0].sortOrder == 0)
        #expect(state.defaultGroupID == nil)
        #expect(await storage.savedSnapshots().count == 1)
    }

    @Test("Group deletion recomputes membership inside its mutation transaction")
    func groupConfirmationIsAtomic() async throws {
        let group = WordbookFixture.group()
        let snapshot = WordbookSnapshot(
            schemaVersion: 1,
            entries: [],
            groups: [group],
            defaultGroupID: group.id
        )
        let saveGate = WordbookTestGate()
        let storage = WordbookStorageSpy(
            loadResult: .loaded(snapshot),
            saveGate: saveGate
        )
        let repository = WordbookRepository(
            storage: storage,
            migrationStore: WordbookMigrationSpy(version: 1, favorites: [])
        )
        _ = await repository.loadIfNeeded()

        let addTask = Task {
            try await repository.add(
                text: "arrives first",
                fromLanguage: .english,
                toLanguage: .simplifiedChinese
            )
        }
        await saveGate.waitUntilEntered()
        let deleteTask = Task {
            try await repository.deleteGroup(id: group.id, confirmed: false)
        }
        for _ in 0 ..< 10 {
            await Task.yield()
        }
        #expect(await storage.saveAttemptCount() == 1)
        await saveGate.open()

        _ = try await addTask.value
        let decision = try await deleteTask.value
        let state = try #require(await repository.currentState().snapshot)
        #expect(decision == .confirmationRequired(1))
        #expect(state.groups == [group])
        #expect(state.entries.count == 1)
        #expect(state.entries[0].groupID == group.id)
        #expect(await storage.savedSnapshots().count == 1)
        #expect(await storage.maxConcurrentSaves() == 1)
    }

    @Test("Updating entry note and group changes updated time")
    func updateEntry() async throws {
        let group = WordbookFixture.group()
        let entry = WordbookFixture.entry(note: "old")
        let snapshot = WordbookSnapshot(
            schemaVersion: 1,
            entries: [entry],
            groups: [group],
            defaultGroupID: nil
        )
        let now = Date(timeIntervalSince1970: 2_000_000_000)
        let (repository, storage) = WordbookFixture.repository(
            snapshot: snapshot,
            now: { now }
        )
        _ = await repository.loadIfNeeded()

        let updated = try await repository.updateEntry(
            id: entry.id,
            note: "new",
            groupID: group.id
        )

        #expect(updated.note == "new")
        #expect(updated.groupID == group.id)
        #expect(updated.createdAt == entry.createdAt)
        #expect(updated.updatedAt == now)
        #expect(await repository.currentState().snapshot?.entries == [updated])
        #expect(await storage.savedSnapshots().last?.entries == [updated])
    }

    @Test("Batch move updates selected entries once")
    func batchMove() async throws {
        let group = WordbookFixture.group()
        let first = WordbookFixture.entry(text: "First")
        let second = WordbookFixture.entry(text: "Second")
        let unchanged = WordbookFixture.entry(
            text: "Already there",
            groupID: group.id,
            updatedAt: Date(timeIntervalSince1970: 1_800_000_000)
        )
        let snapshot = WordbookSnapshot(
            schemaVersion: 1,
            entries: [first, second, unchanged],
            groups: [group],
            defaultGroupID: nil
        )
        let now = Date(timeIntervalSince1970: 2_000_000_000)
        let (repository, storage) = WordbookFixture.repository(
            snapshot: snapshot,
            now: { now }
        )
        _ = await repository.loadIfNeeded()

        try await repository.moveEntries(
            ids: [first.id, second.id, unchanged.id],
            to: group.id
        )
        let state = try #require(await repository.currentState().snapshot)
        let entries = Dictionary(uniqueKeysWithValues: state.entries.map { ($0.id, $0) })

        #expect(entries[first.id]?.groupID == group.id)
        #expect(entries[first.id]?.updatedAt == now)
        #expect(entries[second.id]?.groupID == group.id)
        #expect(entries[second.id]?.updatedAt == now)
        #expect(entries[unchanged.id] == unchanged)
        #expect(await storage.savedSnapshots().count == 1)
    }

    @Test("Batch delete removes every selected entry and index")
    func batchDelete() async throws {
        let first = WordbookFixture.entry(text: "First")
        let second = WordbookFixture.entry(text: "Second")
        let third = WordbookFixture.entry(text: "Third")
        var snapshot = WordbookSnapshot.empty
        snapshot.entries = [first, second, third]
        let (repository, storage) = WordbookFixture.repository(snapshot: snapshot)
        _ = await repository.loadIfNeeded()
        let firstKey = try #require(WordbookEntryKey(
            text: first.text,
            fromLanguage: first.fromLanguage,
            toLanguage: first.toLanguage
        ))
        let secondKey = try #require(WordbookEntryKey(
            text: second.text,
            fromLanguage: second.fromLanguage,
            toLanguage: second.toLanguage
        ))
        let thirdKey = try #require(WordbookEntryKey(
            text: third.text,
            fromLanguage: third.fromLanguage,
            toLanguage: third.toLanguage
        ))

        try await repository.remove(ids: [first.id, third.id])

        #expect(await repository.currentState().snapshot?.entries == [second])
        #expect(await repository.entry(for: firstKey) == nil)
        #expect(await repository.entry(for: secondKey) == second)
        #expect(await repository.entry(for: thirdKey) == nil)
        #expect(await storage.savedSnapshots().last?.entries == [second])
    }

    @Test("Keyed removal confirms noted entries before deleting")
    func keyedRemovalRequiresConfirmation() async throws {
        let entry = WordbookFixture.entry(note: "keep this context")
        var snapshot = WordbookSnapshot.empty
        snapshot.entries = [entry]
        let (repository, storage) = WordbookFixture.repository(snapshot: snapshot)
        _ = await repository.loadIfNeeded()
        let key = try #require(WordbookEntryKey(
            text: entry.text,
            fromLanguage: entry.fromLanguage,
            toLanguage: entry.toLanguage
        ))

        let pending = try await repository.remove(key: key, confirmed: false)
        #expect(pending == .confirmationRequired)
        #expect(await repository.currentState().snapshot == snapshot)
        #expect(await storage.savedSnapshots().isEmpty)

        let removed = try await repository.remove(key: key, confirmed: true)
        #expect(removed == .removed)
        #expect(await repository.currentState().snapshot?.entries.isEmpty == true)
        #expect(await repository.entry(for: key) == nil)
        #expect(await storage.savedSnapshots().count == 1)
    }

    @Test("Keyed confirmation reads the note inside its mutation transaction")
    func keyedConfirmationIsAtomic() async throws {
        let entry = WordbookFixture.entry(note: "")
        var snapshot = WordbookSnapshot.empty
        snapshot.entries = [entry]
        let saveGate = WordbookTestGate()
        let storage = WordbookStorageSpy(
            loadResult: .loaded(snapshot),
            saveGate: saveGate
        )
        let repository = WordbookRepository(
            storage: storage,
            migrationStore: WordbookMigrationSpy(version: 1, favorites: [])
        )
        _ = await repository.loadIfNeeded()
        let key = try #require(WordbookEntryKey(
            text: entry.text,
            fromLanguage: entry.fromLanguage,
            toLanguage: entry.toLanguage
        ))

        let updateTask = Task {
            try await repository.updateEntry(
                id: entry.id,
                note: "added first",
                groupID: nil
            )
        }
        await saveGate.waitUntilEntered()
        let removeTask = Task {
            try await repository.remove(key: key, confirmed: false)
        }
        for _ in 0 ..< 10 {
            await Task.yield()
        }
        #expect(await storage.saveAttemptCount() == 1)
        await saveGate.open()

        let updated = try await updateTask.value
        let decision = try await removeTask.value
        #expect(decision == .confirmationRequired)
        #expect(await repository.currentState().snapshot?.entries == [updated])
        #expect(await repository.entry(for: key) == updated)
        #expect(await storage.savedSnapshots().count == 1)
        #expect(await storage.maxConcurrentSaves() == 1)
    }

    @Test("Concurrent adds are serialized across storage awaits")
    func concurrentAdds() async throws {
        let (repository, storage) = WordbookFixture.repository(snapshot: .empty)
        await storage.setSaveDelay(.milliseconds(30))
        _ = await repository.loadIfNeeded()

        async let first = repository.add(
            text: "first",
            fromLanguage: .english,
            toLanguage: .simplifiedChinese
        )
        async let second = repository.add(
            text: "second",
            fromLanguage: .english,
            toLanguage: .simplifiedChinese
        )
        _ = try await (first, second)

        let texts = Set(await repository.currentState().snapshot?.entries.map(\.text) ?? [])
        #expect(texts == ["first", "second"])
        #expect(await storage.maxConcurrentSaves() == 1)
        #expect(await storage.savedSnapshots().count == 2)
    }

    @Test("Save failure keeps the previous snapshot and index")
    func failedSaveDoesNotPublishCandidate() async throws {
        let (repository, storage) = WordbookFixture.repository(snapshot: .empty)
        _ = await repository.loadIfNeeded()
        await storage.setSaveError(.io)

        await #expect(throws: WordbookRepositoryError.storage) {
            try await repository.add(
                text: "persist me",
                fromLanguage: .english,
                toLanguage: .simplifiedChinese
            )
        }
        let state = await repository.currentState()
        let key = try #require(WordbookEntryKey(
            text: "persist me",
            fromLanguage: .english,
            toLanguage: .simplifiedChinese
        ))

        #expect(state.phase == .ready)
        #expect(state.snapshot == .empty)
        #expect(!state.isPersisting)
        #expect(state.lastFailure == .write)
        #expect(await repository.entry(for: key) == nil)
        #expect(await storage.savedSnapshots().isEmpty)
        #expect(await storage.saveAttemptCount() == 1)
    }
}

// MARK: - Runtime Failure and Reset

extension WordbookRepositoryTests {
    @Test("Retry during corrupt reset does not start a competing bootstrap")
    func retryDuringCorruptResetDoesNotBootstrap() async {
        let resetGate = WordbookTestGate()
        let storage = WordbookStorageSpy(
            loadResult: .protected(.corrupt(
                mainURL: URL(fileURLWithPath: "/tmp/corrupt-wordbook.json"),
                backupURL: nil
            )),
            resetGate: resetGate
        )
        let repository = WordbookRepository(
            storage: storage,
            migrationStore: WordbookMigrationSpy(version: 1, favorites: [])
        )
        _ = await repository.loadIfNeeded()

        let resetTask = Task { await repository.resetProtectedData() }
        await resetGate.waitUntilEntered()
        defer { Task { await resetGate.open() } }

        #expect(await repository.currentState() == .loading)
        let retryState = await repository.retryLoad()
        #expect(retryState == .loading)
        #expect(await repository.currentState() == .loading)
        #expect(await storage.loadCount() == 1)

        await resetGate.open()
        let resetState = await resetTask.value
        #expect(resetState.phase == .ready)
        #expect(resetState.snapshot == .empty)
        #expect(await storage.loadCount() == 2)
    }

    @Test("Newer schema discovered during mutation protects data immediately")
    func mutationNewerSchemaProtectsRepository() async throws {
        let existing = WordbookFixture.entry(text: "Existing")
        var snapshot = WordbookSnapshot.empty
        snapshot.entries = [existing]
        let (repository, storage) = WordbookFixture.repository(snapshot: snapshot)
        _ = await repository.loadIfNeeded()
        let futureURL = URL(fileURLWithPath: "/tmp/wordbook-v2.json")
        await storage.setSaveError(.newerSchema(version: 2, fileURL: futureURL))
        let existingKey = try #require(WordbookEntryKey(
            text: existing.text,
            fromLanguage: existing.fromLanguage,
            toLanguage: existing.toLanguage
        ))
        let newKey = try #require(WordbookEntryKey(
            text: "blocked",
            fromLanguage: .english,
            toLanguage: .simplifiedChinese
        ))

        await #expect(throws: WordbookRepositoryError.storage) {
            try await repository.add(
                text: "blocked",
                fromLanguage: .english,
                toLanguage: .simplifiedChinese
            )
        }
        let state = await repository.currentState()
        #expect(state.phase == .protected(.newerSchema(version: 2, fileURL: futureURL)))
        #expect(state.snapshot == nil)
        #expect(await repository.entry(for: existingKey) == nil)
        #expect(await repository.entry(for: newKey) == nil)

        await #expect(throws: WordbookRepositoryError.unavailable) {
            try await repository.add(
                text: "still blocked",
                fromLanguage: .english,
                toLanguage: .simplifiedChinese
            )
        }
        #expect(await storage.saveAttemptCount() == 1)
        #expect(await storage.savedSnapshots().isEmpty)
    }

    @Test(
        "Fatal runtime store errors retain prior state until reload",
        arguments: RuntimeFailure.allCases
    )
    func fatalStoreErrorRequiresReload(_ scenario: RuntimeFailure) async throws {
        let existing = WordbookFixture.entry(text: "Existing")
        var snapshot = WordbookSnapshot.empty
        snapshot.entries = [existing]
        let (repository, storage) = WordbookFixture.repository(snapshot: snapshot)
        _ = await repository.loadIfNeeded()
        await storage.setSaveError(scenario.storeError)
        let existingKey = try #require(WordbookEntryKey(
            text: existing.text,
            fromLanguage: existing.fromLanguage,
            toLanguage: existing.toLanguage
        ))
        let attemptedKey = try #require(WordbookEntryKey(
            text: "attempted",
            fromLanguage: .english,
            toLanguage: .simplifiedChinese
        ))

        await #expect(throws: WordbookRepositoryError.storage) {
            try await repository.add(
                text: "attempted",
                fromLanguage: .english,
                toLanguage: .simplifiedChinese
            )
        }
        let failed = await repository.currentState()
        #expect(failed.phase == .failed(scenario.failure))
        #expect(failed.snapshot == snapshot)
        #expect(failed.lastFailure == scenario.failure)
        #expect(!failed.isPersisting)
        #expect(await repository.entry(for: existingKey) == existing)
        #expect(await repository.entry(for: attemptedKey) == nil)

        await #expect(throws: WordbookRepositoryError.unavailable) {
            try await repository.add(
                text: "blocked before reload",
                fromLanguage: .english,
                toLanguage: .simplifiedChinese
            )
        }
        #expect(await storage.saveAttemptCount() == 1)

        await storage.setSaveError(nil)
        let reloaded = await repository.retryLoad()
        #expect(reloaded.phase == .ready)
        #expect(reloaded.snapshot == snapshot)
        #expect(await repository.entry(for: existingKey) == existing)
    }

    @Test("Corrupt reset marks migration before reset and returns an empty snapshot")
    func corruptResetIsExplicitAndOrdered() async {
        let recorder = WordbookEventRecorder()
        let storage = WordbookStorageSpy(
            loadResult: .protected(.corrupt(
                mainURL: URL(fileURLWithPath: "/tmp/corrupt-wordbook.json"),
                backupURL: nil
            )),
            eventRecorder: recorder
        )
        let favorite = WordbookFixture.favorite(text: "legacy favorite")
        let migration = WordbookMigrationSpy(
            version: 0,
            favorites: [favorite],
            eventRecorder: recorder
        )
        let repository = WordbookRepository(
            storage: storage,
            migrationStore: migration
        )
        _ = await repository.loadIfNeeded()

        let state = await repository.resetProtectedData()

        #expect(state.phase == .ready)
        #expect(state.snapshot == .empty)
        #expect(await migration.markedVersions() == [1])
        #expect(await recorder.recordedEvents() == [.marked(1), .reset])
        #expect(await storage.resetCount() == 1)
        #expect(await storage.loadCount() == 2)
        #expect(await storage.savedSnapshots().isEmpty)
        #expect(await migration.legacyFavorites() == [favorite])
    }

    @Test("Newer schema discovered during corrupt reset becomes protected")
    func resetNewerSchemaProtectsRepository() async {
        let recorder = WordbookEventRecorder()
        let futureURL = URL(fileURLWithPath: "/tmp/future-wordbook.json")
        let storage = WordbookStorageSpy(
            loadResult: .protected(.corrupt(
                mainURL: URL(fileURLWithPath: "/tmp/corrupt-wordbook.json"),
                backupURL: nil
            )),
            resetError: .newerSchema(version: 7, fileURL: futureURL),
            eventRecorder: recorder
        )
        let migration = WordbookMigrationSpy(
            version: 0,
            favorites: [WordbookFixture.favorite()],
            eventRecorder: recorder
        )
        let repository = WordbookRepository(
            storage: storage,
            migrationStore: migration
        )
        _ = await repository.loadIfNeeded()

        let state = await repository.resetProtectedData()
        #expect(state.phase == .protected(.newerSchema(version: 7, fileURL: futureURL)))
        #expect(state.snapshot == nil)
        #expect(await migration.markedVersions() == [1])
        #expect(await recorder.recordedEvents() == [.marked(1), .reset])
        #expect(await storage.resetCount() == 1)

        await #expect(throws: WordbookRepositoryError.unavailable) {
            try await repository.add(
                text: "blocked",
                fromLanguage: .english,
                toLanguage: .simplifiedChinese
            )
        }
        #expect(await storage.saveAttemptCount() == 0)
    }

    @Test("Future-schema protection cannot invoke destructive reset")
    func futureSchemaResetIsRejected() async {
        let recorder = WordbookEventRecorder()
        let protection = WordbookProtection.newerSchema(
            version: 9,
            fileURL: URL(fileURLWithPath: "/tmp/future-wordbook.json")
        )
        let storage = WordbookStorageSpy(
            loadResult: .protected(protection),
            eventRecorder: recorder
        )
        let migration = WordbookMigrationSpy(
            version: 0,
            favorites: [WordbookFixture.favorite()],
            eventRecorder: recorder
        )
        let repository = WordbookRepository(
            storage: storage,
            migrationStore: migration
        )
        _ = await repository.loadIfNeeded()

        let state = await repository.resetProtectedData()

        #expect(state.phase == .protected(protection))
        #expect(state.snapshot == nil)
        #expect(await storage.resetCount() == 0)
        #expect(await migration.markedVersions().isEmpty)
        #expect(await recorder.recordedEvents().isEmpty)
    }

    @Test("Failed reset marker prevents legacy repopulation after a crash window")
    func failedResetDoesNotReimportFavorites() async {
        let recorder = WordbookEventRecorder()
        let favorite = WordbookFixture.favorite(text: "must stay deleted")
        let migration = WordbookMigrationSpy(
            version: 0,
            favorites: [favorite],
            eventRecorder: recorder
        )
        let failingStorage = WordbookStorageSpy(
            loadResult: .protected(.corrupt(
                mainURL: URL(fileURLWithPath: "/tmp/corrupt-wordbook.json"),
                backupURL: nil
            )),
            resetError: .io,
            eventRecorder: recorder
        )
        let repository = WordbookRepository(
            storage: failingStorage,
            migrationStore: migration
        )
        _ = await repository.loadIfNeeded()

        let failed = await repository.resetProtectedData()
        #expect(failed.phase == .failed(.write))
        #expect(failed.snapshot == nil)
        #expect(await migration.markedVersions() == [1])
        #expect(await recorder.recordedEvents() == [.marked(1), .reset])
        #expect(await failingStorage.resetCount() == 1)

        let laterStorage = WordbookStorageSpy(loadResult: .missing)
        let laterRepository = WordbookRepository(
            storage: laterStorage,
            migrationStore: migration
        )
        let later = await laterRepository.loadIfNeeded()

        #expect(later.phase == .ready)
        #expect(later.snapshot == .empty)
        #expect(await laterStorage.savedSnapshots().isEmpty)
        #expect(await migration.markedVersions() == [1])
        #expect(await migration.legacyFavorites() == [favorite])
    }
}
