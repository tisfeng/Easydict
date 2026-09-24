//
//  GitHubCopilotEventParser.swift
//  Easydict
//
//  Created by tisfeng on 2026/09/24.
//

import Foundation

// MARK: - GitHubCopilotUsage

/// Usage reported in the `result` event of the Copilot CLI's `--output-format json` output.
///
/// The Copilot CLI does not report token counts; it reports premium request consumption,
/// which is the unit GitHub bills Copilot usage in.
struct GitHubCopilotUsage {
    /// Premium requests consumed by this invocation.
    let premiumRequests: Double
    /// Wall-clock duration of the whole session in milliseconds.
    let sessionDurationMs: Int
    /// Time spent in model API calls in milliseconds.
    let apiDurationMs: Int
}

// MARK: - Parse helpers

/// Returns `true` when a message indicates missing or rejected GitHub authentication.
private func isCopilotAuthenticationMessage(_ message: String) -> Bool {
    let lowercased = message.lowercased()
    return lowercased.contains("not logged in")
        || lowercased.contains("not authenticated")
        || lowercased.contains("no authentication")
        || lowercased.contains("please login")
        || lowercased.contains("please log in")
        || lowercased.contains("please sign-in")
        || lowercased.contains("please sign in")
        || lowercased.contains("please run /login")
        || lowercased.contains("unauthorized")
        || lowercased.contains("not licensed")
}

/// Returns `true` when a message indicates quota, rate-limit, or entitlement exhaustion.
private func isCopilotQuotaMessage(_ message: String) -> Bool {
    let lowercased = message.lowercased()
    return lowercased.contains("rate limit")
        || lowercased.contains("quota")
        || lowercased.contains("usage limit")
        || lowercased.contains("out of requests")
}

/// Removes the noisy macOS crash-reporting line the CLI can emit on stderr.
private func cleanedStderr(_ stderr: String) -> String {
    stderr
        .components(separatedBy: "\n")
        .filter { !$0.contains("MallocStackLogging") }
        .joined(separator: "\n")
        .trimmingCharacters(in: .whitespacesAndNewlines)
}

/// Classifies one raw message into a `GitHubCopilotError`.
private func classify(message: String) -> GitHubCopilotError {
    if isCopilotAuthenticationMessage(message) {
        return .notLoggedIn
    }
    if isCopilotQuotaMessage(message) {
        return .quotaExceeded(message: message)
    }
    return .cliError(message: message)
}

/// Parses the CLI failure reason, preferring stdout event messages over stderr text.
///
/// Failed runs are usually reported on stderr only (for example an unusable `--model`
/// value exits 1 with no stdout events at all), so stderr is the fallback rather than
/// an afterthought. Stdout is scanned first because an event payload carries the
/// structured reason when the CLI does report one there.
func parseGitHubCopilotError(fromStdout stdout: String, stderr: String) -> GitHubCopilotError {
    var stdoutMessage: String?
    let decoder = JSONDecoder()

    for line in stdout.components(separatedBy: "\n") where !line.isEmpty {
        guard let data = line.data(using: .utf8),
              let event = try? decoder.decode(GitHubCopilotJSONLine.self, from: data)
        else { continue }
        guard stdoutMessage == nil else { break }

        for candidate in [event.data?.error, event.data?.message] {
            guard let candidate else { continue }
            let trimmed = candidate.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            stdoutMessage = trimmed
            break
        }
    }

    let stderrText = cleanedStderr(stderr)

    // A structured stdout reason wins over stderr, which can also carry unrelated
    // warnings from the CLI's startup path.
    if let stdoutMessage {
        return classify(message: stdoutMessage)
    }
    if !stderrText.isEmpty {
        return classify(message: stderrText)
    }
    return .cliError(message: String(localized: "service.github_copilot.cli_error.unknown"))
}

