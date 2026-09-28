//
//  CodexManagedAccountRecoveryTests.swift
//  EasydictTests
//
//  Created by Alfred on 2026/09/11.
//

import Defaults
@testable import Easydict
import Foundation
import Testing

/// Verifies that a settings refresh preserves current recovery evidence instead
/// of restoring a superseded snapshot or disguising confirmed account loss.
@MainActor
@Suite("Codex managed account recovery", .serialized)
struct CodexManagedAccountRecoveryTests {
    @Test("a successful read-only refresh retains applicable completed verification")
    func refreshRetainsCompletedVerification() async throws {
        try await withAccountFixture(initiallySignedIn: true, release: .current) { fixture in
            let uuid = UUID().uuidString
            installManagedConfiguration(uuid: uuid, model: "gpt-5.5", effort: .high)
            defer { resetManagedConfiguration(uuid: uuid) }
            let configuration = CodexServiceConfiguration(uuid: uuid)
            let account = fixture.account()

            account.validate(configuration: configuration)
            try await waitForAccount { !account.isBusy && account.isValidated(configuration: configuration) }

            account.refresh()
            try await waitForAccount { !account.isBusy }

            #expect(account.isValidated(configuration: configuration))
            #expect(account.verificationError(for: configuration) == nil)
        }
    }

    @Test("a successful read-only refresh retains an applicable configuration validation failure")
    func refreshRetainsCompletedVerificationFailure() async throws {
        try await withAccountFixture(initiallySignedIn: true, release: .current) { fixture in
            let uuid = UUID().uuidString
            installManagedConfiguration(uuid: uuid, model: "gpt-5.4-mini", effort: .high)
            defer { resetManagedConfiguration(uuid: uuid) }
            let configuration = CodexServiceConfiguration(uuid: uuid)
            let account = fixture.account()

            account.validate(configuration: configuration)
            try await waitForAccount { !account.isBusy }
            let validationError = try #require(account.verificationError(for: configuration))

            account.refresh()
            try await waitForAccount { !account.isBusy && account.isSignedIn }

            #expect(account.verificationError(for: configuration) as? CodexManagedError == .invalidModel)
            #expect(account.errorMessage(for: configuration) == validationError.localizedDescription)
        }
    }

    @Test("canceling a repeated read-only refresh keeps its prior check error")
    func cancellingRefreshRetainsPriorCheckError() async throws {
        try await withAccountFixture(statusFailure: .keychain) { fixture in
            let gate = RuntimeFactoryGate()
            let calls = RuntimeFactoryCallCounter()
            let account = CodexManagedAccount(
                runtimeFactory: {
                    await calls.record()
                    if await calls.count == 2 { await gate.wait() }
                    return fixture.runtime()
                },
                coordinator: CodexRequestCoordinator()
            )

            account.refresh()
            try await waitForAccount { !account.isBusy }
            let firstError = try #require(account.errorMessage)

            account.refresh()
            try await waitForRuntimeFactory(gate)
            account.cancelCurrentOperation()
            await gate.release()
            try await waitForAccount { !account.isBusy }

            #expect(account.errorMessage == firstError)
            #expect(!account.isSignedIn)
            #expect(!accountIsSignedOut(account))
        }
    }

    @Test("a cancelled refresh cannot revive a verification invalidated while checking")
    func configurationChangeDuringRefreshCannotRestoreVerification() async throws {
        try await withAccountFixture(initiallySignedIn: true, release: .current) { fixture in
            let uuid = UUID().uuidString
            installManagedConfiguration(uuid: uuid, model: "gpt-5.5", effort: .high)
            defer { resetManagedConfiguration(uuid: uuid) }
            let configuration = CodexServiceConfiguration(uuid: uuid)
            let gate = RuntimeFactoryGate()
            let calls = RuntimeFactoryCallCounter()
            let account = CodexManagedAccount(
                runtimeFactory: {
                    await calls.record()
                    if await calls.count == 2 { await gate.wait() }
                    return fixture.runtime()
                },
                coordinator: CodexRequestCoordinator()
            )

            account.validate(configuration: configuration)
            try await waitForAccount { !account.isBusy && account.isValidated(configuration: configuration) }

            account.refresh()
            try await waitForRuntimeFactory(gate)
            account.configurationChanged(origin: uuid)
            account.cancelCurrentOperation()
            await gate.release()
            try await waitForAccount { !account.isBusy }

            #expect(!account.isValidated(configuration: configuration))
            #expect(account.verificationError(for: configuration) == nil)
        }
    }

