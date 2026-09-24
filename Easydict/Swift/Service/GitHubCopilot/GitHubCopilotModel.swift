//
//  GitHubCopilotModel.swift
//  Easydict
//
//  Created by tisfeng on 2026/09/24.
//

import Foundation

// MARK: - GitHubCopilotModel

/// Model identifiers known to the GitHub Copilot CLI.
///
/// This is **not** a validity whitelist. The CLI resolves the model catalog from the
/// signed-in account, so which models actually work depends on that account's Copilot
/// plan and GitHub's current rollout. The list exists only to populate the settings
/// help text; the model field stays free-form and an empty value omits `--model`,
/// which makes the CLI use the model the user already configured for it.
enum GitHubCopilotModel {
    /// Model IDs observed in the Copilot CLI model catalog, grouped for display.
    /// Source: model IDs referenced by the locally installed `copilot` CLI 1.0.86.
    static let knownModelIDs: [String] = [
        "gpt-5.4",
        "gpt-5.3-codex",
        "gpt-5.2",
        "gpt-5.1",
        "gpt-5-mini",
        "gpt-4.1",
        "gpt-4.1-mini",
        "claude-sonnet-4.6",
        "claude-sonnet-4.5",
        "claude-opus-4.6",
        "claude-haiku-4.5",
        "gemini-3-pro-preview",
    ]

    /// Comma-separated form used as a runtime parameter in the settings help text.
    static var knownModelIDsText: String {
        knownModelIDs.joined(separator: ", ")
    }
}
