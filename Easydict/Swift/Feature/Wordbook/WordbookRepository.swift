//
//  WordbookRepository.swift
//  Easydict
//
//  Created by liangkaiwen on 2026/7/13.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation

// MARK: - WordbookRepositoryError

/// Describes stable repository mutation failures without exposing persistence
/// implementation details to callers. Identifier-bearing cases retain the
/// missing entry or group so consumers can reconcile stale UI state.
enum WordbookRepositoryError: Error, Equatable {
    case unavailable
    case emptyText
    case entryNotFound(UUID)
    case groupNotFound(UUID)
    case emptyGroupName
    case duplicateGroupName
    case invalidGroupOrder
    case storage
}

// MARK: - WordbookRepository

/// Owns the validated in-memory wordbook snapshot and publishes bootstrap
/// state to consumers. Initial loading is shared across concurrent callers,
/// while migration is marked complete only after both durable saves succeed.
actor WordbookRepository {
    // MARK: Lifecycle

    init(
        storage: any WordbookStorage,
        migrationStore: any WordbookMigrationPersisting,
        validator: WordbookSnapshotValidator = .init(),
        migrator: WordbookMigrator = .init(),
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.storage = storage
        self.migrationStore = migrationStore
        self.validator = validator
        self.migrator = migrator
        self.now = now
    }

    // MARK: Internal

    static let shared = WordbookRepository(
        storage: WordbookStore(),
        migrationStore: DefaultsWordbookMigrationStore()
    )

    /// Loads, validates, repairs, and migrates the snapshot at most once.
    func loadIfNeeded() async -> WordbookRepositoryState {
        if didLoad {
            return state
        }
        if let loadTask {
            return await loadTask.value
        }
        let task = Task { await self.bootstrap() }
        loadTask = task
        return await task.value
    }

    /// Retries a failed or protected bootstrap while preserving ready state.
    func retryLoad() async -> WordbookRepositoryState {
        guard state.phase != .ready, state.phase != .loading else {
            return state
        }
        didLoad = false
        state = .loading
        publish()
        return await loadIfNeeded()
    }

    func currentState() -> WordbookRepositoryState {
        state
    }

    /// Returns the storage-owned directory containing wordbook data files.
    func dataDirectoryURL() async -> URL {
        await storage.dataDirectoryURL()
    }

    /// Streams the current state immediately and every subsequent publication.
    func stateUpdates() -> AsyncStream<WordbookRepositoryState> {
        let id = UUID()
        return AsyncStream { continuation in
            continuations[id] = continuation
            continuation.yield(state)
            continuation.onTermination = { [weak self] _ in
                Task { await self?.removeContinuation(id) }
            }
        }
    }

    // MARK: Private

    private let storage: any WordbookStorage
    private let migrationStore: any WordbookMigrationPersisting
    private let validator: WordbookSnapshotValidator
    private let migrator: WordbookMigrator
    private let now: @Sendable () -> Date
    private var state = WordbookRepositoryState.loading
    private var didLoad = false
    private var loadTask: Task<WordbookRepositoryState, Never>?
    private var continuations: [
        UUID: AsyncStream<WordbookRepositoryState>.Continuation
    ] = [:]
    private var entryIDsByKey: [WordbookEntryKey: UUID] = [:]
    private var entryIndexesByID: [UUID: Int] = [:]
    private var mutationActive = false
    private var mutationWaiters: [CheckedContinuation<(), Never>] = []

    /// Builds a publishable snapshot without exposing partially migrated data.
    private func bootstrap() async -> WordbookRepositoryState {
        defer { loadTask = nil }
        var isSaving = false
        do {
            let loaded = try await storage.load()
            let initial: WordbookSnapshot
            let notice: WordbookRecoveryNotice?
            switch loaded {
            case .missing:
                initial = .empty
                notice = nil
            case let .loaded(snapshot):
                initial = snapshot
                notice = nil
            case let .recovered(snapshot, corruptURL):
                initial = snapshot
                notice = .restoredBackup(corruptURL: corruptURL)
            case let .protected(protection):
                return finishProtection(protection)
            }

            let validated = try validator.validateAndRepair(initial)
            var candidate = validated.snapshot
            if validated.repairedReferences {
                isSaving = true
                try await storage.save(candidate)
                isSaving = false
            }

            if await migrationStore.currentVersion() < WordbookMigrator.targetVersion {
                candidate = try migrator.makeCandidate(
                    from: candidate,
                    favorites: await migrationStore.legacyFavorites()
                )
                candidate = try validator.validateAndRepair(candidate).snapshot

                isSaving = true
                try await storage.save(candidate)
                isSaving = false

                // Rotate the verified migrated candidate into the backup too.
                isSaving = true
                try await storage.save(candidate)
                isSaving = false

                await migrationStore.setCurrentVersion(
                    WordbookMigrator.targetVersion
                )
            }

            rebuildIndexes(for: candidate)
            state = WordbookRepositoryState(
                phase: .ready,
                snapshot: candidate,
                isPersisting: false,
                recoveryNotice: notice,
                lastFailure: nil
            )
            didLoad = true
            publish()
            return state
        } catch let WordbookStoreError.newerSchema(version, fileURL) {
            return finishProtection(
                .newerSchema(version: version, fileURL: fileURL)
            )
        } catch is WordbookValidationError {
            return finishBootstrapFailure(.validation)
        } catch is WordbookMigrationError {
            return finishBootstrapFailure(.validation)
        } catch {
            return finishBootstrapFailure(isSaving ? .write : .read)
        }
    }

    private func finishBootstrapFailure(
        _ failure: WordbookFailure
    )
        -> WordbookRepositoryState {
        state = WordbookRepositoryState(
            phase: .failed(failure),
            snapshot: nil,
            isPersisting: false,
            recoveryNotice: nil,
            lastFailure: failure
        )
        didLoad = true
        publish()
        return state
    }

    private func finishProtection(
        _ protection: WordbookProtection
    )
        -> WordbookRepositoryState {
        entryIDsByKey.removeAll(keepingCapacity: false)
        entryIndexesByID.removeAll(keepingCapacity: false)
        state = WordbookRepositoryState(
            phase: .protected(protection),
            snapshot: nil,
            isPersisting: false,
            recoveryNotice: nil,
            lastFailure: nil
        )
        didLoad = true
        publish()
        return state
    }

    private func rebuildIndexes(for snapshot: WordbookSnapshot) {
        entryIDsByKey.removeAll(keepingCapacity: true)
        entryIndexesByID.removeAll(keepingCapacity: true)
        for (index, entry) in snapshot.entries.enumerated() {
            if let key = WordbookEntryKey(
                text: entry.text,
                fromLanguage: entry.fromLanguage,
                toLanguage: entry.toLanguage
            ) {
                entryIDsByKey[key] = entry.id
            }
            entryIndexesByID[entry.id] = index
        }
    }

    private func publish() {
        for continuation in continuations.values {
            continuation.yield(state)
        }
    }

    private func removeContinuation(_ id: UUID) {
        continuations.removeValue(forKey: id)
    }
}

