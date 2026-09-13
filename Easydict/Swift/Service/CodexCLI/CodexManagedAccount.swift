//
//  CodexManagedAccount.swift
//  Easydict
//
//  Created by Alfred on 2026/09/07.
//

import AppKit
import Combine
import Foundation

// MARK: - CodexManagedAccount

/// Serializes the single managed ChatGPT account without inspecting OAuth tokens.
/// Official status is authoritative; login validation runs once in an independent
/// request. Operation generations prevent canceled login/reset results reviving UI.
@MainActor
final class CodexManagedAccount: ObservableObject {
    // MARK: Lifecycle

    init(
        runtimeFactory: @escaping () async throws
            -> CodexManagedRuntime = { try await CodexManagedRuntime.installed() },
        coordinator: CodexRequestCoordinator = .shared
    ) {
        self.runtimeFactory = runtimeFactory
        self.coordinator = coordinator
    }

    // MARK: Internal

    enum State {
        case unknown, checking, signedOut, authorizing, verifying, signedIn, ready
    }

    static let shared = CodexManagedAccount()

    @Published private(set) var state: State = .unknown
    @Published private(set) var accountError: Error?
    @Published private(set) var authorizationURL: URL?

    var isBusy: Bool { operation != nil }
    var isSignedIn: Bool { authenticated }
    var errorMessage: String? { accountError?.localizedDescription }

    func errorMessage(for configuration: CodexServiceConfiguration) -> String? {
        guard !isBusy else { return nil }
        return errorMessage ?? verificationError(for: configuration)?.localizedDescription
    }

    func verificationError(for configuration: CodexServiceConfiguration) -> Error? {
        guard let result = currentVerification(for: configuration),
              case let .failure(error) = result.outcome else { return nil }
        return error
    }

    func refresh() {
        guard operation == nil else { return }
        let generation = begin(state: .checking)
        operation = Task {
            await readStatus(generation: generation)
            finish(generation: generation)
        }
    }

    func login(origin: String) {
        guard operation == nil else { return }
        let generation = begin(state: .checking, kind: .authentication(.login))
        originUUID = origin
        operation = Task {
            do {
                let runtime = try await runtimeFactory()
                let status = try await runtime.command(["login", "status"], process: nextProcess())
                try check(generation)
                if try CodexManagedTranslation.isSignedIn(status) {
                    authenticationState = true
                    state = .signedIn
                } else {
                    authenticationState = false
                    state = .authorizing
                    let parser = CodexAuthorizationURLParser()
                    let result = try await runtime.command(["login"], process: nextProcess(), timeout: 300) { chunk in
                        if let url = parser.append(chunk) {
                            Task { @MainActor [weak self] in
                                guard let self, self.generation == generation, state == .authorizing else { return }
                                authorizationURL = url
                            }
                        }
                    }
                    try check(generation)
                    guard result.exitCode == 0 else { throw CodexManagedError.authenticationFailed }
                    let status = try await runtime.command(["login", "status"], process: nextProcess())
                    try check(generation)
                    guard try CodexManagedTranslation.isSignedIn(status) else {
                        throw CodexManagedError.authenticationFailed
                    }
                    authenticationState = true
                    authorizationURL = nil
                    try await validateConnection(generation: generation, runtime: runtime)
                }
            } catch is CancellationError {
                // The cancel/reset operation owns the subsequent status refresh.
            } catch {
                if self.generation == generation {
                    setFailureState(error)
                    accountError = error
                }
            }
            finish(generation: generation)
        }
    }

    /// Connection verification belongs to the initiating service's saved settings.
    func validate(configuration: CodexServiceConfiguration) {
        guard operation == nil else { return }
        let generation = begin(state: .verifying, kind: .verification)
        validationConfiguration = configuration
        operation = Task {
            var release = CodexRuntimeRelease.current
            do {
                try CodexManagedRuntime.validateSelection(
                    model: configuration.model, effort: configuration.effort.cliValue
                )
                let runtime = try await runtimeFactory()
                release = runtime.release
                try check(generation)
                try await validateConnection(generation: generation, runtime: runtime, configuration: configuration)
                verificationResult = VerificationResult(
                    configuration: configuration,
                    release: release,
                    outcome: .success(())
                )
            } catch is CancellationError {
                if self.generation == generation { state = authenticated ? .signedIn : .unknown }
            } catch {
                if self.generation == generation, !Task.isCancelled,
                   configuration == CodexServiceConfiguration(uuid: configuration.uuid) {
                    setFailureState(error)
                    if (error as? CodexManagedError) == .loginRequired {
                        accountError = error
                    } else {
                        verificationResult = VerificationResult(
                            configuration: configuration,
                            release: release,
                            outcome: .failure(error)
                        )
                    }
                }
            }
            finish(generation: generation)
        }
    }

