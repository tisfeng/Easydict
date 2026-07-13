//
//  WordbookHistoryView.swift
//  Easydict
//
//  Created by liangkaiwen on 2026/7/14.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation
import SFSafeSymbols
import SwiftUI

// MARK: - WordbookHistoryView

/// Displays the current query-history projection with stored language and time
/// metadata. Its star adds missing entries without becoming a removal surface;
/// replay and deletion remain explicit actions owned by the shared root model.
struct WordbookHistoryView: View {
    // MARK: Internal

    let records: [QueryRecord]
    let savedKeys: Set<WordbookEntryKey>
    let canAdd: Bool
    let onAdd: (QueryRecord) -> ()
    let onQuery: (QueryRecord) -> ()
    let onDelete: (QueryRecord) -> ()

    var body: some View {
        List(records) { record in
            row(for: record)
        }
    }

    // MARK: Private

    @Environment(\.locale) private var locale

    private func row(for record: QueryRecord) -> some View {
        let key = WordbookEntryKey(
            text: record.queryText,
            fromLanguage: record.queryFromLanguage,
            toLanguage: record.queryToLanguage
        )
        let isSaved = key.map { savedKeys.contains($0) } ?? false

        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(record.queryText)
                    .lineLimit(2)
                Text(metadata(for: record))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 12)
            starButton(for: record, isSaved: isSaved)

            Button {
                onQuery(record)
            } label: {
                Label("common.query", systemSymbol: .magnifyingglass)
            }
            .buttonStyle(.borderless)

            Button(role: .destructive) {
                onDelete(record)
            } label: {
                Label("common.delete", systemSymbol: .trash)
                    .labelStyle(.iconOnly)
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func starButton(
        for record: QueryRecord,
        isSaved: Bool
    )
        -> some View {
        if isSaved {
            Button {} label: {
                Label(
                    "wordbook.history.already_added",
                    systemSymbol: .starFill
                )
                .labelStyle(.iconOnly)
            }
            .buttonStyle(.borderless)
            .disabled(true)
            .help("wordbook.history.already_added")
        } else {
            Button {
                onAdd(record)
            } label: {
                Label("wordbook.history.add", systemSymbol: .star)
                    .labelStyle(.iconOnly)
            }
            .buttonStyle(.borderless)
            .disabled(!canAdd)
            .help("wordbook.history.add")
        }
    }

    /// Formats the stored direction and query time in the app locale.
    private func metadata(for record: QueryRecord) -> String {
        let date = record.timestamp.formatted(
            Date.FormatStyle(date: .abbreviated, time: .shortened)
                .locale(locale)
        )
        return String(
            format: String(
                localized: "wordbook.entry.metadata",
                locale: locale
            ),
            locale: locale,
            arguments: [
                record.queryFromLanguage.localizedName as CVarArg,
                record.queryToLanguage.localizedName as CVarArg,
                date as CVarArg,
            ]
        )
    }
}