// MARK: - Entry Mutations

extension WordbookRepository {
    func entry(for key: WordbookEntryKey) -> WordbookEntry? {
        guard let id = entryIDsByKey[key],
              let index = entryIndexesByID[id],
              let snapshot = state.snapshot
        else {
            return nil
        }
        return snapshot.entries[index]
    }

    func add(
        text: String,
        fromLanguage: Language,
        toLanguage: Language
    ) async throws
        -> WordbookAddResult {
        guard let key = WordbookEntryKey(
            text: text,
            fromLanguage: fromLanguage,
            toLanguage: toLanguage
        ) else {
            throw WordbookRepositoryError.emptyText
        }

        return try await transaction { snapshot in
            if let id = entryIDsByKey[key],
               let index = entryIndexesByID[id] {
                return (.existing(snapshot.entries[index]), false)
            }
            let date = now()
            let entry = WordbookEntry(
                id: UUID(),
                text: text,
                fromLanguage: fromLanguage,
                toLanguage: toLanguage,
                groupID: snapshot.defaultGroupID,
                note: "",
                createdAt: date,
                updatedAt: date
            )
            snapshot.entries.append(entry)
            return (.inserted(entry), true)
        }
    }

    func remove(id: UUID) async throws {
        try await remove(ids: [id])
    }

    func remove(ids: Set<UUID>) async throws {
        try await transaction { snapshot in
            let oldCount = snapshot.entries.count
            snapshot.entries.removeAll { ids.contains($0.id) }
            return ((), snapshot.entries.count != oldCount)
        }
    }

    func remove(
        key: WordbookEntryKey,
        confirmed: Bool
    ) async throws
        -> WordbookRemoveDecision {
        try await transaction { snapshot in
            guard let id = entryIDsByKey[key],
                  let index = snapshot.entries.firstIndex(where: { $0.id == id })
            else {
                return (.notFound, false)
            }
            if !confirmed, !snapshot.entries[index].note.isEmpty {
                return (.confirmationRequired, false)
            }
            snapshot.entries.remove(at: index)
            return (.removed, true)
        }
    }

