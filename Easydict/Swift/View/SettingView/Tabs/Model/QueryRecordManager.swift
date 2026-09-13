//
//  QueryRecordManager.swift
//  Easydict
//
//  Created by Copilot on 2025/11/19.
//  Copyright © 2025 izual. All rights reserved.
//

import Defaults
import Foundation

// MARK: - QueryRecordManager

/// Manages writable query history and read-only legacy Favorites records.
/// Favorites remain readable only for migration and rollback compatibility.
@objc
class QueryRecordManager: NSObject {
    // MARK: Internal

    /// Defines writable history and read-only legacy Favorites storage.
    @objc
    enum RecordType: Int {
        case favorites
        case history

        // MARK: Internal

        /// Returns the defaults key for the record type.
        var storageKey: Defaults.Key<[QueryRecord]> {
            switch self {
            case .favorites:
                return Defaults.Keys.favorites
            case .history:
                return Defaults.Keys.queryHistory
            }
        }

        /// Provides the maximum number of records allowed for the type.
        var maxCount: Int? {
            switch self {
            case .favorites:
                return nil
            case .history:
                return QueryRecordManager.maxHistoryCount
            }
        }

        /// Determines how duplicates should be handled for the record type.
        var deduplicationPolicy: DeduplicationPolicy {
            switch self {
            case .favorites:
                return .skipIfExists
            case .history:
                return .moveToFront
            }
        }
    }

    /// Describes how to handle duplicate query texts when adding records.
    enum DeduplicationPolicy {
        case skipIfExists
        case moveToFront
    }

    /// Shared instance used by the app.
    @objc static let shared = QueryRecordManager()

    /// Adds a history record; legacy Favorites writes are ignored.
    @objc
    func addRecord(
        queryText: String,
        fromLanguage: Language,
        toLanguage: Language,
        to type: RecordType
    ) {
        updateRecords(for: type) { records in
            let record = makeRecord(
                queryText: queryText,
                fromLanguage: fromLanguage,
                toLanguage: toLanguage
            )

            switch type.deduplicationPolicy {
            case .skipIfExists:
                guard !records.contains(where: { $0.queryText == queryText }) else {
                    return false
                }
            case .moveToFront:
                records.removeAll { $0.queryText == queryText }
            }

            records.insert(record, at: 0)

            if let maxCount = type.maxCount, records.count > maxCount {
                records = Array(records.prefix(maxCount))
            }

            return true
        }
    }

    /// Updates the translated result of an existing history record by query text.
    @objc
    func updateTranslatedResult(
        _ translatedResult: String,
        forQueryText queryText: String,
        in type: RecordType
    ) {
        updateRecords(for: type) { records in
            guard let index = records.firstIndex(where: { $0.queryText == queryText }) else {
                return false
            }
            records[index].translatedResult = translatedResult
            return true
        }
    }

    /// Removes a history record; legacy Favorites writes are ignored.
    func removeRecord(id: UUID, from type: RecordType) {
        updateRecords(for: type) { records in
            let originalCount = records.count
            records.removeAll { $0.id == id }
            return records.count != originalCount
        }
    }

    /// Returns history or legacy Favorites retained for compatibility reads.
    func getAllRecords(for type: RecordType) -> [QueryRecord] {
        loadRecords(for: type)
    }

    /// Clears history; legacy Favorites writes are ignored.
    func clearAllRecords(for type: RecordType) {
        saveRecords([], for: type)
    }

    /// Checks whether the given query text exists in the specified category.
    @objc
    func containsRecord(queryText: String, in type: RecordType) -> Bool {
        loadRecords(for: type).contains { $0.queryText == queryText }
    }

    // MARK: Private

    /// Maximum number of history records to keep.
    private static let maxHistoryCount = 1000

    /// Returns all records stored for the specified type.
    private func loadRecords(for type: RecordType) -> [QueryRecord] {
        Defaults[type.storageKey]
    }

    /// Persists history while rejecting every legacy Favorites write path.
    private func saveRecords(_ records: [QueryRecord], for type: RecordType) {
        guard type == .history else {
            logError("Ignored write to read-only legacy Favorites")
            return
        }
        Defaults[type.storageKey] = records
    }

    /// Updates records for the specified type and saves when modified.
    private func updateRecords(for type: RecordType, mutate: (inout [QueryRecord]) -> Bool) {
        var records = loadRecords(for: type)
        let didChange = mutate(&records)
        if didChange {
            saveRecords(records, for: type)
        }
    }

    /// Creates a query record from the provided values.
    private func makeRecord(
        queryText: String,
        fromLanguage: Language,
        toLanguage: Language
    )
        -> QueryRecord {
        QueryRecord(
            queryText: queryText,
            queryFromLanguage: fromLanguage,
            queryToLanguage: toLanguage
        )
    }
}
