//
//  TranslationHistoryView.swift
//  Easydict
//
//  Created by Ryan on 2026/01/10.
//  Copyright © 2026 izual. All rights reserved.
//

import SwiftUI

// MARK: - TranslationHistoryView

/// View displaying translation history with swipe gesture support.
struct TranslationHistoryView: View {
    // MARK: Lifecycle

    init(onSelectHistory: @escaping (TranslationHistoryItem) -> ()) {
        self.onSelectHistory = onSelectHistory
    }

    // MARK: Internal

    /// Callback when a history item is selected.
    let onSelectHistory: (TranslationHistoryItem) -> ()

    var body: some View {
        VStack(spacing: 0) {
            if historyManager.historyItems.isEmpty {
                emptyStateView
            } else {
                historyListView
            }
        }
        .environmentObject(historyManager)
    }

    // MARK: Private

    @StateObject private var historyManager = TranslationHistoryManager.shared

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("translation.history.empty")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var historyListView: some View {
        List {
            ForEach(historyManager.historyItems) { item in
                HistoryItemRow(item: item, onSelect: {
                    onSelectHistory(item)
                })
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        historyManager.removeHistory(id: item.id)
                    } label: {
                        Label("delete", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.plain)
    }
}

// MARK: - HistoryItemRow

/// Row view for a single history item.
private struct HistoryItemRow: View {
    // MARK: Lifecycle

    init(item: TranslationHistoryItem, onSelect: @escaping () -> ()) {
        self.item = item
        self.onSelect = onSelect
    }

    // MARK: Internal

    let item: TranslationHistoryItem
    let onSelect: () -> ()

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                // Query text
                HStack {
                    Text(item.queryText)
                        .font(.body)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    Spacer()
                }

                // Translated text
                HStack {
                    Text(item.translatedText)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    Spacer()
                }

                // Metadata
                HStack(spacing: 12) {
                    // Language info
                    HStack(spacing: 4) {
                        Text(item.fromLanguage.localizedName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Image(systemName: "arrow.right")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(item.toLanguage.localizedName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // Timestamp - show fixed formatted time, not relative
                    Text(formatTimestamp(item.timestamp))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
        }
        .buttonStyle(.plain)
    }

    // MARK: Private

    /// Formats timestamp for display (fixed format, no auto-update).
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            // Today: show time only
            formatter.dateFormat = "HH:mm"
        } else if calendar.isDateInYesterday(date) {
            // Yesterday: show "Yesterday HH:mm"
            formatter.dateFormat = "HH:mm"
            return "Yesterday \(formatter.string(from: date))"
        } else if calendar.dateInterval(of: .weekOfYear, for: date)?.contains(Date()) == true {
            // This week: show day name and time
            formatter.dateFormat = "EEE HH:mm"
        } else {
            // Older: show date and time
            formatter.dateFormat = "MM/dd HH:mm"
        }

        return formatter.string(from: date)
    }
}
