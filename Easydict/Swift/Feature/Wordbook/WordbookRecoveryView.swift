//
//  WordbookRecoveryView.swift
//  Easydict
//
//  Created by liangkaiwen on 2026/7/14.
//  Copyright © 2026 izual. All rights reserved.
//

import SFSafeSymbols
import SwiftUI

// MARK: - WordbookRecoveryView

/// Presents safe recovery actions for repository protection and load failures.
/// The view intentionally receives storage actions from its owner so it never
/// derives file locations or performs destructive reset without confirmation.
struct WordbookRecoveryView: View {
    // MARK: Internal

    let state: WordbookRepositoryState
    let onRetry: () -> ()
    let onShowInFinder: () -> ()
    let onReset: () -> ()

    @ViewBuilder var body: some View {
        switch state.phase {
        case .loading, .ready:
            EmptyView()
        case .protected(.corrupt):
            statusView(
                title: Text("wordbook.recovery.corrupt.title"),
                message: Text("wordbook.recovery.corrupt.message"),
                allowsRetry: true,
                allowsReset: true
            )
        case let .protected(.newerSchema(version, _)):
            statusView(
                title: Text("wordbook.recovery.newer.title"),
                message: Text(newerSchemaMessage(version: version)),
                allowsRetry: false,
                allowsReset: false
            )
        case .failed:
            statusView(
                title: Text("wordbook.recovery.failed.title"),
                message: Text("wordbook.recovery.failed.message"),
                allowsRetry: true,
                allowsReset: false
            )
        }
    }

    // MARK: Private

    @Environment(\.locale) private var locale

    private func statusView(
        title: Text,
        message: Text,
        allowsRetry: Bool,
        allowsReset: Bool
    )
        -> some View {
        VStack(spacing: 12) {
            title
                .font(.title2)
                .fontWeight(.semibold)
            message
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 460)

            HStack(spacing: 12) {
                if allowsRetry {
                    Button(action: onRetry) {
                        Label("retry", systemSymbol: .arrowClockwise)
                    }
                }

                Button(action: onShowInFinder) {
                    Label(
                        "wordbook.recovery.show_in_finder",
                        systemSymbol: .folder
                    )
                }

                if allowsReset {
                    Button(role: .destructive, action: onReset) {
                        Label(
                            "wordbook.recovery.reset",
                            systemSymbol: .trash
                        )
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func newerSchemaMessage(version: Int) -> String {
        String(
            format: String(
                localized: "wordbook.recovery.newer.message",
                locale: locale
            ),
            locale: locale,
            arguments: [Int64(version) as CVarArg]
        )
    }
}

// MARK: - WordbookRecoveryNoticeView

/// Displays a dismissible, non-color-only notice after backup restoration.
/// Dismissal remains local to the window and does not alter repository state.
struct WordbookRecoveryNoticeView: View {
    let notice: WordbookRecoveryNotice
    let onDismiss: () -> ()

    var body: some View {
        switch notice {
        case .restoredBackup:
            HStack(spacing: 10) {
                Image(systemSymbol: .exclamationmarkTriangle)
                    .accessibilityHidden(true)
                Text("wordbook.recovery.restored.message")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Button("wordbook.action.dismiss", action: onDismiss)
            }
            .padding(10)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.yellow.opacity(0.14))
            }
        }
    }
}
