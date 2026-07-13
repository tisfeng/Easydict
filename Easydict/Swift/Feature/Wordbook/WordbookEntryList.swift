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

/// Renders saved entries as a native multi-select macOS list with row and batch
/// commands. Query and copy remain available whenever the ready list is shown,
/// while editing, moving, and deleting follow the supplied mutation gate and
/// Return replays only one visible selection when the root permits it.
struct WordbookEntryList: View {
    // MARK: Internal

    let entries: [WordbookEntry]
    let groups: [WordbookGroup]
    @Binding var selection: Set<UUID>

    let allowsReturnReplay: Bool
    let canMutate: Bool
    let onQuery: (WordbookEntry) -> ()
    let onEdit: (WordbookEntry) -> ()
    let onMove: (Set<UUID>, UUID?) -> ()
    let onCopy: (WordbookEntry) -> ()
    let onDelete: (Set<UUID>) -> ()

    var body: some View {
        VStack(spacing: 0) {
            if !selection.isEmpty {
                HStack {
                    batchMenu
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }

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
                    .contextMenu {
                        contextMenu(for: entry)
                    }
                    .tag(entry.id)
                    .padding(.vertical, 4)
                }
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

    private var batchMenu: some View {
        Menu {
            moveMenu(ids: selection)

            Divider()

            Button(role: .destructive) {
                onDelete(selection)
            } label: {
                Label("common.delete", systemSymbol: .trash)
            }
        } label: {
            Label("wordbook.bulk.actions", systemSymbol: .ellipsisCircle)
        }
        .disabled(!canMutate)
    }

    @ViewBuilder
    private func contextMenu(for entry: WordbookEntry) -> some View {
        Button {
            onQuery(entry)
        } label: {
            Label("common.query", systemSymbol: .magnifyingglass)
        }

        Button {
            onEdit(entry)
        } label: {
            Label("wordbook.action.edit_note", systemSymbol: .squareAndPencil)
        }
        .disabled(!canMutate)

        moveMenu(ids: [entry.id])
            .disabled(!canMutate)

        Button {
            onCopy(entry)
        } label: {
            Label("wordbook.action.copy_text", systemSymbol: .docOnDoc)
        }

        Divider()

        Button(role: .destructive) {
            onDelete([entry.id])
        } label: {
            Label("common.delete", systemSymbol: .trash)
        }
        .disabled(!canMutate)
    }

    private func moveMenu(ids: Set<UUID>) -> some View {
        Menu {
            Button("wordbook.group.ungrouped") {
                onMove(ids, nil)
            }
            ForEach(groups) { group in
                Button(group.name) {
                    onMove(ids, group.id)
                }
            }
        } label: {
            Label("wordbook.action.move_to_group", systemSymbol: .folder)
        }
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
