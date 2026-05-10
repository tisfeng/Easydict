//
//  CodexCLIRunnerTests.swift
//  EasydictTests
//
//  Created by long2ice on 2026/05/07.
//  Copyright © 2026 izual. All rights reserved.
//

@testable import Easydict
import Foundation
import Testing

@Suite("CodexCLIRunner")
struct CodexCLIRunnerTests {
    // MARK: - buildArguments

    @Test("buildArguments includes required json exec flags")
    func buildArgumentsIncludesRequiredFlags() {
        let arguments = CodexCLIRunner.buildArguments(
            prompt: "Translate this",
            workingDirectory: "/tmp"
        )

        #expect(arguments.contains("exec"))
        #expect(arguments.contains("--json"))
        #expect(arguments.contains("--skip-git-repo-check"))
        #expect(arguments.contains("--ephemeral"))
        #expect(arguments.contains("--sandbox"))
        #expect(arguments.contains("read-only"))
        #expect(arguments.contains("-C"))
        #expect(arguments.contains("/tmp"))
        #expect(arguments.contains("Translate this"))
    }

    @Test("buildArguments places prompt after the -- terminator")
    func buildArgumentsPlacesPromptAfterTerminator() {
        let arguments = CodexCLIRunner.buildArguments(
            prompt: "--looks-like-a-flag",
            workingDirectory: "/tmp"
        )
        let terminatorIndex = arguments.firstIndex(of: "--")
        let promptIndex = arguments.firstIndex(of: "--looks-like-a-flag")
        #expect(terminatorIndex != nil)
        #expect(promptIndex != nil)
        if let terminatorIndex, let promptIndex {
            #expect(terminatorIndex < promptIndex)
        }
    }

    @Test("buildArguments omits -m and -c when model and effort are empty")
    func buildArgumentsOmitsOverridesWhenEmpty() {
        let arguments = CodexCLIRunner.buildArguments(
            prompt: "hi",
            workingDirectory: "/tmp",
            model: "",
            reasoningEffort: nil
        )
        #expect(!arguments.contains("-m"))
        #expect(arguments.contains("-c") == false)
    }

    @Test("buildArguments adds -m when model is non-empty")
    func buildArgumentsAddsModelFlag() {
        let arguments = CodexCLIRunner.buildArguments(
            prompt: "hi",
            workingDirectory: "/tmp",
            model: "gpt-5-mini"
        )
        #expect(arguments.contains("-m"))
        #expect(arguments.contains("gpt-5-mini"))
        // -m must precede the -- terminator
        if let mIdx = arguments.firstIndex(of: "-m"),
           let endIdx = arguments.firstIndex(of: "--") {
            #expect(mIdx < endIdx)
        }
    }

    @Test("buildArguments trims whitespace around model value")
    func buildArgumentsTrimsModel() {
        let arguments = CodexCLIRunner.buildArguments(
            prompt: "hi",
            workingDirectory: "/tmp",
            model: "  gpt-5-mini  "
        )
        #expect(arguments.contains("gpt-5-mini"))
        #expect(!arguments.contains("  gpt-5-mini  "))
    }

    @Test("buildArguments adds -c model_reasoning_effort when effort is non-empty")
    func buildArgumentsAddsReasoningEffortFlag() {
        let arguments = CodexCLIRunner.buildArguments(
            prompt: "hi",
            workingDirectory: "/tmp",
            reasoningEffort: "low"
        )
        #expect(arguments.contains("-c"))
        #expect(arguments.contains("model_reasoning_effort=low"))
    }

    // MARK: - parseCodexError (stderr-only)

    @Test("parseCodexError returns notLoggedIn when stderr says 'not signed in'")
    func parseErrorNotSignedIn() {
        let error = parseCodexError(fromStdout: "", stderr: "Error: not signed in")
        #expect(error == .notLoggedIn)
    }

    @Test("parseCodexError returns notLoggedIn when stderr mentions OPENAI_API_KEY")
    func parseErrorMissingApiKey() {
        let error = parseCodexError(fromStdout: "", stderr: "OPENAI_API_KEY is not set")
        #expect(error == .notLoggedIn)
    }

    @Test("parseCodexError returns quotaExceeded when stderr contains 'rate limit'")
    func parseErrorRateLimit() {
        let error = parseCodexError(fromStdout: "", stderr: "rate limit reached")
        #expect(error == .quotaExceeded(message: nil))
    }

    @Test("parseCodexError returns quotaExceeded when stderr says 'insufficient quota'")
    func parseErrorInsufficientQuota() {
        let error = parseCodexError(fromStdout: "", stderr: "insufficient_quota: please add credits")
        #expect(error == .quotaExceeded(message: nil))
    }

    @Test("parseCodexError returns cliError for unknown stderr")
    func parseErrorUnknown() {
        let message = "something went wrong"
        let error = parseCodexError(fromStdout: "", stderr: message)
        #expect(error == .cliError(message: message))
    }

