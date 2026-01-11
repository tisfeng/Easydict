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

/// Manages query record operations for favorites and history.
@objc
class QueryRecordManager: NSObject {
    // MARK: Lifecycle

    /// Initializes the manager singleton.
    override private init() {
        super.init()
    }

    // MARK: Internal

    /// Shared instance used by the app.
    @objc static let shared = QueryRecordManager()

    /// Adds a query to favorites if it is not already present.
    @objc
    func addFavorite(
        queryText: String,
        fromLanguage: Language,
        toLanguage: Language
    ) {
        let record = makeRecord(
            queryText: queryText,
            fromLanguage: fromLanguage,
            toLanguage: toLanguage
        )

        var favorites = Defaults[.favorites]

        // Avoid duplicates - check if the same query text already exists.
        if !favorites.contains(where: { $0.queryText == queryText }) {
            favorites.insert(record, at: 0)
            Defaults[.favorites] = favorites
        }
    }

    /// Removes a favorite record by ID.
    func removeFavorite(id: UUID) {
        var favorites = Defaults[.favorites]
        favorites.removeAll { $0.id == id }
        Defaults[.favorites] = favorites
    }

    /// Returns all favorite records.
    func getAllFavorites() -> [QueryRecord] {
        Defaults[.favorites]
    }

    /// Clears all favorite records.
    func clearAllFavorites() {
        Defaults[.favorites] = []
    }

    /// Checks whether the given query text is already favorited.
    @objc
    func isFavorited(queryText: String) -> Bool {
        Defaults[.favorites].contains { $0.queryText == queryText }
    }

    /// Adds a query to history, deduplicating and keeping the most recent records.
    @objc
    func addHistory(
        queryText: String,
        fromLanguage: Language,
        toLanguage: Language
    ) {
        let record = makeRecord(
            queryText: queryText,
            fromLanguage: fromLanguage,
            toLanguage: toLanguage
        )

        var history = Defaults[.queryHistory]

        // Remove existing duplicate to avoid multiple entries for the same query.
        history.removeAll { $0.queryText == queryText }

        // Add to the beginning.
        history.insert(record, at: 0)

        // Keep only the most recent records.
        if history.count > maxHistoryCount {
            history = Array(history.prefix(maxHistoryCount))
        }

        Defaults[.queryHistory] = history
    }

    /// Removes a history record by ID.
    func removeHistory(id: UUID) {
        var history = Defaults[.queryHistory]
        history.removeAll { $0.id == id }
        Defaults[.queryHistory] = history
    }

    /// Returns all history records.
    func getAllHistory() -> [QueryRecord] {
        Defaults[.queryHistory]
    }

    /// Clears all history records.
    func clearAllHistory() {
        Defaults[.queryHistory] = []
    }

    // MARK: Private

    /// Maximum number of history records to keep.
    private let maxHistoryCount = 1000

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
