//
//  ChatMessage.swift
//  Easydict
//
//  Created by tisfeng on 2024/11/3.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation

func systemMessage(queryType: EZQueryTextType) -> ChatMessage {
    switch queryType {
    case .dictionary:
        .init(role: .system, content: StreamService.dictSystemPrompt)
    default:
        .init(role: .system, content: StreamService.translationSystemPrompt)
    }
}

func chatMessagePair(userContent: String, assistantContent: String) -> [ChatMessage] {
    [
        .init(role: .user, content: userContent),
        .init(role: .assistant, content: assistantContent),
    ]
}

// MARK: - ChatMessage

struct ChatMessage {
    // MARK: - ChatRole

    enum ChatRole: String, Codable, Equatable, CaseIterable {
        case system
        case user
        case assistant
        case tool
        case model // Gemini role, equal to OpenAI assistant role.
    }

    let role: ChatRole
    let content: String
}

// MARK: - AIToolType

enum AIToolType {
    case polishing
    case summary
}

// MARK: - TextReplacementPromptContext

/// Carries action-only prompt semantics without extending the public HTTP request model.
///
/// The selected service still owns transport, endpoint, credentials, model, temperature,
/// and streaming configuration; this context only chooses the task prompt.
struct TextReplacementPromptContext: Equatable {
    let action: TextReplacementAction
    let additionalPrompt: String

    var normalizedAdditionalPrompt: String {
        additionalPrompt.trim()
    }
}

// MARK: - ChatQueryParam

struct ChatQueryParam {
    let text: String
    let sourceLanguage: Language
    let targetLanguage: Language
    let queryType: EZQueryTextType
    let enableSystemPrompt: Bool

    func unpack() -> (String, Language, Language, EZQueryTextType, Bool) {
        (text, sourceLanguage, targetLanguage, queryType, enableSystemPrompt)
    }
}
