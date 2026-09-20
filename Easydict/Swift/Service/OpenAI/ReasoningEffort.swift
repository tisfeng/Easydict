//
//  ReasoningEffort.swift
//  Easydict
//
//  Created by bsythegreat on 2026/06/14.
//  Copyright © 2026 izual. All rights reserved.
//

import Defaults
import Foundation
import SwiftUI

// MARK: - ReasoningEffort

/// Shared reasoning effort levels for OpenAI-compatible streaming services.
/// Kept orthogonal to the model identifier so any current or future model can
/// opt in via `StreamService.supportsReasoningEffort`. `off` disables
/// reasoning for lower latency; `high` and `max` trade latency for quality.
enum ReasoningEffort: String, CaseIterable, Defaults.Serializable {
    case off
    case high
    case max

    // MARK: Internal

    /// Whether the provider should enable its thinking/reasoning mode.
    var isEnabled: Bool {
        self != .off
    }

    /// Value for the OpenAI-compatible `reasoning_effort` request field, or
    /// `nil` when reasoning is disabled so the field can be omitted.
    var requestValue: String? {
        isEnabled ? rawValue : nil
    }
}

// MARK: EnumLocalizedStringConvertible

extension ReasoningEffort: EnumLocalizedStringConvertible {
    var title: LocalizedStringKey {
        switch self {
        case .off:
            "service.reasoning_effort.off"
        case .high:
            "service.reasoning_effort.high"
        case .max:
            "service.reasoning_effort.max"
        }
    }
}
