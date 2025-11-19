//
//  FavoritesManager.swift
//  Easydict
//
//  Created by Copilot on 2025/11/19.
//  Copyright © 2025 izual. All rights reserved.
//

import Defaults
import Foundation

// MARK: - FavoritesManager

/// Manages favorites operations
@objc
class FavoritesManager: NSObject {
    // MARK: Lifecycle

    override private init() {
        super.init()
    }

    // MARK: Internal

    static let shared = FavoritesManager()

    /// Add a query to favorites
    @objc
    func addFavorite(
        queryText: String,
        fromLanguage: Language,
        toLanguage: Language
    ) {
        let record = QueryRecord(
            queryText: queryText,
            queryFromLanguage: fromLanguage,
            queryToLanguage: toLanguage
        )

        var favorites = Defaults[.favorites]
        
        // Avoid duplicates - check if the same query text already exists
        if !favorites.contains(where: { $0.queryText == queryText }) {
            favorites.insert(record, at: 0)
            Defaults[.favorites] = favorites
        }
    }

    /// Remove a favorite by ID
    func removeFavorite(id: UUID) {
        var favorites = Defaults[.favorites]
        favorites.removeAll { $0.id == id }
        Defaults[.favorites] = favorites
    }

    /// Get all favorites
    func getAllFavorites() -> [QueryRecord] {
        Defaults[.favorites]
    }

    /// Clear all favorites
    func clearAllFavorites() {
        Defaults[.favorites] = []
    }

    /// Check if a query text is already favorited
    @objc
    func isFavorited(queryText: String) -> Bool {
        Defaults[.favorites].contains { $0.queryText == queryText }
    }
}
