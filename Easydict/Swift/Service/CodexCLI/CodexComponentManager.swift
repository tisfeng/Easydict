//
//  CodexComponentManager.swift
//  Easydict
//
//  Created by Alfred on 2026/09/07.
//

import Combine
import Foundation

/// Shares component checks and installation across managed settings pages.
/// A completed component check starts an account read without changing credentials
/// or interrupting translations; cancellation follows the operation's ownership.
@MainActor
final class CodexComponentManager: ObservableObject {
    // MARK: Lifecycle

    init(
        storeFactory: @escaping () async throws -> CodexComponentStore = {
            try CodexComponentStore.applicationStore(descriptor: .load())
        },
        account: CodexManagedAccount = .shared
    ) {
        self.storeFactory = storeFactory
        self.account = account
    }

    // MARK: Internal

    enum State {
        case unknown, checking, missing, downloading(Double), installing, cancelling, ready, failed
    }

    static let shared = CodexComponentManager()

    @Published private(set) var state: State = .unknown
    @Published private(set) var errorMessage: String?

    var isReady: Bool { if case .ready = state { return true }; return false }
    var isBusy: Bool { operation != nil }

    /// Appearance and manual refresh use the same entry; active work wins without queuing.
    func refresh() {
        guard operation == nil, !account.isBusy else { return }
        let generation = begin(state: .checking, kind: .check)
        operation = Task { await checkInstallation(generation) }
    }

    func download(origin: String) {
        consumers.insert(origin)
        guard operation == nil, !account.isBusy else { return }
        let generation = begin(state: .downloading(0), kind: .install)
        operation = Task {
            do {
                let store = try await storeFactory()
                try Task.checkCancellation()
                _ = try await store.install { progress in
                    Task { @MainActor [weak self] in
                        guard let self, self.generation == generation, operation != nil else { return }
                        state = progress.map(State.downloading) ?? .installing
                    }
                }
                try Task.checkCancellation()
                guard generation == self.generation else { return }
                applyAvailability(.ready)
            } catch {
                guard generation == self.generation else { return }
                applyAvailability(.failed, error: error)
            }
            finish(generation)
        }
    }

    func retainConsumer(_ origin: String) {
        consumers.insert(origin)
    }

    func modeChanged(origin: String) {
        consumers.remove(origin)
        if consumers.isEmpty, operation != nil { cancel() }
    }

    func cancel() {
        guard let previous = operation, let kind = operationKind else { return }
        if case .cancelling = state { return }
        previous.cancel()
        let generation = begin(state: .cancelling, kind: kind)
        operation = Task {
            await previous.value
            guard self.generation == generation else { return }
            switch kind {
            case .check:
                state = availability
                errorMessage = availabilityError
                finish(generation)
            case .install:
                // Installation may have completed its atomic promotion before cancellation.
                await checkInstallation(generation)
            }
        }
    }

    // MARK: Private

    /// The displayed phase can change without changing cancellation semantics.
    private enum OperationKind {
        case check, install
    }

    private let storeFactory: () async throws -> CodexComponentStore
    private let account: CodexManagedAccount
    private var generation: UInt = 0
    private var operation: Task<(), Never>?
    private var operationKind: OperationKind?
    private var consumers = Set<String>()
    private var availability: State = .unknown
    private var availabilityError: String?

    private func checkInstallation(_ generation: UInt) async {
        do {
            let store = try await storeFactory()
            try Task.checkCancellation()
            _ = try await store.verifyInstalled()
            guard generation == self.generation else { return }
            applyAvailability(.ready)
        } catch {
            guard generation == self.generation else { return }
            applyAvailability(.missing, error: error)
        }
        finish(generation)
    }

    /// Publish the result and hand off to the account in one MainActor segment.
    private func applyAvailability(_ state: State, error: Error? = nil) {
        availability = state
        availabilityError = (error as? CodexManagedError) == .componentMissing ? nil : error?.localizedDescription
        self.state = state
        errorMessage = availabilityError
        if case .ready = state {
            account.refresh()
        } else if case .missing = state {
            account.componentUnavailable()
        }
    }

    private func begin(state: State, kind: OperationKind) -> UInt {
        generation &+= 1
        self.state = state
        operationKind = kind
        errorMessage = nil
        return generation
    }

    private func finish(_ generation: UInt) {
        guard self.generation == generation else { return }
        operation = nil
        operationKind = nil
        objectWillChange.send()
    }
}
