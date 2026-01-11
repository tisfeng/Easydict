//
//  QueryRecord.swift
//  Easydict
//
//  Created by Copilot on 2025/11/19.
//  Copyright © 2025 izual. All rights reserved.
//

import Defaults
import Foundation

// MARK: - QueryRecord

/// Represents a single query record for favorites or history
struct QueryRecord: Codable, Identifiable, Hashable, Defaults.Serializable {
    // MARK: Lifecycle

    init(
        id: UUID = UUID(),
        queryText: String,
        queryFromLanguage: Language,
        queryToLanguage: Language,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.queryText = queryText
        self.queryFromLanguage = queryFromLanguage
        self.queryToLanguage = queryToLanguage
        self.timestamp = timestamp
    }

    // MARK: Internal

    let id: UUID
    let queryText: String
    let queryFromLanguage: Language
    let queryToLanguage: Language
    let timestamp: Date

    static func == (lhs: QueryRecord, rhs: QueryRecord) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
