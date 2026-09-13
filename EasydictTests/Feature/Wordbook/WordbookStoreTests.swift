//
//  WordbookStoreTests.swift
//  EasydictTests
//
//  Created by liangkaiwen on 2026/7/13.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation
import Testing

@testable import Easydict

/// Verifies version protection, byte preservation, backup rotation, and
/// recovery behavior at the wordbook JSON storage boundary.
@Suite("Wordbook Store", .tags(.wordbook, .unit))
struct WordbookStoreTests {
    // MARK: Internal

    @Test("Missing primary returns missing")
    func missing() async throws {
        let directory = try WordbookFixture.temporaryDirectory()
        defer { WordbookFixture.removeTemporaryDirectory(directory) }
        let store = WordbookStore(directoryURL: directory)

        #expect(try await store.load() == .missing)
    }

    @Test("Second verified save keeps the previous primary as backup")
    func backupRotation() async throws {
        let directory = try WordbookFixture.temporaryDirectory()
        defer { WordbookFixture.removeTemporaryDirectory(directory) }
        let store = WordbookStore(directoryURL: directory)
        let first = WordbookFixture.snapshot(note: "first")
        let second = WordbookFixture.snapshot(note: "second")

        try await store.save(first)
        try await store.save(second)

        #expect(try await store.load() == .loaded(second))
        let backupData = try Data(
            contentsOf: directory.appendingPathComponent("wordbook.backup.json")
        )
        #expect(try JSONDecoder().decode(WordbookSnapshot.self, from: backupData) == first)
    }

    @Test("Corrupt primary is preserved and valid backup is restored")
    func restoresBackup() async throws {
        let directory = try WordbookFixture.temporaryDirectory()
        defer { WordbookFixture.removeTemporaryDirectory(directory) }
        let store = WordbookStore(
            directoryURL: directory,
            now: { Date(timeIntervalSince1970: 1_721_000_000) }
        )
        let first = WordbookFixture.snapshot(note: "backup")
        try await store.save(first)
        try await store.save(WordbookFixture.snapshot(note: "primary"))
        try Data("broken".utf8).write(
            to: directory.appendingPathComponent("wordbook.json"),
            options: .atomic
        )

        let corruptURL = directory.appendingPathComponent(
            "wordbook.corrupt.1721000000000.json"
        )
        #expect(try await store.load() == .recovered(first, corruptURL: corruptURL))
        #expect(FileManager.default.fileExists(atPath: corruptURL.path))
        #expect(try await store.load() == .loaded(first))
    }

