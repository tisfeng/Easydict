//
//  CodexManagedAppServerProcess.swift
//  Easydict
//
//  Created by Alfred on 2026/09/14.
//

import Foundation

/// Owns one long-lived Codex App Server process and its JSONL transport.
/// Protocol interpretation stays in `CodexManagedAppServer`; this type only
/// frames stdout, bounds diagnostic buffers and serializes stdin writes.
final class CodexManagedAppServerProcess: @unchecked Sendable {
    // MARK: Lifecycle

    init(runtime: CodexManagedRuntime) {
        self.runtime = runtime
    }

    deinit {
        terminate()
    }

    // MARK: Internal

    let identifier = UUID()

    func start(
        messageReceived: @escaping @Sendable (Data) -> (),
        terminated: @escaping @Sendable (Data) -> ()
    ) throws {
        let context = Context()
        let process = Process()
        process.executableURL = runtime.executable
        process.arguments = runtime.appServerArguments()
        process.environment = CodexManagedRuntime.environment(
            home: runtime.home,
            codexHome: runtime.codexHome,
            executable: runtime.executable
        )
        process.currentDirectoryURL = runtime.workingDirectory
        process.standardInput = context.stdinPipe
        process.standardOutput = context.stdoutPipe
        process.standardError = context.stderrPipe
        self.messageReceived = messageReceived
        terminationReceived = terminated
        self.context = context

        context.stdoutPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }
            self?.ioQueue.async { [weak self] in self?.appendStdout(data) }
        }
        context.stderrPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }
            self?.ioQueue.async { [weak self] in self?.appendStderr(data) }
        }
        process.terminationHandler = { [weak self] process in
            self?.finish(process)
        }

        try stateLock.withLock {
            guard self.process == nil else { throw CodexManagedError.invalidResponse }
            self.process = process
        }
        do {
            try process.run()
        } catch {
            stateLock.withLock { self.process = nil }
            context.stdoutPipe.fileHandleForReading.readabilityHandler = nil
            context.stderrPipe.fileHandleForReading.readabilityHandler = nil
            throw error
        }
    }

    func send(_ message: [String: Any]) throws {
        var data = try JSONSerialization.data(withJSONObject: message)
        data.append(0x0A)
        let handle = try stateLock.withLock { () -> FileHandle in
            guard process?.isRunning == true, let context else {
                throw CodexManagedError.invalidResponse
            }
            return context.stdinPipe.fileHandleForWriting
        }
        try writeLock.withLock {
            try handle.write(contentsOf: data)
        }
    }

    func terminate() {
        let current = stateLock.withLock { () -> Process? in
            let current = process
            process = nil
            return current
        }
        try? context?.stdinPipe.fileHandleForWriting.close()
        if current?.isRunning == true { current?.terminate() }
    }

    // MARK: Private

    private final class Context: @unchecked Sendable {
        let stdinPipe = Pipe()
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        var stdoutBuffer = Data()
        var stderrBuffer = Data()
    }

    private static let maximumLineSize = 4 * 1024 * 1024
    private static let maximumStderrSize = 1024 * 1024

    private let runtime: CodexManagedRuntime
    private let stateLock = NSLock()
    private let writeLock = NSLock()
    private let ioQueue = DispatchQueue(
        label: "com.easydict.codex-managed-app-server-io",
        qos: .userInitiated
    )
    private var process: Process?
    private var context: Context?
    private var messageReceived: (@Sendable (Data) -> ())?
    private var terminationReceived: (@Sendable (Data) -> ())?

    private func appendStdout(_ data: Data) {
        guard let context else { return }
        context.stdoutBuffer.append(data)
        guard context.stdoutBuffer.count <= Self.maximumLineSize else {
            terminate()
            return
        }
        drainStdout(context, includeRemainder: false)
    }

    private func drainStdout(_ context: Context, includeRemainder: Bool) {
        var readHead = context.stdoutBuffer.startIndex
        while let newline = context.stdoutBuffer[readHead...].firstIndex(of: 0x0A) {
            let line = Data(context.stdoutBuffer[readHead ..< newline])
            if !line.isEmpty { messageReceived?(line) }
            readHead = context.stdoutBuffer.index(after: newline)
        }
        context.stdoutBuffer = readHead < context.stdoutBuffer.endIndex
            ? Data(context.stdoutBuffer[readHead...])
            : Data()
        if includeRemainder, !context.stdoutBuffer.isEmpty {
            messageReceived?(context.stdoutBuffer)
            context.stdoutBuffer = Data()
        }
    }

    private func appendStderr(_ data: Data) {
        guard let context else { return }
        context.stderrBuffer.append(data)
        if context.stderrBuffer.count > Self.maximumStderrSize {
            context.stderrBuffer = Data(context.stderrBuffer.suffix(Self.maximumStderrSize))
        }
    }

    private func finish(_ terminatedProcess: Process) {
        guard let context else { return }
        context.stdoutPipe.fileHandleForReading.readabilityHandler = nil
        context.stderrPipe.fileHandleForReading.readabilityHandler = nil
        ioQueue.sync {}
        let remainingStdout = context.stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        let remainingStderr = context.stderrPipe.fileHandleForReading.readDataToEndOfFile()
        ioQueue.async { [weak self] in
            guard let self else { return }
            if !remainingStdout.isEmpty { context.stdoutBuffer.append(remainingStdout) }
            drainStdout(context, includeRemainder: true)
            if !remainingStderr.isEmpty { appendStderr(remainingStderr) }
            stateLock.withLock {
                if self.process === terminatedProcess { self.process = nil }
            }
            terminationReceived?(context.stderrBuffer)
        }
    }
}
