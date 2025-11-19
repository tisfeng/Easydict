//
//  HistoryManager.swift
//  Easydict
//
//  Created by Copilot on 2025/11/19.
//  Copyright © 2025 izual. All rights reserved.
//

import Defaults
import Foundation

// MARK: - HistoryManager

/// Manages query history operations
@objc
class HistoryManager: NSObject {
    // MARK: Lifecycle

    override private init() {
        super.init()
    }

    // MARK: Internal

    static let shared = HistoryManager()

    /// Maximum number of history records to keep
    private let maxHistoryCount = 1000

    /// Add a query to history
    @objc
    func addHistory(
        queryText: String,
        fromLanguage: Language,
        toLanguage: Language
    ) {
        let record = QueryRecord(
            queryText: queryText,
            queryFromLanguage: fromLanguage,
            queryToLanguage: toLanguage
        )

        var history = Defaults[.queryHistory]
        
        // Remove existing duplicate to avoid multiple entries for the same query
        history.removeAll { $0.queryText == queryText }
        
        // Add to the beginning
        history.insert(record, at: 0)
        
        // Keep only the most recent records
        if history.count > maxHistoryCount {
            history = Array(history.prefix(maxHistoryCount))
        }
        
        Defaults[.queryHistory] = history
    }

    /// Remove a history record by ID
    func removeHistory(id: UUID) {
        var history = Defaults[.queryHistory]
        history.removeAll { $0.id == id }
        Defaults[.queryHistory] = history
    }

    /// Get all history records
    func getAllHistory() -> [QueryRecord] {
        Defaults[.queryHistory]
    }

    /// Clear all history
    func clearAllHistory() {
        Defaults[.queryHistory] = []
    }
}
