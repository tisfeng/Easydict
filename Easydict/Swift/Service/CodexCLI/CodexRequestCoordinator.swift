//
//  CodexRequestCoordinator.swift
//  Easydict
//
//  Created by Alfred on 2026/09/07.
//

import Combine
import Defaults
import Foundation

// MARK: - CodexServiceConfiguration

/// Captures mode and model settings without invoking StreamService's model getter.
/// Fixed storage keys keep managed settings separate from the external CLI values.
struct CodexServiceConfiguration: Equatable {
    // MARK: Lifecycle

    init(uuid: String) {
        self.uuid = uuid
        self.mode = Defaults[CodexAccessMode.key(uuid: uuid)]
        self.model = Defaults[Self.modelKey(uuid: uuid, mode: mode)]
        self.effort = Defaults[Self.effortKey(uuid: uuid, mode: mode)]
    }

    // MARK: Internal

    let uuid: String
    let mode: CodexAccessMode
    let model: String
    let effort: CodexReasoningEffort

    static func reasoningEfforts(mode: CodexAccessMode, model: String) -> [CodexReasoningEffort] {
        switch mode {
        case .localCLI: CodexReasoningEffort.localOptions
        case .managed:
            [.default] + (CodexManagedRuntime.bundledCatalog?.models.first { $0.slug == model }?
                .supported_reasoning_levels.compactMap { CodexReasoningEffort(rawValue: $0.effort) } ?? [])
        }
    }

    static func modelKey(uuid: String, mode: CodexAccessMode) -> Defaults.Key<String> {
        serivceConfigurationKey(
            mode == .managed ? .codexManagedModel : .model,
            serviceType: .codexCLI,
            id: uuid,
            defaultValue: mode == .managed ? CodexManagedRuntime.defaultModel : ""
        )
    }

    static func effortKey(uuid: String, mode: CodexAccessMode) -> Defaults.Key<CodexReasoningEffort> {
        serivceConfigurationKey(
            mode == .managed ? .codexManagedReasoningEffort : .reasoningEffort,
            serviceType: .codexCLI,
            id: uuid,
            defaultValue: .default
        )
    }
}

// MARK: - CodexRequestCoordinator

/// Coordinates only Codex requests across factory-created service instances.
/// Registrations outlive process exit until the owning stream releases them, so
/// configuration changes also invalidate queued text and usage from finished work.
final class CodexRequestCoordinator: @unchecked Sendable {
    // MARK: Internal

    /// A tracked request may deliver a rejection without being allowed to execute.
    enum Admission: Equatable {
        case allowed
        case blocked(CodexAccountOperation)
    }

    static let shared = CodexRequestCoordinator()

    func observe(uuid: String) {
        lock.lock()
        guard observers[uuid] == nil else { lock.unlock(); return }
        observers[uuid] = []
        lock.unlock()
        var subscriptions = Set<AnyCancellable>()
        Defaults.publisher(CodexAccessMode.key(uuid: uuid), options: [])
            .sink { [weak self] _ in
                self?.invalidate(uuid: uuid)
                Task { @MainActor in
                    CodexManagedAccount.shared.configurationChanged(origin: uuid)
                    CodexManagedAccount.shared.cancelLogin(origin: uuid)
                    if Defaults[CodexAccessMode.key(uuid: uuid)] == .localCLI {
                        CodexComponentManager.shared.modeChanged(origin: uuid)
                    }
                }
            }.store(in: &subscriptions)
        for mode in CodexAccessMode.allCases {
            Defaults.publisher(CodexServiceConfiguration.modelKey(uuid: uuid, mode: mode), options: [])
                .sink { [weak self] _ in
                    self?.invalidate(uuid: uuid, mode: mode)
                    if mode == .managed {
                        Task { @MainActor in CodexManagedAccount.shared.configurationChanged(origin: uuid) }
                    }
                }
                .store(in: &subscriptions)
            Defaults.publisher(CodexServiceConfiguration.effortKey(uuid: uuid, mode: mode), options: [])
                .sink { [weak self] _ in
                    self?.invalidate(uuid: uuid, mode: mode)
                    if mode == .managed {
                        Task { @MainActor in CodexManagedAccount.shared.configurationChanged(origin: uuid) }
                    }
                }
                .store(in: &subscriptions)
        }
        lock.withLock { observers[uuid] = subscriptions }
    }

    @discardableResult
    func register(
        token: UUID,
        configuration: CodexServiceConfiguration,
        cancel: @escaping () -> ()
    ) throws
        -> Admission {
        try lock.withLock {
            guard configuration == CodexServiceConfiguration(uuid: configuration.uuid) else {
                throw CancellationError()
            }
            requests[token] = Registration(configuration: configuration, cancel: cancel)
            if configuration.mode == .managed, let accountOperation { return .blocked(accountOperation) }
            return .allowed
        }
    }

    func isCurrent(_ token: UUID) -> Bool {
        lock.withLock {
            guard let request = requests[token] else { return false }
            return request.configuration == CodexServiceConfiguration(uuid: request.configuration.uuid)
        }
    }

    func remove(_ token: UUID) {
        _ = lock.withLock { requests.removeValue(forKey: token) }
    }

    func invalidate(uuid: String? = nil, mode: CodexAccessMode? = nil) {
        let callbacks = lock.withLock { removeRequests(uuid: uuid, mode: mode) }
        for callback in callbacks { callback() }
    }

    /// Change admission and invalidate older requests atomically; callbacks run unlocked.
    func setAccountOperation(_ operation: CodexAccountOperation?) {
        let callbacks = lock.withLock { () -> [() -> ()] in
            accountOperation = operation
            return operation == nil ? [] : removeRequests(mode: .managed)
        }
        for callback in callbacks { callback() }
    }

    @MainActor
    func reset() {
        // The account owns admission and advances its operation generation before
        // an older account task can finish and release the reset's gate.
        CodexManagedAccount.shared.reset()
        invalidate(mode: .localCLI)
        CodexComponentManager.shared.cancel()
    }

    // MARK: Private

    private struct Registration {
        let configuration: CodexServiceConfiguration
        let cancel: () -> ()
    }

    private let lock = NSLock()
    private var requests: [UUID: Registration] = [:]
    private var observers: [String: Set<AnyCancellable>] = [:]
    private var accountOperation: CodexAccountOperation?

    /// Called only under lock; executing callbacks here would reverse the service lock order.
    private func removeRequests(uuid: String? = nil, mode: CodexAccessMode? = nil) -> [() -> ()] {
        let matches = requests.filter {
            (uuid == nil || $0.value.configuration.uuid == uuid)
                && (mode == nil || $0.value.configuration.mode == mode)
        }
        for token in matches.keys { requests.removeValue(forKey: token) }
        return matches.values.map(\.cancel)
    }
}
