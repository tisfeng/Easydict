//
//  WordbookManager.swift
//  Easydict
//
//  Created by liangkaiwen on 2026/7/13.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation

// MARK: - WordbookLookupState

/// Describes Objective-C-safe lookup availability and persistence state.
@objc
enum WordbookLookupState: Int {
    case unavailable
    case absent
    case present
    case persisting
}

// MARK: - WordbookRemovalResult

/// Describes the Objective-C-safe result of a keyed removal request.
@objc
enum WordbookRemovalResult: Int {
    case removed
    case notFound
    case confirmationRequired
}

// MARK: - WordbookLookup

/// Carries lookup state and note presence across the Objective-C boundary.
@objcMembers
final class WordbookLookup: NSObject {
    // MARK: Lifecycle

    init(state: WordbookLookupState, hasNote: Bool = false) {
        self.state = state
        self.hasNote = hasNote
    }

    // MARK: Internal

    let state: WordbookLookupState
    let hasNote: Bool
}

// MARK: - WordbookManager

/// Bridges repository state and keyed mutations to AppKit consumers. The main
/// actor keeps every callback and change notification on the main thread while
/// the repository remains isolated behind its actor boundary.
@MainActor
@objcMembers
final class WordbookManager: NSObject {
    // MARK: Internal

    static let shared = WordbookManager()

    private(set) var repositoryState = WordbookRepositoryState.loading

    /// Starts one shared state observation and triggers lazy repository loading.
    func start() {
        guard observationTask == nil else { return }
        let repository = repository
        observationTask = Task { [weak self, repository] in
            let updates = await repository.stateUpdates()
            for await state in updates {
                guard let self else { return }
                repositoryState = state
                NotificationCenter.default.post(
                    name: .wordbookDidChange,
                    object: self
                )
            }
        }
        Task { [repository] in _ = await repository.loadIfNeeded() }
    }

    /// Resolves one normalized entry without exposing repository state to AppKit.
    func lookup(
        queryText: String,
        fromLanguage: Language,
        toLanguage: Language,
        completion: @escaping (WordbookLookup?, Error?) -> ()
    ) {
        start()
        guard let key = WordbookEntryKey(
            text: queryText,
            fromLanguage: fromLanguage,
            toLanguage: toLanguage
        ) else {
            completion(WordbookLookup(state: .unavailable), nil)
            return
        }
        Task { [repository] in
            let state = await repository.loadIfNeeded()
            guard state.phase == .ready else {
                completion(WordbookLookup(state: .unavailable), nil)
                return
            }
            if state.isPersisting {
                completion(WordbookLookup(state: .persisting), nil)
                return
            }
            let entry = await repository.entry(for: key)
            completion(WordbookLookup(
                state: entry == nil ? .absent : .present,
                hasNote: !(entry?.note.isEmpty ?? true)
            ), nil)
        }
    }

    /// Adds one normalized entry and completes on the main actor.
    func add(
        queryText: String,
        fromLanguage: Language,
        toLanguage: Language,
        completion: @escaping (Error?) -> ()
    ) {
        start()
        Task { [repository] in
            do {
                _ = try await repository.add(
                    text: queryText,
                    fromLanguage: fromLanguage,
                    toLanguage: toLanguage
                )
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }

    /// Atomically removes one keyed entry after any required confirmation.
    func remove(
        queryText: String,
        fromLanguage: Language,
        toLanguage: Language,
        confirmed: Bool,
        completion: @escaping (WordbookRemovalResult, Error?) -> ()
    ) {
        start()
        guard let key = WordbookEntryKey(
            text: queryText,
            fromLanguage: fromLanguage,
            toLanguage: toLanguage
        ) else {
            completion(.notFound, nil)
            return
        }
        Task { [repository] in
            do {
                let decision = try await repository.remove(
                    key: key,
                    confirmed: confirmed
                )
                switch decision {
                case .removed:
                    completion(.removed, nil)
                case .notFound:
                    completion(.notFound, nil)
                case .confirmationRequired:
                    completion(.confirmationRequired, nil)
                }
            } catch {
                completion(.notFound, error)
            }
        }
    }

    // MARK: Private

    private let repository = WordbookRepository.shared
    private var observationTask: Task<(), Never>?
}
