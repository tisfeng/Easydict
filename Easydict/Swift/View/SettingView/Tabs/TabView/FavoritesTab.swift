//
//  FavoritesTab.swift
//  Easydict
//
//  Created by Copilot on 2025/11/19.
//  Copyright © 2025 izual. All rights reserved.
//

import Defaults
import SwiftUI

// MARK: - FavoritesTab

/// Displays favorites and history in a single segmented view.
struct FavoritesTab: View {
    // MARK: Internal

    var body: some View {
        VStack(spacing: 16) {
            Picker(selection: $selectedSection) {
                Text("favorites.tab").tag(FavoritesSection.favorites)
                Text("history.tab").tag(FavoritesSection.history)
            } label: {
                EmptyView()
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top)

            // Header
            HStack {
                Text(headerTitleKey)
                    .font(.headline)
                Spacer()
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
                        QueryRecordRow(record: record)
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
            QueryRecordManager.shared.removeFavorite(id: record.id)
        case .history:
            QueryRecordManager.shared.removeHistory(id: record.id)
        }
    }

    /// Loads the favorites and history data for display.
    private func loadRecords() {
        favorites = QueryRecordManager.shared.getAllFavorites()
        history = QueryRecordManager.shared.getAllHistory()
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

/// Displays a query record and triggers a new query on tap.
struct QueryRecordRow: View {
    // MARK: Internal

    let record: QueryRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(record.queryText)
                .font(.body)
                .lineLimit(2)
            HStack {
                Label(
                    "\(record.queryFromLanguage.localizedName) → \(record.queryToLanguage.localizedName)",
                    systemImage: "arrow.left.arrow.right"
                )
                .font(.caption)
                .foregroundColor(.secondary)
                Spacer()
                Text(Self.timestampFormatter.string(from: record.timestamp))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            performQuery()
        }
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
