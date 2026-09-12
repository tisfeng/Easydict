//
//  WordbookMigrationTests.swift
//  EasydictTests
//
//  Created by liangkaiwen on 2026/7/13.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation
import Testing

@testable import Easydict

// MARK: - WordbookMigrationTests

/// Verifies legacy conversion and repository bootstrap ordering, including the
/// crash window between durable migration and recording its completion marker.
@Suite("Wordbook Migration", .tags(.wordbook, .unit))
struct WordbookMigrationTests {
    @Test("Legacy Favorites preserve identity, languages, and time")
    func preservesLegacyFields() throws {
        let timestamp = Date(timeIntervalSince1970: 1_700_000_000)
        let record = QueryRecord(
            id: UUID(),
            queryText: "look up",
            queryFromLanguage: .english,
            queryToLanguage: .simplifiedChinese,
            timestamp: timestamp
        )

        let candidate = try WordbookMigrator().makeCandidate(
            from: .empty,
            favorites: [record]
        )
        let entry = try #require(candidate.entries.first)

        #expect(entry.id == record.id)
        #expect(entry.text == record.queryText)
        #expect(entry.fromLanguage == record.queryFromLanguage)
        #expect(entry.toLanguage == record.queryToLanguage)
        #expect(entry.groupID == nil)
        #expect(entry.note.isEmpty)
        #expect(entry.createdAt == timestamp)
        #expect(entry.updatedAt == timestamp)
    }

    @Test("Migration is idempotent and never overwrites existing metadata")
    func idempotent() throws {
        let record = WordbookFixture.favorite(text: "Hello")
        var existing = WordbookFixture.entry(text: "hello", note: "keep me")
        existing.groupID = UUID()
        var snapshot = WordbookSnapshot.empty
        snapshot.entries = [existing]

        let first = try WordbookMigrator().makeCandidate(
            from: snapshot,
            favorites: [record]
        )
        let second = try WordbookMigrator().makeCandidate(
            from: first,
            favorites: [record]
        )

        #expect(first.entries == snapshot.entries)
        #expect(second.entries == snapshot.entries)
    }

    @Test("Save failure does not mark migration complete or publish candidate")
    func saveFailureDoesNotPublish() async {
        let storage = WordbookStorageSpy(loadResult: .missing, saveError: .io)
        let migration = WordbookMigrationSpy(
            version: 0,
            favorites: [WordbookFixture.favorite()]
        )
        let repository = WordbookRepository(
            storage: storage,
            migrationStore: migration
        )

        let state = await repository.loadIfNeeded()
        let savedSnapshots = await storage.savedSnapshots()
        let markedVersions = await migration.markedVersions()

        #expect(state.phase == .failed(.write))
        #expect(state.snapshot == nil)
        #expect(savedSnapshots.isEmpty)
        #expect(markedVersions.isEmpty)
    }

    @Test("Second verified save failure leaves migration marker pending")
    func secondSaveFailureDoesNotMark() async {
        let eventRecorder = WordbookEventRecorder()
        let storage = WordbookStorageSpy(
            loadResult: .missing,
            saveError: .io,
            saveErrorOnCall: 2,
            eventRecorder: eventRecorder
        )
        let migration = WordbookMigrationSpy(
            version: 0,
            favorites: [WordbookFixture.favorite()],
            eventRecorder: eventRecorder
        )
        let repository = WordbookRepository(
            storage: storage,
            migrationStore: migration
        )

        let state = await repository.loadIfNeeded()
        let savedSnapshots = await storage.savedSnapshots()
        let markedVersions = await migration.markedVersions()
        let events = await eventRecorder.recordedEvents()

        #expect(state.phase == .failed(.write))
        #expect(state.snapshot == nil)
        #expect(savedSnapshots.count == 1)
        #expect(markedVersions.isEmpty)
        #expect(events == [.saved(1)])
    }

    @Test("Immediate retry after published failure starts a fresh load")
    func retryAfterPublishedFailureStartsFreshLoad() async {
        let loadGate = WordbookTestGate()
        let observerGate = WordbookTestGate()
        let storage = WordbookStorageSpy(
            loadResult: .missing,
            loadError: .io,
            loadGate: loadGate
        )
        let migration = WordbookMigrationSpy(version: 1, favorites: [])
        let repository = WordbookRepository(
            storage: storage,
            migrationStore: migration
        )
        let updates = await repository.stateUpdates()

        let retryTask = Task {
            var iterator = updates.makeAsyncIterator()
            let initialState = await iterator.next()
            #expect(initialState?.phase == .loading)
            await observerGate.enterAndWait()

            let failedState = await iterator.next()
            #expect(failedState?.phase == .failed(.read))
            return await repository.retryLoad()
        }

        await observerGate.waitUntilEntered()
        await observerGate.open()
        let initialTask = Task { await repository.loadIfNeeded() }
        await loadGate.waitUntilEntered()
        await loadGate.open()

        let retriedState = await retryTask.value
        let initialState = await initialTask.value
        let currentState = await repository.currentState()
        let loadCount = await storage.loadCount()

        #expect(initialState.phase == .failed(.read))
        #expect(retriedState.phase == .ready)
        #expect(currentState.phase == .ready)
        #expect(loadCount == 2)
    }

