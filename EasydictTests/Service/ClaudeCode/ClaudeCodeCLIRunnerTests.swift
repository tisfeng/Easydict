//
//  ClaudeCodeCLIRunnerTests.swift
//  EasydictTests
//
//  Created by Karl on 2026/04/07.
//  Copyright © 2026 izual. All rights reserved.
//

@testable import Easydict
import Foundation
import Testing

@Suite("ClaudeCodeCLIRunner")
struct ClaudeCodeCLIRunnerTests {
    // MARK: Internal

    @Test("buildArguments includes required stream-json print flags")
    func buildArgumentsIncludesRequiredStreamJSONPrintFlags() {
        let arguments = ClaudeCodeRunner.buildArguments(prompt: "Translate this", systemPrompt: nil)

        #expect(arguments.contains("-p"))
        #expect(arguments.contains("--print"))
        #expect(arguments.contains("--verbose"))
        #expect(arguments.contains("--output-format"))
        #expect(arguments.contains("stream-json"))
        #expect(arguments.contains("--include-partial-messages"))
    }

    // MARK: - parseError (stderr-only) tests

    @Test("parseError returns notLoggedIn when stderr contains 'not logged in'")
    func parseErrorNotLoggedIn() {
        let error = parseError(fromStdout: "", stderr: "Error: not logged in")
        #expect(error == .notLoggedIn)
    }

    @Test("parseError returns notLoggedIn when stderr contains 'authentication'")
    func parseErrorAuthentication() {
        let error = parseError(fromStdout: "", stderr: "authentication failed")
        #expect(error == .notLoggedIn)
    }

    @Test("parseError returns quotaExceeded when stderr contains 'rate limit'")
    func parseErrorRateLimit() {
        let error = parseError(fromStdout: "", stderr: "rate limit exceeded")
        #expect(error == .quotaExceeded(message: nil))
    }

    @Test("parseError returns quotaExceeded when stderr contains 'usage limit'")
    func parseErrorUsageLimit() {
        let error = parseError(fromStdout: "", stderr: "usage limit reached")
        #expect(error == .quotaExceeded(message: nil))
    }

    @Test("parseError returns cliError for unknown stderr")
    func parseErrorUnknown() {
        let message = "something went wrong"
        let error = parseError(fromStdout: "", stderr: message)
        #expect(error == .cliError(message: message))
    }

    // MARK: - parseError (stdout + stderr) tests

    @Test("parseError detects rate_limit_event in stdout and returns quotaExceeded")
    func parseErrorRateLimitEventInStdout() {
        let rateLimitLine = #"{"type":"rate_limit_event","rate_limit_info":{"status":"rejected"}}"#
        let resultLine =
            #"{"type":"result","subtype":"success","is_error":true,"result":"You've hit your limit \u00b7 resets 3am","#
                + #""duration_ms":100,"num_turns":1,"total_cost_usd":0,"usage":{},"modelUsage":{}}"#
        let stdout = rateLimitLine + "\n" + resultLine
        let error = parseError(fromStdout: stdout, stderr: "")
        #expect(error == .quotaExceeded(message: "You've hit your limit · resets 3am"))
    }

    @Test("parseError returns quotaExceeded with nil message when result text is missing")
    func parseErrorRateLimitEventNoMessage() {
        let rateLimitLine = #"{"type":"rate_limit_event","rate_limit_info":{"status":"rejected"}}"#
        let error = parseError(fromStdout: rateLimitLine, stderr: "")
        #expect(error == .quotaExceeded(message: nil))
    }

    @Test("parseError returns notLoggedIn when stdout result requests login")
    func parseErrorNotLoggedInFromStdoutResult() {
        let stdout =
            #"{"type":"result","subtype":"success","is_error":true,"result":"Not logged in · Please run /login","# +
            #""duration_ms":91,"total_cost_usd":0,"usage":{},"modelUsage":{}}"#
        let error = parseError(fromStdout: stdout, stderr: "")
        #expect(error == .notLoggedIn)
    }

