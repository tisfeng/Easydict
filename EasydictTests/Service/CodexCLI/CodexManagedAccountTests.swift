//
//  CodexManagedAccountTests.swift
//  EasydictTests
//
//  Created by Alfred on 2026/09/07.
//

import Defaults
@testable import Easydict
import Foundation
import Testing

// MARK: - CodexManagedAccountTests

/// Exercises the shared-account state machine against a private, temporary CLI.
/// No test reads real credentials or invokes the bundled Codex executable.
@MainActor
@Suite("Codex managed account", .serialized)
struct CodexManagedAccountTests {
    @Test("a second login tap does not create another browser authorization")
    func duplicateLoginStartsOneAuthorization() async throws {
        try await withAccountFixture { fixture in
            let account = fixture.account()

            account.login(origin: "first-window")
            account.login(origin: "first-window")
            try await waitForAccount { !account.isBusy && account.isSignedIn }

            #expect(fixture.invocationCount("login") == 1)
            #expect(fixture.invocationCount("exec") == 1)
            #expect(fixture.invocationCount("logout") == 0)
        }
    }

    @Test("login only reads status when the shared account is already authenticated")
    func alreadySignedInSkipsAuthorizationAndValidation() async throws {
        try await withAccountFixture(initiallySignedIn: true) { fixture in
            let account = fixture.account()

            account.login(origin: "second-window")
            try await waitForAccount { !account.isBusy && account.isSignedIn }

            #expect(fixture.invocationCount("login") == 0)
            #expect(fixture.invocationCount("exec") == 0)
            #expect(fixture.invocationCount("status") == 1)
        }
    }

    @Test("reset retains an already signed-in shared account")
    func resetRetainsOfficialSignedInStatus() async throws {
        try await withAccountFixture(initiallySignedIn: true) { fixture in
            let account = fixture.account()

            account.reset()
            try await waitForAccount { !account.isBusy && account.isSignedIn }

            #expect(fixture.invocationCount("status") == 1)
            #expect(fixture.invocationCount("logout") == 0)
            #expect(fixture.invocationCount("exec") == 0)
        }
    }

    @Test("reset refreshes status without logging the account out")
    func resetCancelsLoginAndNeverInvokesLogout() async throws {
        try await withAccountFixture(loginDelay: 2) { fixture in
            let account = fixture.account()

            account.login(origin: "first-window")
            try await waitForAccount { fixture.invocationCount("login") == 1 }
            account.reset()
            try await waitForAccount { !account.isBusy && accountIsSignedOut(account) }

            #expect(fixture.invocationCount("logout") == 0)
            #expect(fixture.invocationCount("status") >= 2)
            #expect(!account.isSignedIn)
        }
    }