    @Test("Verified migration marks version one and concurrent loads bootstrap once")
    func marksAfterVerifiedSave() async {
        let eventRecorder = WordbookEventRecorder()
        let storage = WordbookStorageSpy(
            loadResult: .missing,
            eventRecorder: eventRecorder
        )
        let migration = WordbookMigrationSpy(
            version: 0,
            favorites: [WordbookFixture.favorite()],
            eventRecorder: eventRecorder
        )
        let repository = WordbookRepository(
            storage: storage,
            migrationStore: migration
        )

        async let first = repository.loadIfNeeded()
        async let second = repository.loadIfNeeded()
        let states = await [first, second]
        let loadCount = await storage.loadCount()
        let savedSnapshots = await storage.savedSnapshots()
        let markedVersions = await migration.markedVersions()
        let events = await eventRecorder.recordedEvents()

        #expect(states.allSatisfy {
            $0.phase == .ready && $0.snapshot?.entries.count == 1
        })
        #expect(loadCount == 1)
        #expect(savedSnapshots.count == 2)
        #expect(markedVersions == [1])
        #expect(events == [.saved(1), .saved(2), .marked(1)])
    }

    @Test("Marker-zero bootstrap deduplicates an already migrated entry")
    func resumesAfterPersistedMigration() async {
        let favorite = WordbookFixture.favorite(text: "Already migrated")
        let existing = WordbookFixture.entry(
            id: favorite.id,
            text: favorite.queryText,
            fromLanguage: favorite.queryFromLanguage,
            toLanguage: favorite.queryToLanguage,
            createdAt: favorite.timestamp,
            updatedAt: favorite.timestamp
        )
        var migratedSnapshot = WordbookSnapshot.empty
        migratedSnapshot.entries = [existing]
        let storage = WordbookStorageSpy(loadResult: .loaded(migratedSnapshot))
        let migration = WordbookMigrationSpy(version: 0, favorites: [favorite])
        let repository = WordbookRepository(
            storage: storage,
            migrationStore: migration
        )

        let state = await repository.loadIfNeeded()
        let savedSnapshots = await storage.savedSnapshots()
        let markedVersions = await migration.markedVersions()

        #expect(state.phase == .ready)
        #expect(state.snapshot?.entries == [existing])
        #expect(savedSnapshots.count == 2)
        #expect(savedSnapshots.allSatisfy { $0.entries == [existing] })
        #expect(markedVersions == [1])
    }

    @Test("Real store rotates migrated data into backup before marking complete")
    func realStoreRecoveryRetainsFavorite() async throws {
        let directory = try WordbookFixture.temporaryDirectory()
        defer { WordbookFixture.removeTemporaryDirectory(directory) }
        let favorite = WordbookFixture.favorite(text: "durable Favorite")
        let migration = WordbookMigrationSpy(version: 0, favorites: [favorite])
        let repository = WordbookRepository(
            storage: WordbookStore(directoryURL: directory),
            migrationStore: migration
        )

        let initialState = await repository.loadIfNeeded()
        let migratedSnapshot = try #require(initialState.snapshot)
        let primaryURL = directory.appendingPathComponent("wordbook.json")
        let backupURL = directory.appendingPathComponent("wordbook.backup.json")
        let decoder = JSONDecoder()

        // Observe both verified files before reading the recorded marker.
        let primarySnapshot = try decoder.decode(
            WordbookSnapshot.self,
            from: Data(contentsOf: primaryURL)
        )
        let backupSnapshot = try decoder.decode(
            WordbookSnapshot.self,
            from: Data(contentsOf: backupURL)
        )
        let markedVersions = await migration.markedVersions()

        #expect(initialState.phase == .ready)
        #expect(migratedSnapshot.entries.count == 1)
        #expect(primarySnapshot == migratedSnapshot)
        #expect(backupSnapshot == migratedSnapshot)
        #expect(markedVersions == [1])

        try Data("corrupt primary".utf8).write(to: primaryURL, options: .atomic)
        let recoveryRepository = WordbookRepository(
            storage: WordbookStore(directoryURL: directory),
            migrationStore: migration
        )

        let recoveredState = await recoveryRepository.loadIfNeeded()
        let recoveredSnapshot = try #require(recoveredState.snapshot)
        let recoveredEntry = try #require(recoveredSnapshot.entries.first)
        let marksAfterRecovery = await migration.markedVersions()

        #expect(recoveredState.phase == .ready)
        #expect(recoveredState.recoveryNotice != nil)
        #expect(recoveredSnapshot == migratedSnapshot)
        #expect(recoveredEntry.id == favorite.id)
        #expect(recoveredEntry.text == favorite.queryText)
        #expect(recoveredEntry.fromLanguage == favorite.queryFromLanguage)
        #expect(recoveredEntry.toLanguage == favorite.queryToLanguage)
        #expect(marksAfterRecovery == [1])
    }
}
