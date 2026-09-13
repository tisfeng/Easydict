//
//  CodexCLIService.swift
//  Easydict
//
//  Created by long2ice on 2026/05/07.
//  Copyright © 2026 izual. All rights reserved.
//

import Combine
import Defaults
import Foundation

// MARK: - CodexCLIService

/// A translation service using either the bundled ChatGPT runtime or the local CLI.
///
/// Each translation spawns a fresh `codex exec --json` subprocess, so there is no
/// cross-query conversation state. The service overrides `contentStreamTranslate`
/// to slot into the `StreamService` pipeline — accumulation, throttling, and
/// result management are handled by the base class.
@objc(EZCodexCLIService)
final class CodexCLIService: StreamService {
    // MARK: Lifecycle

    deinit {
        runner?.cancel()
        managedRunner?.cancel()
        if let registration { CodexRequestCoordinator.shared.remove(registration) }
    }

    // MARK: Public

    /// Codex CLI has no API key, endpoint, or model fields to observe.
    ///
    /// Returning an empty array prevents `ServiceValidationViewModel` from treating
    /// empty key/endpoint/model values as "missing input", which would permanently
    /// disable the Validate button in the settings UI.
    public override var observeKeys: [Defaults.Key<String>] {
        []
    }

    /// Token usage from the most recent completed translation.
    public private(set) var tokenUsage: CodexTokenUsage?

    public override func serviceType() -> ServiceType {
        .codexCLI
    }

    public override func name() -> String {
        String(localized: "service.codex_cli.name")
    }

    public override func apiKeyRequirement() -> ServiceAPIKeyRequirement {
        .agentCLI
    }

    public override func cancelStream() {
        let current = runLock.withLock { () -> (CodexCLIRunner?, CodexManagedTranslation?) in
            let current = (runner, managedRunner)
            runner = nil
            managedRunner = nil
            return current
        }
        current.0?.cancel()
        current.1?.cancel()
        // The base stream also calls this to release finished resources before
        // its final main-thread callback. Keep configuration invalidation alive
        // until this service starts another request or is released.
    }

    public override func configurationListItems() -> Any? {
        CodexCLIServiceConfigurationView(service: self)
    }

    /// Spawns `codex exec --json` and streams its stdout as text delta chunks.
    ///
    /// `codex exec` does not have a separate system-prompt flag, so the system
    /// instructions and conversation turns are concatenated into a single prompt
    /// and sent through stdin to avoid argv size limits.
    public override func contentStreamTranslate(
        _ text: String,
        from: Language,
        to: Language
    )
        -> AsyncThrowingStream<String, Error> {
        let queryType = queryType(text: text, from: from, to: to)
        let chatQueryParam = ChatQueryParam(
            text: text,
            sourceLanguage: from,
            targetLanguage: to,
            queryType: queryType,
            enableSystemPrompt: true
        )

        // Codex has no separate system-prompt flag, so all messages are merged
        // into one prompt with role prefixes.
        let messages = chatMessageDicts(chatQueryParam)
        let combinedPrompt = messages
            .map { "\($0.role.rawValue): \($0.content)" }
            .joined(separator: "\n\n")

        let configuration = CodexServiceConfiguration(uuid: uuid)
        CodexRequestCoordinator.shared.observe(uuid: uuid)
        let token = UUID()
        let generation = updateResultLock.withLock {
            cancelStream()
            let previous = runLock.withLock {
                let previous = registration
                registration = token
                return previous
            }
            if let previous { CodexRequestCoordinator.shared.remove(previous) }
            tokenUsage = nil
            return resultGeneration
        }

        return AsyncThrowingStream { [weak self] continuation in
            guard let self else { continuation.finish(); return }
            do {
                let admission = try CodexRequestCoordinator.shared
                    .register(token: token, configuration: configuration) { [weak self] in
                        self?.invalidateConfiguration(token: token, generation: generation)
                    }
                if case let .blocked(reason) = admission {
                    finish(continuation, error: CodexManagedError.operationInProgress(reason), token: token)
                    return
                }
            } catch {
                invalidateConfiguration(token: token, generation: generation)
                continuation.finish(throwing: error)
                return
            }
            let local: CodexCLIRunner?
            let managed: CodexManagedTranslation?
            do {
                (local, managed) = try updateResultLock.withLock {
                    guard CodexRequestCoordinator.shared.isCurrent(token) else { throw CancellationError() }
                    let local = configuration.mode == .localCLI ? CodexCLIRunner() : nil
                    let managed = configuration.mode == .managed ? CodexManagedTranslation() : nil
                    runLock.withLock {
                        runner = local
                        managedRunner = managed
                    }
                    return (local, managed)
                }
            } catch {
                continuation.finish(throwing: error)
                return
            }
            let task = Task {
                do {
                    if let managed {
                        try CodexManagedRuntime.validateSelection(
                            model: configuration.model, effort: configuration.effort.cliValue
                        )
                        let result = try await managed.run(
                            prompt: combinedPrompt,
                            model: configuration.model,
                            effort: configuration.effort.cliValue,
                            runtime: try await CodexManagedRuntime.installed()
                        )
                        try self.updateResultLock.withLock {
                            guard CodexRequestCoordinator.shared.isCurrent(token) else { throw CancellationError() }
                            self.tokenUsage = result.usage
                            continuation.yield(result.text)
                        }
                    } else if let local {
                        for try await chunk in local.run(
                            prompt: combinedPrompt,
                            model: configuration.model,
                            reasoningEffort: configuration.effort.cliValue
                        ) {
                            try self.updateResultLock.withLock {
                                guard CodexRequestCoordinator.shared.isCurrent(token) else { throw CancellationError() }
                                continuation.yield(chunk)
                            }
                        }
                        try self.updateResultLock.withLock {
                            guard CodexRequestCoordinator.shared.isCurrent(token) else { throw CancellationError() }
                            self.tokenUsage = local.tokenUsage
                        }
                    }
                    continuation.finish()
                } catch {
                    self.finish(continuation, error: error, token: token)
                }
            }
            continuation.onTermination = { _ in
                task.cancel()
                local?.cancel()
                managed?.cancel()
                // Keep the registration until the next request or deinit: the base stream
                // may still have queued result updates after this content stream ends.
            }
        }
    }

