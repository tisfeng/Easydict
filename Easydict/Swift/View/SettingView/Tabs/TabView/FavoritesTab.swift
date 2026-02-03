//
//  FavoritesTab.swift
//  Easydict
//
//  Created by Copilot on 2025/11/19.
//  Copyright © 2025 izual. All rights reserved.
//

import AppKit
import Defaults
import SwiftUI
import UniformTypeIdentifiers

// MARK: - FavoritesTab

/// Displays favorites and history in a single segmented view.
struct FavoritesTab: View {
    // MARK: Internal

    var body: some View {
        VStack(spacing: 16) {
            Picker(selection: $selectedSection) {
                Text("history.tab").tag(FavoritesSection.history)
                Text("favorites.tab").tag(FavoritesSection.favorites)
            } label: {
                EmptyView()
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top)
            .frame(width: 150)

            // Header
            HStack {
                Text(headerTitleKey)
                    .font(.headline)
                Spacer()
                Menu {
                    Button("favorites.export") {
                        exportRecords(for: .favorites)
                    }
                    .disabled(favorites.isEmpty)
                    Button("history.export") {
                        exportRecords(for: .history)
                    }
                    .disabled(history.isEmpty)
                } label: {
                    Label("common.export", systemImage: "square.and.arrow.up")
                        .labelStyle(.iconOnly)
                }
                .frame(maxWidth: 60)
            }
            .padding(.horizontal)

            if currentRecords.isEmpty {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: emptyStateImageName)
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text(emptyStateTitleKey)
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // List of records
                List {
                    ForEach(currentRecords) { record in
                        QueryRecordRow(record: record, onDelete: {
                            removeRecord(record)
                        })
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                removeRecord(record)
                            } label: {
                                Label("common.delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .borderedCard()
        .padding(20)
        .onReceive(Defaults.publisher(.favorites)) { change in
            favorites = change.newValue
        }
        .onReceive(Defaults.publisher(.queryHistory)) { change in
            history = change.newValue
        }
        .onAppear {
            loadRecords()
        }
    }

    // MARK: Private

    /// Formats export file names.
    private static let exportFileNameFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH-mm-ss"
        return formatter
    }()

    /// Formats export timestamps in a stable format.
    private static let exportTimestampFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    @State private var selectedSection: FavoritesSection = .favorites
    @State private var favorites: [QueryRecord] = []
    @State private var history: [QueryRecord] = []

    private var currentRecords: [QueryRecord] {
        selectedSection == .favorites ? favorites : history
    }

    private var headerTitleKey: LocalizedStringKey {
        selectedSection == .favorites ? "favorites.title" : "history.title"
    }

    private var emptyStateTitleKey: LocalizedStringKey {
        selectedSection == .favorites ? "favorites.empty" : "history.empty"
    }

    private var emptyStateImageName: String {
        selectedSection == .favorites ? "star.slash" : "clock.badge.xmark"
    }

    /// Removes a record from the currently selected section.
    private func removeRecord(_ record: QueryRecord) {
        switch selectedSection {
        case .favorites:
            QueryRecordManager.shared.removeRecord(id: record.id, from: .favorites)
        case .history:
            QueryRecordManager.shared.removeRecord(id: record.id, from: .history)
        }
    }

    /// Loads the favorites and history data for display.
    private func loadRecords() {
        favorites = QueryRecordManager.shared.getAllRecords(for: .favorites)
        history = QueryRecordManager.shared.getAllRecords(for: .history)
    }

    /// Exports the records for the given type to a CSV file.
    private func exportRecords(for type: QueryRecordManager.RecordType) {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [UTType.commaSeparatedText]
        savePanel.canCreateDirectories = true
        savePanel.isExtensionHidden = false
        savePanel.nameFieldStringValue = suggestedExportFileName(for: type)
        savePanel.begin { response in
            guard response == .OK, let url = savePanel.url else {
                return
            }
            let records = QueryRecordManager.shared.getAllRecords(for: type)
            let csv = makeCSV(for: records)
            do {
                try csv.write(to: url, atomically: true, encoding: .utf8)
                NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: "")
            } catch {
                logError("Export records failed: \(error)")
            }
        }
    }

    /// Builds a suggested export filename with a timestamp.
    private func suggestedExportFileName(for type: QueryRecordManager.RecordType) -> String {
        let typeName: String = type == .favorites ? "Favorites" : "History"
        let dateString = Self.exportFileNameFormatter.string(from: Date())
        return "Easydict \(typeName) \(dateString).csv"
    }

    /// Converts records to a CSV string.
    private func makeCSV(for records: [QueryRecord]) -> String {
        var rows = ["queryText,queryFromLanguage,queryToLanguage,timestamp"]
        rows.reserveCapacity(records.count + 1)
        for record in records {
            let timestamp = Self.exportTimestampFormatter.string(from: record.timestamp)
            let values = [
                record.queryText,
                record.queryFromLanguage.localizedName,
                record.queryToLanguage.localizedName,
                timestamp,
            ]
            rows.append(values.map(csvEscaped).joined(separator: ","))
        }
        return rows.joined(separator: "\n")
    }

    /// Escapes a value for CSV output.
    private func csvEscaped(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        if escaped.contains(",") || escaped.contains("\n") || escaped.contains("\r") {
            return "\"\(escaped)\""
        }
        return escaped
    }
}

// MARK: - FavoritesSection

/// Represents the section shown in the favorites tab.
private enum FavoritesSection: String, CaseIterable, Identifiable {
    case favorites
    case history

    // MARK: Internal

    var id: String { rawValue }
}

// MARK: - QueryRecordRow

/// Displays a query record with quick actions.
struct QueryRecordRow: View {
    // MARK: Internal

    let record: QueryRecord
    let onDelete: () -> ()

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(record.queryText)
                    .font(.body)
                    .lineLimit(1)
                Text(Self.timestampFormatter.string(from: record.timestamp))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            HStack(spacing: 12) {
                Button {
                    performQuery()
                } label: {
                    Label("common.query", systemImage: "magnifyingglass")
                        .labelStyle(.titleAndIcon)
                }

                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("common.delete", systemImage: "trash")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: Private

    /// Formats timestamps without relative updates.
    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    /// Replays the query stored in this record.
    private func performQuery() {
        let windowType = Defaults[.shortcutSelectTranslateWindowType]

        // Trigger a new query with the stored text and languages
        let windowManager = EZWindowManager.shared()
        windowManager.showFloating(windowType, queryText: record.queryText, autoQuery: true, actionType: .inputQuery)
    }
}

#Preview {
    FavoritesTab()
        .frame(width: 900, height: 640)
}
