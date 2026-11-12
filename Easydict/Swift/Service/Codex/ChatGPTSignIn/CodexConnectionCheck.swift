//
//  CodexConnectionCheck.swift
//  Easydict
//
//  Created by Alfred on 2026/09/07.
//

import Foundation

/// Runs and validates the one-shot translation used to check a managed connection.
final class CodexConnectionCheck: @unchecked Sendable {
    // MARK: Internal

    /// Holds only a completed translation and its reported usage.
    struct Result {
        let text: String
        let usage: CodexTokenUsage?
    }

    /// Official status exit 1 also covers config/keyring failures; only the exact
    /// signed-out status is classified as unauthenticated. No token data is read.
    static func isSignedIn(_ output: CodexCommandProcess.Output) throws -> Bool {
        guard let outputText = String(data: output.stdout + output.stderr, encoding: .utf8) else {
            throw CodexServiceError.authenticationFailed
        }
        let text = outputText.trimmingCharacters(in: .whitespacesAndNewlines)
        if output.exitCode == 0, text == "Logged in using ChatGPT" { return true }
        if output.exitCode == 1, text == "Not logged in" { return false }
        if text.lowercased().contains("keyring") || text.lowercased().contains("keychain") {
            throw CodexServiceError.keychainUnavailable
        }
        throw CodexServiceError.authenticationFailed
    }

    static func result(_ output: CodexCommandProcess.Output, durationMs: Int = 0) throws -> Result {
        guard let stdout = String(data: output.stdout, encoding: .utf8),
              let stderr = String(data: output.stderr, encoding: .utf8)
        else { throw CodexServiceError.invalidResponse }
        guard output.exitCode == 0 else {
            let failure = parseCodexFailure(fromStdout: stdout, stderr: stderr)
            switch failure {
            case let .authentication(message):
                let message = message.lowercased()
                if message.contains("keyring") || message.contains("keychain") {
                    throw CodexServiceError.keychainUnavailable
                }
                if message.contains("not signed in") || message.contains("not logged in")
                    || message.contains("please run `codex login`") || message.contains("please run codex login") {
                    throw CodexServiceError.loginRequired
                }
                throw CodexServiceError.authenticationFailed
            case let .other(message)
                where message.lowercased().contains("keyring") || message.lowercased().contains("keychain"):
                throw CodexServiceError.keychainUnavailable
            default:
                throw failure.localError
            }
        }
        var finalText: String?
        var completed = false
        var started = false
        for line in stdout.split(separator: "\n") {
            guard let object = try? JSONSerialization.jsonObject(with: Data(line.utf8)) as? [String: Any],
                  let type = object["type"] as? String, !completed
            else { throw CodexServiceError.invalidResponse }
            switch type {
            case "thread.started": break
            case "error":
                // Official retry notifications are nonterminal. A later completed
                // turn is still required; diagnostics alone never imply success.
                guard object["message"] is String else { throw CodexServiceError.invalidResponse }
            case "turn.started":
                guard !started else { throw CodexServiceError.invalidResponse }
                started = true
            case "item.completed", "item.started", "item.updated":
                guard let item = object["item"] as? [String: Any],
                      let kind = item["type"] as? String
                else { throw CodexServiceError.invalidResponse }
                // Warnings can precede turn.started (for example config notices).
                if type == "item.completed", kind == "error" {
                    guard item["message"] is String else { throw CodexServiceError.invalidResponse }
                    continue
                }
                guard started, ["reasoning", "agent_message"].contains(kind) else {
                    throw CodexServiceError.invalidResponse
                }
                if type == "item.completed", kind == "agent_message" {
                    finalText = item["text"] as? String
                }
            case "turn.completed":
                guard started else { throw CodexServiceError.invalidResponse }
                completed = true
            default:
                throw CodexServiceError.invalidResponse
            }
        }
        guard completed, let finalText,
              !finalText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else { throw CodexServiceError.invalidResponse }
        return Result(text: finalText, usage: parseCodexTokenUsage(from: stdout, durationMs: durationMs))
    }

    func run(
        prompt: String,
        model: String,
        effort: String?,
        runtime: CodexRuntime
    ) async throws
        -> Result {
        let arguments = try runtime.translationArguments(model: model, effort: effort)
        let status = try await runtime.command(["login", "status"], process: nextProcess())
        guard try Self.isSignedIn(status) else { throw CodexServiceError.loginRequired }
        let started = Date()
        let output = try await runtime.command(
            arguments,
            process: nextProcess(),
            input: Data(prompt.utf8),
            timeout: 120
        )
        return try Self.result(output, durationMs: Int(Date().timeIntervalSince(started) * 1000))
    }

    func cancel() {
        lock.withLock {
            cancelled = true
            process?.cancel()
        }
    }

    // MARK: Private

    private let lock = NSLock()
    private var cancelled = false
    private var process: CodexCommandProcess?

    private func nextProcess() throws -> CodexCommandProcess {
        try lock.withLock {
            if cancelled { throw CancellationError() }
            let next = CodexCommandProcess()
            process = next
            return next
        }
    }
}
