//
//  GitHubCopilotRunner.swift
//  Easydict
//
//  Created by tisfeng on 2026/09/24.
//

import Foundation

// MARK: - GitHubCopilotRunner

/// Wraps one `copilot -p` subprocess and yields streaming text deltas as an `AsyncThrowingStream<String, Error>`.
///
/// The CLI emits one JSON event per line under `--output-format json`. The runner extracts
/// `assistant.message_delta` text and forwards it to callers; every other event type is
/// retained as a control line for post-exit error and usage parsing.
///
/// Each instance represents exactly one subprocess invocation. Create a new instance per request.
final class GitHubCopilotRunner: @unchecked Sendable {
    // MARK: Lifecycle

    init() {}

    // MARK: Internal

    /// Disposable per-request directories: a redirected CLI home and an empty working directory.
    struct Sandbox {
        let root: URL
        let homeDirectory: URL
        let workingDirectory: URL
        let logDirectory: URL
    }

    /// Placeholder tool name passed to `--available-tools`.
    ///
    /// `--available-tools` is an allowlist that hides every tool not named in it, so naming a
    /// tool that does not exist removes the tool surface entirely. Verified against
    /// Copilot CLI 1.0.86: the reported `tool_count` drops from 19 to 0.
    ///
    /// Excluding tools individually with `--excluded-tools` is not equivalent — the same
    /// build still exposed 11 tools after excluding every documented one.
    static let disabledToolsSentinel = "__easydict_tools_disabled__"

    /// Token usage populated when the subprocess terminates normally.
    /// `nil` when the process has not finished or the `result` event was absent.
    private(set) var tokenUsage: GitHubCopilotUsage?

