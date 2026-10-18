//
//  GitHubCopilotModel.swift
//  Easydict
//
//  Created by tisfeng on 2026/09/24.
//

import Foundation

/// Account-scoped metadata returned by the CLI's `models.list` RPC.
struct GitHubCopilotModel: Codable, Identifiable, Sendable {
    struct Capabilities: Codable, Sendable {
        struct Supports: Codable, Sendable {
            let reasoningEffort: Bool?
        }

        let supports: Supports?
    }

    struct Policy: Codable, Sendable {
        let state: String
    }

    let id: String
    let name: String
    let capabilities: Capabilities?
    let policy: Policy?
    let supportedReasoningEfforts: [String]?
    let defaultReasoningEffort: String?

    var isAvailable: Bool { policy?.state != "disabled" }

    /// Preserve server-provided values, including levels introduced by future CLI versions.
    var reasoningEfforts: [String] {
        guard id != "auto", capabilities?.supports?.reasoningEffort == true else { return [] }
        var seen = Set<String>()
        return (supportedReasoningEfforts ?? []).filter { !$0.isEmpty && seen.insert($0).inserted }
    }
}
