//
//  CodexManagedTranslation.swift
//  Easydict
//
//  Created by Alfred on 2026/09/07.
//

import Foundation

/// Performs an authenticated managed translation and validates its terminal JSONL.
/// A request owns its status/exec subprocesses, so cancellation cannot affect other
/// windows. Only a successful turn with final text and no tool activity is accepted.
final class CodexManagedTranslation: @unchecked Sendable {
    // MARK: Internal

    /// Holds only a completed translation and its reported usage.
    struct Result {
        let text: String
        let usage: CodexTokenUsage?
    }

    /// Official status exit 1 also covers config/keyring failures; only the exact
    /// signed-out status is classified as unauthenticated. No token data is read.
    static func isSignedIn(_ output: CodexManagedProcess.Output) throws -> Bool {
        let text = String(decoding: output.stdout + output.stderr, as: UTF8.self)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if output.exitCode == 0, text == "Logged in using ChatGPT" { return true }
        if output.exitCode == 1, text == "Not logged in" { return false }
        if text.lowercased().contains("keyring") || text.lowercased().contains("keychain") {
            throw CodexManagedError.keychainUnavailable
        }
        throw CodexManagedError.authenticationFailed
    }

    static func result(_ output: CodexManagedProcess.Output, durationMs: Int = 0) throws -> Result {
        guard let stdout = String(data: output.stdout, encoding: .utf8),
              let stderr = String(data: output.stderr, encoding: .utf8)
        else { throw CodexManagedError.invalidResponse }
        guard output.exitCode == 0 else {
            let failure = parseCodexFailure(fromStdout: stdout, stderr: stderr)
            switch failure {
            case let .authentication(message):
                let message = message.lowercased()
                if message.contains("keyring") || message.contains("keychain") {
                    throw CodexManagedError.keychainUnavailable
                }
                if message.contains("not signed in") || message.contains("not logged in")
                    || message.contains("please run `codex login`") || message.contains("please run codex login") {
                    throw CodexManagedError.loginRequired
                }
                throw CodexManagedError.authenticationFailed
            case let .other(message)
                where message.lowercased().contains("keyring") || message.lowercased().contains("keychain"):
                throw CodexManagedError.keychainUnavailable
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
            else { throw CodexManagedError.invalidResponse }
            switch type {
            case "thread.started": break
            case "error":
                // Official retry notifications are nonterminal. A later completed
                // turn is still required; diagnostics alone never imply success.
                guard object["message"] is String else { throw CodexManagedError.invalidResponse }
            case "turn.started":
                guard !started else { throw CodexManagedError.invalidResponse }
                started = true
            case "item.completed", "item.started", "item.updated":
                guard let item = object["item"] as? [String: Any],
                      let kind = item["type"] as? String
                else { throw CodexManagedError.invalidResponse }
                // Warnings can precede turn.started (for example config notices).
                if type == "item.completed", kind == "error" {
                    guard item["message"] is String else { throw CodexManagedError.invalidResponse }
                    continue
                }
                guard started, ["reasoning", "agent_message"].contains(kind) else {
                    throw CodexManagedError.invalidResponse
                }
                if type == "item.completed", kind == "agent_message" {
                    finalText = item["text"] as? String
                }
            case "turn.completed":
                guard started else { throw CodexManagedError.invalidResponse }
                completed = true
            default:
                throw CodexManagedError.invalidResponse
            }
        }
        guard completed, let finalText,
              !finalText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else { throw CodexManagedError.invalidResponse }
        return Result(text: finalText, usage: parseCodexTokenUsage(from: stdout, durationMs: durationMs))
    }

    func run(
        prompt: String,
        model: String,
        effort: String?,
        runtime: CodexManagedRuntime
    ) async throws
        -> Result {
        let arguments = try runtime.translationArguments(model: model, effort: effort)
        let status = try await runtime.command(["login", "status"], process: nextProcess())
        guard try Self.isSignedIn(status) else { throw CodexManagedError.loginRequired }
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
    private var process: CodexManagedProcess?

    private func nextProcess() throws -> CodexManagedProcess {
        try lock.withLock {
            if cancelled { throw CancellationError() }
            let next = CodexManagedProcess()
            process = next
            return next
        }
    }
}
