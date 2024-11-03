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
        .init(role: .system, content: LLMStreamService.dictSystemPrompt)
    default:
        .init(role: .system, content: LLMStreamService.translationSystemPrompt)
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
