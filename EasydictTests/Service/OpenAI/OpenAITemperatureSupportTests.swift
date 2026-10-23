//
//  OpenAITemperatureSupportTests.swift
//  EasydictTests
//
//  Created by Randomness.K on 2026/10/23.
//  Copyright © 2026 izual. All rights reserved.
//

import Testing

@testable import Easydict

/// Verifies service-level temperature policy without inspecting model identifiers.
@Suite("OpenAI Temperature Support", .tags(.unit))
struct OpenAITemperatureSupportTests {
    @Test("Services with disabled temperature omit the parameter")
    func disabledServicesOmitTemperature() {
        let services: [BaseOpenAIService] = [OpenAIService(), MiniMaxService()]
        for service in services {
            #expect(!service.supportsTemperature)
        }
    }

    @Test("Compatible services keep temperature")
    func compatibleServicesKeepTemperature() {
        let services: [BaseOpenAIService] = [GroqService()]
        for service in services {
            #expect(service.supportsTemperature)
        }
    }
}
