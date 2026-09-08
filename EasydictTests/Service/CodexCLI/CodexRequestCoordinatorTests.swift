//
//  CodexRequestCoordinatorTests.swift
//  EasydictTests
//
//  Created by Alfred on 2026/09/07.
//

import Defaults
@testable import Easydict
import Foundation
import Testing

// MARK: - CodexRequestCoordinatorTests

/// Verifies registrations are isolated by service ID, mode, and account activity.
@Suite("Codex request coordinator", .serialized)
struct CodexRequestCoordinatorTests {
    @Test("model invalidation only cancels matching UUID and access mode")
    func modelInvalidationIsScopedToUUIDAndMode() async throws {
        let coordinator = CodexRequestCoordinator()
        let managedUUID = UUID().uuidString
        let localUUID = UUID().uuidString
        let otherManagedUUID = UUID().uuidString
        installConfiguration(uuid: managedUUID, mode: .managed, model: "managed-first")
        installConfiguration(uuid: localUUID, mode: .localCLI, model: "local")
        installConfiguration(uuid: otherManagedUUID, mode: .managed, model: "managed-second")
        defer {
            restoreConfiguration(uuid: managedUUID)
            restoreConfiguration(uuid: localUUID)
            restoreConfiguration(uuid: otherManagedUUID)
        }

        coordinator.observe(uuid: managedUUID)
        let managedConfiguration = CodexServiceConfiguration(uuid: managedUUID)
        let localConfiguration = CodexServiceConfiguration(uuid: localUUID)
        let otherManagedConfiguration = CodexServiceConfiguration(uuid: otherManagedUUID)
        let managedToken = UUID()
        let localToken = UUID()
        let otherManagedToken = UUID()
        let managedCancel = InvocationCounter()
        let localCancel = InvocationCounter()
        let otherManagedCancel = InvocationCounter()
        try coordinator.register(
            token: managedToken,
            configuration: managedConfiguration,
            cancel: managedCancel.increment
        )
        try coordinator.register(token: localToken, configuration: localConfiguration, cancel: localCancel.increment)
        try coordinator.register(
            token: otherManagedToken,
            configuration: otherManagedConfiguration,
            cancel: otherManagedCancel.increment
        )

        Defaults[CodexServiceConfiguration.modelKey(uuid: managedUUID, mode: .managed)] = "managed-first-updated"
        await Task.yield()

        #expect(managedCancel.count == 1)
        #expect(localCancel.isEmpty)
        #expect(otherManagedCancel.isEmpty)
        #expect(!coordinator.isCurrent(managedToken))
        #expect(coordinator.isCurrent(localToken))
        #expect(coordinator.isCurrent(otherManagedToken))
    }

    @Test(
        "account transitions cancel active managed work but retain local CLI work",
        arguments: CodexAccountOperation.allCases
    )
    func accountTransitionCancelsManagedOnly(operation: CodexAccountOperation) throws {
        let coordinator = CodexRequestCoordinator()
        let managedUUID = UUID().uuidString
        let localUUID = UUID().uuidString
        let otherManagedUUID = UUID().uuidString
        installConfiguration(uuid: managedUUID, mode: .managed, model: "managed-first")
        installConfiguration(uuid: localUUID, mode: .localCLI, model: "local")
        installConfiguration(uuid: otherManagedUUID, mode: .managed, model: "managed-second")
        defer {
            coordinator.setAccountOperation(nil)
            restoreConfiguration(uuid: managedUUID)
            restoreConfiguration(uuid: localUUID)
            restoreConfiguration(uuid: otherManagedUUID)
        }

        let managedToken = UUID()
        let localToken = UUID()
        let otherManagedToken = UUID()
        let managedCancel = InvocationCounter()
        let localCancel = InvocationCounter()
        let otherManagedCancel = InvocationCounter()
        try coordinator.register(
            token: managedToken,
            configuration: CodexServiceConfiguration(uuid: managedUUID),
            cancel: managedCancel.increment
        )
        try coordinator.register(
            token: localToken,
            configuration: CodexServiceConfiguration(uuid: localUUID),
            cancel: localCancel.increment
        )
        try coordinator.register(
            token: otherManagedToken,
            configuration: CodexServiceConfiguration(uuid: otherManagedUUID),
            cancel: otherManagedCancel.increment
        )

        coordinator.setAccountOperation(operation)

        #expect(managedCancel.count == 1)
        #expect(otherManagedCancel.count == 1)
        #expect(localCancel.isEmpty)
        #expect(!coordinator.isCurrent(managedToken))
        #expect(!coordinator.isCurrent(otherManagedToken))
        #expect(coordinator.isCurrent(localToken))

        let blockedToken = UUID()
        let blockedCancel = InvocationCounter()
        let admission = try coordinator.register(
            token: blockedToken,
            configuration: CodexServiceConfiguration(uuid: managedUUID),
            cancel: blockedCancel.increment
        )
        #expect(admission == .blocked(operation))
        #expect(coordinator.isCurrent(blockedToken))
        #expect(blockedCancel.isEmpty)
    }

