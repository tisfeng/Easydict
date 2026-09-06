//
//  ClaudeCodeServiceTests.swift
//  EasydictTests
//
//  Created by Karl on 2026/04/07.
//  Copyright © 2026 izual. All rights reserved.
//

import Defaults
@testable import Easydict
import Foundation
import Testing

@Suite("ClaudeCodeService", .serialized)
struct ClaudeCodeServiceTests {
    @Test("serviceType returns .claudeCode")
    func serviceType() {
        let service = ClaudeCodeService()
        #expect(service.serviceType() == .claudeCode)
    }

    @Test("apiKeyRequirement returns .agentCLI")
    func apiKeyRequirement() {
        let service = ClaudeCodeService()
        #expect(service.apiKeyRequirement() == .agentCLI)
    }

    @Test("hasPrivateAPIKey returns false when no API key is configured")
    func hasPrivateAPIKey() {
        // CLI services have no API key; the quota gate is bypassed via .agentCLI requirement,
        // so hasPrivateAPIKey() is never consulted for access control.
        let service = ClaudeCodeService()
        #expect(service.hasPrivateAPIKey() == false)
    }

    @Test("isStream returns true")
    func isStream() {
        let service = ClaudeCodeService()
        #expect(service.isStream() == true)
    }

    @Test("name returns non-empty string")
    func serviceName() {
        // Assert the name is non-empty rather than matching a locale-specific string.
        // The display value comes from the string catalog and varies by locale.
        let service = ClaudeCodeService()
        #expect(!service.name().isEmpty)
    }

    @Test("QueryServiceFactory registers ClaudeCodeService")
    func factoryRegistration() {
        let service = QueryServiceFactory.shared.service(withTypeId: ServiceType.claudeCode.rawValue)
        #expect(service is ClaudeCodeService)
    }

    @Test("legacy empty stored model migrates to the default once, deliberate clears persist")
    func legacyEmptyModelMigration() {
        let service = ClaudeCodeService()
        let modelKey = service.modelKey
        let migratedKey = service.modelMigratedKey
        let originalModel = Defaults[modelKey]
        let originalMigrated = Defaults[migratedKey]
        defer {
            Defaults[modelKey] = originalModel
            Defaults[migratedKey] = originalMigrated
        }

        // Legacy state: an empty model persisted by the old base getter, migration
        // not yet run — a new service instance coerces it back to the default.
        Defaults[modelKey] = ""
        Defaults[migratedKey] = false
        _ = ClaudeCodeService()
        #expect(Defaults[modelKey] == ClaudeCodeRunner.defaultModel)
        #expect(Defaults[migratedKey] == true)

        // A deliberate clear after migration means "use the CLI default" and must
        // survive later service instantiations (e.g. app relaunch).
        Defaults[modelKey] = ""
        _ = ClaudeCodeService()
        #expect(Defaults[modelKey].isEmpty)
    }

    @Test("delayed configuration callbacks preserve free-form model input")
    func delayedConfigurationCallbacksPreserveFreeFormModel() {
        let service = ClaudeCodeService()
        service.uuid = "test-\(UUID().uuidString)"
        let modelKey = service.modelKey
        let supportedModelsKey = service.supportedModelsKey
        let originalModel = Defaults[modelKey]
        let originalSupportedModels = Defaults[supportedModelsKey]
        defer {
            Defaults[modelKey] = originalModel
            Defaults[supportedModelsKey] = originalSupportedModels
        }

        let initialSupportedModels = service.supportedModels
        let finalModel = "claude-opus-4-7"

        service.model = finalModel
        service.modelDidChanged("claude-opus")
        service.supportedModelsTextDidChanged("claude-opus, sonnet")

        #expect(service.model == finalModel)
        #expect(service.supportedModels == initialSupportedModels)

        service.model = ""
        service.modelDidChanged(finalModel)

        #expect(service.model.isEmpty)
        #expect(service.supportedModels == initialSupportedModels)
    }
}