    @Test("a confirmed login loss from manual validation is an account recovery error")
    func manualValidationLoginLossDoesNotBecomeConfigurationFailure() async throws {
        try await withAccountFixture(
            initiallySignedIn: true,
            loginValidationFailure: .execSignedOut,
            release: .current
        ) { fixture in
            let uuid = UUID().uuidString
            installManagedConfiguration(uuid: uuid, model: "gpt-5.5", effort: .high)
            defer { resetManagedConfiguration(uuid: uuid) }
            let configuration = CodexServiceConfiguration(uuid: uuid)
            let account = fixture.account()

            account.validate(configuration: configuration)
            try await waitForAccount { !account.isBusy }

            #expect(accountIsSignedOut(account))
            #expect(account.errorMessage == CodexManagedError.loginRequired.localizedDescription)
            #expect(account.verificationError(for: configuration) == nil)
        }
    }

    @Test("a later cancelled refresh preserves a keychain error over an old verification success")
    func cancelledRefreshKeepsLatestCheckErrorOverVerificationSuccess() async throws {
        try await withAccountFixture(initiallySignedIn: true, release: .current) { fixture in
            let uuid = UUID().uuidString
            installManagedConfiguration(uuid: uuid, model: "gpt-5.5", effort: .high)
            defer { resetManagedConfiguration(uuid: uuid) }
            let configuration = CodexServiceConfiguration(uuid: uuid)
            let gate = RuntimeFactoryGate()
            let calls = RuntimeFactoryCallCounter()
            let account = CodexManagedAccount(
                runtimeFactory: {
                    await calls.record()
                    switch await calls.count {
                    case 2: throw CodexManagedError.keychainUnavailable
                    case 3: await gate.wait()
                    default: return fixture.runtime()
                    }
                    return fixture.runtime()
                },
                coordinator: CodexRequestCoordinator()
            )

            account.validate(configuration: configuration)
            try await waitForAccount { !account.isBusy && account.isValidated(configuration: configuration) }

            account.refresh()
            try await waitForAccount { !account.isBusy }
            let keychainError = try #require(account.errorMessage)
            #expect(!account.isValidated(configuration: configuration))

            account.refresh()
            try await waitForRuntimeFactory(gate)
            account.cancelCurrentOperation()
            await gate.release()
            try await waitForAccount { !account.isBusy }

            #expect(account.errorMessage == keychainError)
            #expect(!account.isValidated(configuration: configuration))
            #expect(!accountIsSignedOut(account))
        }
    }

    @Test("canceling a read-only refresh preserves confirmed signed-out status")
    func cancelledRefreshRetainsSignedOutStatus() async throws {
        try await withAccountFixture { fixture in
            let gate = RuntimeFactoryGate()
            let calls = RuntimeFactoryCallCounter()
            let account = CodexManagedAccount(
                runtimeFactory: {
                    await calls.record()
                    if await calls.count == 2 { await gate.wait() }
                    return fixture.runtime()
                },
                coordinator: CodexRequestCoordinator()
            )

            account.refresh()
            try await waitForAccount { !account.isBusy && accountIsSignedOut(account) }

            account.refresh()
            try await waitForRuntimeFactory(gate)
            account.cancelCurrentOperation()
            await gate.release()
            try await waitForAccount { !account.isBusy }

            #expect(accountIsSignedOut(account))
            #expect(!account.isSignedIn)
        }
    }
}
