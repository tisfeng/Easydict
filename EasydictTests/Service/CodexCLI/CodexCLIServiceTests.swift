//
//  CodexCLIServiceTests.swift
//  EasydictTests
//
//  Created by long2ice on 2026/05/07.
//  Copyright © 2026 izual. All rights reserved.
//

@testable import Easydict
import Testing

@Suite("CodexCLIService")
struct CodexCLIServiceTests {
    @Test("serviceType returns .codexCLI")
    func serviceType() {
        let service = CodexCLIService()
        #expect(service.serviceType() == .codexCLI)
    }

    @Test("apiKeyRequirement returns .agentCLI")
    func apiKeyRequirement() {
        let service = CodexCLIService()
        #expect(service.apiKeyRequirement() == .agentCLI)
    }

    @Test("hasPrivateAPIKey returns false when no API key is configured")
    func hasPrivateAPIKey() {
        let service = CodexCLIService()
        #expect(service.hasPrivateAPIKey() == false)
    }

    @Test("isStream returns true")
    func isStream() {
        let service = CodexCLIService()
        #expect(service.isStream() == true)
    }

    @Test("name returns non-empty string")
    func serviceName() {
        let service = CodexCLIService()
        #expect(!service.name().isEmpty)
    }

    @Test("QueryServiceFactory registers CodexCLIService")
    func factoryRegistration() {
        let service = QueryServiceFactory.shared.service(withTypeId: ServiceType.codexCLI.rawValue)
        #expect(service is CodexCLIService)
    }
}