    func isValidated(configuration: CodexServiceConfiguration) -> Bool {
        guard state == .ready, let result = currentVerification(for: configuration),
              case .success = result.outcome else { return false }
        return true
    }

    /// Completed success and failure both expire; changing back never restores old evidence.
    func configurationChanged(origin: String) {
        if verificationResult?.configuration.uuid == origin {
            verificationResult = nil
            if state == .ready { state = authenticated ? .signedIn : .unknown }
        }
        if validationConfiguration?.uuid == origin { cancelCurrentOperation() }
    }

    /// Component loss invalidates connection evidence, not official credentials.
    func componentUnavailable() {
        verificationResult = nil
        if !isBusy { restorePresentation() }
    }

    func logout() {
        guard operation == nil else { return }
        let generation = begin(state: .checking, kind: .authentication(.logout))
        operation = Task {
            do {
                let runtime = try await runtimeFactory()
                let result = try await runtime.command(["logout"], process: nextProcess())
                try check(generation)
                guard result.exitCode == 0 else { throw CodexManagedError.authenticationFailed }
                await readStatus(generation: generation)
            } catch is CancellationError {
            } catch {
                if self.generation == generation {
                    setFailureState(error)
                    accountError = error
                }
            }
            finish(generation: generation)
        }
    }

    func reopenBrowser() {
        if let authorizationURL { NSWorkspace.shared.open(authorizationURL) }
    }

    func cancelLogin(origin: String) {
        if originUUID == origin, operation != nil { cancelCurrentOperation() }
    }

    /// Read-only work cancels itself. Only identity changes require an exclusive refresh.
    func cancelCurrentOperation() {
        guard operation != nil else { return }
        let reason: CodexAccountOperation?
        if case let .authentication(current) = operationKind {
            reason = current == .resetSettings ? .resetSettings : .cancelRefresh
        } else {
            reason = nil
        }
        cancelOperation(refreshReason: reason)
    }

    /// Settings reset invalidates operations, not official Keychain credentials.
    func reset() {
        cancelOperation(refreshReason: .resetSettings)
    }

    // MARK: Private

    /// Account operations own cancellation scope, independently of their display phase.
    private enum OperationKind {
        case refresh, verification
        case authentication(CodexAccountOperation)
    }

    /// A completed manual check belongs to one configuration and runtime version.
    private struct VerificationResult {
        let configuration: CodexServiceConfiguration
        let release: CodexRuntimeRelease
        let outcome: Result<(), Error>
    }

    @Published private var verificationResult: VerificationResult?

    private let runtimeFactory: () async throws -> CodexManagedRuntime
    private let coordinator: CodexRequestCoordinator
    // nil means no official authentication status has been established yet.
    private var authenticationState: Bool?
    private var generation: UInt = 0
    private var operationKind: OperationKind?
    private var originUUID: String?
    private var operation: Task<(), Never>?
    private var process: CodexManagedProcess?
    private var validation: CodexManagedTranslation?
    private var validationConfiguration: CodexServiceConfiguration?

    private var authenticated: Bool { authenticationState == true }

    private func currentVerification(for configuration: CodexServiceConfiguration) -> VerificationResult? {
        guard let result = verificationResult, result.configuration == configuration,
              configuration == CodexServiceConfiguration(uuid: configuration.uuid),
              result.release == .current else { return nil }
        return result
    }

    private func cancelOperation(refreshReason: CodexAccountOperation?) {
        let previous = operation
        process?.cancel()
        validation?.cancel()
        previous?.cancel()
        let kind = refreshReason.map(OperationKind.authentication) ?? .refresh
        let generation = begin(state: .checking, kind: kind)
        operation = Task {
            await previous?.value
            guard self.generation == generation else { return }
            if refreshReason != nil {
                await readStatus(generation: generation)
            } else {
                restorePresentation()
            }
            finish(generation: generation)
        }
    }

