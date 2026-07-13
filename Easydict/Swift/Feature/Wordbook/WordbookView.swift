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
            .sheet(item: $viewModel.editingEntry) { entry in
                WordbookEntryEditor(
                    entry: entry,
                    groups: viewModel.groups,
                    canSave: viewModel.canMutate
                ) { note, groupID in
                    viewModel.saveEntry(
                        entry,
                        note: note,
                        groupID: groupID
                    )
                }
            }
            .alert(
                "wordbook.group.new",
                isPresented: $showsNewGroup
            ) {
                TextField("wordbook.group.name", text: $groupName)
                Button("cancel", role: .cancel) {
                    groupName = ""
                }
                Button("wordbook.action.save") {
                    let name = groupName
                    groupName = ""
                    viewModel.createGroup(name: name)
                }
                .disabled(groupNameIsEmpty || !viewModel.canMutate)
            }
            .alert(
                "wordbook.group.rename",
                isPresented: renamePresented,
                presenting: groupToRename
            ) { group in
                TextField("wordbook.group.name", text: $groupName)
                Button("cancel", role: .cancel) {
                    groupName = ""
                }
                Button("wordbook.action.save") {
                    let name = groupName
                    groupName = ""
                    viewModel.renameGroup(group, name: name)
                }
                .disabled(groupNameIsEmpty || !viewModel.canMutate)
            }
            .alert(
                "common.delete",
                isPresented: entryDeletePresented,
                presenting: deleteEntryIDs
            ) { ids in
                Button("cancel", role: .cancel) {}
                Button("common.delete", role: .destructive) {
                    viewModel.deleteEntries(ids)
                }
                .disabled(!viewModel.canMutate)
            } message: { ids in
                Text(bulkDeleteMessage(count: ids.count))
            }
            .alert(
                "common.delete",
                isPresented: Binding(get: { viewModel.groupDeletePrompt != nil }, set: { _ in }),
                presenting: viewModel.groupDeletePrompt
            ) { _ in
                Button("cancel", role: .cancel) { viewModel.groupDeletePrompt = nil }
                Button("common.delete", role: .destructive) { viewModel.confirmDeleteGroup() }
                    .disabled(!viewModel.canMutate)
            } message: { prompt in
                Text(groupDeleteMessage(count: prompt.entryCount))
            }
            .alert(
                viewModel.failure?.titleKey ?? "wordbook.error.write.title",
                isPresented: Binding(get: { viewModel.failure != nil }, set: { _ in }),
                presenting: viewModel.failure
            ) { _ in
                if viewModel.canRetryFailure {
                    Button("cancel", role: .cancel) { viewModel.failure = nil }
                    Button("retry") { viewModel.retryFailedMutation() }
                        .disabled(!viewModel.canMutate)
                } else {
                    Button("wordbook.action.dismiss") { viewModel.failure = nil }
                }
            } message: { failure in
                Text(failure.messageKey)
            }
            .alert(
                "wordbook.recovery.reset.title",
                isPresented: $confirmsProtectedReset
            ) {
                Button("wordbook.recovery.reset", role: .destructive) {
                    viewModel.resetProtectedData()
                }
                Button("cancel", role: .cancel) {}
            } message: {
                Text("wordbook.recovery.reset.message")
            }
    }

    // MARK: Private

    @StateObject private var languageState = LanguageState()
    @StateObject private var viewModel = WordbookViewModel()
    @State private var groupName = ""
    @State private var groupToRename: WordbookGroup?
    @State private var showsNewGroup = false
    @State private var deleteEntryIDs = Set<UUID>()
    @State private var confirmsProtectedReset = false
    @FocusState private var searchFocused: Bool

    private var locale: Locale { Locale(identifier: languageState.language.rawValue) }
    private var groupNameIsEmpty: Bool { groupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    private var renamePresented: Binding<Bool> {
        Binding(
            get: { groupToRename != nil },
            set: { isPresented in
                if !isPresented {
                    groupToRename = nil
                }
            }
        )
    }

    private var entryDeletePresented: Binding<Bool> {
        Binding(
            get: { deleteEntryIDs.count > 1 },
            set: { isPresented in
                if !isPresented {
                    deleteEntryIDs.removeAll()
                }
            }
        )
    }

    private var allowsReturnReplay: Bool {
        !searchFocused
            && viewModel.editingEntry == nil
            && !showsNewGroup
            && groupToRename == nil
            && viewModel.failure == nil
            && viewModel.groupDeletePrompt == nil
            && deleteEntryIDs.isEmpty
            && !confirmsProtectedReset
    }

    @ViewBuilder private var content: some View {
        switch viewModel.repositoryState.phase {
        case .loading:
            loadingView
        case .ready:
            readyView
        case .failed, .protected:
            WordbookRecoveryView(
                state: viewModel.repositoryState,
                onRetry: viewModel.retryLoad,
                onShowInFinder: viewModel.showWordbookDataInFinder,
                onReset: { confirmsProtectedReset = true }
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
            if let notice = viewModel.recoveryNotice {
                WordbookRecoveryNoticeView(
                    notice: notice,
                    onDismiss: viewModel.dismissRecoveryNotice
                )
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }

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
                    count: viewModel.scopeCount,
                    canMutate: viewModel.canMutate,
                    onSelect: { scope in
                        viewModel.scope = scope
                    },
                    onCreate: presentNewGroup,
                    onSetDefault: { id in
                        viewModel.setDefaultGroup(id)
                    },
                    onRename: presentRename,
                    onMove: { group, offset in
                        viewModel.moveGroup(group, offset: offset)
                    },
                    onDelete: { group in
                        viewModel.deleteGroup(group)
                    }
                )
                .frame(minWidth: 190, alignment: .leading)
            }

            TextField(
                "wordbook.search.placeholder",
                text: $viewModel.searchText
            )
            .focused($searchFocused)

            sortMenu
                .frame(minWidth: 130)

            exportButton
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
                    groups: viewModel.groups,
                    selection: $viewModel.selection,
                    allowsReturnReplay: allowsReturnReplay,
                    canMutate: viewModel.canMutate,
                    onQuery: { entry in
                        viewModel.replay(entry)
                    },
                    onEdit: { entry in
                        viewModel.editingEntry = entry
                    },
                    onMove: { ids, groupID in
                        viewModel.moveEntries(ids, to: groupID)
                    },
                    onCopy: { entry in
                        viewModel.copyText(entry)
                    },
                    onDelete: requestEntryDelete
                )
            }
        case .history:
            if viewModel.displayedHistory.isEmpty {
                historyEmptyView
            } else {
                WordbookHistoryView(
                    records: viewModel.displayedHistory,
                    savedKeys: viewModel.savedKeys,
                    canAdd: viewModel.canMutate,
                    onAdd: viewModel.addHistory,
                    onQuery: viewModel.replay,
                    onDelete: viewModel.deleteHistory
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

    @ViewBuilder private var exportButton: some View {
        switch viewModel.section {
        case .wordbook:
            Button(action: viewModel.exportWordbook) {
                Label("common.export", systemSymbol: .squareAndArrowUp)
                    .labelStyle(.iconOnly)
            }
            .disabled(viewModel.scopeCount == 0)
            .help("common.export")
        case .history:
            Button(action: viewModel.exportHistory) {
                Label("common.export", systemSymbol: .squareAndArrowUp)
                    .labelStyle(.iconOnly)
            }
            .disabled(viewModel.history.isEmpty)
            .help("common.export")
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

    private func presentNewGroup() {
        groupName = ""
        showsNewGroup = true
    }

    private func presentRename(_ group: WordbookGroup) {
        groupName = group.name
        groupToRename = group
    }

    private func requestEntryDelete(_ ids: Set<UUID>) {
        guard viewModel.canMutate, !ids.isEmpty else { return }
        if ids.count == 1 {
            viewModel.deleteEntries(ids)
        } else {
            deleteEntryIDs = ids
        }
    }

    private func groupDeleteMessage(count: Int) -> String {
        String(
            format: String(
                localized: "wordbook.group.delete_nonempty.message",
                locale: locale
            ),
            locale: locale,
            arguments: [Int64(count) as CVarArg]
        )
    }

    private func bulkDeleteMessage(count: Int) -> String {
        String(
            format: String(
                localized: "wordbook.bulk.delete.message",
                locale: locale
            ),
            locale: locale,
            arguments: [Int64(count) as CVarArg]
        )
    }
}