    @Test("parseError returns notLoggedIn when assistant event reports authentication failure")
    func parseErrorAssistantAuthenticationFailure() {
        let stdout =
            #"{"type":"assistant","message":{"content":[{"type":"text","text":"Not logged in · Please run /login"}]},"# +
            #""error":"authentication_failed"}"#
        let error = parseError(fromStdout: stdout, stderr: "")
        #expect(error == .notLoggedIn)
    }

    @Test("parseError returns cliError when stdout result has a generic failure message")
    func parseErrorGenericStdoutResult() {
        let stdout =
            #"{"type":"result","subtype":"success","is_error":true,"result":"Something failed upstream","# +
            #""duration_ms":91,"total_cost_usd":0,"usage":{},"modelUsage":{}}"#
        let error = parseError(fromStdout: stdout, stderr: "")
        #expect(error == .cliError(message: "Something failed upstream"))
    }

    @Test("parseError falls back to stderr when stdout has no rate_limit_event")
    func parseErrorFallsBackToStderr() {
        let error = parseError(fromStdout: "", stderr: "not logged in")
        #expect(error == .notLoggedIn)
    }

    // MARK: - runWhich tests

    @Test("runWhich finds /bin/sh which always exists on macOS")
    func runWhichFindsShell() {
        let path = ClaudeCodeRunner.runWhich("sh")
        #expect(path != nil)
        #expect(path?.contains("/sh") == true)
    }

    @Test("runWhich returns nil for a binary that does not exist")
    func runWhichMissingBinary() {
        let path = ClaudeCodeRunner.runWhich("__nonexistent_binary_xyz__")
        #expect(path == nil)
    }

    // MARK: - extractTextDelta tests

    @Test("extractTextDelta returns text for a valid content_block_delta line")
    func extractTextDeltaReturnsText() {
        let line = #"{"type":"stream_event","event":{"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"Hello"}}}"#
        let result = extractTextDelta(from: line)
        #expect(result == "Hello")
    }

    @Test("extractTextDelta returns nil for a non-delta event type")
    func extractTextDeltaIgnoresNonDelta() {
        let line =
            #"{"type":"result","subtype":"success","is_error":false,"result":"ok","# +
            #""duration_ms":500,"num_turns":1,"total_cost_usd":0.001,"# +
            #""usage":{"input_tokens":10,"cache_creation_input_tokens":0,"# +
            #""cache_read_input_tokens":0,"output_tokens":5},"modelUsage":{}}"#
        let result = extractTextDelta(from: line)
        #expect(result == nil)
    }

    @Test("extractTextDelta returns nil for malformed JSON")
    func extractTextDeltaMalformedJSON() {
        let result = extractTextDelta(from: "not-json")
        #expect(result == nil)
    }

    // MARK: - parseTokenUsage tests

    @Test("parseTokenUsage returns usage from a valid result event")
    func parseTokenUsageReturnsUsage() {
        let line =
            #"{"type":"result","subtype":"success","is_error":false,"result":"ok","# +
            #""duration_ms":1200,"num_turns":1,"total_cost_usd":0.005,"# +
            #""usage":{"input_tokens":100,"cache_creation_input_tokens":20,"# +
            #""cache_read_input_tokens":5,"output_tokens":50},"modelUsage":{}}"#
        let usage = parseTokenUsage(from: line)
        #expect(usage != nil)
        #expect(usage?.inputTokens == 100)
        #expect(usage?.cacheCreationInputTokens == 20)
        #expect(usage?.cacheReadInputTokens == 5)
        #expect(usage?.outputTokens == 50)
        #expect(usage?.totalCostUSD == 0.005)
        #expect(usage?.durationMs == 1200)
        #expect(usage?.totalInputTokens == 125)
    }

    @Test("parseTokenUsage returns nil when no result event is present")
    func parseTokenUsageReturnsNilForNonResultLine() {
        let line = #"{"type":"stream_event","event":{"type":"message_start"}}"#
        let usage = parseTokenUsage(from: line)
        #expect(usage == nil)
    }

