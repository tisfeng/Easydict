//
//  CodexCLIRunner.swift
//  Easydict
//
//  Created by long2ice on 2026/05/07.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation

// MARK: - CodexCLIRunner

/// Wraps a `codex exec --json` subprocess and yields its assistant text as
/// an `AsyncThrowingStream<String, Error>`.
///
/// Uses `--json` so the CLI emits one JSON event per line. Codex 0.128.x does
/// not stream text deltas — it emits the full message text in a single
/// `item.completed` event whose `item.type == "agent_message"`. The runner
/// yields that text once per turn; all other events (`thread.started`,
/// `turn.started`, `turn.completed`, reasoning items, …) are retained on the
/// control buffer for post-exit error / usage parsing.
///
/// Each instance represents exactly one subprocess invocation.
/// Create a new instance per translation request.
final class CodexCLIRunner: @unchecked Sendable {
    // MARK: Lifecycle

    init() {}

    // MARK: Internal

    /// Token usage populated when the subprocess terminates normally.
    /// `nil` if the process has not yet finished or no `token_count` event was emitted.
    private(set) var tokenUsage: CodexTokenUsage?

    /// Runs `which <name>` directly (without a login shell).
    ///
    /// Used by unit tests, which run in an environment where PATH is already set correctly.
    static func runWhich(_ name: String) -> String? {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = [name]
        process.standardOutput = pipe
        process.standardError = Pipe()
        do {
            try process.run()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else { return nil }
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let path = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return path?.isEmpty == false ? path : nil
        } catch {
            return nil
        }
    }

    /// Resolves which shell executable should run login-shell detection.
    ///
    /// Accepts the user's configured shell when it is an absolute executable path,
    /// and otherwise falls back to `/bin/zsh`.
    static func resolveLoginShellPath(environmentShell: String?) -> String {
        guard let environmentShell,
              environmentShell.hasPrefix("/"),
              FileManager.default.isExecutableFile(atPath: environmentShell)
        else {
            return "/bin/zsh"
        }
        return environmentShell
    }

    /// Builds the argument list for a `codex exec --json` invocation.
    ///
    /// Codex `exec` is non-interactive by default, so no approval flag is required.
    /// `--sandbox read-only` blocks any incidental file writes if the model decides to
    /// call shell tools, `--skip-git-repo-check` lets the CLI run from neutral
    /// working directories, and `--ephemeral` skips writing session files to disk.
    ///
    /// - Parameters:
    ///   - prompt: The full prompt sent to the CLI.
    ///   - workingDirectory: A neutral cwd (typically `/tmp`) so codex does not scan
    ///     user folders for `AGENTS.md`.
    ///   - model: Optional model override. Empty / nil leaves the CLI's default in place.
    ///     Whitespace is trimmed before forming the `-m <model>` flag.
    ///   - reasoningEffort: Optional reasoning-effort override. Empty / nil leaves the
    ///     user's `~/.codex/config.toml` untouched; non-empty forms
    ///     `-c model_reasoning_effort=<value>`.
    static func buildArguments(
        prompt: String,
        workingDirectory: String,
        model: String? = nil,
        reasoningEffort: String? = nil
    )
        -> [String] {
        var arguments = [
            "exec",
            "--json",
            "--skip-git-repo-check",
            "--ephemeral",
            "--sandbox", "read-only",
            "-C", workingDirectory,
        ]

        let trimmedModel = model?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !trimmedModel.isEmpty {
            arguments += ["-m", trimmedModel]
        }

        let trimmedEffort = reasoningEffort?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !trimmedEffort.isEmpty {
            arguments += ["-c", "model_reasoning_effort=\(trimmedEffort)"]
        }

        arguments += ["--", prompt]
        return arguments
    }

    /// Builds the subprocess environment for the Codex CLI invocation.
    ///
    /// Codex reads its own auth state from `~/.codex/auth.json` and `~/.codex/config.toml`,
    /// so we mostly inherit the parent environment (which already carries `OPENAI_API_KEY`
    /// if the user has configured one). We additionally merge the user's login-shell
    /// `PATH` so npm shebang shims (`#!/usr/bin/env node`) can resolve `node` when the
    /// app is launched from Finder with a minimal `PATH`.
    static func buildProcessEnvironment(
        inheritedEnvironment: [String: String] = ProcessInfo.processInfo.environment,
        loginShellPath: String? = CodexCLIRunner.loginShellEnvironmentPath()
    )
        -> [String: String] {
        var environment = inheritedEnvironment
        let merged = mergePathEntries(environment["PATH"], loginShellPath)
        if !merged.isEmpty {
            environment["PATH"] = merged
        }
        return environment
    }

