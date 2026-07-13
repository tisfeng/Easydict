//
//  WordbookViewModel.swift
//  Easydict
//
//  Created by liangkaiwen on 2026/7/14.
//  Copyright © 2026 izual. All rights reserved.
//

import AppKit
import Combine
import Defaults
import Foundation
import SwiftUI

// MARK: - WordbookUIFailure

/// Presents a localized, retryable mutation error without exposing repository
/// or storage details to the management views.
struct WordbookUIFailure: Identifiable {
    let id = UUID()
    let titleKey: LocalizedStringKey
    let messageKey: LocalizedStringKey
}

// MARK: - WordbookGroupDeletePrompt

/// Carries the repository-observed membership count required before deleting
/// a non-empty group.
struct WordbookGroupDeletePrompt: Identifiable {
    let group: WordbookGroup
    let entryCount: Int

    var id: UUID { group.id }
}

// MARK: - WordbookMutation

/// Captures one repository write so the same executor can retry it unchanged.
private enum WordbookMutation {
    case createGroup(String)
    case renameGroup(UUID, String)
    case reorderGroups([UUID])
    case deleteGroup(WordbookGroup, confirmed: Bool)
    case setDefaultGroup(UUID?)
    case updateEntry(UUID, String, UUID?)
    case moveEntries(Set<UUID>, UUID?)
    case deleteEntries(Set<UUID>)
}

// MARK: - WordbookViewModel

/// Owns the live, window-scoped browsing state for saved entries and query
/// history. Repository and Defaults streams update the same observable model,
/// while search, scope, sort, selection, and replay behavior remain available
/// across close-and-reopen cycles of the reusable window.
@MainActor
final class WordbookViewModel: ObservableObject {
    // MARK: Lifecycle

    init(repository: WordbookRepository = .shared) {
        self.repository = repository
        self.section = WordbookSection(rawValue: Defaults[.wordbookSection]) ?? .wordbook
        self.wordbookSort = WordbookSortOrder(rawValue: Defaults[.wordbookSort]) ?? .newest
        self.historySort = WordbookHistorySortOrder(
            rawValue: Defaults[.wordbookHistorySort]
        ) ?? .newest
        self.history = QueryRecordManager.shared.getAllRecords(for: .history)
        self.historyCancellable = Defaults.publisher(.queryHistory)
            .receive(on: RunLoop.main)
            .sink { [weak self] change in
                self?.history = change.newValue
            }
    }

    deinit {
        stateTask?.cancel()
    }

    // MARK: Internal

    @Published var repositoryState = WordbookRepositoryState.loading
    @Published private(set) var queryLocale = Locale(
        identifier: I18nHelper.shared.localizeCode
    )
    @Published var selection = Set<UUID>()
    @Published private(set) var history: [QueryRecord]
    @Published var editingEntry: WordbookEntry?
    @Published var failure: WordbookUIFailure?
    @Published var groupDeletePrompt: WordbookGroupDeletePrompt?
    @Published private(set) var mutationInFlight = false

    @Published var section: WordbookSection {
        didSet {
            Defaults[.wordbookSection] = section.rawValue
            selection.removeAll()
        }
    }

    @Published var scope: WordbookGroupScope = .all {
        didSet { selection.removeAll() }
    }

    @Published var searchText = "" {
        didSet { selection.removeAll() }
    }

    @Published var wordbookSort: WordbookSortOrder {
        didSet { Defaults[.wordbookSort] = wordbookSort.rawValue }
    }

    @Published var historySort: WordbookHistorySortOrder {
        didSet { Defaults[.wordbookHistorySort] = historySort.rawValue }
    }

    var snapshot: WordbookSnapshot {
        repositoryState.snapshot ?? .empty
    }

    var groups: [WordbookGroup] {
        snapshot.groups.sorted { first, second in
            if first.sortOrder != second.sortOrder {
                return first.sortOrder < second.sortOrder
            }
            if first.createdAt != second.createdAt {
                return first.createdAt < second.createdAt
            }
            return first.id.uuidString < second.id.uuidString
        }
    }

    var displayedEntries: [WordbookEntry] {
        query.entries(
            in: snapshot,
            scope: scope,
            searchText: searchText,
            sortOrder: wordbookSort,
            locale: queryLocale
        )
    }

    var displayedHistory: [QueryRecord] {
        query.history(
            history,
            searchText: searchText,
            sortOrder: historySort,
            locale: queryLocale
        )
    }

    var scopeCount: Int {
        query.entries(
            in: snapshot,
            scope: scope,
            searchText: "",
            sortOrder: wordbookSort,
            locale: queryLocale
        ).count
    }

    var canMutate: Bool {
        repositoryState.phase == .ready
            && !repositoryState.isPersisting
            && !mutationInFlight
    }

    /// Starts one repository observation and triggers its lazy bootstrap.
    func start() {
        guard stateTask == nil else { return }
        WordbookManager.shared.start()
        let repository = repository
        stateTask = Task { [weak self, repository] in
            let updates = await repository.stateUpdates()
            for await state in updates {
                guard let self else { return }
                repositoryState = state
                repairSelection(for: state.snapshot)
            }
        }
        Task { [repository] in
            _ = await repository.loadIfNeeded()
        }
    }

    func retryLoad() {
        Task { [repository] in
            _ = await repository.retryLoad()
        }
    }

    /// Reprojects localized search and ordering after the app language changes.
    func updateLocale(_ locale: Locale) {
        queryLocale = locale
        repairSelection(for: repositoryState.snapshot)
    }