    @Test("parseTokenUsage returns nil when result usage payload has no token fields")
    func parseTokenUsageReturnsNilForEmptyUsagePayload() {
        let line =
            #"{"type":"result","subtype":"success","is_error":true,"result":"rate limited","# +
            #""duration_ms":100,"num_turns":1,"total_cost_usd":0,"usage":{},"modelUsage":{}}"#
        let usage = parseTokenUsage(from: line)
        #expect(usage == nil)
    }

    @Test("resolveLoginShellPath accepts executable non-zsh login shells")
    func resolveLoginShellPathAcceptsExecutableNonZshShell() {
        let shell = ClaudeCodeRunner.resolveLoginShellPath(environmentShell: "/bin/sh")
        #expect(shell == "/bin/sh")
    }

    @Test("resolveLoginShellPath falls back for non-absolute shell values")
    func resolveLoginShellPathFallsBackForNonAbsoluteShell() {
        let shell = ClaudeCodeRunner.resolveLoginShellPath(environmentShell: "fish")
        #expect(shell == "/bin/zsh")
    }

    @Test("resolveLoginShellPath falls back for non-executable absolute paths")
    func resolveLoginShellPathFallsBackForNonExecutableAbsolutePath() {
        let shell = ClaudeCodeRunner.resolveLoginShellPath(environmentShell: "/tmp/not-a-shell")
        #expect(shell == "/bin/zsh")
    }

    @Test("loadClaudeSettingsEnvironment returns string env pairs from settings file")
    func loadClaudeSettingsEnvironmentReturnsStringPairs() throws {
        let settingsURL = try makeTemporarySettingsFile(
            """
            {
              "env": {
                "ANTHROPIC_AUTH_TOKEN": "token-123",
                "ANTHROPIC_BASE_URL": "http://127.0.0.1:8317"
              }
            }
            """
        )

        let environment = ClaudeCodeRunner.loadClaudeSettingsEnvironment(settingsURL: settingsURL)

        #expect(environment["ANTHROPIC_AUTH_TOKEN"] == "token-123")
        #expect(environment["ANTHROPIC_BASE_URL"] == "http://127.0.0.1:8317")
    }

    @Test("loadClaudeSettingsEnvironment returns empty dictionary when settings file is missing")
    func loadClaudeSettingsEnvironmentMissingFile() {
        let settingsURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("settings.json")

        let environment = ClaudeCodeRunner.loadClaudeSettingsEnvironment(settingsURL: settingsURL)

        #expect(environment.isEmpty)
    }

    @Test("loadClaudeSettingsEnvironment returns empty dictionary for malformed JSON")
    func loadClaudeSettingsEnvironmentMalformedJSON() throws {
        let settingsURL = try makeTemporarySettingsFile("{ invalid json")

        let environment = ClaudeCodeRunner.loadClaudeSettingsEnvironment(settingsURL: settingsURL)

        #expect(environment.isEmpty)
    }

    @Test("loadClaudeSettingsEnvironment returns empty dictionary for non-string env values")
    func loadClaudeSettingsEnvironmentNonStringValues() throws {
        let settingsURL = try makeTemporarySettingsFile(
            """
            {
              "env": {
                "ANTHROPIC_AUTH_TOKEN": "token-123",
                "CLAUDE_PORT": 8317
              }
            }
            """
        )

        let environment = ClaudeCodeRunner.loadClaudeSettingsEnvironment(settingsURL: settingsURL)

        #expect(environment.isEmpty)
    }

    // MARK: Private

    /// Creates a temporary Claude settings file for loader tests.
    private func makeTemporarySettingsFile(_ content: String) throws -> URL {
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(
            at: temporaryDirectory,
            withIntermediateDirectories: true
        )

        let settingsURL = temporaryDirectory.appendingPathComponent("settings.json")
        try content.write(to: settingsURL, atomically: true, encoding: .utf8)
        return settingsURL
    }
}
