//
//  CodexManagedProcess.swift
//  Easydict
//
//  Created by Alfred on 2026/09/07.
//

import Darwin
import Foundation

/// Executes one managed command in its own process group with bounded pipe I/O.
/// Cancellation, timeout and root exit clean up only this invocation's descendants;
/// the external CLI runner retains its existing launch and environment behavior.
final class CodexManagedProcess: @unchecked Sendable {
    // MARK: Internal

    /// Captures the completed command without exposing authentication output to logs.
    struct Output: Sendable {
        let exitCode: Int32
        let stdout: Data
        let stderr: Data
    }

    func run(
        executable: URL,
        arguments: [String],
        environment: [String: String],
        workingDirectory: URL,
        input: Data = Data(),
        timeout: TimeInterval,
        stderrReceived: (@Sendable (Data) -> ())? = nil
    ) async throws
        -> Output {
        try await withTaskCancellationHandler {
            try await Task.detached(priority: .userInitiated) { [self] in
                try execute(
                    executable: executable,
                    arguments: arguments,
                    environment: environment,
                    workingDirectory: workingDirectory,
                    input: input,
                    timeout: timeout,
                    stderrReceived: stderrReceived
                )
            }.value
        } onCancel: {
            self.cancel()
        }
    }

    func cancel() {
        lock.withLock {
            cancelled = true
            if processID > 0 { kill(-processID, SIGTERM) }
        }
    }

    // MARK: Private

    private let lock = NSLock()
    private var cancelled = false
    private var processID: pid_t = 0
    private let outputLimit = 4 * 1024 * 1024

    /// Uses posix_spawn's process-group attribute to avoid the setpgid-after-launch
    /// race. A single polling loop writes stdin while draining both output streams.
    private func execute(
        executable: URL, arguments: [String], environment: [String: String],
        workingDirectory: URL,
        input: Data, timeout: TimeInterval, stderrReceived: (@Sendable (Data) -> ())?
    ) throws
        -> Output {
        var descriptors: [Int32] = []
        defer { for descriptor in descriptors where descriptor >= 0 { close(descriptor) } }
        for _ in 0 ..< 3 {
            var ends: [Int32] = [0, 0]
            guard pipe(&ends) == 0 else { throw POSIXError(.EMFILE) }
            for descriptor in ends { _ = fcntl(descriptor, F_SETFD, FD_CLOEXEC) }
            descriptors += ends
        }
        var actions: posix_spawn_file_actions_t?
        var attributes: posix_spawnattr_t?
        posix_spawn_file_actions_init(&actions)
        posix_spawnattr_init(&attributes)
        defer {
            posix_spawn_file_actions_destroy(&actions)
            posix_spawnattr_destroy(&attributes)
        }
        posix_spawn_file_actions_adddup2(&actions, descriptors[0], STDIN_FILENO)
        posix_spawn_file_actions_adddup2(&actions, descriptors[3], STDOUT_FILENO)
        posix_spawn_file_actions_adddup2(&actions, descriptors[5], STDERR_FILENO)
        posix_spawn_file_actions_addchdir_np(&actions, workingDirectory.path)
        for descriptor in descriptors { posix_spawn_file_actions_addclose(&actions, descriptor) }
        posix_spawnattr_setflags(&attributes, Int16(POSIX_SPAWN_SETPGROUP))
        posix_spawnattr_setpgroup(&attributes, 0)

        var argv = ([executable.path] + arguments).map { strdup($0) } + [nil]
        var envp = environment.sorted { $0.key < $1.key }.map { strdup("\($0.key)=\($0.value)") } + [nil]
        defer {
            for pointer in argv { free(pointer) }
            for pointer in envp { free(pointer) }
        }
        var child: pid_t = 0
        try lock.withLock {
            if cancelled { throw CancellationError() }
            let status = posix_spawn(&child, executable.path, &actions, &attributes, &argv, &envp)
            guard status == 0 else { throw POSIXError(POSIXErrorCode(rawValue: status) ?? .EIO) }
            processID = child
        }
        defer { lock.withLock { processID = 0 } }
        for index in [0, 3, 5] {
            close(descriptors[index])
            descriptors[index] = -1
        }
        for index in [1, 2, 4] {
            _ = fcntl(descriptors[index], F_SETFL, O_NONBLOCK)
        }
        _ = fcntl(descriptors[1], F_SETNOSIGPIPE, 1)
        return try collect(
            child: child,
            descriptors: &descriptors,
            input: input,
            timeout: timeout,
            stderrReceived: stderrReceived
        )
    }

