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

struct FavoritesTab: View {
    // MARK: Internal

    var body: some View {
        VStack(spacing: 16) {
            // Header with clear button
            HStack {
                Text("favorites.title")
                    .font(.headline)
                Spacer()
                Button(action: {
                    showingClearAlert = true
                }) {
                    Text("favorites.clear_all")
                }
                .disabled(favorites.isEmpty)
                .alert(isPresented: $showingClearAlert) {
                    Alert(
                        title: Text("favorites.clear_alert.title"),
                        message: Text("favorites.clear_alert.message"),
                        primaryButton: .destructive(Text("favorites.clear_alert.confirm")) {
                            FavoritesManager.shared.clearAllFavorites()
                        },
                        secondaryButton: .cancel()
                    )
                }
            }
            .padding(.horizontal)
            .padding(.top)

            if favorites.isEmpty {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "star.slash")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("favorites.empty")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // List of favorites
                List {
                    ForEach(favorites) { record in
                        QueryRecordRow(record: record)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    FavoritesManager.shared.removeFavorite(id: record.id)
                                } label: {
                                    Label("common.delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onReceive(Defaults.publisher(.favorites)) { change in
            favorites = change.newValue
        }
        .onAppear {
            favorites = FavoritesManager.shared.getAllFavorites()
        }
    }

    // MARK: Private

    @State private var favorites: [QueryRecord] = []
    @State private var showingClearAlert = false
}

// MARK: - QueryRecordRow

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
                Text(record.timestamp, style: .relative)
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

    private func performQuery() {
        // Trigger a new query with the stored text and languages
        let windowManager = EZWindowManager.shared()

        // Show main window if needed
        windowManager.showMainWindowIfNeeded()

        // Get the main window and perform the query
        if let mainWindow = windowManager.mainWindow {
            let viewController = mainWindow.queryViewController
            viewController.startQueryText(
                record.queryText,
                actionType: EZActionType.selectTextTranslate
            )
        }
    }
}

#Preview {
    FavoritesTab()
        .frame(width: 900, height: 640)
}
