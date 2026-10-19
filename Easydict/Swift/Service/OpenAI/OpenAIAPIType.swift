//
//  OpenAIAPIType.swift
//  Easydict
//
//  API wire format used by OpenAI-compatible services.

import Defaults
import Foundation
import SwiftUI

// MARK: - OpenAIAPIType

/// Wire format for OpenAI-compatible translation requests.
/// Kept orthogonal to the model identifier so any current or future model can
/// use either format. `chat` sends `messages` to `/v1/chat/completions`.
/// `responses` sends `input` to `/v1/responses`. Some models only support one
/// of the two formats.
enum OpenAIAPIType: String, CaseIterable, Defaults.Serializable {
    case chat
    case responses
}

// MARK: EnumLocalizedStringConvertible

extension OpenAIAPIType: EnumLocalizedStringConvertible {
    var title: LocalizedStringKey {
        switch self {
        case .chat:
            "service.openai_api_type.chat"
        case .responses:
            "service.openai_api_type.responses"
        }
    }
}
