//
//  OpenAITemperatureSupportTests.swift
//  EasydictTests
//

import Testing

@testable import Easydict

/// Verifies the OpenAI `temperature` capability check added for #1311.
@Suite("OpenAI Temperature Support", .tags(.unit))
struct OpenAITemperatureSupportTests {
    @Test("Reasoning families omit temperature")
    func reasoningFamiliesOmitTemperature() {
        let identifiers = [
            "gpt-6-luna", "gpt-6.1-sol", "gpt-5-mini", "gpt-7-preview",
            "o1-preview", "o3-mini", "o4-mini", "o5-mini",
        ]
        for identifier in identifiers {
            #expect(!BaseOpenAIService.modelSupportsTemperature(identifier), "\(identifier)")
        }
    }

    @Test("Chat models keep temperature")
    func chatModelsKeepTemperature() {
        let identifiers = ["gpt-4.1", "gpt-4o", "gpt-4o-mini", "gpt-3.5-turbo"]
        for identifier in identifiers {
            #expect(BaseOpenAIService.modelSupportsTemperature(identifier), "\(identifier)")
        }
    }

    @Test("Provider-qualified IDs are normalized")
    func providerQualifiedIdentifiers() {
        #expect(!BaseOpenAIService.modelSupportsTemperature("openai/gpt-5"))
        #expect(!BaseOpenAIService.modelSupportsTemperature("vendor/gpt-6-astra"))
        #expect(BaseOpenAIService.modelSupportsTemperature("openai/gpt-4o"))
    }
}
