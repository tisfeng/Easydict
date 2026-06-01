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

/// Reasoning effort levels accepted by Codex's `model_reasoning_effort`.
/// The `default` case omits the CLI override and keeps the user's config.
/// Codex does not support `none` for model reasoning effort, so it is not
/// exposed here.
enum CodexReasoningEffort: String, CaseIterable, Defaults.Serializable {
    /// Sentinel meaning "use whatever is in ~/.codex/config.toml";
    /// the runner skips the flag.
    case `default`
    case minimal
    case low
    case medium
    case high
    case xhigh

    // MARK: Internal

    /// The CLI value to pass via `-c model_reasoning_effort=<value>`.
    /// `nil` for `.default`, which signals "do not override the user's config".
    var cliValue: String? {
        self == .default ? nil : rawValue
    }
}

// MARK: EnumLocalizedStringConvertible

extension CodexReasoningEffort: EnumLocalizedStringConvertible {
    var title: LocalizedStringKey {
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
        }
    }
}