    func replay(_ entry: WordbookEntry) {
        showQuery(
            text: entry.text,
            from: entry.fromLanguage,
            to: entry.toLanguage
        )
    }

    func replay(_ record: QueryRecord) {
        showQuery(
            text: record.queryText,
            from: record.queryFromLanguage,
            to: record.queryToLanguage
        )
    }

    func deleteHistory(_ record: QueryRecord) {
        QueryRecordManager.shared.removeRecord(id: record.id, from: .history)
    }

    func createGroup(name: String) {
        perform(.createGroup(name))
    }

    func renameGroup(_ group: WordbookGroup, name: String) {
        perform(.renameGroup(group.id, name))
    }

    func deleteGroup(_ group: WordbookGroup) {
        perform(.deleteGroup(group, confirmed: false))
    }

    func confirmDeleteGroup() {
        guard let prompt = groupDeletePrompt else { return }
        groupDeletePrompt = nil
        perform(.deleteGroup(prompt.group, confirmed: true))
    }

    func setDefaultGroup(_ id: UUID?) {
        perform(.setDefaultGroup(id))
    }

    func saveEntry(_ entry: WordbookEntry, note: String, groupID: UUID?) {
        perform(.updateEntry(entry.id, note, groupID))
    }

    func moveEntries(_ ids: Set<UUID>, to groupID: UUID?) {
        perform(.moveEntries(ids, groupID))
    }

    func deleteEntries(_ ids: Set<UUID>) {
        perform(.deleteEntries(ids))
    }

    func moveGroup(_ group: WordbookGroup, offset: Int) {
        var ids = groups.map(\.id)
        guard let index = ids.firstIndex(of: group.id) else { return }
        let destination = index + offset
        guard ids.indices.contains(destination) else { return }
        ids.swapAt(index, destination)
        perform(.reorderGroups(ids))
    }

    func retryFailedMutation() {
        guard let failedMutation else { return }
        failure = nil
        perform(failedMutation)
    }

    func copyText(_ entry: WordbookEntry) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(entry.text, forType: .string)
    }

    // MARK: Private

    private let repository: WordbookRepository
    private let query = WordbookQuery()
    private var stateTask: Task<(), Never>?
    private var historyCancellable: AnyCancellable?
    private var failedMutation: WordbookMutation?

    /// Runs every management write through one immediate UI gate and retry
    /// slot. The repository transaction gate remains the final serialization
    /// boundary across storage awaits.
    private func perform(_ mutation: WordbookMutation) {
        guard canMutate else { return }
        mutationInFlight = true
        let repository = repository
        Task { [weak self, repository] in
            guard let self else { return }
            defer { mutationInFlight = false }
            do {
                switch mutation {
                case let .createGroup(name):
                    _ = try await repository.createGroup(name: name)
                case let .renameGroup(id, name):
                    try await repository.renameGroup(id: id, name: name)
                case let .reorderGroups(ids):
                    try await repository.reorderGroups(ids: ids)
                case let .deleteGroup(group, confirmed):
                    let decision = try await repository.deleteGroup(
                        id: group.id,
                        confirmed: confirmed
                    )
                    if case let .confirmationRequired(entryCount) = decision {
                        failedMutation = nil
                        groupDeletePrompt = WordbookGroupDeletePrompt(
                            group: group,
                            entryCount: entryCount
                        )
                        return
                    }
                case let .setDefaultGroup(id):
                    try await repository.setDefaultGroup(id: id)
                case let .updateEntry(id, note, groupID):
                    _ = try await repository.updateEntry(
                        id: id,
                        note: note,
                        groupID: groupID
                    )
                case let .moveEntries(ids, groupID):
                    try await repository.moveEntries(ids: ids, to: groupID)
                case let .deleteEntries(ids):
                    try await repository.remove(ids: ids)
                }
                failedMutation = nil
                editingEntry = nil
            } catch let error as WordbookRepositoryError {
                failedMutation = mutation
                failure = WordbookUIFailure(
                    titleKey: error == .duplicateGroupName
                        ? "wordbook.error.duplicate_group.title"
                        : "wordbook.error.write.title",
                    messageKey: error == .duplicateGroupName
                        ? "wordbook.error.duplicate_group.message"
                        : "wordbook.error.write.message"
                )
            } catch {
                failedMutation = mutation
                failure = WordbookUIFailure(
                    titleKey: "wordbook.error.write.title",
                    messageKey: "wordbook.error.write.message"
                )
            }
        }
    }

    /// Drops stale group scopes and IDs that are no longer visible.
    private func repairSelection(for snapshot: WordbookSnapshot?) {
        if case let .group(id) = scope,
           snapshot?.groups.contains(where: { $0.id == id }) != true {
            scope = .all
        }
        guard let snapshot else {
            selection.removeAll()
            return
        }
        let visibleEntryIDs = Set(query.entries(
            in: snapshot,
            scope: scope,
            searchText: searchText,
            sortOrder: wordbookSort,
            locale: queryLocale
        ).map(\.id))
        selection.formIntersection(visibleEntryIDs)
    }

    /// Replays persisted text with its stored language direction.
    private func showQuery(text: String, from: Language, to: Language) {
        let windowType = Defaults[.shortcutSelectTranslateWindowType]
        EZWindowManager.shared().showFloating(
            windowType,
            queryText: text,
            fromLanguage: from,
            toLanguage: to,
            actionType: .inputQuery
        )
    }
}
