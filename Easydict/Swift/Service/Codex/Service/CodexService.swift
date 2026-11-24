//
//  CodexService.swift
//  Easydict
//
//  Created by long2ice on 2026/05/07.
//  Copyright © 2026 izual. All rights reserved.
//

import AppKit
import Combine
import Defaults
import Foundation

// MARK: - CodexService

/// A translation service using either the bundled ChatGPT runtime or the local CLI.
///
/// Both modes stream through their own App Server process with independent
/// ephemeral threads, so there is no cross-query conversation state.
@objc(EZCodexCLIService)
final class CodexService: StreamService {
    // MARK: Lifecycle

    deinit {
        appServerRequest?.cancel()
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

    public override func supportsOCR() -> Bool { true }

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
        let current = runLock.withLock {
            defer { appServerRequest = nil }
            return appServerRequest
        }
        current?.cancel()
        // The base stream also calls this to release finished resources before
        // its final main-thread callback. Keep configuration invalidation alive
        // until this service starts another request or is released.
    }

    public override func configurationListItems() -> Any? {
        CodexCLIServiceConfigurationView(service: self)
    }

    /// Streams a translation through the App Server for the selected runtime.
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

        // Preserve the existing role-prefixed translation prompt in the text turn.
        let messages = chatMessageDicts(chatQueryParam)
        let combinedPrompt = messages
            .map { "\($0.role.rawValue): \($0.content)" }
            .joined(separator: "\n\n")

        let configuration = CodexServiceConfig(uuid: uuid)
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
                    finish(continuation, error: CodexServiceError.operationInProgress(reason), token: token)
                    return
                }
            } catch {
                invalidateConfiguration(token: token, generation: generation)
                continuation.finish(throwing: error)
                return
            }
            let request: CodexAppServerRequest
            do {
                request = try updateResultLock.withLock {
                    guard CodexRequestCoordinator.shared.isCurrent(token) else { throw CancellationError() }
                    let request = CodexAppServerRequest()
                    self.runLock.withLock { self.appServerRequest = request }
                    return request
                }
            } catch {
                continuation.finish(throwing: error)
                return
            }
            let task = Task {
                do {
                    if configuration.mode == .managed {
                        try CodexRuntime.validateSelection(
                            model: configuration.model, effort: configuration.effort.cliValue
                        )
                    }
                    let runtime = configuration.mode == .managed ? try await CodexAppServer.managed
                        .runtime() : nil
                    let response = try await request.runUsingAppServer(
                        prompt: combinedPrompt,
                        model: configuration.model,
                        effort: configuration.effort.cliValue,
                        runtime: runtime
                    ) { chunk in
                        do {
                            try self.updateResultLock.withLock {
                                guard CodexRequestCoordinator.shared.isCurrent(token) else { throw CancellationError() }
                                continuation.yield(chunk)
                            }
                        } catch {
                            request.cancel()
                        }
                    }
                    try self.updateResultLock.withLock {
                        guard CodexRequestCoordinator.shared.isCurrent(token) else { throw CancellationError() }
                        self.tokenUsage = response.usage
                    }
                    continuation.finish()
                } catch {
                    self.finish(continuation, error: error, token: token)
                }
            }
            continuation.onTermination = { _ in
                task.cancel()
                request.cancel()
                // Keep the registration until the next request or deinit: the base stream
                // may still have queued result updates after this content stream ends.
            }
        }
    }

    // MARK: Internal

    override var ocrTranslationConfiguration: [String] {
        let configuration = CodexServiceConfig(uuid: uuid)
        return [
            String(reflecting: type(of: self)),
            serviceTypeWithUniqueIdentifier(),
            uuid,
            configuration.mode.rawValue,
            configuration.model,
            configuration.effort.rawValue,
            String(enableCustomPrompt), String(enableStreaming),
        ]
    }

    override var synchronizesModelWithSupportedModels: Bool { false }

    override var model: String {
        get { CodexServiceConfig(uuid: uuid).model }
        set {
            let mode = Defaults[accessModeKey]
            if mode == .managed, !CodexRuntime.bundledModelNames.contains(newValue) { return }
            Defaults[CodexServiceConfig.modelKey(uuid: uuid, mode: mode)] = newValue
        }
    }

    override var validModels: [String] {
        Defaults[accessModeKey] == .managed ? CodexRuntime.bundledModelNames : super.validModels
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
        CodexServiceConfig.modelKey(uuid: uuid, mode: .managed)
    }

    var managedReasoningEffortKey: Defaults.Key<CodexReasoningEffort> {
        CodexServiceConfig.effortKey(uuid: uuid, mode: .managed)
    }

    override func recognizeImage(_ imageURL: String, prompt: String) async throws -> String {
        try await recognizeImage(imageURL, prompt: prompt, onDelta: { _ in })
    }

    override func recognizeImage(
        _ imageURL: String, prompt: String, onDelta: @escaping @Sendable (String) -> ()
    ) async throws
        -> String {
        try await recognizeImage(imageURL, prompt: prompt, outputSchema: nil, onDelta: onDelta)
    }

    override func recognizeJSONImage(
        _ imageURL: String, prompt: String, onDelta: @escaping @Sendable (String) -> ()
    ) async throws
        -> String {
        let schema: [String: Any] = [
            "type": "object",
            "properties": ["original": ["type": "string"], "translation": ["type": "string"]],
            "required": ["original", "translation"],
            "additionalProperties": false,
        ]
        return try await recognizeImage(imageURL, prompt: prompt, outputSchema: schema, onDelta: onDelta)
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
    private var appServerRequest: CodexAppServerRequest?
    private var registration: UUID?

    private func recognizeImage(
        _ imageURL: String, prompt: String, outputSchema: [String: Any]?,
        onDelta: @escaping @Sendable (String) -> ()
    ) async throws
        -> String {
        updateResultLock.withLock { tokenUsage = nil }
        let configuration = CodexServiceConfig(uuid: uuid)
        let coordinator = CodexRequestCoordinator.shared
        let runner = CodexAppServerRequest()
        let token = UUID()
        coordinator.observe(uuid: uuid)
        defer { coordinator.remove(token) }
        let admission = try coordinator.register(token: token, configuration: configuration) { runner.cancel() }
        if case let .blocked(reason) = admission {
            throw CodexServiceError.operationInProgress(reason)
        }
        let runtime = configuration.mode == .managed ? try await CodexAppServer.managed.runtime() : nil
        try Task.checkCancellation()
        let response = try await runner.runUsingAppServer(
            prompt: prompt,
            model: configuration.model,
            effort: configuration.effort.cliValue,
            runtime: runtime,
            imageURL: imageURL,
            outputSchema: outputSchema,
            deltaReceived: { delta in
                guard coordinator.isCurrent(token) else { return }
                onDelta(delta)
            }
        )
        try Task.checkCancellation()
        try updateResultLock.withLock {
            guard coordinator.isCurrent(token) else { throw CancellationError() }
            tokenUsage = response.usage
        }
        return response.text
    }

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
        let current = updateResultLock.withLock { () -> CodexAppServerRequest? in
            runLock.lock()
            defer { runLock.unlock() }
            guard registration == token else { return nil }
            let current = appServerRequest
            appServerRequest = nil
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
        current?.cancel()
    }
}
