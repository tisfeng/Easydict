//
//  MDictConfigurationView.swift
//  Easydict
//
//  Created by Kuroda Kayn on 2026/05/01.
//  Copyright © 2026 izual. All rights reserved.
//

import SFSafeSymbols
import SwiftUI

// MARK: - MDictConfigurationView

/// SwiftUI configuration panel for the MDict service.
///
/// Lists imported dictionaries, allows toggling, reordering, removing them,
/// and importing new MDX files via a file picker.
struct MDictConfigurationView: View {
    // MARK: Internal

    var body: some View {
        Section {
            ForEach(manager.records) { record in
                DictionaryRow(record: record)
            }
            .onMove { from, to in
                manager.moveDictionary(from: from, to: to)
            }
            .onDelete { offsets in
                manager.removeDictionary(at: offsets)
            }
        } header: {
            HStack {
                Text("service.mdict.section.dictionaries")
                Spacer()
                Button {
                    isImporting = true
                } label: {
                    Label("service.mdict.button.import", systemSymbol: .plus)
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.borderless)
            }
        } footer: {
            if manager.records.isEmpty {
                Text("service.mdict.hint.no_dictionaries")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.init(filenameExtension: "mdx")!],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result)
        }
        .alert(
            "service.mdict.error.import_failed",
            isPresented: $showError
        ) {
            Button("ok") { showError = false }
        } message: {
            Text(importError ?? "")
        }
    }

    // MARK: Private

    @ObservedObject private var manager = MDictManager.shared
    @State private var isImporting = false
    @State private var showError = false
    @State private var importError: String?

    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case let .success(urls):
            guard let url = urls.first else { return }
            let accessed = url.startAccessingSecurityScopedResource()
            defer { if accessed { url.stopAccessingSecurityScopedResource() } }
            do {
                try manager.importDictionary(mdxURL: url)
            } catch {
                importError = error.localizedDescription
                showError = true
            }
        case let .failure(error):
            importError = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - DictionaryRow

/// A single row in the MDict dictionary list showing title and enable toggle.
private struct DictionaryRow: View {
    // MARK: Internal

    let record: MDictDictionaryRecord

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(record.title)
                    .lineLimit(1)
                Text(URL(fileURLWithPath: record.mdxPath).lastPathComponent)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            Toggle("", isOn: Binding(
                get: { record.enabled },
                set: { manager.setEnabled($0, for: record) }
            ))
            .toggleStyle(.switch)
            .controlSize(.small)
            .labelsHidden()
        }
        .padding(.vertical, 2)
    }

    // MARK: Private

    @ObservedObject private var manager = MDictManager.shared
}
