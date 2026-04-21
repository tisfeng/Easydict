//
//  ClaudeCodeService.swift
//  Easydict
//
//  Created by Karl on 2026/04/07.
//  Copyright © 2026 izual. All rights reserved.
//

import Defaults
import Foundation

// MARK: - ClaudeCodeService

/// A translation service that delegates to the locally installed `claude` CLI tool.
///
/// Each translation spawns a fresh `claude -p` subprocess, so there is no
/// cross-query conversation state. The service overrides `contentStreamTranslate`
/// to slot into the `StreamService` pipeline — all accumulation, throttling,
/// and result management are handled by the base class.
@objc(EZClaudeCodeService)
final class ClaudeCodeService: StreamService {
    // MARK: Public

    /// Claude Code has no API key, endpoint, or model fields to observe.
    ///
    /// Returning an empty array prevents `ServiceValidationViewModel` from treating
    /// empty key/endpoint/model values as "missing input", which would permanently
    /// disable the Validate button in the settings UI.
    public override var observeKeys: [Defaults.Key<String>] {
        []
    }

    /// Token usage from the most recent completed translation.
    ///
    /// Populated after the stream finishes. `nil` if no translation has completed yet
    /// or the last request was cancelled / rate-limited before any tokens were consumed.
    public private(set) var tokenUsage: CLITokenUsage?

    public override func serviceType() -> ServiceType {
        .claudeCode
    }

    public override func name() -> String {
        String(localized: "service.claude_code.name")
    }

    public override func apiKeyRequirement() -> ServiceAPIKeyRequirement {
        .agentCLI
    }

    public override func cancelStream() {
        runner?.cancel()
        runner = nil
    }

    public override func configurationListItems() -> Any? {
        ClaudeCodeServiceConfigurationView(service: self)
    }

    /// Spawns `claude -p` and streams its stdout as text delta chunks.
    ///
    /// The base class `streamTranslate` handles chunk accumulation, `isStreamFinished`,
    /// `getFinalResultText`, and error propagation, so this method only needs to
    /// assemble the prompt and hand the stream to the runner.
    ///
    /// The system message is separated from the conversation and passed via `--system-prompt`
    /// so it replaces Claude Code's default system prompt (which is large and tool-heavy).
    /// The remaining user/assistant messages are passed as the `-p` prompt.
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

        // Split the message list into a system prompt and a conversation prompt.
        // The system message goes to `--system-prompt` to replace Claude Code's default
        // (which loads tool descriptions, hooks, etc.).
        // User / assistant messages are joined with role prefixes as the `-p` prompt.
        let messages = chatMessageDicts(chatQueryParam)
        let systemPrompt = messages
            .filter { $0.role == .system }
            .map(\.content)
            .joined(separator: "\n\n")
        let conversationMessages = messages.filter { $0.role != .system }

        let conversationPrompt = conversationMessages
            .map { "\($0.role.rawValue): \($0.content)" }
            .joined(separator: "\n\n")

        // Cancel any in-flight runner before replacing it so the previous subprocess
        // does not continue consuming CPU/quota after a new request starts.
        runner?.cancel()
        let currentRunner = ClaudeCodeRunner()
        runner = currentRunner
        let baseStream = currentRunner.run(
            prompt: conversationPrompt,
            systemPrompt: systemPrompt.isEmpty ? nil : systemPrompt
        )

        // Wrap the stream to capture token usage after the run completes.
        return AsyncThrowingStream { [weak self] continuation in
            let task = Task {
                do {
                    for try await chunk in baseStream {
                        continuation.yield(chunk)
                    }
                    self?.tokenUsage = currentRunner.tokenUsage
                    #if AGENT_CLI_DEBUG
                    if let usage = currentRunner.tokenUsage {
                        // Route usage stats to the debug window only — not into the
                        // translation stream, which would corrupt displayed text and auto-copy.
                        ClaudeCodeDebugLogger.shared.post(
                            "[USAGE] in \(usage.inputTokens) · cache-write \(usage.cacheCreationInputTokens) · cache-read \(usage.cacheReadInputTokens) · out \(usage.outputTokens)"
                        )
                    }
                    #endif
                    continuation.finish()
                } catch is CancellationError {
                    // Task cancellation is user-initiated — finish cleanly without an error.
                    self?.tokenUsage = currentRunner.tokenUsage
                    continuation.finish()
                } catch {
                    self?.tokenUsage = currentRunner.tokenUsage
                    // Preserve LocalizedError.errorDescription for ClaudeCodeError.
                    // QueryError.queryError(from:) uses String(describing:) as a fallback,
                    // which shows raw enum text. Cast first; only use localizedDescription
                    // (which calls errorDescription) when the error is not already a QueryError.
                    let queryError: QueryError
                    if let qe = error as? QueryError {
                        queryError = qe
                    } else {
                        queryError = QueryError(type: .api, message: error.localizedDescription)
                    }
                    continuation.finish(throwing: queryError)
                }
            }
            // Cancel the inner task when the stream consumer drops the stream early
            // (e.g. a new query starts before this one finishes). Cancelling the task
            // propagates CancellationError into the for-await loop, which causes
            // ClaudeCodeRunner's own onTermination handler to fire and stop the subprocess.
            continuation.onTermination = { _ in
                task.cancel()
                currentRunner.cancel()
            }
        }
    }

    // MARK: Private

    private var runner: ClaudeCodeRunner?
}
