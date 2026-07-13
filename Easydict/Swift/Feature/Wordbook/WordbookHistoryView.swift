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
/// metadata. Replay and destructive deletion remain explicit borderless row
/// actions, while filtering and ordering stay owned by the shared root model.
struct WordbookHistoryView: View {
    // MARK: Internal

    let records: [QueryRecord]
    let onQuery: (QueryRecord) -> ()
    let onDelete: (QueryRecord) -> ()

    var body: some View {
        List(records) { record in
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(record.queryText)
                        .lineLimit(2)
                    Text(metadata(for: record))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 12)

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
    }

    // MARK: Private

    @Environment(\.locale) private var locale

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
