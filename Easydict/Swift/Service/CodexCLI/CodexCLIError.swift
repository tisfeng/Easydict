//
//  CodexCLIError.swift
//  Easydict
//
//  Created by long2ice on 2026/05/07.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation

/// Errors that can occur when invoking the Codex CLI.
///
/// Cases map to the failure modes surfaced by the `codex exec --json` subprocess:
/// - **notInstalled** — binary not found on disk.
/// - **notLoggedIn** — CLI exited with an authentication / login error.
/// - **quotaExceeded** — CLI reported a rate-limit or usage-limit condition.
/// - **cliError** — any other non-zero exit; the raw message is preserved for display.
enum CodexCLIError: Error, LocalizedError, Equatable {
    /// The `codex` binary was not found in any known location.
    case notInstalled
    /// The CLI exited with an authentication error (not signed in / unauthorized).
    case notLoggedIn
    /// The CLI exited with a quota / rate-limit error.
    /// - Parameter message: Optional human-readable message from the CLI.
    case quotaExceeded(message: String?)
    /// The CLI exited with a non-zero code for an unrecognised reason.
    case cliError(message: String)

    // MARK: Internal

    var errorDescription: String? {
        switch self {
        case .notInstalled:
            return String(localized: "service.codex_cli.not_installed")
        case .notLoggedIn:
            return String(localized: "service.codex_cli.not_logged_in")
        case let .quotaExceeded(message):
            let base = String(localized: "service.codex_cli.quota_exceeded")
            if let message, !message.isEmpty {
                return "\(base)\n\(message)"
            }
            return base
        case let .cliError(message):
            return String(format: String(localized: "service.codex_cli.cli_error %@"), message)
        }
    }
}
