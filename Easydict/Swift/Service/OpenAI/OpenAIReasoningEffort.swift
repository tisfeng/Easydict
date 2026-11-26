//
//  OpenAIReasoningEffort.swift
//  Easydict
//
//  Created by ChrisJiang on 2026/11/26.
//  Copyright © 2026 izual. All rights reserved.
//

import Defaults
import Foundation
import OpenAI
import SwiftUI

// MARK: - OpenAIReasoningEffort

/// Reasoning effort levels for generic OpenAI-compatible chat endpoints.
///
/// Unlike the DeepSeek-oriented `ReasoningEffort` (`off/high/max`), these
/// mirror the OpenAI `reasoning_effort` values. `default` omits the field so
/// providers and models that reject it keep working unchanged.
enum OpenAIReasoningEffort: String, CaseIterable, Defaults.Serializable {
    case `default`
    case none
    case minimal
    case low
    case medium
    case high
    case xhigh

    // MARK: Internal

    /// Value for the `reasoning_effort` request field, or `nil` to omit it.
    var chatQueryValue: ChatQuery.ReasoningEffort? {
        switch self {
        case .default:
            nil
        case .none:
            ChatQuery.ReasoningEffort.none
        case .minimal:
            .minimal
        case .low:
            .low
        case .medium:
            .medium
        case .high:
            .high
        case .xhigh:
            // Not modeled by the SDK enum yet; encoded verbatim.
            .customValue(rawValue)
        }
    }
}

// MARK: EnumLocalizedStringConvertible

extension OpenAIReasoningEffort: EnumLocalizedStringConvertible {
    var title: LocalizedStringKey {
        switch self {
        case .default:
            "service.openai.reasoning_effort.default"
        case .none:
            "service.openai.reasoning_effort.none"
        case .minimal:
            "service.openai.reasoning_effort.minimal"
        case .low:
            "service.openai.reasoning_effort.low"
        case .medium:
            "service.openai.reasoning_effort.medium"
        case .high:
            "service.openai.reasoning_effort.high"
        case .xhigh:
            "service.openai.reasoning_effort.xhigh"
        }
    }
}