    /// Runs `which <name>` directly, without a login shell.
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
            let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            return path?.isEmpty == false ? path : nil
        } catch {
            return nil
        }
    }

    /// Resolves which shell executable should run login-shell detection.
    static func resolveLoginShellPath(environmentShell: String?) -> String {
        guard let environmentShell,
              environmentShell.hasPrefix("/"),
              FileManager.default.isExecutableFile(atPath: environmentShell)
        else {
            return "/bin/zsh"
        }
        return environmentShell
    }

    /// Builds the argument list for one `copilot -p` invocation.
    ///
    /// Isolation flags applied to every invocation:
    /// - `--available-tools <sentinel>` — removes the entire tool surface (see `disabledToolsSentinel`).
    ///   Must stay last: it is variadic, and a trailing value list could otherwise absorb a
    ///   following flag as a tool name.
    /// - `--disable-builtin-mcps` — keeps the built-in GitHub MCP server out of the session.
    /// - `--no-custom-instructions` — ignores `AGENTS.md` and related files, so the working
    ///   directory cannot inject instructions into a translation request.
    /// - `--no-remote`, `--no-remote-export` — no remote control or session export.
    /// - `--no-auto-update` — the CLI downloads updates by default, which would let behaviour
    ///   drift from what this integration was written and verified against.
    ///
    /// - Parameters:
    ///   - prompt: The conversation prompt.
    ///   - model: Passed via `--model`. An empty string omits the flag and keeps the CLI default.
    ///   - effort: Passed via `--reasoning-effort`; `nil` omits the flag and keeps the CLI default.
    ///   - logDirectoryPath: Passed via `--log-dir` so CLI logs stay inside the disposable
    ///     per-request directory instead of accumulating under the user's `~/.copilot`.
    static func buildArguments(
        prompt: String,
        model: String,
        effort: String?,
        logDirectoryPath: String
    )
        -> [String] {
        var arguments = [
            "-p", prompt,
            "--output-format", "json",
            "--no-color",
            "--no-auto-update",
            "--no-remote",
            "--no-remote-export",
            "--no-custom-instructions",
            "--disable-builtin-mcps",
            "--log-dir", logDirectoryPath,
        ]
        let trimmedModel = model.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedModel.isEmpty {
            arguments += ["--model", trimmedModel]
        }
        if let effort, !effort.isEmpty {
            arguments += ["--reasoning-effort", effort]
        }
        // Variadic; keep last so it cannot consume another flag as a tool name.
        arguments += ["--available-tools", disabledToolsSentinel]
        return arguments
    }

    /// Builds the subprocess environment.
    ///
    /// `COPILOT_HOME` is redirected to a disposable per-request directory for two reasons:
    /// the CLI persists every session (including prompt text) under
    /// `<COPILOT_HOME>/session-state/` indefinitely, and translation input is user text that
    /// must not accumulate in the user's own CLI state. Account identifiers are copied separately
    /// into this directory so the CLI can locate its existing system-keychain credentials.
    ///
    /// The trade-off is that the user's own `~/.copilot/settings.json` does not apply, so their
    /// configured default model is not picked up; the model is chosen in Easydict instead.
    ///
    /// `COPILOT_ALLOW_ALL` is removed unconditionally: the value `true` makes the CLI trust the
    /// working directory and load its skills, plugins, MCP servers, and hooks — including hooks
    /// that run shell commands — which must never happen for a translation request.
    static func buildProcessEnvironment(
        homeDirectoryPath: String,
        inheritedEnvironment: [String: String] = ProcessInfo.processInfo.environment
    )
        -> [String: String] {
        var environment = inheritedEnvironment
        environment["COPILOT_HOME"] = homeDirectoryPath
        environment.removeValue(forKey: "COPILOT_ALLOW_ALL")
        return environment
    }

    /// Runs a command via the user's login shell, returning trimmed stdout or nil on failure.
    ///
    /// stderr is redirected to /dev/null rather than an unread `Pipe()`: login profile scripts can
    /// emit large amounts of output, and an unread pipe fills at ~64 KB and blocks the child
    /// forever, hanging `waitUntilExit()`.
    static func runViaLoginShell(_ command: String) -> String? {
        let shell = resolveLoginShellPath(environmentShell: ProcessInfo.processInfo.environment["SHELL"])
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: shell)
        process.arguments = ["-l", "-c", command]
        process.standardOutput = pipe
        let devNullHandle = try? FileHandle(forWritingTo: URL(fileURLWithPath: "/dev/null"))
        process.standardError = devNullHandle ?? Pipe()
        do {
            try process.run()
            // Drain stdout concurrently so a large write cannot fill the pipe buffer and block.
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

    /// Runs `copilot -p` with the isolation flags above and streams text deltas as they arrive.
    ///
    /// - Returns: A stream that yields text deltas, and throws `GitHubCopilotError.unexpectedToolUse`
    ///   if the CLI reports a tool request despite the removed tool surface.
    func run(
        prompt: String,
        model: String,
        effort: String?
    )
        -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { [weak self] continuation in
            guard let self else {
                continuation.finish()
                return
            }

            continuation.onTermination = { [weak self] _ in
                self?.cancel()
            }

            // Detached so the call chain, which starts on the main thread, cannot block the UI
            // while the first invocation spawns a login shell to resolve the binary.
            Task.detached(priority: .userInitiated) { [weak self] in
                // One decoder per invocation, shared across readabilityHandler calls.
                let decoder = JSONDecoder()
                // Tracked outside the `do` block so the failure path can still clean up.
                var createdSandbox: Sandbox?
                do {
                    let binaryPath = try Self.detectCopilotBinary()

                    // Both the CLI home and the working directory live under one disposable root.
                    // A neutral, empty working directory keeps the CLI from scanning user folders,
                    // and cleaning up the root removes sessions, logs, and caches together.
                    let sandbox = try Self.makeSandboxDirectory()
                    createdSandbox = sandbox
                    let environment = GitHubCopilotEnvironment.resolve()
                    try GitHubCopilotEnvironment.prepareAuthentication(
                        in: sandbox.homeDirectory, environment: environment
                    )

                    #if AGENT_CLI_DEBUG
                    self?.logger = GitHubCopilotLogger(
                        command: "\(binaryPath) -p <prompt>", prompt: prompt
                    )
                    #endif

                    let process = Process()
                    let stdoutPipe = Pipe()
                    let stderrPipe = Pipe()

                    process.executableURL = URL(fileURLWithPath: binaryPath)
                    process.arguments = Self.buildArguments(
                        prompt: prompt,
                        model: model,
                        effort: effort,
                        logDirectoryPath: sandbox.logDirectory.path
                    )
                    process.standardOutput = stdoutPipe
                    process.standardError = stderrPipe
                    process.currentDirectoryURL = sandbox.workingDirectory
                    process.environment = Self.buildProcessEnvironment(
                        homeDirectoryPath: sandbox.homeDirectory.path,
                        inheritedEnvironment: environment
                    )

                    let startTime = Date()
                    // All output state is mutated only on `ioQueue`, which is serial, so a shared
                    // reference type is safe here and avoids threading `inout` through closures.
                    let buffers = GitHubCopilotOutputBuffers()

                    Self.attachStdoutReader(
                        to: stdoutPipe,
                        decoder: decoder,
                        buffers: buffers,
                        loggerProvider: { [weak self] in self?.logger },
                        continuation: continuation
                    )
                    Self.attachStderrReader(to: stderrPipe, buffers: buffers)

                    process.terminationHandler = { [weak self] terminatedProcess in
                        Self.handleTermination(
                            terminatedProcess: terminatedProcess,
                            context: GitHubCopilotTerminationContext(
                                stdoutPipe: stdoutPipe,
                                stderrPipe: stderrPipe,
                                sandbox: sandbox,
                                startTime: startTime,
                                wasCancelled: self?.checkIsCancelled() ?? false,
                                logger: self?.logger,
                                buffers: buffers,
                                decoder: decoder,
                                continuation: continuation,
                                usageSink: { [weak self] usage in self?.tokenUsage = usage }
                            )
                        )
                    }

                    // Check cancellation and assign the process atomically so cancel() cannot run
                    // between the check and the assignment.
                    guard self?.setProcessIfNotCancelled(process) == true else {
                        stdoutPipe.fileHandleForReading.readabilityHandler = nil
                        stderrPipe.fileHandleForReading.readabilityHandler = nil
                        // The process never launched, so nothing will call the termination handler.
                        Self.removeSandbox(sandbox)
                        continuation.finish()
                        return
                    }
                    try process.run()
                    self?.logger?.start()
                    // cancel() skips terminate() when the process was not yet running, so re-check
                    // after launch and terminate if cancellation arrived in between.
                    if self?.checkIsCancelled() == true, process.isRunning {
                        process.terminate()
                    }
                } catch {
                    // Launch or setup failed before a process owned cleanup; do it here so a
                    // failed request cannot leave a sandbox directory behind.
                    if let createdSandbox { Self.removeSandbox(createdSandbox) }
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

    /// Cached path from the first successful `detectCopilotBinary()` call.
    private static var cachedBinaryPath: String?
    private static let cacheLock = NSLock()

    /// Shared serial queue for I/O handler dispatches, reused across invocations.
    private static let ioQueue = DispatchQueue(
        label: "com.easydict.github-copilot-runner-io",
        qos: .userInitiated
    )

    private var process: Process?
    private var logger: GitHubCopilotLogger?
    /// Set by `cancel()` so the termination handler can tell a user stop from a real failure.
    private var isCancelled = false
    private let stateLock = NSLock()

    /// Creates the disposable sandbox for one invocation.
    ///
    /// Cleans up after itself if any directory creation fails, so a partial root cannot be
    /// left behind for the caller to miss.
    private static func makeSandboxDirectory() throws -> Sandbox {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("easydict-copilot-\(UUID().uuidString)", isDirectory: true)
        let home = root.appendingPathComponent("home", isDirectory: true)
        let working = root.appendingPathComponent("work", isDirectory: true)
        let logs = root.appendingPathComponent("logs", isDirectory: true)
        do {
            for directory in [root, home, working, logs] {
                try FileManager.default.createDirectory(
                    at: directory, withIntermediateDirectories: true,
                    attributes: [.posixPermissions: 0o700]
                )
            }
        } catch {
            try? FileManager.default.removeItem(at: root)
            throw error
        }
        return Sandbox(root: root, homeDirectory: home, workingDirectory: working, logDirectory: logs)
    }

    /// Removes the sandbox, discarding sessions, logs, and caches written during the run.
    ///
    /// The sandbox can contain prompt text, so a failure is reported rather than swallowed.
    private static func removeSandbox(_ sandbox: Sandbox) {
        do {
            try FileManager.default.removeItem(at: sandbox.root)
        } catch let error as NSError where error.code == NSFileNoSuchFileError {
            // Already gone; nothing to clean up.
        } catch {
            logError("Failed to remove GitHub Copilot sandbox at \(sandbox.root.path): \(error)")
        }
    }

    /// Reads stderr asynchronously into a capped raw-byte buffer.
    ///
    /// Decoding is deferred to the termination handler so a multi-byte UTF-8 sequence split
    /// across reads is never silently dropped.
    private static func attachStderrReader(to pipe: Pipe, buffers: GitHubCopilotOutputBuffers) {
        pipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }
            ioQueue.async {
                appendCapped(data, to: &buffers.stderrData)
            }
        }
    }

    /// Reads stdout line by line, yielding text deltas and retaining control events.
    private static func attachStdoutReader(
        to pipe: Pipe,
        decoder: JSONDecoder,
        buffers: GitHubCopilotOutputBuffers,
        loggerProvider: @escaping () -> GitHubCopilotLogger?,
        continuation: AsyncThrowingStream<String, Error>.Continuation
    ) {
        pipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }
            let capturedLogger = loggerProvider()
            ioQueue.async {
                capturedLogger?.appendStdout(String(data: data, encoding: .utf8) ?? "")
                buffers.stdoutData.append(data)
                flushLines(
                    buffers: buffers,
                    decoder: decoder,
                    continuation: continuation
                )
            }
        }
    }

    /// Finalizes one invocation: drains the pipes, records usage, and closes the stream.
    ///
    /// Runs on `ioQueue` after a synchronous barrier, so data still held by in-flight
    /// readability handlers cannot be delivered after the stream has finished.
    private static func handleTermination(
        terminatedProcess: Process,
        context: GitHubCopilotTerminationContext
    ) {
        let stdoutPipe = context.stdoutPipe
        let stderrPipe = context.stderrPipe
        let logger = context.logger
        let buffers = context.buffers

        stdoutPipe.fileHandleForReading.readabilityHandler = nil
        stderrPipe.fileHandleForReading.readabilityHandler = nil

        // Drain handlers already queued on ioQueue before reading the remaining pipe data, so
        // queued work is not overtaken by the finish block.
        //
        // Residual window: `readabilityHandler = nil` cannot interrupt a handler that is already
        // executing, and `availableData` may have consumed bytes that are not yet on ioQueue.
        // The barrier cannot recall those bytes, so they can be processed after the stream has
        // finished — losing a trailing delta, or a usage/error line, in a very short race. This
        // matches the existing Claude Code runner; a trailing loss degrades diagnostics for that
        // request without affecting the result already delivered.
        ioQueue.sync {}

        let remainingStdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        let remainingStderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
        let exitCode = Int(terminatedProcess.terminationStatus)

        ioQueue.async {
            // The process has exited and its pipes are drained, so nothing can still be reading
            // the sandbox and it is safe to remove.
            removeSandbox(context.sandbox)

            if !remainingStdoutData.isEmpty {
                logger?.appendStdout(String(data: remainingStdoutData, encoding: .utf8) ?? "")
                buffers.stdoutData.append(remainingStdoutData)
            }
            flushLines(
                buffers: buffers,
                includeRemainder: true,
                decoder: context.decoder,
                continuation: context.continuation
            )

            if !remainingStderrData.isEmpty {
                appendCapped(remainingStderrData, to: &buffers.stderrData)
            }
            let stderrBuffer = String(data: buffers.stderrData, encoding: .utf8) ?? ""

            let duration = Date().timeIntervalSince(context.startTime)
            logger?.finish(stderr: stderrBuffer, exitCode: exitCode, duration: duration)

            let controlBuffer = buffers.controlLines.joined(separator: "\n")
            context.usageSink(parseGitHubCopilotUsage(from: controlBuffer))

            #if AGENT_CLI_DEBUG
            GitHubCopilotDebugLogger.shared.post(
                "[EXIT] code=\(exitCode)  duration=\(String(format: "%.1f", duration))s"
            )
            #endif

            if buffers.sawToolRequest {
                // Already finished with `unexpectedToolUse` at detection time; this keeps the
                // reason visible in the debug log and is a no-op on the continuation.
                context.continuation.finish(throwing: GitHubCopilotError.unexpectedToolUse)
            } else if exitCode != 0, !context.wasCancelled {
                context.continuation.finish(
                    throwing: parseGitHubCopilotError(fromStdout: controlBuffer, stderr: stderrBuffer)
                )
            } else if !buffers.didYieldText, !context.wasCancelled {
                // No delta arrived, so this CLI build no longer streams incrementally. Fall back
                // to the complete message text instead of returning an empty success, which would
                // surface as an unrelated "no result" error.
                let fallback = buffers.controlLines
                    .lazy
                    .compactMap { extractMessageContent(from: $0, decoder: context.decoder) }
                    .first { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                if let fallback {
                    context.continuation.yield(fallback)
                }
                context.continuation.finish()
            } else {
                // Success, or a user-initiated cancellation: finish cleanly.
                context.continuation.finish()
            }
        }
    }

    /// Drains newline-terminated lines from `buffers.stdoutData`, yielding text deltas to
    /// `continuation` and retaining non-delta lines in `buffers.controlLines`.
    ///
    /// A tool request ends the stream immediately: the isolation flags should make one
    /// impossible, so the safest response is to stop forwarding model output at once rather
    /// than let a possibly agentic run continue. Text already forwarded cannot be retracted —
    /// the base class accumulates what it received — so the caller surfaces the error instead
    /// of presenting the response as a valid translation.
    ///
    /// Splits on the 0x0A byte, which is safe because newline is a single byte in UTF-8.
    private static func flushLines(
        buffers: GitHubCopilotOutputBuffers,
        includeRemainder: Bool = false,
        decoder: JSONDecoder,
        continuation: AsyncThrowingStream<String, Error>.Continuation
    ) {
        func handle(_ lineData: Data) {
            guard let line = String(data: lineData, encoding: .utf8), !line.isEmpty else { return }
            if buffers.sawToolRequest { return }
            if toolRequestCount(from: line) > 0 {
                buffers.sawToolRequest = true
                buffers.controlLines.append(line)
                continuation.finish(throwing: GitHubCopilotError.unexpectedToolUse)
                return
            }
            if let delta = extractMessageDelta(from: line, decoder: decoder) {
                buffers.didYieldText = true
                continuation.yield(delta)
            } else {
                buffers.controlLines.append(line)
            }
        }

        var readHead = buffers.stdoutData.startIndex
        while let newlineIdx = buffers.stdoutData[readHead...].firstIndex(of: 0x0A) {
            handle(buffers.stdoutData[readHead ..< newlineIdx])
            readHead = buffers.stdoutData.index(after: newlineIdx)
        }
        buffers.stdoutData = readHead < buffers.stdoutData.endIndex
            ? Data(buffers.stdoutData[readHead...])
            : Data()

        if includeRemainder, !buffers.stdoutData.isEmpty {
            handle(buffers.stdoutData)
            buffers.stdoutData = Data()
        }
    }

    /// Appends `data` to `buffer`, capping the total at 1 MB by keeping the most recent suffix.
    private static func appendCapped(_ data: Data, to buffer: inout Data) {
        let maxSize = 1_048_576 // 1 MB
        buffer.append(data)
        if buffer.count > maxSize {
            buffer = Data(buffer.suffix(maxSize))
        }
    }

    /// Returns the path to the first `copilot` binary found on this machine.
    ///
    /// The result is cached after the first success, and revalidated on every call so an
    /// uninstall or upgrade is detected. The lock is held across the slow path so concurrent
    /// first-time callers do not each spawn a login shell.
    ///
    /// - Throws: `GitHubCopilotError.notInstalled` if no binary is found.
    private static func detectCopilotBinary() throws -> String {
        cacheLock.lock()
        defer { cacheLock.unlock() }

        if let cached = cachedBinaryPath {
            if FileManager.default.isExecutableFile(atPath: cached) {
                return cached
            }
            cachedBinaryPath = nil
        }

        var resolvedPath: String?

        // GUI apps do not inherit the user's shell PATH, so probe through a login shell first.
        // Login scripts can emit banners before the real output, so accept only the first line
        // that is named `copilot` and points at an executable.
        if let raw = runViaLoginShell("which copilot") {
            resolvedPath = raw
                .components(separatedBy: "\n")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .first {
                    !$0.isEmpty
                        && URL(fileURLWithPath: $0).lastPathComponent == "copilot"
                        && FileManager.default.isExecutableFile(atPath: $0)
                }
        }

        if resolvedPath == nil {
            let candidates = [
                "/opt/homebrew/bin/copilot",
                "/usr/local/bin/copilot",
                "\(NSHomeDirectory())/.local/bin/copilot",
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
        throw GitHubCopilotError.notInstalled
    }

    /// Reads `isCancelled` thread-safely.
    private func checkIsCancelled() -> Bool {
        stateLock.withLock { isCancelled }
    }

    /// Atomically checks `isCancelled` and assigns `process`, closing the race window that a
    /// separate check and assignment would leave open against `cancel()`.
    private func setProcessIfNotCancelled(_ newProcess: Process) -> Bool {
        stateLock.withLock {
            guard !isCancelled else { return false }
            process = newProcess
            return true
        }
    }
}

extension GitHubCopilotRunner {
    /// Returns the detected `copilot` binary path, or `nil` if not found.
    ///
    /// Used by the configuration view status row.
    static func detectBinaryPath() -> String? {
        try? detectCopilotBinary()
    }
}

// MARK: - GitHubCopilotTerminationContext

/// Everything the termination handler needs to finalize one invocation.
///
/// Grouped into a type because the handler needs more values than a lint-friendly parameter list
/// allows, and the group is only ever constructed and consumed as a unit.
private struct GitHubCopilotTerminationContext {
    let stdoutPipe: Pipe
    let stderrPipe: Pipe
    let sandbox: GitHubCopilotRunner.Sandbox
    let startTime: Date
    let wasCancelled: Bool
    let logger: GitHubCopilotLogger?
    let buffers: GitHubCopilotOutputBuffers
    let decoder: JSONDecoder
    let continuation: AsyncThrowingStream<String, Error>.Continuation
    let usageSink: (GitHubCopilotUsage?) -> ()
}

// MARK: - GitHubCopilotOutputBuffers

/// Mutable stdout/stderr accumulation for one invocation.
///
/// Shared between the readability handlers and the termination handler. Every access happens on
/// `GitHubCopilotRunner.ioQueue`, which is serial, so no additional locking is required.
private final class GitHubCopilotOutputBuffers: @unchecked Sendable {
    /// Non-delta stdout lines retained for post-exit usage and error parsing.
    var controlLines: [String] = []
    /// Incomplete stdout bytes carried between reads; buffered as `Data` so a multi-byte UTF-8
    /// character split across reads is not dropped.
    var stdoutData = Data()
    /// Raw stderr bytes, decoded once after exit.
    var stderrData = Data()
    /// Set when the CLI reports a tool request, which the isolation flags should prevent.
    var sawToolRequest = false
    /// Whether any text delta was forwarded; a run without deltas falls back to the
    /// complete `assistant.message` text if the CLI stopped streaming incrementally.
    var didYieldText = false
}