    @Test("Corrupt primary and backup enter protected mode without overwriting bytes")
    func protectsDoubleCorruption() async throws {
        let directory = try WordbookFixture.temporaryDirectory()
        defer { WordbookFixture.removeTemporaryDirectory(directory) }
        let mainURL = directory.appendingPathComponent("wordbook.json")
        let backupURL = directory.appendingPathComponent("wordbook.backup.json")
        let mainBytes = Data("bad-main".utf8)
        let backupBytes = Data("bad-backup".utf8)
        try mainBytes.write(to: mainURL)
        try backupBytes.write(to: backupURL)

        let store = WordbookStore(
            directoryURL: directory,
            now: { Date(timeIntervalSince1970: 1) }
        )
        #expect(
            try await store.load()
                == .protected(.corrupt(mainURL: mainURL, backupURL: backupURL))
        )
        #expect(try Data(contentsOf: mainURL) == mainBytes)
        #expect(try Data(contentsOf: backupURL) == backupBytes)
    }

    @Test("Future schema is detected from the header and never overwritten")
    func protectsFutureSchema() async throws {
        let directory = try WordbookFixture.temporaryDirectory()
        defer { WordbookFixture.removeTemporaryDirectory(directory) }
        let mainURL = directory.appendingPathComponent("wordbook.json")
        let future = WordbookFixture.futureData()
        try future.write(to: mainURL)
        let store = WordbookStore(directoryURL: directory)

        #expect(
            try await store.load()
                == .protected(.newerSchema(version: 99, fileURL: mainURL))
        )
        await expectStoreError(.newerSchema(version: 99, fileURL: mainURL)) {
            try await store.save(.empty)
        }
        #expect(try Data(contentsOf: mainURL) == future)
    }

    @Test("Semantic corruption in primary recovers from validated backup")
    func recoversSemanticCorruption() async throws {
        let directory = try WordbookFixture.temporaryDirectory()
        defer { WordbookFixture.removeTemporaryDirectory(directory) }
        let store = WordbookStore(
            directoryURL: directory,
            now: { Date(timeIntervalSince1970: 2) }
        )
        let backup = WordbookFixture.snapshot(note: "backup")
        try await store.save(backup)
        try await store.save(WordbookFixture.snapshot(note: "primary"))
        let invalidBytes = try WordbookFixture.encoded(
            WordbookFixture.duplicateEntrySnapshot(note: "invalid-primary")
        )
        let mainURL = directory.appendingPathComponent("wordbook.json")
        try invalidBytes.write(to: mainURL, options: .atomic)

        let corruptURL = directory.appendingPathComponent("wordbook.corrupt.2000.json")
        #expect(try await store.load() == .recovered(backup, corruptURL: corruptURL))
        #expect(try Data(contentsOf: corruptURL) == invalidBytes)
        #expect(
            try JSONDecoder().decode(
                WordbookSnapshot.self,
                from: Data(contentsOf: mainURL)
            ) == backup
        )
    }

    @Test("Semantic corruption in primary and backup preserves both files")
    func protectsSemanticDoubleCorruption() async throws {
        let directory = try WordbookFixture.temporaryDirectory()
        defer { WordbookFixture.removeTemporaryDirectory(directory) }
        let mainURL = directory.appendingPathComponent("wordbook.json")
        let backupURL = directory.appendingPathComponent("wordbook.backup.json")
        let mainBytes = try WordbookFixture.encoded(
            WordbookFixture.duplicateEntrySnapshot(note: "invalid-main")
        )
        let backupBytes = try WordbookFixture.encoded(
            WordbookFixture.duplicateKeySnapshot(note: "invalid-backup")
        )
        try mainBytes.write(to: mainURL)
        try backupBytes.write(to: backupURL)
        let store = WordbookStore(directoryURL: directory)

        #expect(
            try await store.load()
                == .protected(.corrupt(mainURL: mainURL, backupURL: backupURL))
        )
        #expect(try Data(contentsOf: mainURL) == mainBytes)
        #expect(try Data(contentsOf: backupURL) == backupBytes)
    }

    @Test("Valid orphan backup is copied to primary")
    func restoresOrphanBackup() async throws {
        let directory = try WordbookFixture.temporaryDirectory()
        defer { WordbookFixture.removeTemporaryDirectory(directory) }
        let mainURL = directory.appendingPathComponent("wordbook.json")
        let backupURL = directory.appendingPathComponent("wordbook.backup.json")
        let snapshot = WordbookFixture.snapshot(note: "orphan-backup")
        let backupBytes = try WordbookFixture.encoded(snapshot)
        try backupBytes.write(to: backupURL)
        let store = WordbookStore(directoryURL: directory)

        #expect(try await store.load() == .recovered(snapshot, corruptURL: nil))
        #expect(try Data(contentsOf: mainURL) == backupBytes)
        #expect(try Data(contentsOf: backupURL) == backupBytes)
    }

    @Test("Invalid orphan backup enters corrupt protection without mutation")
    func protectsInvalidOrphanBackup() async throws {
        let directory = try WordbookFixture.temporaryDirectory()
        defer { WordbookFixture.removeTemporaryDirectory(directory) }
        let mainURL = directory.appendingPathComponent("wordbook.json")
        let backupURL = directory.appendingPathComponent("wordbook.backup.json")
        let backupBytes = try WordbookFixture.encoded(
            WordbookFixture.duplicateEntrySnapshot(note: "invalid-orphan")
        )
        try backupBytes.write(to: backupURL)
        let store = WordbookStore(directoryURL: directory)

        #expect(
            try await store.load()
                == .protected(.corrupt(mainURL: mainURL, backupURL: backupURL))
        )
        #expect(!FileManager.default.fileExists(atPath: mainURL.path))
        #expect(try Data(contentsOf: backupURL) == backupBytes)
    }

    @Test("Future-schema orphan backup enters version protection without mutation")
    func protectsFutureOrphanBackup() async throws {
        let directory = try WordbookFixture.temporaryDirectory()
        defer { WordbookFixture.removeTemporaryDirectory(directory) }
        let mainURL = directory.appendingPathComponent("wordbook.json")
        let backupURL = directory.appendingPathComponent("wordbook.backup.json")
        let backupBytes = WordbookFixture.futureData()
        try backupBytes.write(to: backupURL)
        let store = WordbookStore(directoryURL: directory)

        #expect(
            try await store.load()
                == .protected(.newerSchema(version: 99, fileURL: backupURL))
        )
        #expect(!FileManager.default.fileExists(atPath: mainURL.path))
        #expect(try Data(contentsOf: backupURL) == backupBytes)
    }

    @Test("Future backup appearing after load blocks save and reset")
    func protectsFutureBackupRace() async throws {
        let directory = try WordbookFixture.temporaryDirectory()
        defer { WordbookFixture.removeTemporaryDirectory(directory) }
        let store = WordbookStore(directoryURL: directory)
        let first = WordbookFixture.snapshot(note: "first")
        let current = WordbookFixture.snapshot(note: "current")
        try await store.save(first)
        try await store.save(current)
        #expect(try await store.load() == .loaded(current))

        let mainURL = directory.appendingPathComponent("wordbook.json")
        let backupURL = directory.appendingPathComponent("wordbook.backup.json")
        let mainBytes = try Data(contentsOf: mainURL)
        let futureBytes = WordbookFixture.futureData()
        try futureBytes.write(to: backupURL, options: .atomic)
        let expected = WordbookStoreError.newerSchema(version: 99, fileURL: backupURL)

        await expectStoreError(expected) {
            try await store.save(WordbookFixture.snapshot(note: "candidate"))
        }
        await expectStoreError(expected) {
            try await store.resetProtectedData()
        }
        #expect(try Data(contentsOf: mainURL) == mainBytes)
        #expect(try Data(contentsOf: backupURL) == futureBytes)
    }

    @Test("Unreadable backup blocks save without changing valid primary")
    func rejectsUnreadableBackup() async throws {
        let directory = try WordbookFixture.temporaryDirectory()
        defer { WordbookFixture.removeTemporaryDirectory(directory) }
        let store = WordbookStore(directoryURL: directory)
        try await store.save(WordbookFixture.snapshot(note: "primary"))
        let mainURL = directory.appendingPathComponent("wordbook.json")
        let backupURL = directory.appendingPathComponent("wordbook.backup.json")
        let mainBytes = try Data(contentsOf: mainURL)
        try FileManager.default.createDirectory(
            at: backupURL,
            withIntermediateDirectories: false
        )

        await expectStoreError(.io) {
            try await store.save(WordbookFixture.snapshot(note: "candidate"))
        }
        var isDirectory = ObjCBool(false)
        let backupExists = FileManager.default.fileExists(
            atPath: backupURL.path,
            isDirectory: &isDirectory
        )
        #expect(try Data(contentsOf: mainURL) == mainBytes)
        #expect(backupExists && isDirectory.boolValue)
    }

    @Test("Failed recovery write surfaces IO and preserves source files")
    func reportsRecoveryWriteFailure() async throws {
        let directory = try WordbookFixture.temporaryDirectory()
        defer { WordbookFixture.removeTemporaryDirectory(directory) }
        let mainURL = directory.appendingPathComponent("wordbook.json")
        let backupURL = directory.appendingPathComponent("wordbook.backup.json")
        let mainBytes = Data("corrupt-primary".utf8)
        let backupBytes = try WordbookFixture.encoded(
            WordbookFixture.snapshot(note: "valid-backup")
        )
        try mainBytes.write(to: mainURL)
        try backupBytes.write(to: backupURL)
        try WordbookFixture.setUserImmutable(true, at: mainURL)
        defer { try? WordbookFixture.setUserImmutable(false, at: mainURL) }
        let store = WordbookStore(directoryURL: directory)

        await expectStoreError(.io) {
            _ = try await store.load()
        }
        #expect(try Data(contentsOf: mainURL) == mainBytes)
        #expect(try Data(contentsOf: backupURL) == backupBytes)
    }

    @Test("Duplicate-key candidate is rejected before backup rotation")
    func rejectsDuplicateCandidate() async throws {
        let directory = try WordbookFixture.temporaryDirectory()
        defer { WordbookFixture.removeTemporaryDirectory(directory) }
        let store = WordbookStore(directoryURL: directory)
        try await store.save(WordbookFixture.snapshot(note: "first"))
        try await store.save(WordbookFixture.snapshot(note: "current"))
        let mainURL = directory.appendingPathComponent("wordbook.json")
        let backupURL = directory.appendingPathComponent("wordbook.backup.json")
        let mainBytes = try Data(contentsOf: mainURL)
        let backupBytes = try Data(contentsOf: backupURL)

        await expectStoreError(.verificationFailed) {
            try await store.save(
                WordbookFixture.duplicateKeySnapshot(note: "invalid-candidate")
            )
        }
        #expect(try Data(contentsOf: mainURL) == mainBytes)
        #expect(try Data(contentsOf: backupURL) == backupBytes)
    }

    @Test("Repairable candidate is rejected before backup rotation")
    func rejectsRepairableCandidate() async throws {
        let directory = try WordbookFixture.temporaryDirectory()
        defer { WordbookFixture.removeTemporaryDirectory(directory) }
        let store = WordbookStore(directoryURL: directory)
        try await store.save(WordbookFixture.snapshot(note: "first"))
        try await store.save(WordbookFixture.snapshot(note: "current"))
        let mainURL = directory.appendingPathComponent("wordbook.json")
        let backupURL = directory.appendingPathComponent("wordbook.backup.json")
        let mainBytes = try Data(contentsOf: mainURL)
        let backupBytes = try Data(contentsOf: backupURL)

        await expectStoreError(.verificationFailed) {
            try await store.save(
                WordbookFixture.danglingReferenceSnapshot(note: "repairable-candidate")
            )
        }
        #expect(try Data(contentsOf: mainURL) == mainBytes)
        #expect(try Data(contentsOf: backupURL) == backupBytes)
    }

    @Test("Corrupt archive timestamp collisions retain every byte sequence")
    func preservesCorruptArchiveCollisions() async throws {
        let directory = try WordbookFixture.temporaryDirectory()
        defer { WordbookFixture.removeTemporaryDirectory(directory) }
        let store = WordbookStore(
            directoryURL: directory,
            now: { Date(timeIntervalSince1970: 3) }
        )
        let backup = WordbookFixture.snapshot(note: "backup")
        try await store.save(backup)
        try await store.save(WordbookFixture.snapshot(note: "primary"))
        let mainURL = directory.appendingPathComponent("wordbook.json")
        let firstBytes = Data("first-corruption".utf8)
        let secondBytes = Data("second-corruption".utf8)
        let firstURL = directory.appendingPathComponent("wordbook.corrupt.3000.json")
        let secondURL = directory.appendingPathComponent("wordbook.corrupt.3000.1.json")

        try firstBytes.write(to: mainURL, options: .atomic)
        #expect(try await store.load() == .recovered(backup, corruptURL: firstURL))
        try secondBytes.write(to: mainURL, options: .atomic)
        #expect(try await store.load() == .recovered(backup, corruptURL: secondURL))

        #expect(firstURL != secondURL)
        #expect(try Data(contentsOf: firstURL) == firstBytes)
        #expect(try Data(contentsOf: secondURL) == secondBytes)
    }

    @Test("Ordinary file at data directory path causes deterministic IO failure")
    func rejectsFileAsDirectory() async throws {
        let root = try WordbookFixture.temporaryDirectory()
        defer { WordbookFixture.removeTemporaryDirectory(root) }
        let directoryFile = root.appendingPathComponent("not-a-directory")
        let originalBytes = Data("keep-me".utf8)
        try originalBytes.write(to: directoryFile)
        let store = WordbookStore(directoryURL: directoryFile)

        await expectStoreError(.io) {
            try await store.save(WordbookFixture.snapshot(note: "candidate"))
        }
        #expect(try Data(contentsOf: directoryFile) == originalBytes)
    }

    // MARK: Private

    /// Records the exact store error while keeping each test focused on state.
    private func expectStoreError(
        _ expected: WordbookStoreError,
        operation: () async throws -> ()
    ) async {
        do {
            try await operation()
            Issue.record("Expected WordbookStoreError: \(expected)")
        } catch let error as WordbookStoreError {
            #expect(error == expected)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
}
