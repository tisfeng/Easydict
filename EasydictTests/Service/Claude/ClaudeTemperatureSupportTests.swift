//
//  ClaudeTemperatureSupportTests.swift
//  EasydictTests
//
//  Created by Randomness.K on 2026/10/23.
//  Copyright © 2026 izual. All rights reserved.
//

import Testing

@testable import Easydict

/// Verifies the Claude `temperature` capability check added for #1311.
@Suite("Claude Temperature Support", .tags(.unit))
struct ClaudeTemperatureSupportTests {
    @Test("Pre-4.7 families keep temperature")
    func preReasoningModelsKeepTemperature() {
        let identifiers = [
            "claude-sonnet-4-6", "claude-haiku-4-5", "claude-opus-4-6",
            "claude-opus-4-1-20250805", "claude-3-7-sonnet-20250219",
            "claude-3-5-haiku-20241022", "claude-2.1", "claude-instant-1.2",
        ]
        for identifier in identifiers {
            #expect(ClaudeService.modelSupportsTemperature(identifier), "\(identifier)")
        }
    }

    @Test("Dated 4.0 IDs are not read as an oversized minor")
    func datedFourOhIdentifiersKeepTemperature() {
        let identifiers = ["claude-opus-4-20250514", "claude-sonnet-4-20250514"]
        for identifier in identifiers {
            #expect(ClaudeService.modelSupportsTemperature(identifier), "\(identifier)")
        }
    }

    @Test("Opus 4.7 and later omit temperature")
    func reasoningEraModelsOmitTemperature() {
        let identifiers = [
            "claude-opus-4-7", "claude-opus-4-10", "claude-sonnet-5-5",
            "claude-haiku-5-5", "claude-opus-5-5",
        ]
        for identifier in identifiers {
            #expect(!ClaudeService.modelSupportsTemperature(identifier), "\(identifier)")
        }
    }

    @Test("Provider-qualified, malformed and unknown IDs fail safe")
    func providerQualifiedAndUnknownIdentifiers() {
        #expect(ClaudeService.modelSupportsTemperature("anthropic/claude-opus-4-6"))
        #expect(!ClaudeService.modelSupportsTemperature("anthropic/claude-opus-4-7"))
        #expect(!ClaudeService.modelSupportsTemperature("claude-."))
        #expect(!ClaudeService.modelSupportsTemperature("claude-opus-."))
        #expect(!ClaudeService.modelSupportsTemperature("some-custom-model"))
    }
}
