//
//  OpenAIReasoningEffortTests.swift
//  EasydictTests
//
//  Created by ChrisJiang on 2026/11/26.
//  Copyright © 2026 izual. All rights reserved.
//

import Defaults
import Foundation
import Testing

@testable import Easydict

/// Tests how OpenAI-compatible services encode `reasoning_effort` into chat completion requests.
@Suite("OpenAI Reasoning Effort Request", .serialized, .tags(.unit))
struct OpenAIReasoningEffortTests {
    // MARK: Internal

    @Test("Default reasoning effort omits reasoning_effort from encoded query")
    func defaultReasoningEffortOmitsField() throws {
        let service = makeCustomOpenAIService()
        let effortKey = service.openAIReasoningEffortKey
        let modelKey = service.modelKey
        defer { Defaults.reset(effortKey, modelKey) }

        let query = service.makeChatQuery(messages: [])
        let data = try JSONEncoder().encode(query)
        let payload = try jsonObject(from: data)

        #expect(payload["reasoning_effort"] == nil)
    }

    @Test(
        "Configured non-default reasoning effort is encoded in stream request body",
        arguments: OpenAIReasoningEffort.allCases.filter { $0 != .default }
    )
    func nonDefaultReasoningEffortEncodesInStreamRequest(effort: OpenAIReasoningEffort) throws {
        let service = makeCustomOpenAIService()
        let effortKey = service.openAIReasoningEffortKey
        let modelKey = service.modelKey
        defer { Defaults.reset(effortKey, modelKey) }

        Defaults[effortKey] = effort

        let url = try #require(URL(string: dummyEndpoint))
        let request = try OpenAIStreamTransport().makeRequest(
            query: service.makeChatQuery(messages: []),
            url: url,
            apiKey: ""
        )
        let body = try #require(request.httpBody)
        let payload = try jsonObject(from: body)

        #expect(payload["reasoning_effort"] as? String == effort.rawValue)
        #expect(payload["stream"] as? Bool == true)
    }

    @Test("Distinct CustomOpenAIService instances keep independent reasoning efforts")
    func distinctCustomOpenAIInstancesAreIndependent() throws {
        let firstService = makeCustomOpenAIService()
        let secondService = makeCustomOpenAIService()
        let firstEffortKey = firstService.openAIReasoningEffortKey
        let secondEffortKey = secondService.openAIReasoningEffortKey
        let firstModelKey = firstService.modelKey
        let secondModelKey = secondService.modelKey
        defer {
            Defaults.reset(firstEffortKey, secondEffortKey, firstModelKey, secondModelKey)
        }

        Defaults[firstEffortKey] = .low
        Defaults[secondEffortKey] = .xhigh

        let firstPayload = try jsonObject(
            from: JSONEncoder().encode(firstService.makeChatQuery(messages: []))
        )
        let secondPayload = try jsonObject(
            from: JSONEncoder().encode(secondService.makeChatQuery(messages: []))
        )

        #expect(firstPayload["reasoning_effort"] as? String == "low")
        #expect(secondPayload["reasoning_effort"] as? String == "xhigh")
    }

    @Test("Built-in OpenAIService never sends reasoning_effort even when stored")
    func builtInOpenAIServiceNeverSendsReasoningEffort() throws {
        let service = OpenAIService()
        service.uuid = UUID().uuidString
        let effortKey = service.openAIReasoningEffortKey
        let modelKey = service.modelKey
        defer { Defaults.reset(effortKey, modelKey) }

        Defaults[effortKey] = .high

        let url = try #require(URL(string: dummyEndpoint))
        let request = try OpenAIStreamTransport().makeRequest(
            query: service.makeChatQuery(messages: []),
            url: url,
            apiKey: ""
        )
        let body = try #require(request.httpBody)
        let payload = try jsonObject(from: body)

        #expect(!service.supportsOpenAIReasoningEffort)
        #expect(payload["reasoning_effort"] == nil)
    }

    // MARK: Private

    private let dummyEndpoint = "https://example.invalid/v1/chat/completions"

    private func makeCustomOpenAIService() -> CustomOpenAIService {
        let service = CustomOpenAIService()
        service.uuid = UUID().uuidString
        return service
    }

    private func jsonObject(from data: Data) throws -> [String: Any] {
        try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }
}
