//
//  WordbookStore.swift
//  Easydict
//
//  Created by liangkaiwen on 2026/7/13.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation

// MARK: - WordbookStorage

/// Defines the asynchronous persistence boundary for complete wordbook
/// snapshots. Implementations expose recovery and protection states without
/// requiring repository consumers to understand the underlying file layout.
protocol WordbookStorage: Sendable {
    func load() async throws -> WordbookLoadResult
    func save(_ snapshot: WordbookSnapshot) async throws
    func resetProtectedData() async throws
    func dataDirectoryURL() async -> URL
}

// MARK: - WordbookLoadResult

/// Describes whether persisted data is absent, loaded, recovered, or protected.
/// Recovery retains the optional corrupt archive URL for a user-facing notice.
enum WordbookLoadResult: Equatable, Sendable {
    case missing
    case loaded(WordbookSnapshot)
    case recovered(WordbookSnapshot, corruptURL: URL?)
    case protected(WordbookProtection)
}

// MARK: - WordbookStoreError

/// Identifies storage failures that callers can map to retry, verification, or
/// rollback handling. A newer schema retains its version and exact file URL so
/// callers can protect data that this app version cannot safely interpret.
enum WordbookStoreError: Error, Equatable {
    case io
    case invalidPrimary
    case verificationFailed
    case rollbackFailed
    case newerSchema(version: Int, fileURL: URL)
}

// MARK: - WordbookStore

