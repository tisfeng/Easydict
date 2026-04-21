//
//  ClaudeCodeRunner.swift
//  Easydict
//
//  Created by Karl on 2026/04/07.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation

// MARK: - ClaudeCodeRunner

/// Wraps a `claude -p --print` subprocess and yields streaming text deltas as an `AsyncThrowingStream<String, Error>`.
///
/// Uses `--print --verbose --output-format stream-json --include-partial-messages` so the CLI emits
/// one JSON event per line. The runner extracts `content_block_delta` text deltas and forwards them to callers,
/// giving token-by-token granularity identical to the Anthropic API SSE stream.
///
/// Each instance represents exactly one subprocess invocation. Create a new instance per translation request.
final class ClaudeCodeRunner: @unchecked Sendable {
    // MARK: Lifecycle

    init() {}

    // MARK: Internal

    /// Token usage populated when the subprocess terminates normally.
    /// `nil` if the process has not yet finished or the `result` event was absent.
    private(set) var tokenUsage: CLITokenUsage?

    /// Runs `which <name>` directly (without a login shell).
    ///
    /// Used by unit tests, which run in an environment where PATH is already set correctly.
    static func runWhich(_ name: String) -> String? {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = [name]
        process.standardOutput = pipe
        process.standardError = Pipe() // suppress stderr
        do {
            try process.run()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else { return nil }
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
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

    /// Builds the argument list for a `claude -p --print` invocation.
    ///
    /// The current Claude Code CLI requires `--verbose` when `--print` is combined
    /// with `--output-format stream-json`.
    static func buildArguments(prompt: String, systemPrompt: String?) -> [String] {
        var arguments = [
            "-p", prompt,
            "--print",
            "--verbose",
            "--output-format", "stream-json",
            "--include-partial-messages",
            "--no-session-persistence",
            "--tools", "", // disable all built-in tools
            "--strict-mcp-config", // ignore user MCP config; no --mcp-config = no servers
            "--setting-sources", "", // skip all settings files to prevent plugin hooks
        ]
        if let systemPrompt, !systemPrompt.isEmpty {
            arguments += ["--system-prompt", systemPrompt]
        }
        return arguments
    }

    /// Loads string env vars from the user's Claude settings file.
    ///
    /// Returns an empty dictionary if the file is missing, unreadable, malformed,
    /// has no `env` object, or the `env` object contains non-string values.
    static func loadClaudeSettingsEnvironment(settingsURL: URL? = nil) -> [String: String] {
        let resolvedSettingsURL = settingsURL
            ?? URL(fileURLWithPath: NSHomeDirectory())
            .appendingPathComponent(".claude")
            .appendingPathComponent("settings.json")

        guard let settingsData = try? Data(contentsOf: resolvedSettingsURL),
              let settings = try? JSONDecoder().decode(
                  ClaudeUserSettings.self,
                  from: settingsData
              ),
              let environment = settings.env else {
            return [:]
        }

        return environment
    }

    /// Builds the subprocess environment for the Claude CLI invocation.
    ///
    /// Claude settings sources remain disabled, but the user's configured
    /// `env` block is injected explicitly so auth and proxy settings still
    /// reach the subprocess.
    static func buildProcessEnvironment(
        settingsURL: URL? = nil,
        inheritedEnvironment: [String: String] = ProcessInfo.processInfo.environment
    )
        -> [String: String] {
        var processEnvironment = inheritedEnvironment
        let settingsEnvironment = loadClaudeSettingsEnvironment(settingsURL: settingsURL)

        for (key, value) in settingsEnvironment {
            processEnvironment[key] = value
        }

        return processEnvironment
    }

    /// Runs `claude -p --print` with optimised flags and streams text delta chunks as they arrive.
    ///
    /// The CLI emits one newline-delimited JSON object per event when invoked with
    /// `--print --verbose --output-format stream-json`.
    /// This method extracts `text_delta` text from each `content_block_delta` event, giving
    /// token-by-token granularity identical to the Anthropic API SSE stream.
    ///
    /// Token-reduction flags applied to every invocation:
    /// - `--system-prompt` — replaces the large Claude Code default system prompt with the
    ///   caller-supplied translation prompt, skipping all Claude Code tool/agent instructions.
    /// - `--tools ""` — disables all built-in tools so their descriptions never enter context.
    /// - `--strict-mcp-config` (without `--mcp-config`) — ignores the user's MCP server config,
    ///   preventing MCP tool descriptions from entering the context.
    /// - `--no-session-persistence` — skips session file I/O.
    /// - `--setting-sources ""` — skips loading all settings files (user/project/local), which
    ///   prevents plugins (e.g. superpowers) from registering their SessionStart hooks.
    ///   The user's `~/.claude/settings.json` `env` block is injected separately so auth and
    ///   proxy variables still reach the subprocess without re-enabling hooks or plugins.
    ///
    /// - Parameters:
    ///   - prompt: The conversation prompt (user / assistant messages only, without system message).
    ///   - systemPrompt: Passed via `--system-prompt` to replace Claude Code's default system
    ///     prompt. `nil` omits the flag and leaves Claude Code's default in place.
    /// - Returns: A stream that yields text delta strings as they arrive from the CLI.
    func run(prompt: String, systemPrompt: String? = nil) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { [weak self] continuation in
            guard let self else {
                continuation.finish()
                return
            }

            // Ensure the subprocess is terminated if the stream consumer cancels early
            // (e.g. a new query starts before the current one finishes).
            continuation.onTermination = { [weak self] _ in
                self?.cancel()
            }

            // Use Task.detached to break out of any inherited actor context (e.g. @MainActor).
            // The call chain that reaches here is typically initiated from the main thread,
            // so a plain Task { } would run on the main actor and block the UI when
            // detectClaudeBinary() spawns a login shell on the first invocation.
            Task.detached(priority: .userInitiated) { [weak self] in
                // One decoder per invocation, shared across all readabilityHandler calls.
                // Avoids the per-line JSONDecoder allocation on the hot streaming path.
                let decoder = JSONDecoder()
                do {
                    let binaryPath = try Self.detectClaudeBinary()
                    #if AGENT_CLI_DEBUG
                    self?.logger = ClaudeCodeLogger(command: "\(binaryPath) -p <prompt>", prompt: prompt)
                    #endif

                    let process = Process()
                    let stdoutPipe = Pipe()
                    let stderrPipe = Pipe()

                    process.executableURL = URL(fileURLWithPath: binaryPath)
                    process.arguments = Self.buildArguments(prompt: prompt, systemPrompt: systemPrompt)
                    process.standardOutput = stdoutPipe
                    process.standardError = stderrPipe
                    // Use a neutral working directory so claude does not scan user folders.
                    process.currentDirectoryURL = FileManager.default.temporaryDirectory
                    // Keep Claude settings sources disabled, but explicitly inject
                    // user-configured env vars such as auth and proxy settings.
                    process.environment = Self.buildProcessEnvironment()

                    let startTime = Date()
                    // Raw stderr bytes; decoded to String once in the termination handler
                    // after all data has arrived, so multi-byte UTF-8 sequences are never split.
                    var stderrDataBuffer = Data()
                    // Accumulates non-delta stdout lines for post-exit error/usage detection.
                    // Stored as an array to avoid O(N²) string concatenation on repeated appends.
                    var stdoutControlLines: [String] = []
                    // Incomplete stdout bytes carried over between readabilityHandler calls.
                    // Buffered at the Data level so multi-byte UTF-8 chars split across reads
                    // are not dropped when converting to String.
                    var stdoutDataBuffer = Data()

                    // Read stderr asynchronously into a raw-byte buffer (capped at 1 MB).
                    // Decoding is deferred to the termination handler so that multi-byte UTF-8
                    // characters split across availableData reads are never silently dropped.
                    stderrPipe.fileHandleForReading.readabilityHandler = { handle in
                        let data = handle.availableData
                        guard !data.isEmpty else { return }
                        Self.ioQueue.async {
                            Self.appendCapped(data, to: &stderrDataBuffer)
                        }
                    }

                    // Read stdout line by line, parse each JSON event, and yield text deltas.
                    // Only non-delta lines are kept in stdoutControlLines for error/usage parsing.
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

                        // Drain all readabilityHandler blocks already queued on ioQueue before
                        // we read remaining pipe data or enqueue the finish block.
                        //
                        // Race: a readabilityHandler fires on the OS thread, captures
                        // `data = handle.availableData` (consuming those bytes from the pipe),
                        // then calls ioQueue.async. If that ioQueue.async happens AFTER we
                        // enqueue the termination finish block, the handler's data is processed
                        // after finish() — yielded text is silently dropped, and the result/
                        // usage line may miss parseTokenUsage / parseError.
                        //
                        // Mitigation: sync-wait on ioQueue to flush any blocks already queued,
                        // then read remaining pipe bytes (a syscall). Any readabilityHandler
                        // that was executing during the nil above has microseconds to reach its
                        // own ioQueue.async — that enqueue happens before our subsequent
                        // ioQueue.async { finish }, preserving FIFO order.
                        Self.ioQueue.sync {}

                        // Capture isCancelled by value NOW under stateLock, while self may still exist.
                        // ClaudeCodeService.cancelStream() sets runner = nil immediately, so
                        // self can be deallocated before ioQueue.async runs, making
                        // self?.checkIsCancelled() return nil (treated as false) even after cancellation.
                        let wasCancelled = self?.checkIsCancelled() ?? false

                        // Read remaining pipe data synchronously on the termination-handler queue
                        // before dispatching to ioQueue, so the OS pipe buffer is drained promptly.
                        let remainingStdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                        let remainingStderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()

                        let exitCode = Int(terminatedProcess.terminationStatus)
                        // Capture logger strongly so it outlives the weak self reference.
                        let capturedLogger = self?.logger

                        Self.ioQueue.async { [weak self] in
                            if !remainingStdoutData.isEmpty {
                                capturedLogger?
                                    .appendStdout(String(data: remainingStdoutData, encoding: .utf8) ?? "")
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
                            capturedLogger?.finish(stderr: stderrBuffer, exitCode: exitCode, duration: duration)

                            // Join control lines once here; used by both parseTokenUsage and parseError.
                            let controlBuffer = stdoutControlLines.joined(separator: "\n")
                            self?.tokenUsage = parseTokenUsage(from: controlBuffer)

                            #if AGENT_CLI_DEBUG
                            ClaudeCodeDebugLogger.shared.post(
                                "[EXIT] code=\(exitCode)  duration=\(String(format: "%.1f", duration))s"
                            )
                            #endif

                            if exitCode != 0, !wasCancelled {
                                let error = parseError(fromStdout: controlBuffer, stderr: stderrBuffer)
                                continuation.finish(throwing: error)
                            } else {
                                // Either success or user-initiated cancellation — finish cleanly.
                                continuation.finish()
                            }
                        }
                    }

                    // Atomically check isCancelled and assign self.process so that cancel()
                    // cannot run between a plain guard check and the subsequent assignment.
                    // Returns false (== nil) if the runner was already cancelled.
                    guard self?.setProcessIfNotCancelled(process) == true else {
                        // Clear readability handlers so they release captured resources
                        // (continuation, decoder, buffer vars) without waiting for the
                        // pipes to be connected to a process that will never launch.
                        stdoutPipe.fileHandleForReading.readabilityHandler = nil
                        stderrPipe.fileHandleForReading.readabilityHandler = nil
                        continuation.finish()
                        return
                    }
                    try process.run()
                    self?.logger?.start()
                    // Post-launch cancellation guard: cancel() checks isRunning before calling
                    // terminate(), so if cancel() ran between setProcessIfNotCancelled and run()
                    // it would have skipped terminate() (isRunning was false at that point).
                    // Now that the process is running, terminate it if cancellation was requested.
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
        // Capture the current process and flip the flag atomically so that a concurrent
        // guard check in Task.detached sees a consistent state.
        let processToTerminate = stateLock.withLock { () -> Process? in
            isCancelled = true
            let current = process
            process = nil
            return current
        }
        // Guard isRunning before terminate() to avoid NSInvalidArgumentException
        // when cancel() is called before the process has been launched.
        if processToTerminate?.isRunning == true {
            processToTerminate?.terminate()
        }
    }

    // MARK: Private

    /// User-scoped Claude settings used only for explicit env injection.
    private struct ClaudeUserSettings: Decodable {
        let env: [String: String]?
    }

    /// Cached path from the first successful `detectClaudeBinary()` call.
    /// Avoids spawning a login shell on every translation request.
    private static var cachedBinaryPath: String?
    private static let cacheLock = NSLock()

    /// Shared serial queue for all I/O handler dispatches across invocations.
    /// Reusing one queue avoids the overhead of creating a new DispatchQueue per translation.
    private static let ioQueue = DispatchQueue(
        label: "com.easydict.claude-code-runner-io",
        qos: .userInitiated
    )

    private var process: Process?
    private var logger: ClaudeCodeLogger?
    /// Set to `true` by `cancel()` so the termination handler can distinguish
    /// a user-initiated stop from a real CLI failure. Always access under `stateLock`.
    private var isCancelled = false
    /// Serializes read/write access to `isCancelled` and `process` across
    /// `cancel()` (caller thread) and `Task.detached` (concurrency thread pool).
    private let stateLock = NSLock()

    /// Drains all newline-terminated lines from `buffer`, yielding text deltas to
    /// `continuation` and appending non-delta lines to `controlLines`.
    ///
    /// Splits on the 0x0A byte, which is safe because newline is a single byte in UTF-8;
    /// multi-byte sequences never contain 0x0A. Uses a read-head offset to avoid creating
    /// an intermediate `Data` copy per newline, keeping the hot streaming path at O(N).
    ///
    /// - Parameter includeRemainder: When `true`, any bytes remaining after the last newline
    ///   are also decoded and dispatched. Pass `true` only in the termination handler after
    ///   all pipe data has been read, so a final line without a trailing newline is not lost.
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
                if let delta = extractTextDelta(from: line, decoder: decoder) {
                    continuation.yield(delta)
                } else {
                    // Retain control events (result, rate_limit_event, system) for
                    // post-exit error detection and token-usage parsing.
                    controlLines.append(line)
                }
            }
            readHead = buffer.index(after: newlineIdx)
        }
        // Advance past all consumed bytes in a single slice (one allocation, not per-line).
        buffer = readHead < buffer.endIndex ? Data(buffer[readHead...]) : Data()

        if includeRemainder, !buffer.isEmpty,
           let line = String(data: buffer, encoding: .utf8), !line.isEmpty {
            if let delta = extractTextDelta(from: line, decoder: decoder) {
                continuation.yield(delta)
            } else {
                controlLines.append(line)
            }
            buffer = Data()
        }
    }

    /// Appends `data` to `buffer`, capping the total at 1 MB by retaining only the
    /// most-recent suffix when the limit would be exceeded.
    ///
    /// The 1 MB cap prevents unbounded stderr growth if the CLI emits large error payloads.
    private static func appendCapped(_ data: Data, to buffer: inout Data) {
        let maxSize = 1_048_576 // 1 MB
        buffer.append(data)
        if buffer.count > maxSize {
            buffer = Data(buffer.suffix(maxSize))
        }
    }

    /// Returns the path to the first `claude` binary found on this machine.
    ///
    /// The result is cached after the first successful lookup so the login-shell
    /// invocation only happens once per app session. The cached path is revalidated
    /// on each call so that uninstall or upgrade is detected automatically.
    ///
    /// The lock is held through the entire slow-path probe to prevent concurrent
    /// first-time callers from each spawning a login shell simultaneously.
    ///
    /// - Throws: `ClaudeCodeError.notInstalled` if no binary is found.
    private static func detectClaudeBinary() throws -> String {
        cacheLock.lock()
        defer { cacheLock.unlock() }

        // Fast path: return cached path only if it still exists and is executable.
        // Re-checking prevents stale cache entries after a claude uninstall or upgrade.
        if let cached = cachedBinaryPath {
            if FileManager.default.isExecutableFile(atPath: cached) {
                return cached
            }
            // Cached path is stale — clear it and fall through to re-detect.
            cachedBinaryPath = nil
        }

        // Slow path: probe for the binary while holding the lock so that concurrent
        // first-time callers block here rather than each spawning their own login shell.
        var resolvedPath: String?

        // 1. Try via login shell so PATH from ~/.zshrc / ~/.bash_profile is available.
        //    GUI apps do not inherit the user's shell PATH, so a plain `which` call fails.
        //    Login shell startup scripts can emit arbitrary output (banners, alias definitions,
        //    etc.) before the actual path, so split on newlines and accept only the first
        //    line whose basename is "claude" and that points to an executable file.
        if let raw = runViaLoginShell("which claude") {
            resolvedPath = raw
                .components(separatedBy: "\n")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .first {
                    !$0.isEmpty
                        && URL(fileURLWithPath: $0).lastPathComponent == "claude"
                        && FileManager.default.isExecutableFile(atPath: $0)
                }
        }

        // 2. Check common manual-install locations as fallback.
        if resolvedPath == nil {
            let candidates = [
                "\(NSHomeDirectory())/.local/bin/claude",
                "\(NSHomeDirectory())/.claude/local/claude",
                "/usr/local/bin/claude",
                "/opt/homebrew/bin/claude",
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
        throw ClaudeCodeError.notInstalled
    }

    /// Runs a command via the user's login shell, returning trimmed stdout or nil on failure.
    ///
    /// Uses `-l` (login) so the shell sources the user's profile and picks up their full PATH.
    private static func runViaLoginShell(_ command: String) -> String? {
        let shell = resolveLoginShellPath(environmentShell: ProcessInfo.processInfo.environment["SHELL"])
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: shell)
        process.arguments = ["-l", "-c", command]
        process.standardOutput = pipe
        // Redirect stderr to /dev/null instead of an unread Pipe().
        // Login shell profile scripts can emit large amounts of output to stderr (e.g. from
        // sourced tools like nvm, rbenv, or homebrew init). An unread Pipe() has a fixed OS
        // buffer (~64 KB); once full, the child process blocks on write(), causing
        // waitUntilExit() to hang indefinitely and preventing binary detection from completing.
        // Uses the URL-based initialiser (non-deprecated); handle is closed after process exit.
        // Falls back to a Pipe() if /dev/null cannot be opened (e.g. sandbox restrictions),
        // accepting the theoretical buffer-full hang rather than crashing with nil.
        let devNullHandle = try? FileHandle(forWritingTo: URL(fileURLWithPath: "/dev/null"))
        process.standardError = devNullHandle ?? Pipe()
        do {
            try process.run()
            // Drain stdout concurrently to prevent pipe-buffer deadlock.
            // Login shell profile scripts can produce stdout output; without concurrent
            // draining, a large write fills the OS buffer (~64 KB) and the child process
            // blocks indefinitely, causing waitUntilExit() to hang.
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
            let path = String(data: outputData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
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
    /// Combining the check and the assignment into one locked operation closes the race
    /// window that exists when the two steps run separately: `cancel()` could execute
    /// between a plain guard check and the subsequent `self.process = …` write.
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

extension ClaudeCodeRunner {
    /// Returns the detected `claude` binary path, or `nil` if not found.
    ///
    /// Uses the same login-shell detection as `run(prompt:)`.
    /// Used by the configuration view status row.
    static func detectBinaryPath() -> String? {
        try? detectClaudeBinary()
    }
}