    @Test("parseCodexError ignores benign stderr noise from codex")
    func parseErrorIgnoresStderrNoise() {
        let stderr = "Reading additional input from stdin...\nShell cwd was reset to /Users/foo"
        let error = parseCodexError(fromStdout: "", stderr: stderr)
        // The cleaned stderr is empty, so we get the localized fallback.
        if case .cliError = error {
            // expected
        } else {
            Issue.record("expected cliError, got \(error)")
        }
    }

    // MARK: - parseCodexError (stdout JSONL)

    @Test("parseCodexError detects auth failure in turn.failed event (string error)")
    func parseErrorAuthFromTurnFailed() {
        let line =
            #"{"type":"turn.failed","error":"Not signed in. Please run codex login."}"#
        let error = parseCodexError(fromStdout: line, stderr: "")
        #expect(error == .notLoggedIn)
    }

    @Test("parseCodexError detects auth failure when error is an object payload")
    func parseErrorAuthFromTurnFailedObject() {
        let line =
            #"{"type":"turn.failed","error":{"message":"Not signed in. Please run codex login.","code":"unauthorized"}}"#
        let error = parseCodexError(fromStdout: line, stderr: "")
        #expect(error == .notLoggedIn)
    }

    @Test("parseCodexError detects quota in turn.failed event")
    func parseErrorQuotaFromTurnFailed() {
        let line =
            #"{"type":"turn.failed","error":"Rate limit exceeded for requests"}"#
        let error = parseCodexError(fromStdout: line, stderr: "")
        #expect(error == .quotaExceeded(message: "Rate limit exceeded for requests"))
    }

    @Test("parseCodexError detects quota when error is an object payload")
    func parseErrorQuotaFromTurnFailedObject() {
        let line =
            #"{"type":"turn.failed","error":{"message":"Rate limit exceeded for requests","type":"rate_limit_error"}}"#
        let error = parseCodexError(fromStdout: line, stderr: "")
        #expect(error == .quotaExceeded(message: "Rate limit exceeded for requests"))
    }

    @Test("parseCodexError returns cliError for generic turn.failed event")
    func parseErrorGenericFromTurnFailed() {
        let line =
            #"{"type":"turn.failed","error":"Something failed upstream"}"#
        let error = parseCodexError(fromStdout: line, stderr: "")
        #expect(error == .cliError(message: "Something failed upstream"))
    }

    @Test("parseCodexError returns cliError carrying the object's message field")
    func parseErrorGenericFromTurnFailedObject() {
        let line =
            #"{"type":"turn.failed","error":{"message":"Something failed upstream","code":"unknown"}}"#
        let error = parseCodexError(fromStdout: line, stderr: "")
        #expect(error == .cliError(message: "Something failed upstream"))
    }

    @Test("parseCodexError falls back to stderr when stdout has no error event")
    func parseErrorFallsBackToStderr() {
        let error = parseCodexError(fromStdout: "", stderr: "not signed in")
        #expect(error == .notLoggedIn)
    }

    @Test("parseCodexError does not mis-classify auth/quota tokens in non-failure events")
    func parseErrorIgnoresAuthQuotaInNonFailureEvents() {
        // A successful run whose assistant text or reasoning happens to mention
        // "401", "unauthorized", or "rate limit". The classifier must NOT treat
        // this as a login or quota failure — these are normal events, not failures.
        let agentMessage =
            #"{"type":"item.completed","item":{"id":"item_0","type":"agent_message","# +
            #""text":"HTTP 401 means unauthorized; rate limit is unrelated."}}"#
        let reasoning =
            #"{"type":"item.completed","item":{"id":"item_1","type":"reasoning","# +
            #""text":"Considering quota and 429 handling..."}}"#
        let stdout = agentMessage + "\n" + reasoning
        let error = parseCodexError(fromStdout: stdout, stderr: "boom")
        #expect(error == .cliError(message: "boom"))
    }

    @Test("parseCodexError prefers terminal failure event over earlier non-failure noise")
    func parseErrorPrefersTerminalFailureOverNoise() {
        // A successful agent_message followed by a turn.failed must classify on
        // the failure event's message, not the earlier non-failure text.
        let agentMessage =
            #"{"type":"item.completed","item":{"id":"item_0","type":"agent_message","# +
            #""text":"Discussing 401 errors as part of the answer."}}"#
        let turnFailed =
            #"{"type":"turn.failed","error":"Rate limit exceeded for requests"}"#
        let stdout = agentMessage + "\n" + turnFailed
        let error = parseCodexError(fromStdout: stdout, stderr: "")
        #expect(error == .quotaExceeded(message: "Rate limit exceeded for requests"))
    }

    // MARK: - extractCodexText

