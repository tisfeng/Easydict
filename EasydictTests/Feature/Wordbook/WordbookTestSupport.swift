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

// MARK: - Migration Test Support

extension WordbookFixture {
    static func group(
        id: UUID = UUID(),
        name: String = "Favorites",
        sortOrder: Int = 0,
        createdAt: Date = Date(timeIntervalSince1970: 1_700_000_000)
    )
        -> WordbookGroup {
        WordbookGroup(
            id: id,
            name: name,
            sortOrder: sortOrder,
            createdAt: createdAt
        )
    }

    static func favorite(
        id: UUID = UUID(),
        text: String = "Hello",
        fromLanguage: Language = .english,
        toLanguage: Language = .simplifiedChinese,
        timestamp: Date = Date(timeIntervalSince1970: 1_700_000_000)
    )
        -> QueryRecord {
        QueryRecord(
            id: id,
            queryText: text,
            queryFromLanguage: fromLanguage,
            queryToLanguage: toLanguage,
            timestamp: timestamp
        )
    }

    static func entry(
        id: UUID = UUID(),
        text: String = "Hello",
        fromLanguage: Language = .english,
        toLanguage: Language = .simplifiedChinese,
        groupID: UUID? = nil,
        note: String = "",
        createdAt: Date = Date(timeIntervalSince1970: 1_700_000_000),
        updatedAt: Date = Date(timeIntervalSince1970: 1_700_000_000)
    )
        -> WordbookEntry {
        WordbookEntry(
            id: id,
            text: text,
            fromLanguage: fromLanguage,
            toLanguage: toLanguage,
            groupID: groupID,
            note: note,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    static func repository(
        snapshot: WordbookSnapshot,
        now: @escaping @Sendable () -> Date = { Date() }
    )
        -> (WordbookRepository, WordbookStorageSpy) {
        let storage = WordbookStorageSpy(loadResult: .loaded(snapshot))
        let migration = WordbookMigrationSpy(version: 1, favorites: [])
        let repository = WordbookRepository(
            storage: storage,
            migrationStore: migration,
            now: now
        )
        return (repository, storage)
    }
}

// MARK: - WordbookEventRecorder

/// Records storage writes, reset attempts, and migration-marker updates in one
/// serial history so tests can assert ordering across both dependency actors.
actor WordbookEventRecorder {
    // MARK: Internal

    /// Identifies one externally visible repository persistence event.
    enum Event: Equatable, Sendable {
        case saved(Int)
        case marked(Int)
        case reset
    }

    func record(_ event: Event) {
        history.append(event)
    }

    func recordedEvents() -> [Event] {
        history
    }

    // MARK: Private

    private var history: [Event] = []
}

// MARK: - WordbookTestGate

/// Coordinates a one-shot test rendezvous: one task announces arrival and
/// suspends until another task explicitly opens the gate.
actor WordbookTestGate {
    // MARK: Internal

    /// Announces arrival, wakes observers, and waits until the gate opens.
    func enterAndWait() async {
        entered = true
        let observers = entryObservers
        entryObservers.removeAll()
        for observer in observers {
            observer.resume()
        }

        guard !isOpen else {
            return
        }
        await withCheckedContinuation { continuation in
            releaseObservers.append(continuation)
        }
    }

    /// Suspends until another task has entered the gate.
    func waitUntilEntered() async {
        guard !entered else {
            return
        }
        await withCheckedContinuation { continuation in
            entryObservers.append(continuation)
        }
    }

    /// Releases the entered task exactly once.
    func open() {
        guard !isOpen else {
            return
        }
        isOpen = true
        let observers = releaseObservers
        releaseObservers.removeAll()
        for observer in observers {
            observer.resume()
        }
    }

    // MARK: Private

    private var entered = false
    private var isOpen = false
    private var entryObservers: [CheckedContinuation<(), Never>] = []
    private var releaseObservers: [CheckedContinuation<(), Never>] = []
}

// MARK: - WordbookStorageSpy

/// Isolates repository persistence from disk while preserving the complete
/// storage contract, failure controls, and successfully persisted snapshots.
actor WordbookStorageSpy: WordbookStorage {
    // MARK: Lifecycle

    init(
        loadResult: WordbookLoadResult,
        loadError: WordbookStoreError? = nil,
        loadErrorOnCall: Int = 1,
        loadGate: WordbookTestGate? = nil,
        saveError: WordbookStoreError? = nil,
        saveErrorOnCall: Int = 1,
        saveGate: WordbookTestGate? = nil,
        resetError: WordbookStoreError? = nil,
        eventRecorder: WordbookEventRecorder? = nil,
        directoryURL: URL = FileManager.default.temporaryDirectory
    ) {
        self.loadResult = loadResult
        self.loadError = loadError
        self.loadErrorOnCall = loadErrorOnCall
        self.loadGate = loadGate
        self.saveError = saveError
        self.saveErrorOnCall = saveErrorOnCall
        self.saveGate = saveGate
        self.resetError = resetError
        self.eventRecorder = eventRecorder
        self.directoryURL = directoryURL
    }

    // MARK: Internal

    func load() async throws -> WordbookLoadResult {
        loadCalls += 1
        let call = loadCalls
        if call == 1 {
            await loadGate?.enterAndWait()
        }
        if call == loadErrorOnCall, let loadError {
            throw loadError
        }
        return loadResult
    }

    func save(_ snapshot: WordbookSnapshot) async throws {
        saveAttempts += 1
        let call = saveAttempts
        activeSaves += 1
        peakConcurrentSaves = max(peakConcurrentSaves, activeSaves)
        defer { activeSaves -= 1 }

        if call == 1 {
            await saveGate?.enterAndWait()
        }
        if let saveDelay {
            try? await Task.sleep(for: saveDelay)
        }
        if call == saveErrorOnCall, let saveError {
            throw saveError
        }
        saveCalls.append(snapshot)
        await eventRecorder?.record(.saved(saveCalls.count))
    }

    func resetProtectedData() async throws {
        resetCalls += 1
        await eventRecorder?.record(.reset)
        if let resetError {
            throw resetError
        }
        loadResult = .missing
    }

    func dataDirectoryURL() async -> URL {
        directoryURL
    }

    func loadCount() -> Int {
        loadCalls
    }

    func savedSnapshots() -> [WordbookSnapshot] {
        saveCalls
    }

    func setSaveError(_ error: WordbookStoreError?) {
        saveError = error
        saveErrorOnCall = saveAttempts + 1
    }

    func setSaveDelay(_ delay: Duration?) {
        saveDelay = delay
    }

    func saveAttemptCount() -> Int {
        saveAttempts
    }

    func maxConcurrentSaves() -> Int {
        peakConcurrentSaves
    }

    func resetCount() -> Int {
        resetCalls
    }

    // MARK: Private

    private var loadResult: WordbookLoadResult
    private let loadError: WordbookStoreError?
    private let loadErrorOnCall: Int
    private let loadGate: WordbookTestGate?
    private var saveError: WordbookStoreError?
    private var saveErrorOnCall: Int
    private let saveGate: WordbookTestGate?
    private let resetError: WordbookStoreError?
    private let eventRecorder: WordbookEventRecorder?
    private let directoryURL: URL
    private var loadCalls = 0
    private var saveAttempts = 0
    private var saveCalls: [WordbookSnapshot] = []
    private var saveDelay: Duration?
    private var activeSaves = 0
    private var peakConcurrentSaves = 0
    private var resetCalls = 0
}

// MARK: - WordbookMigrationSpy

/// Supplies legacy Favorites and a mutable migration marker while retaining
/// every version write so repository ordering and idempotence remain visible.
actor WordbookMigrationSpy: WordbookMigrationPersisting {
    // MARK: Lifecycle

    init(
        version: Int,
        favorites: [QueryRecord],
        eventRecorder: WordbookEventRecorder? = nil
    ) {
        self.version = version
        self.favorites = favorites
        self.eventRecorder = eventRecorder
    }

    // MARK: Internal

    func currentVersion() async -> Int {
        version
    }

    func legacyFavorites() async -> [QueryRecord] {
        favorites
    }

    func setCurrentVersion(_ version: Int) async {
        self.version = version
        marks.append(version)
        await eventRecorder?.record(.marked(version))
    }

    func markedVersions() -> [Int] {
        marks
    }

    // MARK: Private

    private var version: Int
    private let favorites: [QueryRecord]
    private let eventRecorder: WordbookEventRecorder?
    private var marks: [Int] = []
}