    private func collect(
        child: pid_t, descriptors: inout [Int32], input: Data, timeout: TimeInterval,
        stderrReceived: (@Sendable (Data) -> ())?
    ) throws
        -> Output {
        let started = ProcessInfo.processInfo.systemUptime
        var stopTime: TimeInterval?
        var exited = false
        var status: Int32 = 0
        var inputOffset = 0
        var stdout = Data()
        var stderr = Data()
        var failure: Error?

        while true {
            let now = ProcessInfo.processInfo.systemUptime
            if stopTime == nil {
                if lock.withLock({ cancelled }) {
                    failure = CancellationError()
                    stopTime = now
                } else if now - started >= timeout {
                    failure = CodexManagedError.timeout
                    stopTime = now
                }
                if stopTime != nil { kill(-child, SIGTERM) }
            }
            if !exited, waitpid(child, &status, WNOHANG) == child {
                exited = true
                // The root may have exited while a descendant still owns a pipe.
                kill(-child, SIGTERM)
                if stopTime == nil { stopTime = now }
            }
            if let stopTime, now - stopTime >= 0.5 { kill(-child, SIGKILL) }
            // EOF does not imply the process group has ended: a descendant can
            // redirect both pipes and ignore TERM. Keep the grace/KILL sequence
            // until the group is gone, independently of pipe ownership.
            if exited, descriptors[2] < 0, descriptors[4] < 0,
               kill(-child, 0) == -1, errno == ESRCH { break }
            if let stopTime, now - stopTime >= 1.5 {
                kill(-child, SIGKILL)
                if !exited {
                    while waitpid(child, &status, 0) == -1, errno == EINTR {}
                }
                break
            }

            if descriptors[1] >= 0 {
                if inputOffset < input.count, stopTime == nil {
                    let count = input.withUnsafeBytes { bytes in
                        Darwin.write(
                            descriptors[1],
                            bytes.baseAddress!.advanced(by: inputOffset),
                            min(16384, input.count - inputOffset)
                        )
                    }
                    if count > 0 { inputOffset += count }
                    else if count < 0, errno != EAGAIN, errno != EINTR {
                        close(descriptors[1])
                        descriptors[1] = -1
                    }
                }
                if inputOffset == input.count || stopTime != nil {
                    close(descriptors[1])
                    descriptors[1] = -1
                }
            }

            for index in [2, 4] where descriptors[index] >= 0 {
                var buffer = [UInt8](repeating: 0, count: 16384)
                let count = Darwin.read(descriptors[index], &buffer, buffer.count)
                if count > 0 {
                    let chunk = Data(buffer.prefix(count))
                    if stdout.count + stderr.count + count > outputLimit {
                        failure = CodexManagedError.outputTooLarge
                        if stopTime == nil { stopTime = now; kill(-child, SIGTERM) }
                    } else if index == 2 {
                        stdout.append(chunk)
                    } else {
                        stderr.append(chunk)
                        stderrReceived?(chunk)
                    }
                } else if count == 0 || (errno != EAGAIN && errno != EINTR) {
                    close(descriptors[index])
                    descriptors[index] = -1
                }
            }
            var events = [
                pollfd(fd: descriptors[2], events: Int16(POLLIN), revents: 0),
                pollfd(fd: descriptors[4], events: Int16(POLLIN), revents: 0),
            ]
            if descriptors[1] >= 0 {
                events.append(pollfd(fd: descriptors[1], events: Int16(POLLOUT), revents: 0))
            }
            _ = poll(&events, nfds_t(events.count), 20)
        }
        if lock.withLock({ cancelled }) { throw CancellationError() }
        if let failure { throw failure }
        let signal = status & 0x7F
        let exitCode = signal == 0 ? (status >> 8) & 0xFF : 128 + signal
        return Output(exitCode: exitCode, stdout: stdout, stderr: stderr)
    }
}
