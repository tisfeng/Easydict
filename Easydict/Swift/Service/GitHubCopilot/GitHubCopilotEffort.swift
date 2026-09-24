//
//  GitHubCopilotEffort.swift
//  Easydict
//
//  Created by tisfeng on 2026/09/24.
//

import Defaults
import Foundation
import SwiftUI

// MARK: - GitHubCopilotEffort

/// Reasoning effort levels accepted by the Copilot CLI `--reasoning-effort` flag.
/// The `default` case omits the flag and keeps the CLI's own configured default,
/// so behaviour only changes when the user opts in.
enum GitHubCopilotEffort: String, CaseIterable, Defaults.Serializable {
    /// Sentinel meaning "use the CLI's own default effort"; the runner skips the flag.
    case `default`
    case none
    case minimal
    case low
    case medium
    case high
    case xhigh
    case max

    // MARK: Internal

    /// The CLI value to pass via `--reasoning-effort <level>`.
    /// `nil` for `.default`, which signals "do not override the CLI default".
    var cliValue: String? {
        self == .default ? nil : rawValue
    }
}

// MARK: EnumLocalizedStringConvertible

extension GitHubCopilotEffort: EnumLocalizedStringConvertible {
    var title: LocalizedStringKey {
        switch self {
        case .default:
            "service.github_copilot.effort.default"
        case .none:
            "service.github_copilot.effort.none"
        case .minimal:
            "service.github_copilot.effort.minimal"
        case .low:
            "service.github_copilot.effort.low"
        case .medium:
            "service.github_copilot.effort.medium"
        case .high:
            "service.github_copilot.effort.high"
        case .xhigh:
            "service.github_copilot.effort.xhigh"
        case .max:
            "service.github_copilot.effort.max"
        }
    }
}
