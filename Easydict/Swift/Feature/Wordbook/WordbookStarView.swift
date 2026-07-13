//
//  WordbookStarView.swift
//  Easydict
//
//  Created by liangkaiwen on 2026/7/14.
//  Copyright © 2026 izual. All rights reserved.
//

import AppKit
import SFSafeSymbols
import SwiftUI

// MARK: - WordbookStarState

/// Describes the lookup and persistence phases rendered by the query star.
private enum WordbookStarState {
    case empty
    case resolvingLanguage
    case checking
    case unavailable
    case absent
    case present
    case persisting
}

// MARK: - WordbookStarAlert

/// Identifies confirmation and retry alerts presented by the query star.
private enum WordbookStarAlert: Int, Identifiable {
    case removeNote
    case retry

    // MARK: Internal

    var id: Int { rawValue }
}

// MARK: - WordbookStarModel

/// Coordinates one visible query with Wordbook persistence. Separate lookup
/// generations and mutation identifiers prevent callbacks for stale text or
/// languages from changing the current star or presenting an outdated alert.
@MainActor
private final class WordbookStarModel: ObservableObject {
    // MARK: Lifecycle

    init(manager: WordbookManager = .shared) {
        self.manager = manager
        self.observer = NotificationCenter.default.addObserver(
            forName: .wordbookDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in self?.refresh() }
        }
        manager.start()
    }

    deinit {
        if let observer { NotificationCenter.default.removeObserver(observer) }
    }

    // MARK: Internal

    /// Captures the exact visible text and its normalized persistence identity.
    struct Query: Equatable {
        let key: WordbookEntryKey
        let text: String
        let fromLanguage: Language
        let toLanguage: Language
    }

    @Published private(set) var state = WordbookStarState.empty
    @Published var alert: WordbookStarAlert?

    func update(
        text: String,
        fromLanguage: Language,
        toLanguage: Language,
        languageResolved: Bool
    ) {
        let nextQuery = WordbookEntryKey(
            text: text,
            fromLanguage: fromLanguage,
            toLanguage: toLanguage
        ).map { key in
            Query(
                key: key,
                text: text,
                fromLanguage: fromLanguage,
                toLanguage: toLanguage
            )
        }
        if query != nextQuery || isLanguageResolved != languageResolved {
            generation &+= 1
            activeMutationID = nil
            dismissAlert()
        }
        query = nextQuery
        isLanguageResolved = languageResolved
        guard nextQuery != nil else {
            state = .empty
            return
        }
        guard languageResolved else {
            state = .resolvingLanguage
            return
        }
        refresh()
    }

    func toggle() {
        guard let query else { return }
        switch state {
        case .absent:
            performAdd(query)
        case .present:
            performRemove(query, confirmed: false)
        default:
            break
        }
    }

    func reset() {
        generation &+= 1
        activeMutationID = nil
        query = nil
        isLanguageResolved = false
        state = .empty
        dismissAlert()
    }

    func confirmRemoval() {
        guard let pendingRemoval else { return }
        performRemove(pendingRemoval, confirmed: true)
    }

    func retry() {
        let retryAction = retryAction
        self.retryAction = nil
        retryAction?()
    }

    func dismissAlert() {
        alert = nil
        pendingRemoval = nil
        retryAction = nil
    }

    // MARK: Private

    private let manager: WordbookManager
    private var observer: NSObjectProtocol?
    private var query: Query?
    private var pendingRemoval: Query?
    private var retryAction: (() -> ())?
    private var generation = 0
    private var activeMutationID: UUID?
    private var isLanguageResolved = false

    private func refresh() {
        guard activeMutationID == nil,
              isLanguageResolved,
              let query else { return }
        generation &+= 1
        let expectedGeneration = generation
        state = .checking
        manager.lookup(
            queryText: query.text,
            fromLanguage: query.fromLanguage,
            toLanguage: query.toLanguage
        ) { [weak self] lookup, error in
            guard let self,
                  generation == expectedGeneration,
                  activeMutationID == nil,
                  self.query == query else { return }
            state = error == nil
                ? (lookup?.state.starState ?? .unavailable)
                : .unavailable
        }
    }

    private func performAdd(_ query: Query) {
        guard self.query == query else { return }
        generation &+= 1
        let mutationID = UUID()
        activeMutationID = mutationID
        state = .persisting
        manager.add(
            queryText: query.text,
            fromLanguage: query.fromLanguage,
            toLanguage: query.toLanguage
        ) { [weak self] error in
            guard let self,
                  activeMutationID == mutationID,
                  self.query == query else { return }
            activeMutationID = nil
            if let error {
                logError("Wordbook star add failed: \(error)")
                retryAction = { [weak self] in self?.performAdd(query) }
                alert = .retry
            }
            refresh()
        }
    }

    private func performRemove(_ query: Query, confirmed: Bool) {
        guard self.query == query else { return }
        generation &+= 1
        let mutationID = UUID()
        activeMutationID = mutationID
        state = .persisting
        manager.remove(
            queryText: query.text,
            fromLanguage: query.fromLanguage,
            toLanguage: query.toLanguage,
            confirmed: confirmed
        ) { [weak self] result, error in
            guard let self,
                  activeMutationID == mutationID,
                  self.query == query else { return }
            activeMutationID = nil
            if let error {
                logError("Wordbook star removal failed: \(error)")
                retryAction = { [weak self] in
                    self?.performRemove(query, confirmed: confirmed)
                }
                alert = .retry
            } else if result == .confirmationRequired {
                pendingRemoval = query
                alert = .removeNote
            }
            refresh()
        }
    }
}

