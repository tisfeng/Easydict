//
//  HistoryTab.swift
//  Easydict
//
//  Created by Copilot on 2025/11/19.
//  Copyright © 2025 izual. All rights reserved.
//

import Defaults
import SwiftUI

// MARK: - HistoryTab

struct HistoryTab: View {
    // MARK: Internal

    var body: some View {
        VStack(spacing: 16) {
            // Header with clear button
            HStack {
                Text("history.title")
                    .font(.headline)
                Spacer()
                Button(action: {
                    showingClearAlert = true
                }) {
                    Text("history.clear_all")
                }
                .disabled(history.isEmpty)
                .alert(isPresented: $showingClearAlert) {
                    Alert(
                        title: Text("history.clear_alert.title"),
                        message: Text("history.clear_alert.message"),
                        primaryButton: .destructive(Text("history.clear_alert.confirm")) {
                            HistoryManager.shared.clearAllHistory()
                        },
                        secondaryButton: .cancel()
                    )
                }
            }
            .padding(.horizontal)
            .padding(.top)

            if history.isEmpty {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "clock.badge.xmark")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("history.empty")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // List of history records
                List {
                    ForEach(history) { record in
                        QueryRecordRow(record: record)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    HistoryManager.shared.removeHistory(id: record.id)
                                } label: {
                                    Label("common.delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onReceive(Defaults.publisher(.queryHistory)) { change in
            history = change.newValue
        }
        .onAppear {
            history = HistoryManager.shared.getAllHistory()
        }
    }

    // MARK: Private

    @State private var history: [QueryRecord] = []
    @State private var showingClearAlert = false
}

#Preview {
    HistoryTab()
        .frame(width: 900, height: 640)
}