/// Scans stdout for the `result` event and extracts usage.
///
/// Returns `nil` when no `result` event is present, which happens if the run failed
/// before any model request was made.
func parseGitHubCopilotUsage(from stdout: String) -> GitHubCopilotUsage? {
    let decoder = JSONDecoder()
    for line in stdout.components(separatedBy: "\n") where !line.isEmpty {
        guard let data = line.data(using: .utf8),
              let event = try? decoder.decode(GitHubCopilotJSONLine.self, from: data),
              event.type == "result",
              let usage = event.usage
        else { continue }

        guard let premiumRequests = usage.premiumRequests else { return nil }
        return GitHubCopilotUsage(
            premiumRequests: premiumRequests,
            sessionDurationMs: usage.sessionDurationMs ?? 0,
            apiDurationMs: usage.totalApiDurationMs ?? 0
        )
    }
    return nil
}

/// Extracts the streamed assistant text from one CLI output line.
///
/// Only `assistant.message_delta` carries translatable output. `assistant.reasoning_delta`
/// shares the `deltaContent` field but holds model reasoning, and `assistant.message`
/// repeats the complete text after streaming — taking either would corrupt the result.
///
/// - Parameter decoder: Caller-supplied decoder to avoid per-call allocation on the hot path.
func extractMessageDelta(from line: String, decoder: JSONDecoder = JSONDecoder()) -> String? {
    guard let data = line.data(using: .utf8),
          let event = try? decoder.decode(GitHubCopilotJSONLine.self, from: data),
          event.type == "assistant.message_delta"
    else { return nil }
    return event.data?.deltaContent
}

/// Returns the number of tool requests the CLI reported for one output line.
///
/// Translation runs with `--available-tools` pointing at a non-existent tool, which
/// removes the entire tool surface (verified as `tool_count: 0`). A non-zero result
/// means that guarantee no longer holds, so the caller must reject the response
/// instead of presenting text produced alongside a tool call.
///
/// Uses `JSONSerialization` rather than `JSONDecoder` on purpose: a strict decode of the
/// whole event fails when the CLI changes the shape of a tool request, which would report
/// zero tool activity exactly when the guard matters most. Any toolRequests value that
/// cannot be read as a list is therefore treated as activity rather than as absence.
func toolRequestCount(from line: String) -> Int {
    guard let data = line.data(using: .utf8),
          let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          root["type"] as? String == "assistant.message",
          let payload = root["data"] as? [String: Any],
          let requests = payload["toolRequests"]
    else { return 0 }

    // An explicit `null` reads as "no requests", the same as an absent field.
    if requests is NSNull { return 0 }
    // Present with an unexpected shape: fail closed rather than assume no activity.
    guard let list = requests as? [Any] else { return 1 }
    return list.count
}

/// Extracts the complete assistant text from one `assistant.message` line.
///
/// Used only as a fallback when a run produced no `assistant.message_delta` at all, which would
/// mean the CLI no longer streams incremental output. Yielding this alongside deltas would
/// duplicate the text, so callers must check that no delta was received first.
func extractMessageContent(from line: String, decoder: JSONDecoder = JSONDecoder()) -> String? {
    guard let data = line.data(using: .utf8),
          let event = try? decoder.decode(GitHubCopilotJSONLine.self, from: data),
          event.type == "assistant.message"
    else { return nil }
    return event.data?.content
}

// MARK: - GitHubCopilotJSONLine

/// One newline-delimited JSON event from the Copilot CLI's `--output-format json` output.
///
/// The `result` event carries `exitCode` and `usage` at the top level, while every other
/// event nests its payload under `data`.
struct GitHubCopilotJSONLine: Decodable {
    let type: String
    let data: GitHubCopilotEventData?
    let exitCode: Int?
    let usage: GitHubCopilotRawUsage?
}

// MARK: - GitHubCopilotEventData

/// The `data` payload shared by the CLI's event types.
struct GitHubCopilotEventData: Decodable {
    /// Incremental assistant text for `assistant.message_delta`.
    let deltaContent: String?
    /// Complete assistant text for `assistant.message`.
    let content: String?
    /// Message text for events that report one.
    let message: String?
    /// Machine-readable failure text for events that report one.
    let error: String?
}

// MARK: - GitHubCopilotRawUsage

/// Raw usage fields decoded from the `result` event.
///
/// Fields are optional because a failed run may omit them entirely; a decode failure
/// would otherwise hide the failure behind a missing-usage result.
struct GitHubCopilotRawUsage: Decodable {
    let premiumRequests: Double?
    let totalApiDurationMs: Int?
    let sessionDurationMs: Int?
}
