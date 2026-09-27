//
//  ExplainServiceTests.swift
//  EasydictTests
//
//  Created by tisfeng on 2026/9/26.
//  Copyright © 2026 izual. All rights reserved.
//

import Testing

@testable import Easydict

/// Offline tests for the Explain ("这是什么") AI tool service, covering factory
/// registration and the prompt message assembly behavior.
@Suite("Explain Service", .tags(.unit))
struct ExplainServiceTests {
    /// Verifies the service is registered in the factory under the `.explain` type.
    @Test("Factory resolves ExplainService by type")
    func factoryResolvesExplainService() {
        let service = QueryServiceFactory.shared.service(withTypeId: ServiceType.explain.rawValue)

        #expect(service is ExplainService, "Factory should create ExplainService for .explain")
        #expect(
            QueryServiceFactory.shared.allServiceTypes.contains(.explain),
            ".explain should be listed in allServiceTypes"
        )
    }

    /// Verifies the display name comes from the `explain_service` localization key.
    @Test("Service name is localized")
    func serviceNameIsLocalized() {
        let service = ExplainService()

        #expect(!service.name().isEmpty, "Service name should not be empty")
        #expect(service.name() != "explain_service", "Name should resolve the localization key")
    }

    /// Verifies chatMessageDicts builds a system prompt, few-shot pairs, and a
    /// final user prompt that wraps the query text.
    @Test("Chat messages include system, few-shot, and wrapped query")
    func chatMessagesAreAssembled() throws {
        let service = ExplainService()
        let query = ChatQueryParam(
            text: "EACCES permission denied",
            sourceLanguage: .english,
            targetLanguage: .simplifiedChinese,
            queryType: .translation,
            enableSystemPrompt: false
        )

        let messages = service.chatMessageDicts(query)

        // [system] + 2 few-shot pairs (user+assistant) + [user] = 6 messages.
        #expect(messages.count == 6, "Expected system + 2 few-shot pairs + user, got \(messages.count)")
        #expect(messages[0].role == .system, "First message should be the system prompt")

        // After the system message, roles must alternate user/assistant pairs.
        for (offset, message) in messages.dropFirst().enumerated() {
            let expectedRole: ChatMessage.ChatRole = offset.isMultiple(of: 2) ? .user : .assistant
            #expect(
                message.role == expectedRole,
                "Message \(offset + 1) should alternate user/assistant roles"
            )
        }

        let last = try #require(messages.last)
        #expect(last.role == .user, "Last message should be the user prompt")
        #expect(last.content.contains("\"\"\"EACCES permission denied\"\"\""), "User prompt should wrap the query text")
    }

    /// Verifies the user prompt requests the answer in the user's first language.
    @Test("Prompt requests first language as answer language")
    func promptUsesFirstLanguage() throws {
        let service = ExplainService()
        let answerLanguage = MyConfiguration.shared.firstLanguage
        let query = ChatQueryParam(
            text: "spill the tea",
            sourceLanguage: .english,
            targetLanguage: .simplifiedChinese,
            queryType: .translation,
            enableSystemPrompt: false
        )

        let messages = service.chatMessageDicts(query)

        let last = try #require(messages.last)
        #expect(
            last.content.contains("Using \(answerLanguage.rawValue) to explain"),
            "Prompt should ask the model to answer in \(answerLanguage.rawValue)"
        )
    }
}
