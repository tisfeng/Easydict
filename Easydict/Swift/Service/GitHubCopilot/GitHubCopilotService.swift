//
//  GitHubCopilotService.swift
//  Easydict
//
//  Created by tisfeng on 2026/09/24.
//

import Defaults
import Foundation

// MARK: - GitHubCopilotService

/// A translation service that delegates to the locally installed `copilot` CLI.
///
/// Each translation spawns a fresh `copilot -p` subprocess, so there is no cross-query
/// conversation state. The service overrides `contentStreamTranslate` to slot into the
/// `StreamService` pipeline — accumulation, throttling, and result management stay in the base class.
///
/// The user's own `copilot login` credentials are reused; Easydict never reads or stores a token.
/// The subprocess runs with a disposable `COPILOT_HOME` and no available tools, so a translation
/// cannot read files, run shell commands, or leave session state behind.
@objc(EZGitHubCopilotService)
final class GitHubCopilotService: StreamService {
    // MARK: Public

    /// GitHub Copilot has no API key, endpoint, or model field for the base class to observe.
    ///
    /// Returning an empty array prevents `ServiceValidationViewModel` from treating empty
    /// key/endpoint/model values as "missing input", which would permanently disable the
    /// Validate button in the settings UI.
    public override var observeKeys: [Defaults.Key<String>] {
        []
    }

    /// Usage from the most recent completed translation.
    public private(set) var tokenUsage: GitHubCopilotUsage?

    public override func serviceType() -> ServiceType {
        .gitHubCopilot
    }

    public override func name() -> String {
        String(localized: "service.github_copilot.name")
    }

    public override func apiKeyRequirement() -> ServiceAPIKeyRequirement {
        .agentCLI
    }

    public override func cancelStream() {
        translationTask?.cancel()
        translationTask = nil
        runner?.cancel()
        runner = nil
    }

    public override func configurationListItems() -> Any? {
        GitHubCopilotServiceConfigurationView(service: self)
    }

    /// Spawns `copilot -p` and streams its output as text delta chunks.
    ///
    /// `copilot -p` has no separate system-prompt flag, so the system instructions and the
    /// conversation turns are concatenated into a single prompt with role prefixes.
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

        let combinedPrompt = chatMessageDicts(chatQueryParam)
            .map { "\($0.role.rawValue): \($0.content)" }
            .joined(separator: "\n\n")

        // Cancel any in-flight runner before replacing it so the previous subprocess does not
        // keep consuming the user's Copilot quota after a new request starts.
        cancelStream()
        let currentRunner = GitHubCopilotRunner()
        runner = currentRunner
        let selectedModel = model
        let selectedEffort = Defaults[effortKey]

        return AsyncThrowingStream { [weak self] continuation in
            let task = Task {
                do {
                    let models = await MainActor.run { GitHubCopilotModelStore.shared.snapshot?.models ?? [] }
                    try Task.checkCancellation()
                    let baseStream = currentRunner.run(
                        prompt: combinedPrompt, model: selectedModel, effort: selectedEffort, models: models
                    )
                    for try await chunk in baseStream {
                        continuation.yield(chunk)
                    }
                    self?.tokenUsage = currentRunner.tokenUsage
                    #if AGENT_CLI_DEBUG
                    if let usage = currentRunner.tokenUsage {
                        // Usage goes to the debug window only — yielding it would corrupt the
                        // translated text and any auto-copy of the result.
                        GitHubCopilotDebugLogger.shared.post(
                            "[USAGE] premium-requests \(usage.premiumRequests) · api \(usage.apiDurationMs)ms · session \(usage.sessionDurationMs)ms"
                        )
                    }
                    #endif
                    continuation.finish()
                } catch is CancellationError {
                    self?.tokenUsage = currentRunner.tokenUsage
                    continuation.finish()
                } catch {
                    self?.tokenUsage = currentRunner.tokenUsage
                    // Preserve the localized `errorDescription` for GitHubCopilotError: the
                    // generic QueryError conversion would fall back to `String(describing:)`
                    // and surface raw enum text instead of an actionable message.
                    let queryError: QueryError
                    if let queryErrorValue = error as? QueryError {
                        queryError = queryErrorValue
                    } else {
                        queryError = QueryError(type: .api, message: error.localizedDescription)
                    }
                    continuation.finish(throwing: queryError)
                }
            }
            self?.translationTask = task
            // Cancelling the task propagates into the for-await loop, which fires the runner's
            // own onTermination handler and stops the subprocess.
            continuation.onTermination = { _ in
                task.cancel()
                currentRunner.cancel()
            }
        }
    }

    // MARK: Internal

    /// Empty selects the saved CLI model, or its runtime default if none is configured.
    override var defaultModels: [String] {
        [""]
    }

    /// Copilot's account catalog owns selection; the base class's static list must not reset it.
    override var synchronizesModelWithSupportedModels: Bool {
        false
    }

    /// Preserve the selected ID even while the asynchronous catalog is unavailable.
    override var model: String {
        get { Defaults[modelKey] }
        set { Defaults[modelKey] = newValue }
    }

    @MainActor override var modelDisplayName: String {
        model.isEmpty ? String(localized: "service.github_copilot.catalog.default_model")
            : GitHubCopilotModelStore.shared.title(for: model)
    }

    @MainActor override var selectableModels: [String] {
        var models = GitHubCopilotModelStore.shared.selectableModels
        if !model.isEmpty, !models.contains(model) { models.append(model) }
        return models
    }

    @MainActor override var modelSelectionHint: String? {
        guard GitHubCopilotModelStore.shared.snapshot?.models.contains(where: \.isAvailable) != true else {
            return nil
        }
        return String(localized: "service.github_copilot.catalog.refresh_in_settings")
    }

    /// Empty omits `--reasoning-effort`; nonempty values come from the CLI catalog.
    var effortKey: Defaults.Key<String> {
        serviceDefaultsKey(.cliEffort, defaultValue: "")
    }

    @MainActor
    override func modelSelectionTitle(for identifier: String) -> String {
        GitHubCopilotModelStore.shared.title(for: identifier)
    }

    @MainActor
    override func selectModel(_ identifier: String) {
        GitHubCopilotModelStore.shared.selectModel(identifier, modelKey: modelKey, effortKey: effortKey)
    }

    /// Bridges the AppKit application lifecycle to the shared model catalog scheduler.
    @MainActor
    @objc
    static func startAutomaticModelUpdates() {
        GitHubCopilotModelStore.shared.startAutomaticRefresh()
    }

    @MainActor
    @objc
    static func stopAutomaticModelUpdates() {
        GitHubCopilotModelStore.shared.stopAutomaticRefresh()
    }

    // MARK: Private

    private var runner: GitHubCopilotRunner?
    private var translationTask: Task<(), Never>?
}