    private func begin(state: State, kind: OperationKind = .refresh) -> UInt {
        generation &+= 1
        self.state = state
        switch kind {
        case .refresh: break
        case .authentication, .verification:
            verificationResult = nil
            accountError = nil
        }
        validationConfiguration = nil
        authorizationURL = nil
        originUUID = nil
        operationKind = kind
        if case let .authentication(reason) = kind { coordinator.setAccountOperation(reason) }
        return generation
    }

    private func finish(generation: UInt) {
        guard self.generation == generation else { return }
        operation = nil
        process = nil
        validation = nil
        validationConfiguration = nil
        originUUID = nil
        authorizationURL = nil
        if case .authentication = operationKind { coordinator.setAccountOperation(nil) }
        operationKind = nil
        objectWillChange.send()
    }

    private func check(_ generation: UInt) throws {
        try Task.checkCancellation()
        if self.generation != generation { throw CancellationError() }
    }

    /// Only confirmed loss of authentication changes the available account actions.
    private func setFailureState(_ error: Error) {
        if (error as? CodexManagedError) == .loginRequired {
            authenticationState = false
            verificationResult = nil
            state = .signedOut
        } else {
            state = authenticated ? .signedIn : .unknown
        }
    }

    private func nextProcess() -> CodexManagedProcess {
        let next = CodexManagedProcess()
        process = next
        return next
    }

    private func readStatus(generation: UInt) async {
        do {
            let runtime = try await runtimeFactory()
            try check(generation)
            let output = try await runtime.command(["login", "status"], process: nextProcess())
            try check(generation)
            authenticationState = try CodexManagedTranslation.isSignedIn(output)
            if !authenticated { verificationResult = nil }
            accountError = nil
            restorePresentation()
        } catch is CancellationError {
        } catch {
            if self.generation == generation {
                setFailureState(error)
                accountError = error
            }
        }
    }

    /// Derive idle presentation from current evidence; never revive a saved snapshot.
    private func restorePresentation() {
        guard let authenticationState else {
            state = .unknown
            return
        }
        guard authenticationState else {
            state = .signedOut
            return
        }
        if accountError == nil, let result = verificationResult,
           currentVerification(for: result.configuration) != nil,
           case .success = result.outcome {
            state = .ready
        } else {
            state = .signedIn
        }
    }

    private func validateConnection(
        generation: UInt, runtime: CodexManagedRuntime, configuration: CodexServiceConfiguration? = nil
    ) async throws {
        state = .verifying
        let request = CodexManagedTranslation()
        validation = request
        try check(generation)
        if let configuration {
            guard configuration.mode == .managed,
                  configuration == CodexServiceConfiguration(uuid: configuration.uuid)
            else { throw CancellationError() }
        }
        let result = try await request.run(
            prompt: "Translate the English greeting Hello into Simplified Chinese. Return only the translation.",
            model: configuration?.model ?? runtime.release.defaultModel,
            effort: configuration?.effort.cliValue, runtime: runtime
        )
        try check(generation)
        if let configuration,
           configuration != CodexServiceConfiguration(uuid: configuration.uuid) {
            throw CancellationError()
        }
        let greeting = result.text.trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
        guard ["你好", "您好"].contains(greeting) else { throw CodexManagedError.invalidResponse }
        authenticationState = true
        state = .ready
    }
}

// MARK: - CodexAuthorizationURLParser

/// Buffers only enough login stderr to extract the official browser address.
/// The URL stays in memory and is never sent to the app's normal CLI logger.
private final class CodexAuthorizationURLParser: @unchecked Sendable {
    // MARK: Internal

    func append(_ data: Data) -> URL? {
        buffer.append(data)
        if buffer.count > 16384 { buffer.removeFirst(buffer.count - 16384) }
        let text = String(decoding: buffer, as: UTF8.self)
        for word in text.split(whereSeparator: \.isWhitespace) {
            guard let url = URL(string: String(word)), url.scheme == "https",
                  url.host == "auth.openai.com", url.path == "/oauth/authorize",
                  word.last != "&", text.last?.isWhitespace == true
            else { continue }
            return url
        }
        return nil
    }

    // MARK: Private

    private var buffer = Data()
}
