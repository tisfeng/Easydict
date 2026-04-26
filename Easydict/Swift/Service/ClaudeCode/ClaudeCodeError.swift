//
//  ClaudeCodeError.swift
//  Easydict
//
//  Created by Karl on 2026/04/07.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation

/// Errors that can occur when invoking the Claude Code CLI.
///
/// Cases map to the failure modes surfaced by the `claude -p` subprocess:
/// - **notInstalled** — binary not found on disk.
/// - **notLoggedIn** — CLI exited with an authentication / login error (covers "unauthorized" scenarios).
/// - **quotaExceeded** — CLI reported a rate-limit or usage-limit condition.
/// - **cliError** — any other non-zero exit, including process failures and unexpected termination;
///   the raw stderr message is preserved for display.
enum ClaudeCodeError: Error, LocalizedError, Equatable {
    /// The `claude` binary was not found in any known location.
    case notInstalled
    /// The CLI exited with an authentication error (not logged in / unauthorized).
    case notLoggedIn
    /// The CLI exited with a quota / rate-limit error.
    /// - Parameter message: Optional human-readable message from the CLI (e.g. "You've hit your limit · resets 3am").
    case quotaExceeded(message: String?)
    /// The CLI exited with a non-zero code for an unrecognised reason,
    /// including process failures and unexpected termination.
    case cliError(message: String)

    // MARK: Internal

    var errorDescription: String? {
        switch self {
        case .notInstalled:
            return String(localized: "service.claude_code.not_installed")
        case .notLoggedIn:
            return String(localized: "service.claude_code.not_logged_in")
        case let .quotaExceeded(message):
            let base = String(localized: "service.claude_code.quota_exceeded")
            if let message, !message.isEmpty {
                return "\(base)\n\(message)"
            }
            return base
        case let .cliError(message):
            return String(format: String(localized: "service.claude_code.cli_error %@"), message)
        }
    }
}
