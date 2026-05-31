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
    /// Every invocation uses a read-only sandbox and disables tool features that are
    /// unnecessary for translation. It still loads the user's normal Codex config.
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

        for feature in disabledToolFeatures {
            arguments += ["--disable", feature]
        }

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
    /// Parent values win, but Finder / Dock launches often miss shell-profile values.
    /// The login-shell environment only fills allowlisted auth, Codex home, and proxy
    /// variables that are absent from the parent. `PATH` is merged separately so npm
    /// shebang shims (`#!/usr/bin/env node`) can resolve `node`.
    static func buildProcessEnvironment(
        inheritedEnvironment: [String: String] = ProcessInfo.processInfo.environment,
        loginShellEnvironment: [String: String]? = CodexCLIRunner.loginShellEnvironment()
    )
        -> [String: String] {
        var environment = inheritedEnvironment
        let merged = mergePathEntries(environment["PATH"], loginShellEnvironment?["PATH"])
        if !merged.isEmpty {
            environment["PATH"] = merged
        }

        for key in loginShellEnvironmentKeys where key != "PATH" {
            guard environment[key] == nil,
                  let value = loginShellEnvironment?[key],
                  !value.isEmpty
            else {
                continue
            }
            environment[key] = value
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

    /// Returns allowlisted variables from the user's login-shell environment.
    ///
    /// The result is cached after the first successful lookup so the login-shell
    /// invocation only happens once per app session.
    ///
    /// The command sources zsh/bash runtime rc files before wrapping allowlisted
    /// `KEY=value` output in sentinels. This lets macOS GUI launches recover
    /// exported auth and network variables from shell profile setup.
    static func loginShellEnvironment() -> [String: String]? {
        cacheLock.lock()
        defer { cacheLock.unlock() }

        if let cached = cachedLoginShellEnvironment {
            return cached
        }

        let shellPath = resolveLoginShellPath(
            environmentShell: ProcessInfo.processInfo.environment["SHELL"]
        )
        let command = loginShellEnvironmentCommand(shellPath: shellPath)
        if let output = runViaLoginShell(command, shellPath: shellPath),
           let environment = extractLoginShellEnvironment(from: output) {
            cachedLoginShellEnvironment = environment
            return environment
        }
        return nil
    }

    /// Extracts allowlisted `KEY=value` pairs framed by environment sentinels.
    /// Returns nil when either sentinel is missing.
    static func extractLoginShellEnvironment(from output: String) -> [String: String]? {
        guard let beginRange = output.range(of: environmentSentinelBegin),
              let endRange = output.range(
                  of: environmentSentinelEnd,
                  range: beginRange.upperBound ..< output.endIndex
              )
        else {
            return nil
        }

        var environment: [String: String] = [:]
        let framedOutput = output[beginRange.upperBound ..< endRange.lowerBound]
        for rawEntry in framedOutput.split(separator: "\0", omittingEmptySubsequences: false) {
            let entry = rawEntry.trimmingCharacters(in: .newlines)
            guard !entry.isEmpty,
                  let separatorIndex = entry.firstIndex(of: "=")
            else {
                continue
            }

            let key = String(entry[..<separatorIndex])
            guard loginShellEnvironmentKeys.contains(key) else { continue }

            let valueStart = entry.index(after: separatorIndex)
            environment[key] = String(entry[valueStart...])
        }
        return environment
    }

    /// Builds the shell script used to print allowlisted environment values.
    ///
    /// zsh and bash runtime rc files are sourced silently because macOS GUI apps
    /// often miss variables exported from `~/.zshrc` or `~/.bashrc`.
    static func loginShellEnvironmentCommand(shellPath: String) -> String {
        let keys = loginShellEnvironmentKeys.joined(separator: " ")
        let rcSource = loginShellEnvironmentRCSource(shellPath: shellPath)
        return #"""
        \#(rcSource)
        printf '%s\n' '\#(environmentSentinelBegin)'
        for key in \#(keys); do
          if value=$(/usr/bin/printenv "$key"); then
            printf '%s=%s\0' "$key" "$value"
          fi
        done
        printf '\n%s\n' '\#(environmentSentinelEnd)'
        """#
    }

    /// Runs `codex exec --json` and yields the agent's final message text.
    ///
    /// The CLI emits one newline-delimited JSON object per event when invoked with `--json`.
    /// Codex 0.128.x does not stream deltas, so the user sees the response appear in one
    /// chunk after the model finishes generating.
    ///
    /// Token-reduction / safety flags applied to every invocation:
    /// - `--disable <feature>` — disables Codex tools that translation does not need.
    /// - `--sandbox read-only` — keeps a read-only fallback boundary for subprocesses.
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
                do {
                    let binaryPath = try Self.detectCodexBinary()
                    #if AGENT_CLI_DEBUG
                    self?.logger = CodexCLILogger(command: "\(binaryPath) exec --json", prompt: prompt)
                    #endif

                    let context = CodexRunContext()
                    let workingDirectory = FileManager.default.temporaryDirectory.path
                    let process = Self.configuredProcess(
                        for: CodexProcessConfiguration(
                            binaryPath: binaryPath,
                            prompt: prompt,
                            model: model,
                            reasoningEffort: reasoningEffort,
                            workingDirectory: workingDirectory,
                            context: context
                        )
                    )
                    Self.installReadabilityHandlers(
                        context: context,
                        logger: self?.logger,
                        continuation: continuation
                    )

                    process.terminationHandler = { [weak self] terminatedProcess in
                        context.stdoutPipe.fileHandleForReading.readabilityHandler = nil
                        context.stderrPipe.fileHandleForReading.readabilityHandler = nil

                        // See ClaudeCodeRunner for the rationale behind the sync barrier:
                        // it flushes any in-flight readabilityHandler dispatches before we
                        // enqueue the finish block, preserving FIFO order on the IO queue.
                        Self.ioQueue.sync {}

                        let wasCancelled = self?.checkIsCancelled() ?? false
                        let remainingStdoutData = context.stdoutPipe.fileHandleForReading
                            .readDataToEndOfFile()
                        let remainingStderrData = context.stderrPipe.fileHandleForReading
                            .readDataToEndOfFile()
                        let exitCode = Int(terminatedProcess.terminationStatus)
                        let capturedLogger = self?.logger

                        Self.ioQueue.async { [weak self] in
                            if !remainingStdoutData.isEmpty {
                                capturedLogger?.appendStdout(
                                    String(data: remainingStdoutData, encoding: .utf8) ?? ""
                                )
                                context.stdoutDataBuffer.append(remainingStdoutData)
                            }
                            Self.flushLines(
                                from: &context.stdoutDataBuffer,
                                into: &context.stdoutControlLines,
                                includeRemainder: true,
                                decoder: context.decoder,
                                continuation: continuation
                            )

                            if !remainingStderrData.isEmpty {
                                Self.appendCapped(remainingStderrData, to: &context.stderrDataBuffer)
                            }
                            let stderrBuffer = String(
                                data: context.stderrDataBuffer,
                                encoding: .utf8
                            ) ?? ""

                            let duration = Date().timeIntervalSince(context.startTime)
                            capturedLogger?.finish(
                                stderr: stderrBuffer,
                                exitCode: exitCode,
                                duration: duration
                            )

                            let controlBuffer = context.stdoutControlLines.joined(separator: "\n")
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
                        context.stdoutPipe.fileHandleForReading.readabilityHandler = nil
                        context.stderrPipe.fileHandleForReading.readabilityHandler = nil
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

    /// Stores per-run pipes and buffers shared by subprocess I/O callbacks.
    /// Mutations happen on `ioQueue` after the handlers are installed.
    private final class CodexRunContext: @unchecked Sendable {
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        let decoder = JSONDecoder()
        let startTime = Date()
        var stderrDataBuffer = Data()
        var stdoutControlLines: [String] = []
        var stdoutDataBuffer = Data()
    }

    /// Captures immutable values needed to configure one Codex subprocess.
    private struct CodexProcessConfiguration {
        let binaryPath: String
        let prompt: String
        let model: String?
        let reasoningEffort: String?
        let workingDirectory: String
        let context: CodexRunContext
    }

    /// Codex feature flags disabled for translation-only subprocess runs.
    ///
    /// Official references:
    /// - CLI `--disable`: https://developers.openai.com/codex/cli/reference
    /// - Feature flags: https://developers.openai.com/codex/config-basic#feature-flags
    /// - Feature list: https://developers.openai.com/codex/cli/reference#codex-features
    private static let disabledToolFeatures = [
        "shell_tool",
        "shell_snapshot",
        "browser_use",
        "browser_use_external",
        "in_app_browser",
        "computer_use",
        "image_generation",
        "apps",
        "plugins",
        "hooks",
        "multi_agent",
        "skill_mcp_dependency_install",
        "tool_call_mcp_elicitation",
        "tool_suggest",
        "workspace_dependencies",
    ]

    /// Cached path from the first successful `detectCodexBinary()` call.
    /// Avoids spawning a login shell on every translation request.
    private static var cachedBinaryPath: String?

    /// Cached login-shell environment from the first successful lookup.
    /// Same caching rationale as `cachedBinaryPath`.
    private static var cachedLoginShellEnvironment: [String: String]?

    /// Login-shell variables that are safe and useful for translation subprocesses.
    private static let loginShellEnvironmentKeys = [
        "PATH", "OPENAI_API_KEY", "CODEX_API_KEY", "CODEX_ACCESS_TOKEN",
        "CODEX_HOME", "CODEX_CA_CERTIFICATE", "SSL_CERT_FILE",
        "HTTPS_PROXY", "HTTP_PROXY", "ALL_PROXY", "NO_PROXY",
        "https_proxy", "http_proxy", "all_proxy", "no_proxy",
    ]

    /// Sentinels used to frame the login-shell environment inside stdout so we
    /// can recover it even when profile scripts print banners on the same stream.
    private static let environmentSentinelBegin = "__EZ_CODEX_ENV_BEGIN__"
    private static let environmentSentinelEnd = "__EZ_CODEX_ENV_END__"

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

    private static func loginShellEnvironmentRCSource(shellPath: String) -> String {
        switch URL(fileURLWithPath: shellPath).lastPathComponent {
        case "zsh":
            return #"if [ -r "$HOME/.zshrc" ]; then . "$HOME/.zshrc" >/dev/null 2>/dev/null; fi"#
        case "bash":
            return #"if [ -r "$HOME/.bashrc" ]; then . "$HOME/.bashrc" >/dev/null 2>/dev/null; fi"#
        default:
            return ""
        }
    }

    private static func configuredProcess(for configuration: CodexProcessConfiguration)
        -> Process {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: configuration.binaryPath)
        process.arguments = buildArguments(
            prompt: configuration.prompt,
            workingDirectory: configuration.workingDirectory,
            model: configuration.model,
            reasoningEffort: configuration.reasoningEffort
        )
        process.standardOutput = configuration.context.stdoutPipe
        process.standardError = configuration.context.stderrPipe
        process.currentDirectoryURL = URL(fileURLWithPath: configuration.workingDirectory)
        process.environment = buildProcessEnvironment()
        return process
    }

    private static func installReadabilityHandlers(
        context: CodexRunContext,
        logger: CodexCLILogger?,
        continuation: AsyncThrowingStream<String, Error>.Continuation
    ) {
        context.stderrPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }
            ioQueue.async {
                appendCapped(data, to: &context.stderrDataBuffer)
            }
        }

        context.stdoutPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }
            ioQueue.async {
                logger?.appendStdout(String(data: data, encoding: .utf8) ?? "")
                context.stdoutDataBuffer.append(data)
                flushLines(
                    from: &context.stdoutDataBuffer,
                    into: &context.stdoutControlLines,
                    decoder: context.decoder,
                    continuation: continuation
                )
            }
        }
    }

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
    private static func runViaLoginShell(_ command: String, shellPath: String? = nil) -> String? {
        let shell = shellPath ?? resolveLoginShellPath(
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
