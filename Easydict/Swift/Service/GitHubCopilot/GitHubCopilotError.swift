//
//  GitHubCopilotError.swift
//  Easydict
//
//  Created by tisfeng on 2026/09/24.
//

import Foundation

/// Errors that can occur when invoking the GitHub Copilot CLI.
///
/// Cases map to the failure modes surfaced by the `copilot -p` subprocess:
/// - **notInstalled** — binary not found on disk.
/// - **notLoggedIn** — CLI reported missing or rejected GitHub authentication.
/// - **quotaExceeded** — CLI reported a rate-limit or premium-request quota condition.
/// - **unexpectedToolUse** — the CLI reported a tool request even though translation
///   runs with the tool surface fully removed; the result is discarded rather than shown.
/// - **cliError** — any other non-zero exit, including an unusable `--model` value;
///   the raw CLI message is preserved for display.
enum GitHubCopilotError: Error, LocalizedError, Equatable {
    /// The `copilot` binary was not found in any known location.
    case notInstalled
    /// The CLI reported that no usable GitHub authentication is available.
    case notLoggedIn
    /// The CLI reported a rate-limit or quota condition.
    /// - Parameter message: Optional human-readable message from the CLI.
    case quotaExceeded(message: String?)
    /// The CLI reported a tool request despite running with no available tools.
    case unexpectedToolUse
    /// The CLI exited with a non-zero code for an unrecognised reason,
    /// including process failures and unexpected termination.
    case cliError(message: String)

    // MARK: Internal

    var errorDescription: String? {
        switch self {
        case .notInstalled:
            return String(localized: "service.github_copilot.not_installed")
        case .notLoggedIn:
            return String(localized: "service.github_copilot.not_logged_in")
        case let .quotaExceeded(message):
            let base = String(localized: "service.github_copilot.quota_exceeded")
            if let message, !message.isEmpty {
                return "\(base)\n\(message)"
            }
            return base
        case .unexpectedToolUse:
            return String(localized: "service.github_copilot.unexpected_tool_use")
        case let .cliError(message):
            return String(format: String(localized: "service.github_copilot.cli_error %@"), message)
        }
    }
}
