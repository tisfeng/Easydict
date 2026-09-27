//
//  GitHubCopilotServiceTests.swift
//  EasydictTests
//
//  Created by tisfeng on 2026/09/27.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation
import Testing

@testable import Easydict

// MARK: - GitHubCopilotServiceTests

@Suite("GitHubCopilotService", .serialized)
struct GitHubCopilotServiceTests {
    @Test("service exposes its CLI-backed translation contract")
    func serviceContract() {
        let service = GitHubCopilotService()

        #expect(service.serviceType() == .gitHubCopilot)
        #expect(service.apiKeyRequirement() == .agentCLI)
        #expect(service.hasPrivateAPIKey() == false)
        #expect(service.isStream())
        #expect(service.observeKeys.isEmpty)
        #expect(!service.name().isEmpty)
    }

    @Test("service is registered in the query service factory")
    func factoryRegistration() {
        let service = QueryServiceFactory.shared.service(
            withTypeId: ServiceType.gitHubCopilot.rawValue
        )

        #expect(service is GitHubCopilotService)
    }

    /// The non-default `GitHubCopilotLocalValidation` test plan enables this real CLI call.
    @Test(
        "local Copilot CLI translates through the real service path",
        .enabled(
            if: ProcessInfo.processInfo.environment["EASYDICT_RUN_COPILOT_LOCAL_VALIDATION"] == "1",
            "Set EASYDICT_RUN_COPILOT_LOCAL_VALIDATION=1 to run with the local Copilot CLI and login."
        )
    )
    func validatesLocalCopilotTranslation() async {
        let service = GitHubCopilotService()
        let result = await service.validate()

        #expect(
            result.error == nil,
            "GitHub Copilot validation failed: \(result.error?.localizedDescription ?? "unknown error")"
        )
        #expect(result.translatedText?.isEmpty == false)
    }
}
