//
//  WordbookCSVExporter.swift
//  Easydict
//
//  Created by liangkaiwen on 2026/7/13.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation

// MARK: - WordbookCSVExporter

/// Builds deterministic CSV text for ordered wordbook entries and query
/// history records. Callers supply display names explicitly, keeping export
/// formatting independent from localization, search, persistence, and UI
/// state while preserving exact schemas and RFC 4180 escaping.
struct WordbookCSVExporter {
    // MARK: Internal

    /// Encodes entries using the exact seven-column wordbook schema.
    func makeWordbookCSV(
        entries: [WordbookEntry],
        groups: [WordbookGroup],
        ungroupedName: String,
        languageName: (Language) -> String
    )
        -> String {
        let groupNames = Dictionary(
            uniqueKeysWithValues: groups.map { ($0.id, $0.name) }
        )
        var rows = [
            [
                "text", "fromLanguage", "toLanguage", "note",
                "group", "createdAt", "updatedAt",
            ],
        ]
        rows.reserveCapacity(entries.count + 1)
        for entry in entries {
            rows.append([
                entry.text,
                languageName(entry.fromLanguage),
                languageName(entry.toLanguage),
                entry.note,
                entry.groupID.flatMap { groupNames[$0] } ?? ungroupedName,
                iso8601(entry.createdAt),
                iso8601(entry.updatedAt),
            ])
        }
        return encode(rows)
    }

    /// Encodes records using the exact four-column query-history schema.
    func makeHistoryCSV(
        records: [QueryRecord],
        languageName: (Language) -> String
    )
        -> String {
        var rows = [
            [
                "queryText", "queryFromLanguage", "queryToLanguage", "timestamp",
            ],
        ]
        rows.reserveCapacity(records.count + 1)
        for record in records {
            rows.append([
                record.queryText,
                languageName(record.queryFromLanguage),
                languageName(record.queryToLanguage),
                iso8601(record.timestamp),
            ])
        }
        return encode(rows)
    }

    // MARK: Private

    private func encode(_ rows: [[String]]) -> String {
        rows.map { $0.map(escape).joined(separator: ",") }
            .joined(separator: "\r\n") + "\r\n"
    }

    private func escape(_ value: String) -> String {
        let requiresQuotes = value.contains(",") || value.contains("\"")
            || value.contains("\r") || value.contains("\n")
        guard requiresQuotes else { return value }
        return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
    }

    private func iso8601(_ date: Date) -> String {
        ISO8601DateFormatter.string(
            from: date,
            timeZone: TimeZone(secondsFromGMT: 0)!,
            formatOptions: [.withInternetDateTime]
        )
    }
}
