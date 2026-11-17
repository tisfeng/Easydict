//
//  TokenHubServiceTests.swift
//  EasydictTests
//
//  Copyright © 2026 izual. All rights reserved.
//

import Testing

@testable import Easydict

@Suite("TokenHubService", .serialized)
struct TokenHubServiceTests {
    @Test("exposes TokenHub's OpenAI-compatible configuration")
    func serviceConfiguration() {
        let service = TokenHubService()

        #expect(service.serviceType() == .tokenHub)
        #expect(service.apiKeyRequirement() == .userProvided)
        #expect(service.isStream())
        #expect(service.canFetchRemoteModels)
        #expect(service.defaultEndpoint == "https://tokenhub.tencentmaas.com/v1/chat/completions")
        #expect(service.defaultModel == "hy-mt2-lite")
        #expect(service.defaultModels == ["hy-mt2-pro", "hy-mt2-plus", "hy-mt2-lite"])
        #expect(!service.name().isEmpty)
    }

    @Test("is registered in the query service factory")
    func factoryRegistration() {
        let service = QueryServiceFactory.shared.service(
            withTypeId: ServiceType.tokenHub.rawValue
        )

        #expect(service is TokenHubService)
    }

    @Test("validates a TokenHub translation with configured credentials", .tags(.integration))
    func validatesTokenHubTranslation() async {
        let result = await TokenHubService().validate()

        #expect(
            result.error == nil,
            "TokenHub validation failed: \(result.error?.localizedDescription ?? "unknown error")"
        )
        #expect(result.translatedText?.isEmpty == false)
    }
}
