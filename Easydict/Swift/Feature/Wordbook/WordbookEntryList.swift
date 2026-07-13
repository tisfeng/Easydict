//
//  WordbookEntryList.swift
//  Easydict
//
//  Created by liangkaiwen on 2026/7/14.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation
import SFSafeSymbols
import SwiftUI

// MARK: - WordbookEntryList

/// Renders the visible saved entries as a native selectable macOS list. Each
/// row preserves localized language and date metadata, supports explicit and
/// double-click replay, and exposes Return only when one visible entry is
/// selected and the root view allows the default action.
struct WordbookEntryList: View {
    // MARK: Internal

    let entries: [WordbookEntry]
    @Binding var selection: Set<UUID>

    let allowsReturnReplay: Bool
    let onQuery: (WordbookEntry) -> ()

    var body: some View {
        List(selection: $selection) {
            ForEach(entries) { entry in
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.text)
                            .lineLimit(2)
                        if !entry.note.isEmpty {
                            Text(entry.note)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        Text(metadata(for: entry))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 12)

                    Button {
                        onQuery(entry)
                    } label: {
                        Label("common.query", systemSymbol: .magnifyingglass)
                    }
                    .buttonStyle(.borderless)
                }
                .contentShape(Rectangle())
                .onTapGesture(count: 2) {
                    onQuery(entry)
                }
                .tag(entry.id)
                .padding(.vertical, 4)
            }
        }
        .background {
            if let selectedEntry {
                Button("common.query") {
                    onQuery(selectedEntry)
                }
                .keyboardShortcut(.defaultAction)
                .frame(width: 0, height: 0)
                .focusable(false)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
                .disabled(!allowsReturnReplay)
            }
        }
    }

    // MARK: Private

    @Environment(\.locale) private var locale

    private var selectedEntry: WordbookEntry? {
        let selectedEntries = entries.filter { selection.contains($0.id) }
        guard selectedEntries.count == 1 else { return nil }
        return selectedEntries.first
    }

    /// Formats the stored direction and creation time in the app locale.
    private func metadata(for entry: WordbookEntry) -> String {
        let date = entry.createdAt.formatted(
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
                entry.fromLanguage.localizedName as CVarArg,
                entry.toLanguage.localizedName as CVarArg,
                date as CVarArg,
            ]
        )
    }
}