    @Test("settings reset retains its admission gate after the canceled login finishes")
    func resetKeepsAdmissionGateAfterPriorLoginFinishes() async throws {
        try await withAccountFixture(loginDelay: 2, secondStatusDelay: 2) { fixture in
            let uuid = UUID().uuidString
            installManagedConfiguration(uuid: uuid, model: "gpt-5.5", effort: .high)
            defer { resetManagedConfiguration(uuid: uuid) }
            let coordinator = CodexRequestCoordinator()
            let account = CodexManagedAccount(
                runtimeFactory: { fixture.runtime() },
                coordinator: coordinator
            )
            let resetToken = UUID()
            let finalToken = UUID()
            let configuration = CodexServiceConfiguration(uuid: uuid)
            defer {
                coordinator.remove(resetToken)
                coordinator.remove(finalToken)
                coordinator.setAccountOperation(nil)
            }

            account.login(origin: "first-window")
            try await waitForAccount { fixture.invocationCount("login") == 1 }
            account.reset()
            // The second status read begins only after the canceled login Task has returned.
            try await waitForAccount { fixture.invocationCount("status") == 2 }

            #expect(
                try coordinator.register(token: resetToken, configuration: configuration, cancel: {})
                    == .blocked(.resetSettings)
            )
            #expect(coordinator.isCurrent(resetToken))

            try await waitForAccount { !account.isBusy && accountIsSignedOut(account) }
            #expect(
                try coordinator.register(token: finalToken, configuration: configuration, cancel: {}) == .allowed
            )
        }
    }

    @Test("a canceled stale status result cannot revive signed-in UI")
    func resetRejectsLateStatusResult() async throws {
        try await withAccountFixture(firstStatusDelayedAndSignedIn: true) { fixture in
            let account = fixture.account()

            account.refresh()
            try await waitForAccount { fixture.invocationCount("status") == 1 }
            account.reset()
            try await waitForAccount { !account.isBusy && accountIsSignedOut(account) }
            try await Task.sleep(for: .milliseconds(700))

            #expect(accountIsSignedOut(account))
            #expect(!account.isSignedIn)
            #expect(fixture.invocationCount("logout") == 0)
        }
    }

    @Test("Keychain failures remain unknown instead of reporting signed out")
    func keychainStatusFailureDoesNotClaimSignedOut() async throws {
        try await withAccountFixture(statusFailure: .keychain) { fixture in
            let account = fixture.account()

            account.refresh()
            try await waitForAccount { !account.isBusy }

            #expect(!accountIsSignedOut(account))
            #expect(!account.isSignedIn)
            #expect(account.errorMessage != nil)
            #expect(fixture.invocationCount("logout") == 0)
        }
    }

    @Test("canceling authentication validation refreshes official status without logging out")
    func cancelingAuthenticationValidationPreservesSignedInStatus() async throws {
        try await withAccountFixture(validationDelay: 2) { fixture in
            let account = fixture.account()

            account.login(origin: "first-window")
            try await waitForAccount { fixture.invocationCount("exec") == 1 }
            account.cancelCurrentOperation()
            try await waitForAccount { !account.isBusy && account.isSignedIn }

            #expect(fixture.invocationCount("logout") == 0)
            #expect(fixture.invocationCount("status") >= 3)
        }
    }

    @Test("logout uses the official command then reads its resulting status")
    func logoutUsesOfficialStatusAfterSuccessfulCommand() async throws {
        try await withAccountFixture(initiallySignedIn: true) { fixture in
            let account = fixture.account()

            account.logout()
            try await waitForAccount { !account.isBusy && accountIsSignedOut(account) }

            #expect(fixture.invocationCount("logout") == 1)
            #expect(fixture.invocationCount("status") == 1)
            #expect(!account.isSignedIn)
        }
    }

    @Test(
        "a failed automatic login validation returns to the signed-out state",
        arguments: ["status", "exec"]
    )
    func automaticLoginValidationFailureReturnsSignedOut(
        failure: String
    ) async throws {
        let loginValidationFailure: LoginValidationFailure = failure == "status"
            ? .statusSignedOut
            : .execSignedOut
        try await withAccountFixture(loginValidationFailure: loginValidationFailure) { fixture in
            let account = fixture.account()

            account.login(origin: "first-window")
            try await waitForAccount { !account.isBusy }

            #expect(!account.isSignedIn)
            #expect(accountIsSignedOut(account))
            #expect(account.errorMessage == CodexManagedError.loginRequired.localizedDescription)
        }
    }

    @Test("translation runtime accepts only exact bundled model slugs")
    func runtimeRejectsUnknownAndPrefixModels() async throws {
        try await withAccountFixture { fixture in
            let runtime = fixture.runtime()

            #expect(throws: CodexManagedError.invalidModel) {
                try runtime.translationArguments(model: "gpt-5.4-mini-preview", effort: nil)
            }
            #expect(throws: CodexManagedError.invalidModel) {
                try runtime.translationArguments(model: "gpt-5.4-mini:unsafe", effort: nil)
            }
            let arguments = try runtime.translationArguments(model: runtime.release.defaultModel, effort: nil)
            #expect(arguments.contains(runtime.release.defaultModel))
        }
    }

    @Test("each runtime release forms arguments with its catalog default model")
    func runtimeDefaultModelsAreReleaseSpecific() async throws {
        for release in [CodexRuntimeRelease.legacy, .modern] {
            try await withAccountFixture(release: release) { fixture in
                let runtime = fixture.runtime()
                let arguments = try runtime.translationArguments(model: runtime.release.defaultModel, effort: nil)

                #expect(runtime.release.defaultModel == release.defaultModel)
                #expect(arguments.contains("-m"))
                #expect(arguments.contains(release.defaultModel))
            }
        }
    }

    @Test("account validation executes the injected runtime default model")
    func validationUsesInjectedRuntimeDefaultModel() async throws {
        for release in [CodexRuntimeRelease.legacy, .modern] {
            try await withAccountFixture(release: release) { fixture in
                let account = fixture.account()

                account.login(origin: release.rawValue)
                try await waitForAccount { !account.isBusy && account.isSignedIn }

                #expect(fixture.invocationCount("exec") == 1)
                #expect(fixture.execModel == release.defaultModel)
            }
        }
    }

    @Test("manual validation records an exact configuration and invalidates it when settings change")
    func validationTracksConfigurationAndInvalidatesSuccess() async throws {
        try await withAccountFixture(initiallySignedIn: true, release: .current) { fixture in
            let uuid = UUID().uuidString
            let otherUUID = UUID().uuidString
            installManagedConfiguration(uuid: uuid, model: "gpt-5.5", effort: .high)
            installManagedConfiguration(uuid: otherUUID, model: "gpt-5.5", effort: .high)
            defer {
                resetManagedConfiguration(uuid: uuid)
                resetManagedConfiguration(uuid: otherUUID)
            }
            let configuration = CodexServiceConfiguration(uuid: uuid)
            let otherConfiguration = CodexServiceConfiguration(uuid: otherUUID)
            let account = fixture.account()

            account.validate(configuration: configuration)
            try await waitForAccount { !account.isBusy && account.isValidated(configuration: configuration) }

            #expect(fixture.execArguments.contains("-m"))
            #expect(fixture.execArguments.contains("gpt-5.5"))
            #expect(fixture.execArguments.contains("model_reasoning_effort=\"high\""))
            #expect(!account.isValidated(configuration: otherConfiguration))

            Defaults[CodexServiceConfiguration.modelKey(uuid: uuid, mode: .managed)] = "gpt-5.6-luna"
            #expect(!account.isValidated(configuration: CodexServiceConfiguration(uuid: uuid)))
            Defaults[CodexServiceConfiguration.effortKey(uuid: uuid, mode: .managed)] = .medium
            #expect(!account.isValidated(configuration: CodexServiceConfiguration(uuid: uuid)))
            Defaults[CodexAccessMode.key(uuid: uuid)] = .localCLI
            #expect(!account.isValidated(configuration: CodexServiceConfiguration(uuid: uuid)))

            account.configurationChanged(origin: uuid)

            #expect(!account.isValidated(configuration: configuration))
        }
    }

    @Test("a configuration change rejects a delayed runtime failure from a pending validation")
    func configurationChangeRejectsDelayedRuntimeFailure() async throws {
        let uuid = UUID().uuidString
        installManagedConfiguration(uuid: uuid, model: "gpt-5.5", effort: .high)
        defer { resetManagedConfiguration(uuid: uuid) }
        let configuration = CodexServiceConfiguration(uuid: uuid)
        let gate = RuntimeFactoryGate()
        let account = CodexManagedAccount(
            runtimeFactory: {
                await gate.wait()
                throw DelayedRuntimeFailure()
            },
            coordinator: CodexRequestCoordinator()
        )

        account.validate(configuration: configuration)
        try await waitForRuntimeFactory(gate)
        Defaults[CodexServiceConfiguration.modelKey(uuid: uuid, mode: .managed)] = "gpt-5.6-luna"
        account.configurationChanged(origin: uuid)
        await gate.release()
        try await waitForAccount { !account.isBusy }

        #expect(account.errorMessage == nil)
        #expect(!account.isValidated(configuration: configuration))
        #expect(!account.isValidated(configuration: CodexServiceConfiguration(uuid: uuid)))
    }

    @Test("a corrected configuration clears an earlier manual validation failure")
    func configurationChangeClearsCompletedValidationFailure() async throws {
        try await withAccountFixture(initiallySignedIn: true, release: .current) { fixture in
            let uuid = UUID().uuidString
            installManagedConfiguration(uuid: uuid, model: "gpt-5.4-mini", effort: .high)
            defer { resetManagedConfiguration(uuid: uuid) }
            let account = fixture.account()

            account.validate(configuration: CodexServiceConfiguration(uuid: uuid))
            try await waitForAccount { !account.isBusy }
            #expect(account.errorMessage == nil)
            #expect(account
                .verificationError(for: CodexServiceConfiguration(uuid: uuid)) as? CodexManagedError == .invalidModel)

            installManagedConfiguration(uuid: uuid, model: "gpt-5.5", effort: .high)
            account.configurationChanged(origin: uuid)

            #expect(account.errorMessage == nil)
            #expect(account.errorMessage(for: CodexServiceConfiguration(uuid: uuid)) == nil)
            #expect(account.verificationError(for: CodexServiceConfiguration(uuid: uuid)) == nil)
        }
    }

    @Test("cancelling a manual validation keeps an active managed registration")
    func cancellingValidationDoesNotCancelManagedRegistration() async throws {
        try await withAccountFixture(
            initiallySignedIn: true,
            validationDelay: 2,
            release: .current
        ) { fixture in
            let uuid = UUID().uuidString
            installManagedConfiguration(uuid: uuid, model: "gpt-5.5", effort: .high)
            defer { resetManagedConfiguration(uuid: uuid) }
            let configuration = CodexServiceConfiguration(uuid: uuid)
            let coordinator = CodexRequestCoordinator()
            let registration = UUID()
            let cancellation = AccountRegistrationCancellation()
            let translation = CodexManagedTranslation()
            let account = CodexManagedAccount(
                runtimeFactory: { fixture.runtime() },
                coordinator: coordinator
            )
            try coordinator.register(
                token: registration,
                configuration: configuration,
                cancel: {
                    cancellation.record()
                    translation.cancel()
                }
            )
            defer {
                coordinator.remove(registration)
                coordinator.setAccountOperation(nil)
            }

            account.refresh()
            try await waitForAccount { !account.isBusy && account.isSignedIn }
            account.validate(configuration: configuration)
            try await waitForAccount { fixture.invocationCount("exec") == 1 }
            let translationTask = Task {
                try await translation.run(
                    prompt: "Translate Hello into Simplified Chinese.",
                    model: configuration.model,
                    effort: configuration.effort.cliValue,
                    runtime: fixture.runtime()
                )
            }
            try await waitForAccount { fixture.invocationCount("exec") == 2 }
            let statusBeforeCancellation = fixture.invocationCount("status")
            account.cancelCurrentOperation()
            try await waitForAccount { !account.isBusy && account.isSignedIn }
            let translationResult = try await translationTask.value

            #expect(cancellation.isEmpty)
            #expect(coordinator.isCurrent(registration))
            #expect(fixture.invocationCount("status") == statusBeforeCancellation)
            #expect(translationResult.text == "你好")
        }
    }

    @Test("a registration started during manual validation survives its cancellation")
    func registrationStartedDuringValidationSurvivesCancellation() async throws {
        try await withAccountFixture(
            initiallySignedIn: true,
            validationDelay: 2,
            release: .current
        ) { fixture in
            let uuid = UUID().uuidString
            installManagedConfiguration(uuid: uuid, model: "gpt-5.5", effort: .high)
            defer { resetManagedConfiguration(uuid: uuid) }
            let configuration = CodexServiceConfiguration(uuid: uuid)
            let coordinator = CodexRequestCoordinator()
            let account = CodexManagedAccount(
                runtimeFactory: { fixture.runtime() },
                coordinator: coordinator
            )
            let registration = UUID()
            let cancellation = AccountRegistrationCancellation()
            defer {
                coordinator.remove(registration)
                coordinator.setAccountOperation(nil)
            }

            account.refresh()
            try await waitForAccount { !account.isBusy && account.isSignedIn }
            account.validate(configuration: configuration)
            try await waitForAccount { fixture.invocationCount("exec") == 1 }
            let admission = try coordinator.register(
                token: registration,
                configuration: configuration,
                cancel: cancellation.record
            )
            #expect(admission == .allowed)

            account.cancelCurrentOperation()
            try await waitForAccount { !account.isBusy && account.isSignedIn }

            #expect(cancellation.isEmpty)
            #expect(coordinator.isCurrent(registration))
        }
    }

    @Test("cancelling a read-only status check keeps a managed registration current")
    func cancellingRefreshDoesNotCancelManagedRegistration() async throws {
        try await withAccountFixture(firstStatusDelayedAndSignedIn: true, release: .current) { fixture in
            let uuid = UUID().uuidString
            installManagedConfiguration(uuid: uuid, model: "gpt-5.5", effort: .high)
            defer { resetManagedConfiguration(uuid: uuid) }
            let configuration = CodexServiceConfiguration(uuid: uuid)
            let coordinator = CodexRequestCoordinator()
            let account = CodexManagedAccount(
                runtimeFactory: { fixture.runtime() },
                coordinator: coordinator
            )
            let registration = UUID()
            let cancellation = AccountRegistrationCancellation()
            try coordinator.register(
                token: registration,
                configuration: configuration,
                cancel: cancellation.record
            )
            defer {
                coordinator.remove(registration)
                coordinator.setAccountOperation(nil)
            }

            account.refresh()
            try await waitForAccount { fixture.invocationCount("status") == 1 }
            account.cancelCurrentOperation()
            try await waitForAccount { !account.isBusy }
            try await Task.sleep(for: .milliseconds(700))

            #expect(cancellation.isEmpty)
            #expect(coordinator.isCurrent(registration))
            #expect(!account.isSignedIn)
        }
    }

    @Test("cancelling authentication keeps managed admission blocked until its status refresh ends")
    func cancellingAuthenticationKeepsAdmissionBlockedUntilRefreshEnds() async throws {
        try await withAccountFixture(loginDelay: 2) { fixture in
            let uuid = UUID().uuidString
            installManagedConfiguration(uuid: uuid, model: "gpt-5.5", effort: .high)
            defer { resetManagedConfiguration(uuid: uuid) }
            let configuration = CodexServiceConfiguration(uuid: uuid)
            let coordinator = CodexRequestCoordinator()
            let account = CodexManagedAccount(
                runtimeFactory: { fixture.runtime() },
                coordinator: coordinator
            )
            let loginToken = UUID()
            let refreshToken = UUID()
            let finalToken = UUID()
            defer {
                coordinator.remove(loginToken)
                coordinator.remove(refreshToken)
                coordinator.remove(finalToken)
                coordinator.setAccountOperation(nil)
            }

            account.login(origin: "first-window")
            try await waitForAccount { fixture.invocationCount("login") == 1 }
            #expect(
                try coordinator.register(token: loginToken, configuration: configuration, cancel: {})
                    == .blocked(.login)
            )

            account.cancelCurrentOperation()
            #expect(
                try coordinator.register(token: refreshToken, configuration: configuration, cancel: {})
                    == .blocked(.cancelRefresh)
            )
            try await waitForAccount { !account.isBusy && accountIsSignedOut(account) }

            #expect(
                try coordinator.register(token: finalToken, configuration: configuration, cancel: {}) == .allowed
            )
        }
    }

    @Test("invalid manual selections fail before resolving the managed runtime")
    func invalidValidationSelectionsDoNotResolveRuntime() async throws {
        try await withAccountFixture(release: .modern) { fixture in
            let factoryCalls = RuntimeFactoryCallCounter()
            let account = CodexManagedAccount(
                runtimeFactory: {
                    await factoryCalls.record()
                    return fixture.runtime()
                },
                coordinator: CodexRequestCoordinator()
            )
            let selections: [(model: String, effort: CodexReasoningEffort)] = [
                ("gpt-5.4-mini", .high),
                ("gpt-5.5", .ultra),
            ]

            for selection in selections {
                let uuid = UUID().uuidString
                installManagedConfiguration(uuid: uuid, model: selection.model, effort: selection.effort)
                defer { resetManagedConfiguration(uuid: uuid) }
                let configuration = CodexServiceConfiguration(uuid: uuid)

                account.validate(configuration: configuration)
                try await waitForAccount { !account.isBusy }

                let callCount = await factoryCalls.count
                #expect(callCount == 0)
                #expect(!account.isValidated(configuration: configuration))
            }
        }
    }

    @Test("retired models and unsupported effort fail before starting a process")
    func invalidRuntimeSelectionsDoNotStartProcesses() async throws {
        try await withAccountFixture(initiallySignedIn: true) { fixture in
            let translation = CodexManagedTranslation()

            await #expect(throws: CodexManagedError.invalidModel) {
                try await translation.run(
                    prompt: "Hello",
                    model: "gpt-5.4-mini",
                    effort: nil,
                    runtime: fixture.runtime()
                )
            }
            await #expect(throws: CodexManagedError.invalidModel) {
                try await translation.run(
                    prompt: "Hello",
                    model: CodexRuntimeRelease.legacy.defaultModel,
                    effort: "ultra",
                    runtime: fixture.runtime()
                )
            }

            #expect(fixture.invocationCount("status") == 0)
            #expect(fixture.invocationCount("exec") == 0)
        }
        try await withAccountFixture(initiallySignedIn: true, release: .modern) { fixture in
            let translation = CodexManagedTranslation()

            await #expect(throws: CodexManagedError.invalidModel) {
                try await translation.run(
                    prompt: "Hello",
                    model: CodexRuntimeRelease.modern.defaultModel,
                    effort: "ultra",
                    runtime: fixture.runtime()
                )
            }

            #expect(fixture.invocationCount("status") == 0)
            #expect(fixture.invocationCount("exec") == 0)
        }
    }
}