    func updateEntry(
        id: UUID,
        note: String,
        groupID: UUID?
    ) async throws
        -> WordbookEntry {
        try await transaction { snapshot in
            if let groupID,
               !snapshot.groups.contains(where: { $0.id == groupID }) {
                throw WordbookRepositoryError.groupNotFound(groupID)
            }
            guard let index = snapshot.entries.firstIndex(where: { $0.id == id }) else {
                throw WordbookRepositoryError.entryNotFound(id)
            }
            if snapshot.entries[index].note == note,
               snapshot.entries[index].groupID == groupID {
                return (snapshot.entries[index], false)
            }
            snapshot.entries[index].note = note
            snapshot.entries[index].groupID = groupID
            snapshot.entries[index].updatedAt = now()
            return (snapshot.entries[index], true)
        }
    }

    func moveEntries(ids: Set<UUID>, to groupID: UUID?) async throws {
        try await transaction { snapshot in
            if let groupID,
               !snapshot.groups.contains(where: { $0.id == groupID }) {
                throw WordbookRepositoryError.groupNotFound(groupID)
            }
            var changed = false
            let date = now()
            for index in snapshot.entries.indices
                where ids.contains(snapshot.entries[index].id) {
                if snapshot.entries[index].groupID != groupID {
                    snapshot.entries[index].groupID = groupID
                    snapshot.entries[index].updatedAt = date
                    changed = true
                }
            }
            return ((), changed)
        }
    }
}

// MARK: - Group Mutations

extension WordbookRepository {
    func createGroup(name: String) async throws -> WordbookGroup {
        let normalized = try normalizedGroupName(name)
        return try await transaction { snapshot in
            guard !snapshot.groups.contains(where: {
                groupNameKey($0.name) == normalized.key
            }) else {
                throw WordbookRepositoryError.duplicateGroupName
            }
            compactGroupOrder(in: &snapshot)
            let group = WordbookGroup(
                id: UUID(),
                name: normalized.stored,
                sortOrder: snapshot.groups.count,
                createdAt: now()
            )
            snapshot.groups.append(group)
            return (group, true)
        }
    }

    func renameGroup(id: UUID, name: String) async throws {
        let normalized = try normalizedGroupName(name)
        try await transaction { snapshot in
            guard let index = snapshot.groups.firstIndex(where: { $0.id == id }) else {
                throw WordbookRepositoryError.groupNotFound(id)
            }
            guard !snapshot.groups.contains(where: {
                $0.id != id && groupNameKey($0.name) == normalized.key
            }) else {
                throw WordbookRepositoryError.duplicateGroupName
            }
            guard snapshot.groups[index].name != normalized.stored else {
                return ((), false)
            }
            snapshot.groups[index].name = normalized.stored
            return ((), true)
        }
    }

    func reorderGroups(ids: [UUID]) async throws {
        try await transaction { snapshot in
            guard Set(ids) == Set(snapshot.groups.map(\.id)),
                  ids.count == snapshot.groups.count
            else {
                throw WordbookRepositoryError.invalidGroupOrder
            }
            let old = snapshot.groups.sorted { first, second in
                if first.sortOrder != second.sortOrder {
                    return first.sortOrder < second.sortOrder
                }
                if first.createdAt != second.createdAt {
                    return first.createdAt < second.createdAt
                }
                return first.id.uuidString < second.id.uuidString
            }.map(\.id)
            let needsCompaction = ids.enumerated().contains { order, id in
                snapshot.groups.first(where: { $0.id == id })?.sortOrder != order
            }
            guard old != ids || needsCompaction else {
                return ((), false)
            }
            for (order, id) in ids.enumerated() {
                let index = snapshot.groups.firstIndex(where: { $0.id == id })!
                snapshot.groups[index].sortOrder = order
            }
            return ((), true)
        }
    }

    func deleteGroup(
        id: UUID,
        confirmed: Bool
    ) async throws
        -> WordbookGroupDeleteDecision {
        try await transaction { snapshot in
            guard snapshot.groups.contains(where: { $0.id == id }) else {
                throw WordbookRepositoryError.groupNotFound(id)
            }
            let entryCount = snapshot.entries.lazy.filter { $0.groupID == id }.count
            if entryCount > 0, !confirmed {
                return (.confirmationRequired(entryCount), false)
            }
            snapshot.groups.removeAll { $0.id == id }
            for (order, index) in snapshot.groups.indices.sorted(by: { firstIndex, secondIndex in
                let first = snapshot.groups[firstIndex]
                let second = snapshot.groups[secondIndex]
                if first.sortOrder != second.sortOrder {
                    return first.sortOrder < second.sortOrder
                }
                if first.createdAt != second.createdAt {
                    return first.createdAt < second.createdAt
                }
                return first.id.uuidString < second.id.uuidString
            }).enumerated() {
                snapshot.groups[index].sortOrder = order
            }
            let date = now()
            for index in snapshot.entries.indices where snapshot.entries[index].groupID == id {
                snapshot.entries[index].groupID = nil
                snapshot.entries[index].updatedAt = date
            }
            if snapshot.defaultGroupID == id {
                snapshot.defaultGroupID = nil
            }
            return (.deleted, true)
        }
    }

