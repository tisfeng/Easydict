//
//  OpenAIReasoningEffortTests.swift
//  EasydictTests
//
//  Created by tisfeng on 2026/9/8.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation
import OpenAI
import Testing

@testable import Easydict

// MARK: - OpenAIReasoningEffortTests

/// Tests the optional and subclass-overridable reasoning mode used by OpenAI-compatible services.
@Suite("OpenAI Reasoning Effort", .tags(.unit))
struct OpenAIReasoningEffortTests {
    // MARK: Internal

    @Test("Default stream service omits reasoning effort")
    func defaultReasoningEffort() throws {
        let service = OpenAIService()
        let body = try encodedQueryBody(service: service)

        #expect(body["reasoning_effort"] == nil)
    }

    @Test("Subclass can explicitly send reasoning effort none")
    func explicitNoneReasoningEffort() throws {
        let service = NoneReasoningOpenAIService()
        let body = try encodedQueryBody(service: service)

        #expect(body["reasoning_effort"] as? String == "none")
    }

    @Test("Subclass can override the default reasoning effort")
    func overriddenReasoningEffort() throws {
        let service = HighReasoningOpenAIService()
        let body = try encodedQueryBody(service: service)

        #expect(body["reasoning_effort"] as? String == "high")
    }

    // MARK: Private

    private func encodedQueryBody(service: BaseOpenAIService) throws -> [String: Any] {
        let message = try #require(
            ChatQuery.ChatCompletionMessageParam(role: .user, content: "hello")
        )
        let query = service.openAIChatQuery(messages: [message])
        let data = try JSONEncoder().encode(query)
        return try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }
}

// MARK: - NoneReasoningOpenAIService

private final class NoneReasoningOpenAIService: OpenAIService {
    override var reasoningEffort: ChatQuery.ReasoningEffort? {
        .some(.none)
    }
}

// MARK: - HighReasoningOpenAIService

private final class HighReasoningOpenAIService: OpenAIService {
    override var reasoningEffort: ChatQuery.ReasoningEffort? {
        .some(.high)
    }
}