    // MARK: Internal

    override var synchronizesModelWithSupportedModels: Bool { false }

    override var model: String {
        get { CodexServiceConfiguration(uuid: uuid).model }
        set {
            let mode = Defaults[accessModeKey]
            if mode == .managed, !CodexManagedRuntime.bundledModelNames.contains(newValue) { return }
            Defaults[CodexServiceConfiguration.modelKey(uuid: uuid, mode: mode)] = newValue
        }
    }

    override var validModels: [String] {
        Defaults[accessModeKey] == .managed ? CodexManagedRuntime.bundledModelNames : super.validModels
    }

    /// Stored reasoning-effort override. `.default` means "do not override
    /// `~/.codex/config.toml`"; other cases map to codex's accepted values.
    /// `modelKey` is inherited from `StreamService` and resolves to an empty
    /// default, which the runner treats as "use codex CLI default".
    var reasoningEffortKey: Defaults.Key<CodexReasoningEffort> {
        serviceDefaultsKey(.reasoningEffort, defaultValue: .default)
    }

    var accessModeKey: Defaults.Key<CodexAccessMode> { CodexAccessMode.key(uuid: uuid) }

    var managedModelKey: Defaults.Key<String> {
        CodexServiceConfiguration.modelKey(uuid: uuid, mode: .managed)
    }

    var managedReasoningEffortKey: Defaults.Key<CodexReasoningEffort> {
        CodexServiceConfiguration.effortKey(uuid: uuid, mode: .managed)
    }

    /// Keeps fixed subscriptions: local model edits preserve automatic query behavior,
    /// while mode/auth/managed model changes refresh UI without sending current text.
    func setupCodexSubscribers() {
        CodexRequestCoordinator.shared.observe(uuid: uuid)
        Defaults.publisher(nameKey, options: [])
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.notifyServiceConfigurationChanged() }
            .store(in: &cancellables)
        Defaults.publisher(accessModeKey, options: [])
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.notifyServiceConfigurationChanged() }
            .store(in: &cancellables)
        Defaults.publisher(modelKey, options: [])
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self, Defaults[accessModeKey] == .localCLI else { return }
                notifyServiceConfigurationChanged(autoQuery: true)
            }.store(in: &cancellables)
        Defaults.publisher(managedModelKey, options: [])
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self, Defaults[accessModeKey] == .managed else { return }
                notifyServiceConfigurationChanged()
            }
            .store(in: &cancellables)
    }

    // MARK: Private

    private let runLock = NSLock()
    private var runner: CodexCLIRunner?
    private var managedRunner: CodexManagedTranslation?
    private var registration: UUID?

    /// Rejections and execution failures use the same result identity and error boundary.
    private func finish(
        _ continuation: AsyncThrowingStream<String, Error>.Continuation, error: Error, token: UUID
    ) {
        updateResultLock.withLock {
            if error is CancellationError || !CodexRequestCoordinator.shared.isCurrent(token) {
                continuation.finish(throwing: CancellationError())
            } else {
                let queryError = (error as? QueryError)
                    ?? QueryError(type: .api, message: error.localizedDescription)
                continuation.finish(throwing: queryError)
            }
        }
    }

    private func invalidateConfiguration(token: UUID, generation: UInt) {
        let current = updateResultLock.withLock { () -> (CodexCLIRunner?, CodexManagedTranslation?) in
            runLock.lock()
            defer { runLock.unlock() }
            guard registration == token else { return (nil, nil) }
            let current = (runner, managedRunner)
            runner = nil
            managedRunner = nil
            registration = nil
            if generation == resultGeneration {
                resultGeneration &+= 1
                result?.isStreamFinished = true
                result?.isLoading = false
                result?.error = nil
                tokenUsage = nil
                let invalidatedGeneration = resultGeneration
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    updateResultLock.withLock {
                        guard self.resultGeneration == invalidatedGeneration else { return }
                        self.notifyServiceConfigurationChanged()
                    }
                }
            }
            return current
        }
        current.0?.cancel()
        current.1?.cancel()
    }
}
