//
//  OpenAIStreamResultTests.swift
//  EasydictTests
//
//  Created by tisfeng on 2026/9/8.
//  Copyright © 2026 izual. All rights reserved.
//

import OpenAI
import Testing

@testable import Easydict

/// Tests compatibility helpers for the upstream OpenAI SDK response models.
@Suite("OpenAI Stream Result", .tags(.unit))
struct OpenAIStreamResultTests {
    @Test("Create text-only chat completion chunk")
    func createTextOnlyChunk() throws {
        let result = try ChatStreamResult.create(content: "translated text", model: "test-model")

        #expect(result.id.hasPrefix("chatcmpl-"))
        #expect(result.object == "chat.completion.chunk")
        #expect(result.created == result.created.rounded(.towardZero))
        #expect(result.model == "test-model")
        #expect(result.choices.count == 1)
        #expect(result.choices[0].index == 0)
        #expect(result.content == "translated text")
    }
}