// MARK: - WordbookStarHost

/// Owns the SwiftUI star and exposes only its hosting view and query updates to
/// Objective-C. The legacy titlebar retains this non-visual object while the
/// observable model remains the single source of truth for rendered state.
@objc(WordbookStarHost)
@MainActor
final class WordbookStarHost: NSObject {
    // MARK: Lifecycle

    override init() {
        let model = WordbookStarModel()
        self.model = model
        self.view = NSHostingView(rootView: WordbookStarView(model: model))
        super.init()
    }

    // MARK: Internal

    @objc let view: NSView

    @objc(updateWithQueryText:fromLanguage:toLanguage:languageResolved:)
    func update(
        queryText: String,
        fromLanguage: Language,
        toLanguage: Language,
        languageResolved: Bool
    ) {
        model.update(
            text: queryText,
            fromLanguage: fromLanguage,
            toLanguage: toLanguage,
            languageResolved: languageResolved
        )
    }

    @objc(reset)
    func reset() {
        model.reset()
    }

    // MARK: Private

    private let model: WordbookStarModel
}

extension WordbookLookupState {
    fileprivate var starState: WordbookStarState {
        switch self {
        case .absent:
            .absent
        case .present:
            .present
        case .persisting:
            .persisting
        case .unavailable:
            .unavailable
        }
    }
}

// MARK: - WordbookStarView

/// Renders a fixed-size star, progress indicator, and mutation alerts for the
/// current query while delegating all persistence state changes to its model.
private struct WordbookStarView: View {
    @ObservedObject var model: WordbookStarModel

    var body: some View {
        Group {
            switch model.state {
            case .empty:
                Button(action: {}) { Image(systemSymbol: .star) }
                    .disabled(true)
                    .help("wordbook.star.empty")
                    .accessibilityLabel("wordbook.star.empty")
            case .resolvingLanguage:
                Button(action: {}) { ProgressView().controlSize(.small) }
                    .disabled(true)
                    .help("wordbook.star.resolving")
                    .accessibilityLabel("wordbook.star.resolving")
            case .checking:
                Button(action: {}) { ProgressView().controlSize(.small) }
                    .disabled(true)
                    .help("wordbook.star.checking")
                    .accessibilityLabel("wordbook.star.checking")
            case .unavailable:
                Button(action: {}) { Image(systemSymbol: .star) }
                    .disabled(true)
                    .help("wordbook.star.unavailable")
                    .accessibilityLabel("wordbook.star.unavailable")
            case .absent:
                Button(action: model.toggle) { Image(systemSymbol: .star) }
                    .help("wordbook.star.add")
                    .accessibilityLabel("wordbook.star.add")
            case .present:
                Button(action: model.toggle) { Image(systemSymbol: .starFill) }
                    .help("wordbook.star.remove")
                    .accessibilityLabel("wordbook.star.remove")
            case .persisting:
                Button(action: {}) { ProgressView().controlSize(.small) }
                    .disabled(true)
                    .help("wordbook.star.saving")
                    .accessibilityLabel("wordbook.star.saving")
            }
        }
        .buttonStyle(.plain)
        .frame(width: 24, height: 24)
        .alert(item: $model.alert) { item in
            switch item {
            case .removeNote:
                Alert(
                    title: Text("wordbook.star.remove_note.title"),
                    message: Text("wordbook.star.remove_note.message"),
                    primaryButton: .destructive(
                        Text("wordbook.action.remove"),
                        action: model.confirmRemoval
                    ),
                    secondaryButton: .cancel(
                        Text("cancel"),
                        action: model.dismissAlert
                    )
                )
            case .retry:
                Alert(
                    title: Text("wordbook.error.write.title"),
                    message: Text("wordbook.error.write.message"),
                    primaryButton: .default(
                        Text("retry"),
                        action: model.retry
                    ),
                    secondaryButton: .cancel(
                        Text("cancel"),
                        action: model.dismissAlert
                    )
                )
            }
        }
    }
}
