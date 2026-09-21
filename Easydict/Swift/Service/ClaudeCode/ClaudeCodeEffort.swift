//
//  ClaudeCodeEffort.swift
//  Easydict
//
//  Created by Karl on 2026/08/30.
//  Copyright © 2026 izual. All rights reserved.
//

import Defaults
import Foundation
import SwiftUI

// MARK: - ClaudeCodeEffort

/// Effort levels accepted by the Claude CLI `--effort` flag.
/// The `default` case omits the flag and keeps the CLI's own default,
/// so users only see the CLI's behaviour change when they opt in.
enum ClaudeCodeEffort: String, CaseIterable, Defaults.Serializable {
    /// Sentinel meaning "use the CLI's own default effort";
    /// the runner skips the flag.
    case `default`
    case low
    case medium
    case high
    case xhigh
    case max

    // MARK: Internal

    /// The CLI value to pass via `--effort <level>`.
    /// `nil` for `.default`, which signals "do not override the CLI default".
    var cliValue: String? {
        self == .default ? nil : rawValue
    }
}

// MARK: EnumLocalizedStringConvertible

extension ClaudeCodeEffort: EnumLocalizedStringConvertible {
    var title: LocalizedStringKey {
        switch self {
        case .default:
            "service.claude_code.effort.default"
        case .low:
            "service.claude_code.effort.low"
        case .medium:
            "service.claude_code.effort.medium"
        case .high:
            "service.claude_code.effort.high"
        case .xhigh:
            "service.claude_code.effort.xhigh"
        case .max:
            "service.claude_code.effort.max"
        }
    }
}
