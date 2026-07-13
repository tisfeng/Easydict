//
//  WordbookRepository.swift
//  Easydict
//
//  Created by liangkaiwen on 2026/7/13.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation

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
        let result = await task.value
        loadTask = nil
        return result
    }

    /// Retries a failed or protected bootstrap while preserving ready state.
    func retryLoad() async -> WordbookRepositoryState {
        guard state.phase != .ready else {
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

    /// Builds a publishable snapshot without exposing partially migrated data.
    private func bootstrap() async -> WordbookRepositoryState {
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
