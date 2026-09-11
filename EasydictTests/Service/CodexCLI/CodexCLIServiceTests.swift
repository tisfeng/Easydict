//
//  CodexCLIServiceTests.swift
//  EasydictTests
//
//  Created by long2ice on 2026/05/07.
//  Copyright © 2026 izual. All rights reserved.
//

import Defaults
@testable import Easydict
import Foundation
import Testing

// MARK: - CodexCLIServiceTests

@Suite("CodexCLIService", .serialized)
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
        let service = QueryServiceFactory.shared.service(
            withTypeId: ServiceType.codexCLI.rawValue
        )
        #expect(service is CodexCLIService)
    }

    @Test("local CLI reasoning effort options stay separate from managed values")
    func localReasoningEffortOptionsStaySeparateFromManagedValues() {
        #expect(CodexReasoningEffort.localOptions == [
            .default,
            .minimal,
            .low,
            .medium,
            .high,
            .xhigh,
        ])
        #expect(!CodexReasoningEffort.localOptions.contains(.max))
        #expect(!CodexReasoningEffort.localOptions.contains(.ultra))
    }

    @Test("Default reasoning effort does not override CLI config")
    func defaultReasoningEffortDoesNotOverrideCLIConfig() {
        #expect(CodexReasoningEffort.default.cliValue == nil)
    }

    @Test("local connection validation rejects a retained unsupported effort")
    func localConnectionValidationRejectsRetainedUnsupportedEffort() async {
        let service = CodexCLIService()
        let uuid = UUID().uuidString
        service.uuid = uuid
        let modeKey = CodexAccessMode.key(uuid: uuid)
        let effortKey = CodexServiceConfiguration.effortKey(uuid: uuid, mode: .localCLI)
        defer {
            service.cancelStream()
            Defaults.reset(modeKey, effortKey)
        }

        Defaults[modeKey] = .localCLI
        Defaults[effortKey] = .max

        let result = await service.validate()

        #expect(Defaults[effortKey] == .max)
        #expect(result.error?.message == CodexCLIError.unsupportedReasoningEffort.localizedDescription)
    }

    @Test("Documented reasoning effort values keep CLI values")
    func documentedReasoningEffortsKeepCLIValues() {
        #expect(CodexReasoningEffort.minimal.cliValue == "minimal")
        #expect(CodexReasoningEffort.low.cliValue == "low")
        #expect(CodexReasoningEffort.medium.cliValue == "medium")
        #expect(CodexReasoningEffort.high.cliValue == "high")
        #expect(CodexReasoningEffort.xhigh.cliValue == "xhigh")
    }

    @Test("current model interface follows the active mode without rewriting saved selections")
    func currentModelInterfaceFollowsActiveMode() {
        let service = CodexCLIService()
        let uuid = UUID().uuidString
        service.uuid = uuid
        let streamService: StreamService = service
        let modeKey = CodexAccessMode.key(uuid: uuid)
        let managedModelKey = CodexServiceConfiguration.modelKey(uuid: uuid, mode: .managed)
        let localModelKey = CodexServiceConfiguration.modelKey(uuid: uuid, mode: .localCLI)
        let localModelsKey = service.validModelsKey
        defer {
            Defaults.reset(modeKey, managedModelKey, localModelKey, localModelsKey)
        }

        let bundledModels = CodexManagedRuntime.bundledModelNames
        #expect(!bundledModels.isEmpty)
        guard let bundledModel = bundledModels.first else { return }

        let retiredManagedModel = "gpt-5.4-mini-retired"
        let localModel = "my-local-codex"
        Defaults[managedModelKey] = retiredManagedModel
        Defaults[localModelKey] = localModel
        Defaults[localModelsKey] = [localModel, "other-local-codex"]
        Defaults[modeKey] = .managed

        // The result-row interface must show the request snapshot for the active
        // mode. Reading a now-invalid old selection must not rewrite it.
        #expect(streamService.model == CodexServiceConfiguration(uuid: uuid).model)
        #expect(streamService.model == retiredManagedModel)
        #expect(streamService.validModels == bundledModels)
        #expect(Defaults[managedModelKey] == retiredManagedModel)

        streamService.model = bundledModel
        #expect(Defaults[managedModelKey] == bundledModel)
        #expect(Defaults[localModelKey] == localModel)

        streamService.model = "untrusted-managed-model"
        #expect(Defaults[managedModelKey] == bundledModel)

        Defaults[modeKey] = .localCLI
        let secondService = CodexCLIService()
        secondService.uuid = uuid
        #expect(streamService.model == localModel)
        #expect(secondService.model == localModel)
        #expect(streamService.validModels == [localModel, "other-local-codex"])

        streamService.model = "updated-local-codex"
        #expect(Defaults[localModelKey] == "updated-local-codex")
        #expect(Defaults[managedModelKey] == bundledModel)
    }

    @MainActor
    @Test("queued local model update cannot auto-query after switching to managed mode")
    func queuedLocalModelUpdateCannotAutoQueryAfterModeSwitch() async throws {
        let service = CodexCLIService()
        let uuid = UUID().uuidString
        service.uuid = uuid
        let modeKey = CodexAccessMode.key(uuid: uuid)
        let managedModelKey = CodexServiceConfiguration.modelKey(uuid: uuid, mode: .managed)
        let localModelKey = CodexServiceConfiguration.modelKey(uuid: uuid, mode: .localCLI)
        defer {
            service.cancelSubscribers()
            Defaults.reset(modeKey, managedModelKey, localModelKey)
        }

        Defaults[modeKey] = .localCLI
        Defaults[localModelKey] = "first-local-model"
        Defaults[managedModelKey] = CodexManagedRuntime.defaultModel
        service.setupCodexSubscribers()

        let updates = ServiceUpdateRecorder()
        let expectedServiceType = service.serviceTypeWithUniqueIdentifier()
        let observer = NotificationCenter.default.addObserver(
            forName: .serviceHasUpdated,
            object: nil,
            queue: nil
        ) { notification in
            guard notification.userInfo?[UserInfoKey.serviceType] as? String == expectedServiceType else { return }
            updates.append(
                autoQuery: notification.userInfo?[UserInfoKey.autoQuery] as? Bool ?? false,
                wasPostedOnMainThread: Thread.isMainThread
            )
        }
        defer { NotificationCenter.default.removeObserver(observer) }

        // Local model edits retain their established auto-query behavior.
        Defaults[localModelKey] = "second-local-model"
        try await Task.sleep(for: .milliseconds(100))
        #expect(!updates.isEmpty)
        #expect(updates.containsAutoQuery)
        #expect(updates.allPostedOnMainThread)

        // Managed model edits refresh the row without resending the current text.
        updates.clear()
        Defaults[modeKey] = .managed
        try await Task.sleep(for: .milliseconds(100))
        updates.clear()
        let differentManagedModel = CodexManagedRuntime.bundledModelNames.first {
            $0 != Defaults[managedModelKey]
        }
        #expect(differentManagedModel != nil)
        guard let differentManagedModel else { return }
        Defaults[managedModelKey] = differentManagedModel
        try await Task.sleep(for: .milliseconds(100))
        #expect(!updates.isEmpty)
        #expect(!updates.containsAutoQuery)
        #expect(updates.allPostedOnMainThread)

        // Both defaults publishers deliver on the next main-queue turn. The queued
        // local event must re-check the mode then, so it cannot query text after the
        // user has already selected managed mode.
        updates.clear()
        Defaults[modeKey] = .localCLI
        try await Task.sleep(for: .milliseconds(100))
        updates.clear()
        Defaults[localModelKey] = "third-local-model"
        Defaults[modeKey] = .managed
        try await Task.sleep(for: .milliseconds(100))

        #expect(!updates.isEmpty)
        #expect(updates.allPostedOnMainThread)
        #expect(!updates.containsAutoQuery)
    }
}

// MARK: - ServiceUpdateRecorder

private final class ServiceUpdateRecorder: @unchecked Sendable {
    // MARK: Internal

    var isEmpty: Bool { lock.withLock { updates.isEmpty } }
    var containsAutoQuery: Bool { lock.withLock { updates.contains { $0.autoQuery } } }
    var allPostedOnMainThread: Bool { lock.withLock { updates.allSatisfy(\.wasPostedOnMainThread) } }

    func append(autoQuery: Bool, wasPostedOnMainThread: Bool) {
        lock.withLock { updates.append((autoQuery, wasPostedOnMainThread)) }
    }

    func clear() {
        lock.withLock { updates.removeAll() }
    }

    // MARK: Private

    private let lock = NSLock()
    private var updates: [(autoQuery: Bool, wasPostedOnMainThread: Bool)] = []
}
