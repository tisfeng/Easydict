//
//  WordbookView.swift
//  Easydict
//
//  Created by liangkaiwen on 2026/7/14.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation
import SFSafeSymbols
import SwiftUI

// MARK: - WordbookView

/// Composes the reusable Wordbook window from repository state and
/// window-scoped browsing controls. It injects the app-selected locale into
/// every child, keeps the existing hosted model alive between red-close and
/// reopen, and routes loading, recovery summaries, saved entries, and history.
struct WordbookView: View {
    // MARK: Internal

    var body: some View {
        content
            .environmentObject(languageState)
            .environment(\.locale, locale)
            .task {
                viewModel.updateLocale(locale)
                viewModel.start()
            }
            .onReceive(
                NotificationCenter.default.publisher(
                    for: .languagePreferenceChanged
                )
            ) { _ in
                let locale = Locale(
                    identifier: languageState.language.rawValue
                )
                viewModel.updateLocale(locale)
                HostWindowManager.shared.updateWindowTitle(
                    windowId: .wordbookWindowId,
                    title: String(
                        localized: "wordbook.window.title",
                        locale: locale
                    )
                )
            }
    }

    // MARK: Private

    @StateObject private var languageState = LanguageState()
    @StateObject private var viewModel = WordbookViewModel()
    @FocusState private var searchFocused: Bool

    private var locale: Locale {
        Locale(identifier: languageState.language.rawValue)
    }

    @ViewBuilder private var content: some View {
        switch viewModel.repositoryState.phase {
        case .loading:
            loadingView
        case .ready:
            readyView
        case let .protected(protection):
            protectedView(protection)
        case .failed:
            statusView(
                title: Text("wordbook.recovery.failed.title"),
                message: Text("wordbook.recovery.failed.message")
            )
        }
    }

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("wordbook.loading")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var readyView: some View {
        VStack(spacing: 12) {
            Picker("wordbook.section.label", selection: $viewModel.section) {
                Text("wordbook.section.wordbook")
                    .tag(WordbookSection.wordbook)
                Text("wordbook.section.history")
                    .tag(WordbookSection.history)
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 360)
            .padding(.top, 16)

            toolbar
                .padding(.horizontal, 16)

            sectionContent
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var toolbar: some View {
        HStack(spacing: 12) {
            if viewModel.section == .wordbook {
                WordbookGroupMenu(
                    groups: viewModel.groups,
                    scope: viewModel.scope,
                    defaultGroupID: viewModel.snapshot.defaultGroupID,
                    count: viewModel.scopeCount
                ) { scope in
                    viewModel.scope = scope
                }
                .frame(minWidth: 190, alignment: .leading)
            }

            TextField(
                "wordbook.search.placeholder",
                text: $viewModel.searchText
            )
            .focused($searchFocused)

            sortMenu
                .frame(minWidth: 130)
        }
    }

    @ViewBuilder private var sectionContent: some View {
        switch viewModel.section {
        case .wordbook:
            if viewModel.displayedEntries.isEmpty {
                wordbookEmptyView
            } else {
                WordbookEntryList(
                    entries: viewModel.displayedEntries,
                    selection: $viewModel.selection,
                    allowsReturnReplay: !searchFocused
                ) { entry in
                    viewModel.replay(entry)
                }
            }
        case .history:
            if viewModel.displayedHistory.isEmpty {
                historyEmptyView
            } else {
                WordbookHistoryView(
                    records: viewModel.displayedHistory,
                    onQuery: { record in
                        viewModel.replay(record)
                    },
                    onDelete: { record in
                        viewModel.deleteHistory(record)
                    }
                )
            }
        }
    }

    @ViewBuilder private var sortMenu: some View {
        switch viewModel.section {
        case .wordbook:
            Menu {
                sortButton(
                    title: Text("wordbook.sort.newest"),
                    selected: viewModel.wordbookSort == .newest
                ) {
                    viewModel.wordbookSort = .newest
                }
                sortButton(
                    title: Text("wordbook.sort.oldest"),
                    selected: viewModel.wordbookSort == .oldest
                ) {
                    viewModel.wordbookSort = .oldest
                }
                sortButton(
                    title: Text("wordbook.sort.text"),
                    selected: viewModel.wordbookSort == .text
                ) {
                    viewModel.wordbookSort = .text
                }
            } label: {
                wordbookSortLabel
            }
        case .history:
            Menu {
                sortButton(
                    title: Text("wordbook.history_sort.newest"),
                    selected: viewModel.historySort == .newest
                ) {
                    viewModel.historySort = .newest
                }
                sortButton(
                    title: Text("wordbook.history_sort.oldest"),
                    selected: viewModel.historySort == .oldest
                ) {
                    viewModel.historySort = .oldest
                }
            } label: {
                historySortLabel
            }
        }
    }

    @ViewBuilder private var wordbookSortLabel: some View {
        switch viewModel.wordbookSort {
        case .newest:
            Text("wordbook.sort.newest")
        case .oldest:
            Text("wordbook.sort.oldest")
        case .text:
            Text("wordbook.sort.text")
        }
    }

    @ViewBuilder private var historySortLabel: some View {
        switch viewModel.historySort {
        case .newest:
            Text("wordbook.history_sort.newest")
        case .oldest:
            Text("wordbook.history_sort.oldest")
        }
    }

    private var wordbookEmptyView: some View {
        VStack(spacing: 10) {
            Image(systemSymbol: .starSlash)
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text("wordbook.empty.wordbook.title")
                .font(.headline)
            Text("wordbook.empty.wordbook.message")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var historyEmptyView: some View {
        VStack(spacing: 10) {
            Image(systemSymbol: .clockBadgeXmark)
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text("wordbook.empty.history.title")
                .font(.headline)
            Text("wordbook.empty.history.message")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func protectedView(
        _ protection: WordbookProtection
    )
        -> some View {
        switch protection {
        case .corrupt:
            statusView(
                title: Text("wordbook.recovery.corrupt.title"),
                message: Text("wordbook.recovery.corrupt.message")
            )
        case let .newerSchema(version, _):
            statusView(
                title: Text("wordbook.recovery.newer.title"),
                message: Text(newerSchemaMessage(version: version))
            )
        }
    }

    private func statusView(title: Text, message: Text) -> some View {
        VStack(spacing: 12) {
            title
                .font(.title2)
                .fontWeight(.semibold)
            message
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 460)
            Button("retry") {
                viewModel.retryLoad()
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func sortButton(
        title: Text,
        selected: Bool,
        action: @escaping () -> ()
    )
        -> some View {
        Button(action: action) {
            HStack {
                if selected {
                    Image(systemSymbol: .checkmark)
                }
                title
            }
        }
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
