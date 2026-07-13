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
import UniformTypeIdentifiers

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
    case addEntry(String, Language, Language)
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
    @Published var recoveryNotice: WordbookRecoveryNotice?
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

    var savedKeys: Set<WordbookEntryKey> {
        Set(snapshot.entries.compactMap {
            WordbookEntryKey(
                text: $0.text,
                fromLanguage: $0.fromLanguage,
                toLanguage: $0.toLanguage
            )
        })
    }

    var canMutate: Bool {
        repositoryState.phase == .ready && !repositoryState.isPersisting && !mutationInFlight
    }

    var canRetryFailure: Bool { failedMutation != nil }

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
                if let notice = state.recoveryNotice,
                   notice != observedRecoveryNotice {
                    recoveryNotice = notice
                }
                observedRecoveryNotice = state.recoveryNotice
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

    func addHistory(_ record: QueryRecord) {
        perform(.addEntry(record.queryText, record.queryFromLanguage, record.queryToLanguage))
    }

    func dismissRecoveryNotice() { recoveryNotice = nil }

    func showWordbookDataInFinder() {
        Task { [repository] in
            let url = await repository.dataDirectoryURL()
            NSWorkspace.shared.activateFileViewerSelecting([url])
        }
    }

    func resetProtectedData() {
        Task { [weak self, repository] in
            let state = await repository.resetProtectedData()
            self?.repositoryState = state
        }
    }

    /// Exports the complete current group scope while ignoring search text.
    func exportWordbook() {
        let entries = query.entries(
            in: snapshot,
            scope: scope,
            searchText: "",
            sortOrder: wordbookSort,
            locale: queryLocale
        )
        let csv = exporter.makeWordbookCSV(
            entries: entries,
            groups: groups,
            ungroupedName: String(localized: "wordbook.group.ungrouped", locale: queryLocale),
            languageName: { $0.localizedName }
        )
        presentExport(
            csv: csv,
            filenameFormat: String(localized: "wordbook.export.filename", locale: queryLocale)
        )
    }

    /// Exports complete query history in its current order without filtering.
    func exportHistory() {
        let records = query.history(
            history,
            searchText: "",
            sortOrder: historySort,
            locale: queryLocale
        )
        let csv = exporter.makeHistoryCSV(records: records, languageName: { $0.localizedName })
        presentExport(
            csv: csv,
            filenameFormat: String(localized: "wordbook.history_export.filename", locale: queryLocale)
        )
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
        if perform(.deleteGroup(prompt.group, confirmed: true)) {
            groupDeletePrompt = nil
        }
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
        if perform(failedMutation) {
            failure = nil
        }
    }

    func copyText(_ entry: WordbookEntry) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(entry.text, forType: .string)
    }

    // MARK: Private

    private let repository: WordbookRepository
    private let query = WordbookQuery()
    private let exporter = WordbookCSVExporter()
    private let exportFilenameFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter
    }()

    private var stateTask: Task<(), Never>?
    private var historyCancellable: AnyCancellable?
    private var failedMutation: WordbookMutation?
    private var observedRecoveryNotice: WordbookRecoveryNotice?

    /// Accepts a management write only after synchronously closing the local
    /// UI gate. The repository gate remains the final serialization boundary
    /// across storage awaits, and rejected writes keep their pending UI state.
    @discardableResult
    private func perform(_ mutation: WordbookMutation) -> Bool {
        guard canMutate else { return false }
        mutationInFlight = true
        let repository = repository
        Task { [weak self, repository] in
            guard let self else { return }
            defer { mutationInFlight = false }
            do {
                switch mutation {
                case let .addEntry(text, from, to):
                    _ = try await repository.add(text: text, fromLanguage: from, toLanguage: to)
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
        return true
    }

    /// Presents a CSV save panel and reports write failures as non-retryable.
    private func presentExport(csv: String, filenameFormat: String) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.commaSeparatedText]
        panel.canCreateDirectories = true
        panel.isExtensionHidden = false
        let stamp = exportFilenameFormatter.string(from: .now)
        panel.nameFieldStringValue = String(
            format: filenameFormat,
            locale: queryLocale,
            arguments: [stamp as CVarArg]
        )
        let data = Data(csv.utf8)
        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            Task { @MainActor [weak self, data, url] in
                guard let self else { return }
                do {
                    try await Task.detached(priority: .utility) {
                        try data.write(to: url, options: .atomic)
                    }.value
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                } catch {
                    logError("Wordbook export failed: \(error)")
                    failedMutation = nil
                    failure = WordbookUIFailure(
                        titleKey: "wordbook.export.error.title",
                        messageKey: "wordbook.export.error.message"
                    )
                }
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