    /// Merges two colon-separated `PATH` strings, preserving order and removing duplicates.
    static func mergePathEntries(_ first: String?, _ second: String?) -> String {
        var seen = Set<String>()
        var result: [String] = []
        for source in [first, second] {
            guard let source else { continue }
            for entry in source.split(separator: ":", omittingEmptySubsequences: true) {
                let value = String(entry)
                if seen.insert(value).inserted {
                    result.append(value)
                }
            }
        }
        return result.joined(separator: ":")
    }

    /// Returns the user's login-shell `PATH`, or nil if it cannot be resolved.
    ///
    /// The result is cached after the first successful lookup so the login-shell
    /// invocation only happens once per app session.
    static func loginShellEnvironmentPath() -> String? {
        cacheLock.lock()
        defer { cacheLock.unlock() }

        if let cached = cachedLoginShellPath {
            return cached
        }
        if let value = runViaLoginShell(#"printf %s "$PATH""#), !value.isEmpty {
            cachedLoginShellPath = value
            return value
        }
        return nil
    }

    /// Runs `codex exec --json` and yields the agent's final message text.
    ///
    /// The CLI emits one newline-delimited JSON object per event when invoked with `--json`.
    /// Codex 0.128.x does not stream deltas, so the user sees the response appear in one
    /// chunk after the model finishes generating.
    ///
    /// Token-reduction / safety flags applied to every invocation:
    /// - `--sandbox read-only` — blocks file writes if the model calls shell tools.
    /// - `--skip-git-repo-check` — lets the CLI run from neutral working directories.
    /// - `--ephemeral` — skips writing rollout / session files to disk.
    /// - `-C <tmpdir>` — uses a neutral working directory so codex does not scan user folders
    ///   for `AGENTS.md` or other repo-local instructions.
    ///
    /// - Parameters:
    ///   - prompt: The full prompt sent to the CLI. The caller is responsible for
    ///     embedding any system instructions, since `codex exec` does not have a separate
    ///     system-prompt flag.
    ///   - model: Optional model override (empty string and nil both leave codex's
    ///     default in place).
    ///   - reasoningEffort: Optional reasoning-effort override
    ///     (empty / nil keeps the user's `~/.codex/config.toml` setting).
    /// - Returns: A stream that yields text delta strings as they arrive from the CLI.
    func run(
        prompt: String,
        model: String? = nil,
        reasoningEffort: String? = nil
    )
        -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { [weak self] continuation in
            guard let self else {
                continuation.finish()
                return
            }

            // Ensure the subprocess is terminated if the stream consumer cancels early.
            continuation.onTermination = { [weak self] _ in
                self?.cancel()
            }

            // Use Task.detached to break out of any inherited actor context (e.g. @MainActor).
            // detectCodexBinary() spawns a login shell on the first invocation, which would
            // block the UI if scheduled on the main actor.
            Task.detached(priority: .userInitiated) { [weak self] in
                let decoder = JSONDecoder()
                do {
                    let binaryPath = try Self.detectCodexBinary()
                    #if AGENT_CLI_DEBUG
                    self?.logger = CodexCLILogger(command: "\(binaryPath) exec --json", prompt: prompt)
                    #endif

                    let process = Process()
                    let stdoutPipe = Pipe()
                    let stderrPipe = Pipe()
                    let workingDirectory = FileManager.default.temporaryDirectory.path

                    process.executableURL = URL(fileURLWithPath: binaryPath)
                    process.arguments = Self.buildArguments(
                        prompt: prompt,
                        workingDirectory: workingDirectory,
                        model: model,
                        reasoningEffort: reasoningEffort
                    )
                    process.standardOutput = stdoutPipe
                    process.standardError = stderrPipe
                    process.currentDirectoryURL = URL(fileURLWithPath: workingDirectory)
                    process.environment = Self.buildProcessEnvironment()

                    let startTime = Date()
                    var stderrDataBuffer = Data()
                    var stdoutControlLines: [String] = []
                    var stdoutDataBuffer = Data()

                    stderrPipe.fileHandleForReading.readabilityHandler = { handle in
                        let data = handle.availableData
                        guard !data.isEmpty else { return }
                        Self.ioQueue.async {
                            Self.appendCapped(data, to: &stderrDataBuffer)
                        }
                    }

                    stdoutPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
                        let data = handle.availableData
                        guard !data.isEmpty else { return }
                        let capturedLogger = self?.logger
                        Self.ioQueue.async {
                            capturedLogger?.appendStdout(String(data: data, encoding: .utf8) ?? "")
                            stdoutDataBuffer.append(data)
                            Self.flushLines(
                                from: &stdoutDataBuffer,
                                into: &stdoutControlLines,
                                decoder: decoder,
                                continuation: continuation
                            )
                        }
                    }

                    process.terminationHandler = { [weak self] terminatedProcess in
                        stdoutPipe.fileHandleForReading.readabilityHandler = nil
                        stderrPipe.fileHandleForReading.readabilityHandler = nil

                        // See ClaudeCodeRunner for the rationale behind the sync barrier:
                        // it flushes any in-flight readabilityHandler dispatches before we
                        // enqueue the finish block, preserving FIFO order on the IO queue.
                        Self.ioQueue.sync {}

                        let wasCancelled = self?.checkIsCancelled() ?? false
                        let remainingStdoutData = stdoutPipe.fileHandleForReading
                            .readDataToEndOfFile()
                        let remainingStderrData = stderrPipe.fileHandleForReading
                            .readDataToEndOfFile()
                        let exitCode = Int(terminatedProcess.terminationStatus)
                        let capturedLogger = self?.logger

                        Self.ioQueue.async { [weak self] in
                            if !remainingStdoutData.isEmpty {
                                capturedLogger?.appendStdout(
                                    String(data: remainingStdoutData, encoding: .utf8) ?? ""
                                )
                                stdoutDataBuffer.append(remainingStdoutData)
                            }
                            Self.flushLines(
                                from: &stdoutDataBuffer,
                                into: &stdoutControlLines,
                                includeRemainder: true,
                                decoder: decoder,
                                continuation: continuation
                            )

                            if !remainingStderrData.isEmpty {
                                Self.appendCapped(remainingStderrData, to: &stderrDataBuffer)
                            }
                            let stderrBuffer = String(data: stderrDataBuffer, encoding: .utf8) ?? ""

                            let duration = Date().timeIntervalSince(startTime)
                            capturedLogger?.finish(
                                stderr: stderrBuffer,
                                exitCode: exitCode,
                                duration: duration
                            )

                            let controlBuffer = stdoutControlLines.joined(separator: "\n")
                            self?.tokenUsage = parseCodexTokenUsage(
                                from: controlBuffer,
                                durationMs: Int(duration * 1000)
                            )

                            #if AGENT_CLI_DEBUG
                            CodexCLIDebugLogger.shared.post(
                                "[EXIT] code=\(exitCode)  duration=\(String(format: "%.1f", duration))s"
                            )
                            #endif

                            if exitCode != 0, !wasCancelled {
                                let error = parseCodexError(
                                    fromStdout: controlBuffer,
                                    stderr: stderrBuffer
                                )
                                continuation.finish(throwing: error)
                            } else {
                                continuation.finish()
                            }
                        }
                    }

                    guard self?.setProcessIfNotCancelled(process) == true else {
                        stdoutPipe.fileHandleForReading.readabilityHandler = nil
                        stderrPipe.fileHandleForReading.readabilityHandler = nil
                        continuation.finish()
                        return
                    }
                    try process.run()
                    self?.logger?.start()
                    if self?.checkIsCancelled() == true, process.isRunning {
                        process.terminate()
                    }
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    /// Terminates the subprocess if it is running.
    func cancel() {
        let processToTerminate = stateLock.withLock { () -> Process? in
            isCancelled = true
            let current = process
            process = nil
            return current
        }
        if processToTerminate?.isRunning == true {
            processToTerminate?.terminate()
        }
    }

    // MARK: Private

    /// Cached path from the first successful `detectCodexBinary()` call.
    /// Avoids spawning a login shell on every translation request.
    private static var cachedBinaryPath: String?

    /// Cached login-shell `PATH` from the first successful lookup.
    /// Same caching rationale as `cachedBinaryPath`.
    private static var cachedLoginShellPath: String?

    private static let cacheLock = NSLock()

    /// Shared serial queue for all I/O handler dispatches across invocations.
    private static let ioQueue = DispatchQueue(
        label: "com.easydict.codex-cli-runner-io",
        qos: .userInitiated
    )

    private var process: Process?
    private var logger: CodexCLILogger?
    /// Set to `true` by `cancel()` so the termination handler can distinguish
    /// a user-initiated stop from a real CLI failure. Always access under `stateLock`.
    private var isCancelled = false
    private let stateLock = NSLock()

    /// Drains all newline-terminated lines from `buffer`, yielding text deltas to
    /// `continuation` and appending non-delta lines to `controlLines`.
    private static func flushLines(
        from buffer: inout Data,
        into controlLines: inout [String],
        includeRemainder: Bool = false,
        decoder: JSONDecoder,
        continuation: AsyncThrowingStream<String, Error>.Continuation
    ) {
        var readHead = buffer.startIndex
        while let newlineIdx = buffer[readHead...].firstIndex(of: 0x0A) {
            let lineData = buffer[readHead ..< newlineIdx]
            if let line = String(data: lineData, encoding: .utf8), !line.isEmpty {
                if let delta = extractCodexText(from: line, decoder: decoder) {
                    continuation.yield(delta)
                } else {
                    controlLines.append(line)
                }
            }
            readHead = buffer.index(after: newlineIdx)
        }
        buffer = readHead < buffer.endIndex ? Data(buffer[readHead...]) : Data()

        if includeRemainder, !buffer.isEmpty,
           let line = String(data: buffer, encoding: .utf8), !line.isEmpty {
            if let delta = extractCodexText(from: line, decoder: decoder) {
                continuation.yield(delta)
            } else {
                controlLines.append(line)
            }
            buffer = Data()
        }
    }

    /// Appends `data` to `buffer`, capping the total at 1 MB by retaining only the
    /// most-recent suffix when the limit would be exceeded.
    private static func appendCapped(_ data: Data, to buffer: inout Data) {
        let maxSize = 1_048_576 // 1 MB
        buffer.append(data)
        if buffer.count > maxSize {
            buffer = Data(buffer.suffix(maxSize))
        }
    }

    /// Returns the path to the first `codex` binary found on this machine.
    ///
    /// The result is cached after the first successful lookup so the login-shell
    /// invocation only happens once per app session. The cached path is revalidated
    /// on each call so that uninstall or upgrade is detected automatically.
    ///
    /// - Throws: `CodexCLIError.notInstalled` if no binary is found.
    private static func detectCodexBinary() throws -> String {
        cacheLock.lock()
        defer { cacheLock.unlock() }

        if let cached = cachedBinaryPath {
            if FileManager.default.isExecutableFile(atPath: cached) {
                return cached
            }
            cachedBinaryPath = nil
        }

        var resolvedPath: String?

        if let raw = runViaLoginShell("which codex") {
            resolvedPath = raw
                .components(separatedBy: "\n")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .first {
                    !$0.isEmpty
                        && URL(fileURLWithPath: $0).lastPathComponent == "codex"
                        && FileManager.default.isExecutableFile(atPath: $0)
                }
        }

        if resolvedPath == nil {
            let candidates = [
                "\(NSHomeDirectory())/.local/bin/codex",
                "\(NSHomeDirectory())/.codex/bin/codex",
                "/usr/local/bin/codex",
                "/opt/homebrew/bin/codex",
            ]
            for candidate in candidates where FileManager.default.isExecutableFile(atPath: candidate) {
                resolvedPath = candidate
                break
            }
        }

        if let path = resolvedPath {
            cachedBinaryPath = path
            return path
        }
        throw CodexCLIError.notInstalled
    }

    /// Runs a command via the user's login shell, returning trimmed stdout or nil on failure.
    private static func runViaLoginShell(_ command: String) -> String? {
        let shell = resolveLoginShellPath(
            environmentShell: ProcessInfo.processInfo.environment["SHELL"]
        )
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: shell)
        process.arguments = ["-l", "-c", command]
        process.standardOutput = pipe
        let devNullHandle = try? FileHandle(forWritingTo: URL(fileURLWithPath: "/dev/null"))
        process.standardError = devNullHandle ?? Pipe()
        do {
            try process.run()
            var outputData = Data()
            let readGroup = DispatchGroup()
            readGroup.enter()
            DispatchQueue.global(qos: .userInitiated).async {
                outputData = pipe.fileHandleForReading.readDataToEndOfFile()
                readGroup.leave()
            }
            process.waitUntilExit()
            try? devNullHandle?.close()
            readGroup.wait()
            guard process.terminationStatus == 0 else { return nil }
            let path = String(data: outputData, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return path?.isEmpty == false ? path : nil
        } catch {
            try? devNullHandle?.close()
            return nil
        }
    }

    /// Reads `isCancelled` thread-safely under `stateLock`.
    private func checkIsCancelled() -> Bool {
        stateLock.withLock { isCancelled }
    }

    /// Atomically checks `isCancelled` and, if not cancelled, assigns `process`.
    ///
    /// - Returns: `true` if the process was assigned; `false` if already cancelled.
    private func setProcessIfNotCancelled(_ newProcess: Process) -> Bool {
        stateLock.withLock {
            guard !isCancelled else { return false }
            process = newProcess
            return true
        }
    }
}

extension CodexCLIRunner {
    /// Returns the detected `codex` binary path, or `nil` if not found.
    ///
    /// Used by the configuration view status row.
    static func detectBinaryPath() -> String? {
        try? detectCodexBinary()
    }
}
