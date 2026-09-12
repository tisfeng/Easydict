//
//  WordbookEntryEditor.swift
//  Easydict
//
//  Created by liangkaiwen on 2026/7/14.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation
import SwiftUI

// MARK: - WordbookEntryEditor

/// Edits one saved entry using local note and group drafts initialized when
/// the sheet opens. Read-only text, language, and timestamp metadata retain
/// the persisted context, while only the explicit Save action emits one write.
struct WordbookEntryEditor: View {
    // MARK: Lifecycle

    init(
        entry: WordbookEntry,
        groups: [WordbookGroup],
        canSave: Bool,
        onSave: @escaping (String, UUID?) -> ()
    ) {
        self.entry = entry
        self.groups = groups
        self.canSave = canSave
        self.onSave = onSave
        _note = State(initialValue: entry.note)
        _groupID = State(initialValue: entry.groupID)
    }

    // MARK: Internal

    let entry: WordbookEntry
    let groups: [WordbookGroup]
    let canSave: Bool
    let onSave: (String, UUID?) -> ()

    var body: some View {
        Form {
            LabeledContent("wordbook.entry.text") {
                Text(entry.text)
                    .textSelection(.enabled)
            }
            LabeledContent("wordbook.entry.languages") {
                Text(languagePair)
            }
            Picker("wordbook.entry.group", selection: $groupID) {
                Text("wordbook.group.ungrouped")
                    .tag(UUID?.none)
                ForEach(groups) { group in
                    Text(group.name)
                        .tag(Optional(group.id))
                }
            }
            TextEditor(text: $note)
                .frame(minHeight: 140)
                .accessibilityLabel("wordbook.entry.note")
            LabeledContent("wordbook.entry.created_at") {
                Text(dateText(entry.createdAt))
            }
            LabeledContent("wordbook.entry.updated_at") {
                Text(dateText(entry.updatedAt))
            }
            HStack {
                Spacer()
                Button("cancel") {
                    dismiss()
                }
                Button("wordbook.action.save") {
                    onSave(note, groupID)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!canSave)
            }
        }
        .padding(20)
        .frame(width: 560, height: 480)
    }

    // MARK: Private

    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    @State private var note: String
    @State private var groupID: UUID?

    private var languagePair: String {
        String(
            format: String(
                localized: "wordbook.entry.language_pair",
                locale: locale
            ),
            locale: locale,
            arguments: [
                entry.fromLanguage.localizedName as CVarArg,
                entry.toLanguage.localizedName as CVarArg,
            ]
        )
    }

    private func dateText(_ date: Date) -> String {
        date.formatted(
            Date.FormatStyle(date: .abbreviated, time: .shortened)
                .locale(locale)
        )
    }
}
