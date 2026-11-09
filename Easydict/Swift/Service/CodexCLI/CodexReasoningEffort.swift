//
//  CodexReasoningEffort.swift
//  Easydict
//
//  Created by long2ice on 2026/05/10.
//  Copyright © 2026 izual. All rights reserved.
//

import Defaults
import Foundation
import SwiftUI

// MARK: - CodexReasoningEffort

/// Stored reasoning effort values across Codex modes, not a capability list.
/// The `default` case omits the CLI override and keeps the user's config.
/// Codex does not support `none` for model reasoning effort, so it is not
/// exposed here.
enum CodexReasoningEffort: String, CaseIterable, Codable, Defaults.Serializable, Defaults.PreferRawRepresentable {
    /// Sentinel meaning "use whatever is in ~/.codex/config.toml";
    /// the runner skips the flag.
    case `default`
    case minimal
    case low
    case medium
    case high
    case xhigh
    case max
    case ultra

    // MARK: Internal

    /// Preserve the original local CLI overrides independently of managed models.
    /// Specific local models may support fewer levels; default leaves that choice to CLI.
    static let localOptions: [Self] = [.default, .minimal, .low, .medium, .high, .xhigh]

    /// The CLI value to pass via `-c model_reasoning_effort=<value>`.
    /// `nil` for `.default`, which signals "do not override the user's config".
    var cliValue: String? {
        self == .default ? nil : rawValue
    }

    static func validateLocalOverride(_ value: String?, supportedEfforts: [Self] = localOptions) throws {
        guard let value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard let effort = Self(rawValue: value.trimmingCharacters(in: .whitespacesAndNewlines)),
              supportedEfforts.contains(effort), effort != .default
        else { throw CodexCLIError.unsupportedReasoningEffort }
    }
}

// MARK: EnumLocalizedStringConvertible

extension CodexReasoningEffort: EnumLocalizedStringConvertible {
    var title: LocalizedStringKey { LocalizedStringKey(titleKey) }

    var localizedTitle: String {
        NSLocalizedString(titleKey, comment: "Codex reasoning effort")
    }

    private var titleKey: String {
        switch self {
        case .default:
            "service.codex_cli.reasoning_effort.default"
        case .minimal:
            "service.codex_cli.reasoning_effort.minimal"
        case .low:
            "service.codex_cli.reasoning_effort.low"
        case .medium:
            "service.codex_cli.reasoning_effort.medium"
        case .high:
            "service.codex_cli.reasoning_effort.high"
        case .xhigh:
            "service.codex_cli.reasoning_effort.xhigh"
        case .max:
            "service.codex_cli.reasoning_effort.max"
        case .ultra:
            "service.codex_cli.reasoning_effort.ultra"
        }
    }
}
