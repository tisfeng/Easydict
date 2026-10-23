//
//  OpenAITemperatureSupportTests.swift
//  EasydictTests
//
//  Created by Randomness.K on 2026/10/23.
//  Copyright © 2026 izual. All rights reserved.
//

import Testing

@testable import Easydict

/// Verifies the OpenAI `temperature` capability check added for #1311.
@Suite("OpenAI Temperature Support", .tags(.unit))
struct OpenAITemperatureSupportTests {
    @Test("Reasoning families omit temperature")
    func reasoningFamiliesOmitTemperature() {
        let identifiers = [
            "gpt-6-luna", "gpt-6.1-sol",
        ]
        for identifier in identifiers {
            #expect(!BaseOpenAIService.modelSupportsTemperature(identifier), "\(identifier)")
        }
    }

    @Test("Chat models keep temperature")
    func chatModelsKeepTemperature() {
        let identifiers = ["gpt-4.1"]
        for identifier in identifiers {
            #expect(BaseOpenAIService.modelSupportsTemperature(identifier), "\(identifier)")
        }
    }
}
