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
        runner?.cancel()
        let currentRunner = GitHubCopilotRunner()
        runner = currentRunner
        let baseStream = currentRunner.run(
            prompt: combinedPrompt,
            model: model,
            effort: Defaults[effortKey].cliValue
        )

        return AsyncThrowingStream { [weak self] continuation in
            let task = Task {
                do {
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
            // Cancelling the task propagates into the for-await loop, which fires the runner's
            // own onTermination handler and stops the subprocess.
            continuation.onTermination = { _ in
                task.cancel()
                currentRunner.cancel()
            }
        }
    }

    // MARK: Internal

    /// Default for the inherited `modelKey`, which holds the model override edited in the
    /// configuration view. Empty means "omit `--model`" and keeps the CLI's own default.
    override var defaultModels: [String] {
        [""]
    }

    /// Copilot accepts any model identifier its account exposes as free-form input, so it must
    /// not participate in the base class's model-list synchronization.
    override var synchronizesModelWithSupportedModels: Bool {
        false
    }

    /// Free-form model override without the base class's valid-model coercion.
    ///
    /// The configuration view accepts any identifier, so the base getter — which resets values
    /// missing from `validModels` back to the default — would silently discard a custom model
    /// the first time anything reads `model`.
    override var model: String {
        get { Defaults[modelKey] }
        set { Defaults[modelKey] = newValue }
    }

    /// Stored reasoning-effort override. `.default` means "do not pass `--reasoning-effort`".
    ///
    /// Uses the `cliEffort` slot rather than `reasoningEffort`, whose storage the base class
    /// already claims with the incompatible `ReasoningEffort` enum.
    var effortKey: Defaults.Key<GitHubCopilotEffort> {
        serviceDefaultsKey(.cliEffort, defaultValue: .default)
    }

    // MARK: Private

    private var runner: GitHubCopilotRunner?
}
