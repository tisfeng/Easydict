//
//  CodexComponentManager.swift
//  Easydict
//
//  Created by Alfred on 2026/09/07.
//

import Combine
import Foundation

/// A single user-initiated component download shared by all managed settings pages.
/// Component availability is separate from the account's official authentication state.
@MainActor
final class CodexComponentManager: ObservableObject {
    // MARK: Internal

    enum State {
        case unknown, checking, missing, downloading(Double), installing, cancelling, ready, failed
    }

    static let shared = CodexComponentManager()

    @Published private(set) var state: State = .unknown
    @Published private(set) var errorMessage: String?

    var isReady: Bool { if case .ready = state { return true }; return false }
    var isBusy: Bool { operation != nil }

    func refreshIfNeeded() {
        if case .unknown = state { refresh() }
    }

    func refresh() {
        guard operation == nil else { return }
        let generation = begin(state: .checking)
        operation = Task {
            do {
                let store = try CodexComponentStore.applicationStore(descriptor: .load())
                _ = try await store.verifyInstalled()
                guard generation == self.generation else { return }
                state = .ready
            } catch {
                guard generation == self.generation else { return }
                state = .missing
                if (error as? CodexManagedError) != .componentMissing { errorMessage = error.localizedDescription }
            }
            finish(generation)
        }
    }

    func download(origin: String) {
        consumers.insert(origin)
        guard operation == nil else { return }
        let generation = begin(state: .downloading(0))
        operation = Task {
            do {
                let store = try CodexComponentStore.applicationStore(descriptor: .load())
                _ = try await store.install { progress in
                    Task { @MainActor [weak self] in
                        guard let self, self.generation == generation, operation != nil else { return }
                        state = progress.map(State.downloading) ?? .installing
                    }
                }
                try Task.checkCancellation()
                guard generation == self.generation else { return }
                state = .ready
                CodexManagedAccount.shared.refresh()
            } catch {
                guard generation == self.generation else { return }
                state = .failed
                errorMessage = error.localizedDescription
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
        guard let previous = operation else { return }
        previous.cancel()
        let generation = begin(state: .cancelling)
        operation = Task {
            await previous.value
            guard self.generation == generation else { return }
            finish(generation)
            state = .unknown
            refreshIfNeeded()
        }
    }

    // MARK: Private

    private var generation: UInt = 0
    private var operation: Task<(), Never>?
    private var consumers = Set<String>()

    private func begin(state: State) -> UInt {
        generation &+= 1
        self.state = state
        errorMessage = nil
        return generation
    }

    private func finish(_ generation: UInt) {
        guard self.generation == generation else { return }
        operation = nil
        objectWillChange.send()
    }
}
