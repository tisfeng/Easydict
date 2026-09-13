//
//  WordbookQuery.swift
//  Easydict
//
//  Created by liangkaiwen on 2026/7/13.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation

// MARK: - WordbookQuery

/// Produces pure in-memory projections for saved entries and query history.
/// Scope, search, and deterministic ordering stay independent from persistence
/// so callers can reuse the same behavior without triggering storage access.
struct WordbookQuery {
    // MARK: Internal

    func entries(
        in snapshot: WordbookSnapshot,
        scope: WordbookGroupScope,
        searchText: String,
        sortOrder: WordbookSortOrder,
        locale: Locale = .current
    )
        -> [WordbookEntry] {
        let scoped = snapshot.entries.filter { entry in
            switch scope {
            case .all:
                true
            case .ungrouped:
                entry.groupID == nil
            case let .group(id):
                entry.groupID == id
            }
        }
        let needle = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let filtered = needle.isEmpty ? scoped : scoped.filter { entry in
            contains(entry.text, needle: needle, locale: locale)
                || contains(entry.note, needle: needle, locale: locale)
        }

        return filtered.sorted { first, second in
            switch sortOrder {
            case .newest:
                if first.createdAt != second.createdAt {
                    return first.createdAt > second.createdAt
                }
            case .oldest:
                if first.createdAt != second.createdAt {
                    return first.createdAt < second.createdAt
                }
            case .text:
                let order = first.text.compare(
                    second.text,
                    options: [.caseInsensitive],
                    range: nil,
                    locale: locale
                )
                if order != .orderedSame {
                    return order == .orderedAscending
                }
                if first.createdAt != second.createdAt {
                    return first.createdAt < second.createdAt
                }
            }

            return first.id.uuidString < second.id.uuidString
        }
    }

    func history(
        _ records: [QueryRecord],
        searchText: String,
        sortOrder: WordbookHistorySortOrder,
        locale: Locale = .current
    )
        -> [QueryRecord] {
        let needle = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let filtered = needle.isEmpty ? records : records.filter { record in
            contains(record.queryText, needle: needle, locale: locale)
        }

        return filtered.sorted { first, second in
            if first.timestamp != second.timestamp {
                return sortOrder == .newest
                    ? first.timestamp > second.timestamp
                    : first.timestamp < second.timestamp
            }

            return first.id.uuidString < second.id.uuidString
        }
    }

    // MARK: Private

    private func contains(
        _ value: String,
        needle: String,
        locale: Locale
    )
        -> Bool {
        value.range(
            of: needle,
            options: [.caseInsensitive],
            range: value.startIndex ..< value.endIndex,
            locale: locale
        ) != nil
    }
}
