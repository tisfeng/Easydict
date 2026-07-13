//
//  WordbookViewModel.swift
//  Easydict
//
//  Created by liangkaiwen on 2026/7/14.
//  Copyright © 2026 izual. All rights reserved.
//

import Combine
import Defaults
import Foundation

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

    // MARK: Private

    private let repository: WordbookRepository
    private let query = WordbookQuery()
    private var stateTask: Task<(), Never>?
    private var historyCancellable: AnyCancellable?

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