    @Test("removing one registration does not cancel another request")
    func removeLeavesOtherRegistrationsUntouched() throws {
        let coordinator = CodexRequestCoordinator()
        let uuid = UUID().uuidString
        installConfiguration(uuid: uuid, mode: .managed, model: "managed")
        defer { restoreConfiguration(uuid: uuid) }

        let removedToken = UUID()
        let retainedToken = UUID()
        let removedCancel = InvocationCounter()
        let retainedCancel = InvocationCounter()
        let configuration = CodexServiceConfiguration(uuid: uuid)
        try coordinator.register(token: removedToken, configuration: configuration, cancel: removedCancel.increment)
        try coordinator.register(token: retainedToken, configuration: configuration, cancel: retainedCancel.increment)

        coordinator.remove(removedToken)

        #expect(!coordinator.isCurrent(removedToken))
        #expect(coordinator.isCurrent(retainedToken))
        #expect(removedCancel.isEmpty)
        #expect(retainedCancel.isEmpty)
    }

    @Test("reading stored selections preserves retired managed and custom local CLI values")
    func readingConfigurationDoesNotRewriteStoredSelections() {
        let uuid = UUID().uuidString
        let managedModel = "gpt-5.4-mini"
        let localModel = "my-local-codex"
        installConfiguration(uuid: uuid, mode: .managed, model: managedModel)
        Defaults[CodexServiceConfiguration.effortKey(uuid: uuid, mode: .managed)] = .ultra
        Defaults[CodexServiceConfiguration.modelKey(uuid: uuid, mode: .localCLI)] = localModel
        Defaults[CodexServiceConfiguration.effortKey(uuid: uuid, mode: .localCLI)] = .max
        defer { restoreConfiguration(uuid: uuid) }

        let managed = CodexServiceConfiguration(uuid: uuid)

        #expect(managed.mode == .managed)
        #expect(managed.model == managedModel)
        #expect(managed.effort == .ultra)
        #expect(Defaults[CodexServiceConfiguration.modelKey(uuid: uuid, mode: .managed)] == managedModel)
        #expect(Defaults[CodexServiceConfiguration.effortKey(uuid: uuid, mode: .managed)] == .ultra)

        Defaults[CodexAccessMode.key(uuid: uuid)] = .localCLI
        let local = CodexServiceConfiguration(uuid: uuid)

        #expect(local.mode == .localCLI)
        #expect(local.model == localModel)
        #expect(local.effort == .max)
        #expect(Defaults[CodexServiceConfiguration.modelKey(uuid: uuid, mode: .localCLI)] == localModel)
        #expect(Defaults[CodexServiceConfiguration.effortKey(uuid: uuid, mode: .localCLI)] == .max)
    }

    @Test("reasoning effort candidates follow mode and managed model catalog")
    func reasoningEffortCandidatesFollowModeAndManagedModelCatalog() {
        #expect(CodexServiceConfiguration.reasoningEfforts(mode: .localCLI, model: "gpt-6-astra") == [
            .default,
            .minimal,
            .low,
            .medium,
            .high,
            .xhigh,
        ])

        #expect(CodexServiceConfiguration.reasoningEfforts(mode: .managed, model: "gpt-5.5") == [
            .default,
            .low,
            .medium,
            .high,
            .xhigh,
        ])

        if CodexManagedRuntime.bundledModelNames.contains("gpt-5.6-luna") {
            let lunaEfforts = CodexServiceConfiguration.reasoningEfforts(
                mode: .managed,
                model: "gpt-5.6-luna"
            )
            #expect(lunaEfforts == [.default, .low, .medium, .high, .xhigh, .max])
            #expect(!lunaEfforts.contains(.ultra))
        }
    }
}

// MARK: - InvocationCounter

private final class InvocationCounter: @unchecked Sendable {
    // MARK: Internal

    var count: Int { lock.withLock { value } }

    var isEmpty: Bool { count == 0 }

    func increment() {
        lock.withLock { value += 1 }
    }

    // MARK: Private

    private let lock = NSLock()
    private var value = 0
}

private func installConfiguration(uuid: String, mode: CodexAccessMode, model: String) {
    Defaults[CodexAccessMode.key(uuid: uuid)] = mode
    Defaults[CodexServiceConfiguration.modelKey(uuid: uuid, mode: mode)] = model
    Defaults[CodexServiceConfiguration.effortKey(uuid: uuid, mode: mode)] = .default
}

private func restoreConfiguration(uuid: String) {
    Defaults[CodexAccessMode.key(uuid: uuid)] = .managed
    Defaults[CodexServiceConfiguration.modelKey(uuid: uuid, mode: .managed)] = CodexManagedRuntime.defaultModel
    Defaults[CodexServiceConfiguration.effortKey(uuid: uuid, mode: .managed)] = .default
    Defaults[CodexServiceConfiguration.modelKey(uuid: uuid, mode: .localCLI)] = ""
    Defaults[CodexServiceConfiguration.effortKey(uuid: uuid, mode: .localCLI)] = .default
}
