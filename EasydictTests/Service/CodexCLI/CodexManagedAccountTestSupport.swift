//
//  CodexManagedAccountTestSupport.swift
//  EasydictTests
//
//  Created by Alfred on 2026/09/13.
//

import Defaults
@testable import Easydict
import Foundation

// MARK: - AccountStatusFailure

enum AccountStatusFailure {
    case none
    case keychain
}

// MARK: - LoginValidationFailure

enum LoginValidationFailure: CaseIterable {
    case statusSignedOut
    case execSignedOut
}

// MARK: - AccountFixture

/// Creates an empty private runtime root and a shell implementation of its CLI.
final class AccountFixture {
    // MARK: Lifecycle

    init(
        initiallySignedIn: Bool,
        loginDelay: Int,
        validationDelay: Int,
        firstStatusDelayedAndSignedIn: Bool,
        secondStatusDelay: Int,
        statusFailure: AccountStatusFailure,
        loginValidationFailure: LoginValidationFailure?,
        release: CodexRuntimeRelease
    ) throws {
        self.release = release
        self.directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Easydict-CodexAccountTests-\(UUID().uuidString)", isDirectory: true)
        let package = directory.appendingPathComponent("runtime", isDirectory: true)
        let bin = package.appendingPathComponent("bin", isDirectory: true)
        self.executable = bin.appendingPathComponent("codex")
        self.stateFile = directory.appendingPathComponent("signed-in")
        self.logFile = directory.appendingPathComponent("invocations")
        self.execArgumentsFile = directory.appendingPathComponent("exec-arguments")
        try FileManager.default.createDirectory(at: bin, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(
            at: directory.appendingPathComponent("home"),
            withIntermediateDirectories: true
        )
        try FileManager.default.createDirectory(
            at: directory.appendingPathComponent("codex-home"),
            withIntermediateDirectories: true
        )
        try FileManager.default.createDirectory(
            at: directory.appendingPathComponent("work"),
            withIntermediateDirectories: true
        )
        let catalog = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("scripts/codex-runtime/\(release.rawValue)/translation-models.json")
        try FileManager.default.copyItem(at: catalog, to: directory.appendingPathComponent("translation-models.json"))
        if initiallySignedIn { FileManager.default.createFile(atPath: stateFile.path, contents: Data()) }
        let scriptOptions = ScriptOptions(
            loginDelay: loginDelay,
            validationDelay: validationDelay,
            firstStatusDelayedAndSignedIn: firstStatusDelayedAndSignedIn,
            secondStatusDelay: secondStatusDelay,
            statusFailure: statusFailure,
            loginValidationFailure: loginValidationFailure
        )
        try script(options: scriptOptions).write(to: executable, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: executable.path)
    }

    deinit {
        try? FileManager.default.removeItem(at: directory)
    }

    // MARK: Internal

    let directory: URL

    var execArguments: [String] {
        (try? String(contentsOf: execArgumentsFile, encoding: .utf8))?
            .split(separator: "\n").map(String.init) ?? []
    }

    var execModel: String? {
        guard let marker = execArguments.firstIndex(of: "-m"), execArguments.indices.contains(marker + 1)
        else { return nil }
        return execArguments[marker + 1]
    }

    @MainActor
    func account() -> CodexManagedAccount {
        let runtime = runtime()
        return CodexManagedAccount(runtimeFactory: { runtime }, coordinator: CodexRequestCoordinator())
    }

    func runtime() -> CodexManagedRuntime {
        CodexManagedRuntime(
            executable: executable,
            home: directory.appendingPathComponent("home"),
            codexHome: directory.appendingPathComponent("codex-home"),
            workingDirectory: directory.appendingPathComponent("work"),
            release: release,
            catalogURL: directory.appendingPathComponent("translation-models.json")
        )
    }

    func invocationCount(_ name: String) -> Int {
        guard let log = try? String(contentsOf: logFile, encoding: .utf8) else { return 0 }
        return log.split(separator: "\n").filter { $0 == Substring(name) }.count
    }

    func setSignedIn(_ signedIn: Bool) throws {
        if signedIn {
            FileManager.default.createFile(atPath: stateFile.path, contents: Data())
        } else if FileManager.default.fileExists(atPath: stateFile.path) {
            try FileManager.default.removeItem(at: stateFile)
        }
    }

    // MARK: Private

    private struct ScriptOptions {
        let loginDelay: Int
        let validationDelay: Int
        let firstStatusDelayedAndSignedIn: Bool
        let secondStatusDelay: Int
        let statusFailure: AccountStatusFailure
        let loginValidationFailure: LoginValidationFailure?
    }

    private let executable: URL
    private let release: CodexRuntimeRelease
    private let stateFile: URL
    private let logFile: URL
    private let execArgumentsFile: URL

    private func script(options: ScriptOptions)
        -> String {
        let log = shellQuoted(logFile.path)
        let state = shellQuoted(stateFile.path)
        let statusCount = shellQuoted(directory.appendingPathComponent("status-count").path)
        let execArguments = shellQuoted(execArgumentsFile.path)
        let failure = options.statusFailure == .keychain ? "yes" : "no"
        let initialStatusDelay = options.firstStatusDelayedAndSignedIn ? "yes" : "no"
        let validationStatusSignedOut = options.loginValidationFailure == .statusSignedOut ? "yes" : "no"
        let validationExecSignedOut = options.loginValidationFailure == .execSignedOut ? "yes" : "no"
        return """
        #!/bin/sh
        log=\(log)
        state=\(state)
        status_count=\(statusCount)
        if [ "$1" = "login" ] && [ "$2" = "status" ]; then
          printf 'status\\n' >> "$log"
          count=0
          if [ -f "$status_count" ]; then count=$(cat "$status_count"); fi
          count=$((count + 1))
          printf '%s' "$count" > "$status_count"
          if [ \(failure) = yes ]; then
            printf 'Keychain access denied\\n'
            exit 1
          fi
          if [ \(initialStatusDelay) = yes ] && [ "$count" = 1 ]; then
            trap '' TERM
            sleep 0.4
            printf 'Logged in using ChatGPT\\n'
            exit 0
          fi
          if [ "$count" = 2 ]; then sleep \(options.secondStatusDelay); fi
          if [ \(validationStatusSignedOut) = yes ] && [ "$count" = 3 ]; then
            printf 'Not logged in\\n'
            exit 1
          fi
          if [ -f "$state" ]; then
            printf 'Logged in using ChatGPT\\n'
            exit 0
          fi
          printf 'Not logged in\\n'
          exit 1
        fi
        if [ "$1" = "login" ]; then
          printf 'login\\n' >> "$log"
          sleep \(options.loginDelay)
          : > "$state"
          exit 0
        fi
        if [ "$1" = "exec" ]; then
          printf 'exec\\n' >> "$log"
          shift
          printf '%s\\n' "$@" > \(execArguments)
          sleep \(options.validationDelay)
          if [ \(validationExecSignedOut) = yes ]; then
            printf '%s\\n' '{"type":"turn.failed","error":"Not logged in. Please run codex login."}'
            exit 1
          fi
          printf '%s\\n' '{"type":"thread.started"}'
          printf '%s\\n' '{"type":"turn.started"}'
          printf '%s\\n' '{"type":"item.completed","item":{"type":"agent_message","text":"你好"}}'
          printf '%s\\n' '{"type":"turn.completed"}'
          exit 0
        fi
        if [ "$1" = "logout" ]; then
          printf 'logout\\n' >> "$log"
          rm -f "$state"
          exit 0
        fi
        printf 'unexpected\\n' >&2
        exit 2
        """
    }
}

@MainActor
func withAccountFixture<T>(
    initiallySignedIn: Bool = false,
    loginDelay: Int = 0,
    validationDelay: Int = 0,
    firstStatusDelayedAndSignedIn: Bool = false,
    secondStatusDelay: Int = 0,
    statusFailure: AccountStatusFailure = .none,
    loginValidationFailure: LoginValidationFailure? = nil,
    release: CodexRuntimeRelease = .legacy,
    _ body: (AccountFixture) async throws -> T
) async throws
    -> T {
    let fixture = try AccountFixture(
        initiallySignedIn: initiallySignedIn,
        loginDelay: loginDelay,
        validationDelay: validationDelay,
        firstStatusDelayedAndSignedIn: firstStatusDelayedAndSignedIn,
        secondStatusDelay: secondStatusDelay,
        statusFailure: statusFailure,
        loginValidationFailure: loginValidationFailure,
        release: release
    )
    return try await body(fixture)
}

@MainActor
func waitForAccount(
    timeout: TimeInterval = 4,
    _ condition: @escaping @MainActor () -> Bool
) async throws {
    let deadline = Date().addingTimeInterval(timeout)
    while !condition() {
        guard Date() < deadline else { throw AccountTestTimeout() }
        try await Task.sleep(for: .milliseconds(20))
    }
}

func waitForRuntimeFactory(
    _ gate: RuntimeFactoryGate,
    timeout: TimeInterval = 4
) async throws {
    let deadline = Date().addingTimeInterval(timeout)
    while !(await gate.isWaiting) {
        guard Date() < deadline else { throw AccountTestTimeout() }
        try await Task.sleep(for: .milliseconds(20))
    }
}

@MainActor
func accountIsSignedOut(_ account: CodexManagedAccount) -> Bool {
    if case .signedOut = account.state { return true }
    return false
}

func installManagedConfiguration(
    uuid: String, model: String, effort: CodexReasoningEffort
) {
    Defaults[CodexAccessMode.key(uuid: uuid)] = .managed
    Defaults[CodexServiceConfiguration.modelKey(uuid: uuid, mode: .managed)] = model
    Defaults[CodexServiceConfiguration.effortKey(uuid: uuid, mode: .managed)] = effort
}

func resetManagedConfiguration(uuid: String) {
    Defaults.reset(
        CodexAccessMode.key(uuid: uuid),
        CodexServiceConfiguration.modelKey(uuid: uuid, mode: .managed),
        CodexServiceConfiguration.effortKey(uuid: uuid, mode: .managed)
    )
}

// MARK: - AccountTestTimeout

private struct AccountTestTimeout: Error {}

// MARK: - AccountRegistrationCancellation

final class AccountRegistrationCancellation: @unchecked Sendable {
    // MARK: Internal

    var count: Int { lock.withLock { value } }
    var isEmpty: Bool { count == 0 }

    func record() {
        lock.withLock { value += 1 }
    }

    // MARK: Private

    private let lock = NSLock()
    private var value = 0
}

// MARK: - RuntimeFactoryCallCounter

/// Counts managed-runtime resolution attempts made after static selection validation.
actor RuntimeFactoryCallCounter {
    // MARK: Internal

    var count: Int { value }

    func record() {
        value += 1
    }

    // MARK: Private

    private var value = 0
}

// MARK: - DelayedRuntimeFailure

struct DelayedRuntimeFailure: Error {}

// MARK: - RuntimeFactoryGate

/// Suspends resolution until the test releases the continuation after invalidation.
actor RuntimeFactoryGate {
    // MARK: Internal

    var isWaiting: Bool { continuation != nil }

    func wait() async {
        await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
    }

    func release() {
        continuation?.resume()
        continuation = nil
    }

    // MARK: Private

    private var continuation: CheckedContinuation<(), Never>?
}

private func shellQuoted(_ value: String) -> String {
    "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
}