    @Test("extractCodexText returns text for an agent_message item.completed line")
    func extractTextReturnsAgentMessage() {
        let line =
            #"{"type":"item.completed","item":{"id":"item_0","type":"agent_message","text":"Hello world"}}"#
        #expect(extractCodexText(from: line) == "Hello world")
    }

    @Test("extractCodexText returns nil for reasoning items")
    func extractTextIgnoresReasoning() {
        let line =
            #"{"type":"item.completed","item":{"id":"item_1","type":"reasoning","text":"thinking"}}"#
        #expect(extractCodexText(from: line) == nil)
    }

    @Test("extractCodexText returns nil for thread.started events")
    func extractTextIgnoresThreadStarted() {
        let line = #"{"type":"thread.started","thread_id":"abc"}"#
        #expect(extractCodexText(from: line) == nil)
    }

    @Test("extractCodexText returns nil for turn.completed events")
    func extractTextIgnoresTurnCompleted() {
        let line =
            #"{"type":"turn.completed","usage":{"input_tokens":100,"cached_input_tokens":0,"# +
            #""output_tokens":20,"reasoning_output_tokens":5}}"#
        #expect(extractCodexText(from: line) == nil)
    }

    @Test("extractCodexText returns nil for malformed JSON")
    func extractTextMalformedJSON() {
        #expect(extractCodexText(from: "not-json") == nil)
    }

    // MARK: - parseCodexTokenUsage

    @Test("parseCodexTokenUsage returns usage from turn.completed event")
    func parseTokenUsageReturnsUsage() {
        let line =
            #"{"type":"turn.completed","usage":{"input_tokens":120,"cached_input_tokens":40,"# +
            #""output_tokens":60,"reasoning_output_tokens":5}}"#
        let usage = parseCodexTokenUsage(from: line, durationMs: 1234)
        #expect(usage != nil)
        #expect(usage?.inputTokens == 120)
        #expect(usage?.cachedInputTokens == 40)
        #expect(usage?.outputTokens == 60)
        #expect(usage?.reasoningOutputTokens == 5)
        #expect(usage?.totalTokens == 225)
        #expect(usage?.durationMs == 1234)
        #expect(usage?.totalInputTokens == 160)
    }

    @Test("parseCodexTokenUsage returns the most recent turn.completed event")
    func parseTokenUsagePicksLatest() {
        let first =
            #"{"type":"turn.completed","usage":{"input_tokens":10,"cached_input_tokens":0,"# +
            #""output_tokens":5,"reasoning_output_tokens":0}}"#
        let second =
            #"{"type":"turn.completed","usage":{"input_tokens":100,"cached_input_tokens":20,"# +
            #""output_tokens":30,"reasoning_output_tokens":2}}"#
        let usage = parseCodexTokenUsage(from: first + "\n" + second)
        #expect(usage?.inputTokens == 100)
        #expect(usage?.totalTokens == 152)
    }

    @Test("parseCodexTokenUsage returns nil when no turn.completed event is present")
    func parseTokenUsageReturnsNilForNonTurnLine() {
        let line = #"{"type":"thread.started","thread_id":"abc"}"#
        #expect(parseCodexTokenUsage(from: line) == nil)
    }

    @Test("parseCodexTokenUsage returns nil when usage payload is empty")
    func parseTokenUsageReturnsNilForEmptyPayload() {
        let line = #"{"type":"turn.completed","usage":{}}"#
        #expect(parseCodexTokenUsage(from: line) == nil)
    }

    // MARK: - login shell helpers

    @Test("resolveLoginShellPath accepts executable absolute shell")
    func resolveLoginShellPathAcceptsExecutableAbsolute() {
        let shell = CodexCLIRunner.resolveLoginShellPath(environmentShell: "/bin/sh")
        #expect(shell == "/bin/sh")
    }

    @Test("resolveLoginShellPath falls back for non-absolute values")
    func resolveLoginShellPathFallsBackForNonAbsolute() {
        let shell = CodexCLIRunner.resolveLoginShellPath(environmentShell: "fish")
        #expect(shell == "/bin/zsh")
    }

    @Test("resolveLoginShellPath falls back for non-executable absolute paths")
    func resolveLoginShellPathFallsBackForNonExecutable() {
        let shell = CodexCLIRunner.resolveLoginShellPath(environmentShell: "/tmp/not-a-shell")
        #expect(shell == "/bin/zsh")
    }

    @Test("runWhich finds /bin/sh which always exists on macOS")
    func runWhichFindsShell() {
        let path = CodexCLIRunner.runWhich("sh")
        #expect(path != nil)
        #expect(path?.contains("/sh") == true)
    }

    @Test("runWhich returns nil for a binary that does not exist")
    func runWhichMissingBinary() {
        let path = CodexCLIRunner.runWhich("__nonexistent_codex_xyz__")
        #expect(path == nil)
    }
}
