//
//  CodexCLIService.swift
//  Easydict
//
//  Created by long2ice on 2026/05/07.
//  Copyright © 2026 izual. All rights reserved.
//

import Defaults
import Foundation

// MARK: - CodexCLIService

/// A translation service that delegates to the locally installed `codex` CLI tool.
///
/// Each translation spawns a fresh `codex exec --json` subprocess, so there is no
/// cross-query conversation state. The service overrides `contentStreamTranslate`
/// to slot into the `StreamService` pipeline — accumulation, throttling, and
/// result management are handled by the base class.
@objc(EZCodexCLIService)
final class CodexCLIService: StreamService {
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
        runner?.cancel()
        runner = nil
    }

    public override func configurationListItems() -> Any? {
        CodexCLIServiceConfigurationView(service: self)
    }

    /// Spawns `codex exec --json` and streams its stdout as text delta chunks.
    ///
    /// `codex exec` does not have a separate system-prompt flag, so the system
    /// instructions and conversation turns are concatenated into a single prompt
    /// argument.
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

        runner?.cancel()
        let currentRunner = CodexCLIRunner()
        runner = currentRunner
        let baseStream = currentRunner.run(prompt: combinedPrompt)

        return AsyncThrowingStream { [weak self] continuation in
            let task = Task {
                do {
                    for try await chunk in baseStream {
                        continuation.yield(chunk)
                    }
                    self?.tokenUsage = currentRunner.tokenUsage
                    #if AGENT_CLI_DEBUG
                    if let usage = currentRunner.tokenUsage {
                        CodexCLIDebugLogger.shared.post(
                            "[USAGE] in \(usage.inputTokens) · cache \(usage.cachedInputTokens) · out \(usage.outputTokens) · reasoning \(usage.reasoningOutputTokens) · total \(usage.totalTokens)"
                        )
                    }
                    #endif
                    continuation.finish()
                } catch is CancellationError {
                    self?.tokenUsage = currentRunner.tokenUsage
                    continuation.finish()
                } catch {
                    self?.tokenUsage = currentRunner.tokenUsage
                    let queryError: QueryError
                    if let qe = error as? QueryError {
                        queryError = qe
                    } else {
                        queryError = QueryError(type: .api, message: error.localizedDescription)
                    }
                    continuation.finish(throwing: queryError)
                }
            }
            continuation.onTermination = { _ in
                task.cancel()
                currentRunner.cancel()
            }
        }
    }

    // MARK: Private

    private var runner: CodexCLIRunner?
}