    func setDefaultGroup(id: UUID?) async throws {
        try await transaction { snapshot in
            if let id,
               !snapshot.groups.contains(where: { $0.id == id }) {
                throw WordbookRepositoryError.groupNotFound(id)
            }
            guard snapshot.defaultGroupID != id else {
                return ((), false)
            }
            snapshot.defaultGroupID = id
            return ((), true)
        }
    }
}

// MARK: - Protected Reset

extension WordbookRepository {
    /// Resets only explicitly confirmed corrupt data after recording that
    /// legacy migration must never run again for the destructive reset.
    func resetProtectedData() async -> WordbookRepositoryState {
        guard case .protected(.corrupt) = state.phase else {
            return state
        }
        state = .loading
        publish()
        await migrationStore.setCurrentVersion(WordbookMigrator.targetVersion)
        do {
            try await storage.resetProtectedData()
            didLoad = false
            loadTask = nil
            return await loadIfNeeded()
        } catch let WordbookStoreError.newerSchema(version, fileURL) {
            return finishProtection(
                .newerSchema(version: version, fileURL: fileURL)
            )
        } catch {
            return finishBootstrapFailure(.write)
        }
    }
}

// MARK: - Mutation Transaction

extension WordbookRepository {
    /// Waits for exclusive mutation ownership, including across storage awaits.
    fileprivate func acquireMutation() async {
        if !mutationActive {
            mutationActive = true
            return
        }
        await withCheckedContinuation { continuation in
            mutationWaiters.append(continuation)
        }
    }

    /// Transfers ownership directly to the oldest waiter or opens the gate.
    fileprivate func releaseMutation() {
        if mutationWaiters.isEmpty {
            mutationActive = false
        } else {
            mutationWaiters.removeFirst().resume()
        }
    }

    /// Validates and saves a complete candidate before publishing it.
    fileprivate func transaction<Result>(
        _ change: (inout WordbookSnapshot) throws -> (result: Result, changed: Bool)
    ) async throws
        -> Result {
        await acquireMutation()
        defer { releaseMutation() }

        guard state.phase == .ready, let previous = state.snapshot else {
            throw WordbookRepositoryError.unavailable
        }
        var candidate = previous
        let output = try change(&candidate)
        guard output.changed else {
            return output.result
        }
        candidate = try validator.validateAndRepair(candidate).snapshot

        state.isPersisting = true
        state.lastFailure = nil
        publish()
        do {
            try await storage.save(candidate)
            rebuildIndexes(for: candidate)
            state.snapshot = candidate
            state.isPersisting = false
            state.lastFailure = nil
            publish()
            return output.result
        } catch let WordbookStoreError.newerSchema(version, fileURL) {
            _ = finishProtection(
                .newerSchema(version: version, fileURL: fileURL)
            )
            throw WordbookRepositoryError.storage
        } catch let storeError as WordbookStoreError
            where storeError == .rollbackFailed || storeError == .invalidPrimary {
            state.snapshot = previous
            state.isPersisting = false
            let failure: WordbookFailure = storeError == .rollbackFailed ? .write : .read
            state.phase = .failed(failure)
            state.lastFailure = failure
            didLoad = false
            loadTask = nil
            publish()
            throw WordbookRepositoryError.storage
        } catch {
            state.snapshot = previous
            state.isPersisting = false
            state.lastFailure = .write
            publish()
            throw WordbookRepositoryError.storage
        }
    }

    fileprivate func normalizedGroupName(_ name: String) throws -> (stored: String, key: String) {
        let stored = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !stored.isEmpty else {
            throw WordbookRepositoryError.emptyGroupName
        }
        return (
            stored,
            groupNameKey(stored)
        )
    }

    fileprivate func groupNameKey(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).folding(
            options: [.caseInsensitive],
            locale: Locale(identifier: "en_US_POSIX")
        )
    }

    /// Compacts stable display order before appending a new group.
    fileprivate func compactGroupOrder(in snapshot: inout WordbookSnapshot) {
        let orderedIDs = snapshot.groups.sorted { first, second in
            if first.sortOrder != second.sortOrder {
                return first.sortOrder < second.sortOrder
            }
            if first.createdAt != second.createdAt {
                return first.createdAt < second.createdAt
            }
            return first.id.uuidString < second.id.uuidString
        }.map(\.id)
        for (order, id) in orderedIDs.enumerated() {
            let index = snapshot.groups.firstIndex(where: { $0.id == id })!
            snapshot.groups[index].sortOrder = order
        }
    }
}