/// Persists versioned wordbook snapshots with a verified rotating backup. The
/// actor detects future schemas from the JSON header before decoding, archives
/// corrupt primary bytes, restores only validated backups, and requires an
/// explicit reset before protected data can be replaced.
actor WordbookStore: WordbookStorage {
    // MARK: Lifecycle

    init(
        directoryURL: URL? = nil,
        fileManager: FileManager = .default,
        validator: WordbookSnapshotValidator = .init(),
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.fileManager = fileManager
        self.validator = validator
        self.now = now
        if let directoryURL {
            self.directoryURL = directoryURL
        } else {
            let applicationSupport = fileManager.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            )[0]
            self.directoryURL = applicationSupport
                .appendingPathComponent(
                    Bundle.main.bundleIdentifier ?? "Easydict",
                    isDirectory: true
                )
                .appendingPathComponent("Wordbook", isDirectory: true)
        }
    }

    // MARK: Internal

    /// Returns the directory that owns the primary, backup, and corrupt files.
    func dataDirectoryURL() async -> URL {
        directoryURL
    }

    /// Loads the primary snapshot or safely recovers a validated orphan backup.
    func load() async throws -> WordbookLoadResult {
        if let newer = try newerSchemaFile() {
            return .protected(.newerSchema(version: newer.version, fileURL: newer.url))
        }

        guard fileManager.fileExists(atPath: primaryURL.path) else {
            guard fileManager.fileExists(atPath: backupURL.path) else {
                return .missing
            }
            let backup: WordbookSnapshot
            do {
                backup = try decodeCurrentSnapshot(at: backupURL)
            } catch WordbookStoreError.invalidPrimary {
                return .protected(.corrupt(mainURL: primaryURL, backupURL: backupURL))
            } catch let WordbookStoreError.newerSchema(version, fileURL) {
                return .protected(.newerSchema(version: version, fileURL: fileURL))
            }

            try atomicCopy(from: backupURL, to: primaryURL)
            let restored: WordbookSnapshot
            do {
                restored = try decodeCurrentSnapshot(at: primaryURL)
            } catch WordbookStoreError.invalidPrimary {
                throw WordbookStoreError.verificationFailed
            }
            guard restored == backup else {
                throw WordbookStoreError.verificationFailed
            }
            return .recovered(backup, corruptURL: nil)
        }

        do {
            let snapshot = try decodeCurrentSnapshot(at: primaryURL)
            return .loaded(snapshot)
        } catch let WordbookStoreError.newerSchema(version, fileURL) {
            return .protected(.newerSchema(version: version, fileURL: fileURL))
        } catch WordbookStoreError.invalidPrimary {
            let preservedURL = try preserveCorruptPrimary()
            guard fileManager.fileExists(atPath: backupURL.path) else {
                return .protected(.corrupt(mainURL: primaryURL, backupURL: nil))
            }

            let backup: WordbookSnapshot
            do {
                backup = try decodeCurrentSnapshot(at: backupURL)
            } catch let WordbookStoreError.newerSchema(version, fileURL) {
                return .protected(.newerSchema(version: version, fileURL: fileURL))
            } catch WordbookStoreError.invalidPrimary {
                return .protected(.corrupt(mainURL: primaryURL, backupURL: backupURL))
            }

            try atomicCopy(from: backupURL, to: primaryURL)
            let restored: WordbookSnapshot
            do {
                restored = try decodeCurrentSnapshot(at: primaryURL)
            } catch WordbookStoreError.invalidPrimary {
                throw WordbookStoreError.verificationFailed
            }
            guard restored == backup else {
                throw WordbookStoreError.verificationFailed
            }
            return .recovered(backup, corruptURL: preservedURL)
        }
    }

    /// Validates and atomically saves a snapshot after rotating a safe primary.
    func save(_ snapshot: WordbookSnapshot) async throws {
        guard snapshot.schemaVersion == WordbookSnapshot.currentSchemaVersion else {
            throw WordbookStoreError.verificationFailed
        }
        do {
            let validated = try validator.validateAndRepair(snapshot)
            guard validated.snapshot == snapshot else {
                throw WordbookStoreError.verificationFailed
            }
        } catch {
            throw WordbookStoreError.verificationFailed
        }
        if let newer = try newerSchemaFile() {
            throw WordbookStoreError.newerSchema(
                version: newer.version,
                fileURL: newer.url
            )
        }
        do {
            try fileManager.createDirectory(
                at: directoryURL,
                withIntermediateDirectories: true
            )
        } catch {
            throw WordbookStoreError.io
        }

        let hadPrimary = fileManager.fileExists(atPath: primaryURL.path)
        if hadPrimary {
            let previous = try decodeCurrentSnapshot(at: primaryURL)
            try atomicCopy(from: primaryURL, to: backupURL)
            guard try decodeCurrentSnapshot(at: backupURL) == previous else {
                throw WordbookStoreError.verificationFailed
            }
        }

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(snapshot)
            try data.write(to: primaryURL, options: .atomic)
            guard try decodeCurrentSnapshot(at: primaryURL) == snapshot else {
                throw WordbookStoreError.verificationFailed
            }
        } catch let writeError {
            do {
                if hadPrimary, fileManager.fileExists(atPath: backupURL.path) {
                    let backup = try decodeCurrentSnapshot(at: backupURL)
                    try atomicCopy(from: backupURL, to: primaryURL)
                    guard try decodeCurrentSnapshot(at: primaryURL) == backup else {
                        throw WordbookStoreError.verificationFailed
                    }
                } else if fileManager.fileExists(atPath: primaryURL.path) {
                    try fileManager.removeItem(at: primaryURL)
                }
            } catch {
                throw WordbookStoreError.rollbackFailed
            }
            if let storeError = writeError as? WordbookStoreError {
                throw storeError
            }
            throw WordbookStoreError.io
        }
    }

    /// Archives protected files, removes them, and creates a verified empty store.
    func resetProtectedData() async throws {
        if let newer = try newerSchemaFile() {
            throw WordbookStoreError.newerSchema(
                version: newer.version,
                fileURL: newer.url
            )
        }
        do {
            let existingURLs = [primaryURL, backupURL].filter {
                fileManager.fileExists(atPath: $0.path)
            }
            for url in existingURLs {
                try Data(contentsOf: url).write(
                    to: corruptURL(),
                    options: .atomic
                )
            }
            for url in existingURLs {
                try fileManager.removeItem(at: url)
            }
        } catch let error as WordbookStoreError {
            throw error
        } catch {
            throw WordbookStoreError.io
        }
        try await save(.empty)
    }

    // MARK: Private

    /// Decodes only the schema header before the complete snapshot payload.
    private struct Header: Decodable {
        let schemaVersion: Int
    }

    private let directoryURL: URL
    private let fileManager: FileManager
    private let validator: WordbookSnapshotValidator
    private let now: @Sendable () -> Date

    private var primaryURL: URL {
        directoryURL.appendingPathComponent("wordbook.json")
    }

    private var backupURL: URL {
        directoryURL.appendingPathComponent("wordbook.backup.json")
    }

    /// Finds the first future-schema primary or backup without full decoding.
    private func newerSchemaFile() throws -> (version: Int, url: URL)? {
        for url in [primaryURL, backupURL]
            where fileManager.fileExists(atPath: url.path) {
            let data: Data
            do {
                data = try Data(contentsOf: url)
            } catch {
                throw WordbookStoreError.io
            }
            guard let header = try? JSONDecoder().decode(Header.self, from: data) else {
                // Readable malformed JSON is handled by normal recovery.
                continue
            }
            if header.schemaVersion > WordbookSnapshot.currentSchemaVersion {
                return (header.schemaVersion, url)
            }
        }
        return nil
    }

    /// Decodes and semantically validates a current-schema snapshot.
    private func decodeCurrentSnapshot(at url: URL) throws -> WordbookSnapshot {
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw WordbookStoreError.io
        }

        do {
            let header = try JSONDecoder().decode(Header.self, from: data)
            if header.schemaVersion > WordbookSnapshot.currentSchemaVersion {
                throw WordbookStoreError.newerSchema(
                    version: header.schemaVersion,
                    fileURL: url
                )
            }
            guard header.schemaVersion == WordbookSnapshot.currentSchemaVersion else {
                throw WordbookStoreError.invalidPrimary
            }
            let snapshot = try JSONDecoder().decode(WordbookSnapshot.self, from: data)
            _ = try validator.validateAndRepair(snapshot)
            return snapshot
        } catch is WordbookValidationError {
            throw WordbookStoreError.invalidPrimary
        } catch let error as WordbookStoreError {
            throw error
        } catch {
            throw WordbookStoreError.invalidPrimary
        }
    }

    /// Copies corrupt primary bytes to a collision-safe timestamped archive.
    private func preserveCorruptPrimary() throws -> URL {
        let destination = corruptURL()
        do {
            try Data(contentsOf: primaryURL).write(
                to: destination,
                options: .atomic
            )
            return destination
        } catch {
            throw WordbookStoreError.io
        }
    }

    /// Replaces a destination atomically with the source file's exact bytes.
    private func atomicCopy(from source: URL, to destination: URL) throws {
        do {
            try Data(contentsOf: source).write(to: destination, options: .atomic)
        } catch {
            throw WordbookStoreError.io
        }
    }

    /// Returns a timestamped archive path that never replaces an existing file.
    private func corruptURL() -> URL {
        let milliseconds = Int64((now().timeIntervalSince1970 * 1_000).rounded())
        var sequence = 0
        while true {
            let suffix = sequence == 0 ? "" : ".\(sequence)"
            let url = directoryURL.appendingPathComponent(
                "wordbook.corrupt.\(milliseconds)\(suffix).json"
            )
            if !fileManager.fileExists(atPath: url.path) {
                return url
            }
            sequence += 1
        }
    }
}
