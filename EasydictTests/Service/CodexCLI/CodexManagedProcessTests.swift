//
//  CodexManagedProcessTests.swift
//  EasydictTests
//
//  Created by Alfred on 2026/09/07.
//

@testable import Easydict
import Foundation
import Testing

// MARK: - CodexManagedProcessTests

@Suite("Codex managed process")
struct CodexManagedProcessTests {
    @Test("drains long stdin and simultaneous stdout and stderr")
    func drainsAllPipesWithoutTruncatingInput() async throws {
        let input = Data(repeating: 0x61, count: 1_048_576)
        let received = DataCollector()
        let output = try await runPython(
            "import sys; data = sys.stdin.buffer.read(); sys.stdout.buffer.write(data); sys.stderr.buffer.write(b'e' * 262144)",
            input: input,
            stderrReceived: { received.append($0) }
        )

        #expect(output.exitCode == 0)
        #expect(output.stdout == input)
        #expect(output.stderr.count == 262_144)
        #expect(received.data == output.stderr)
    }

    @Test("returns timeout after stopping the owned process group")
    func timesOutLongRunningCommand() async throws {
        await #expect(throws: CodexManagedError.timeout) {
            try await runPython("import time; time.sleep(10)", timeout: 0.1)
        }
    }

    @Test("cancellation stops a child that inherits the root process group")
    func cancellationStopsDescendant() async throws {
        try await withTemporaryDirectory { directory in
            let marker = directory.appendingPathComponent("cancelled-child")
            let process = CodexManagedProcess()
            let task = Task {
                try await process.run(
                    executable: URL(fileURLWithPath: "/bin/sh"),
                    arguments: ["-c", "(sleep 1; echo leaked > \"$0\") & wait", marker.path],
                    environment: processEnvironment,
                    workingDirectory: directory,
                    timeout: 5
                )
            }

            try await Task.sleep(for: .milliseconds(150))
            process.cancel()
            await #expect(throws: CancellationError.self) { try await task.value }
            try await Task.sleep(for: .milliseconds(1_100))
            #expect(!FileManager.default.fileExists(atPath: marker.path))
        }
    }

    @Test("cancelling one invocation leaves another process group running")
    func cancellationDoesNotStopAnotherProcess() async throws {
        try await withTemporaryDirectory { directory in
            let cancelledMarker = directory.appendingPathComponent("cancelled")
            let completedMarker = directory.appendingPathComponent("completed")
            let cancelledProcess = CodexManagedProcess()
            let completedProcess = CodexManagedProcess()
            let cancelledTask = Task {
                try await shellMarkerProcess(cancelledProcess, marker: cancelledMarker, delay: 1, directory: directory)
            }
            let completedTask = Task {
                try await shellMarkerProcess(
                    completedProcess,
                    marker: completedMarker,
                    delay: 0.4,
                    directory: directory
                )
            }

            try await Task.sleep(for: .milliseconds(150))
            cancelledProcess.cancel()
            await #expect(throws: CancellationError.self) { try await cancelledTask.value }
            let completed = try await completedTask.value

            #expect(completed.exitCode == 0)
            #expect(!FileManager.default.fileExists(atPath: cancelledMarker.path))
            #expect(FileManager.default.fileExists(atPath: completedMarker.path))
        }
    }

    @Test("cleans a pipe-owning descendant after its root exits")
    func cleansDescendantAfterRootExit() async throws {
        try await withTemporaryDirectory { directory in
            let marker = directory.appendingPathComponent("orphan")
            let output = try await runShell(
                "(sleep 1; echo leaked > \"$0\") & exit 0",
                arguments: [marker.path],
                directory: directory,
                timeout: 3
            )

            #expect(output.exitCode == 0)
            try await Task.sleep(for: .milliseconds(1_100))
            #expect(!FileManager.default.fileExists(atPath: marker.path))
        }
    }

    @Test("waits through the SIGKILL grace period when a detached-output child ignores TERM")
    func killsTermIgnoringDescendantAfterRootExit() async throws {
        try await withTemporaryDirectory { directory in
            let marker = directory.appendingPathComponent("term-ignoring-orphan")
            let ready = directory.appendingPathComponent("term-ignoring-orphan-ready")
            let output = try await runShell(
                "(exec 3>\"$1\"; trap '' TERM; exec </dev/null >/dev/null 2>/dev/null; echo ready >&3; exec 3>&-; sleep 1; echo leaked > \"$0\") & while [ ! -e \"$1\" ]; do sleep 0.01; done; exit 0",
                arguments: [marker.path, ready.path],
                directory: directory,
                timeout: 3
            )

            #expect(output.exitCode == 0)
            try await Task.sleep(for: .milliseconds(1_100))
            #expect(!FileManager.default.fileExists(atPath: marker.path))
        }
    }

    @Test("cancellation reaches a detached-output child that ignores TERM")
    func cancellationKillsTermIgnoringDescendant() async throws {
        try await withTemporaryDirectory { directory in
            let marker = directory.appendingPathComponent("term-ignoring-cancelled")
            let ready = directory.appendingPathComponent("term-ignoring-ready")
            let process = CodexManagedProcess()
            let task = Task {
                try await runShell(
                    "(trap '' TERM; echo ready > \"$1\"; exec </dev/null >/dev/null 2>/dev/null; sleep 1; echo leaked > \"$0\") & wait",
                    arguments: [marker.path, ready.path],
                    directory: directory,
                    process: process
                )
            }
            try await waitForFile(ready)

            process.cancel()
            await #expect(throws: CancellationError.self) { try await task.value }
            try await Task.sleep(for: .milliseconds(1_100))
            #expect(!FileManager.default.fileExists(atPath: marker.path))
        }
    }

    @Test("fails before retaining output over the bounded limit")
    func rejectsOversizedOutput() async throws {
        await #expect(throws: CodexManagedError.outputTooLarge) {
            try await runPython("import sys; sys.stdout.buffer.write(b'x' * (5 * 1024 * 1024))", timeout: 5)
        }
    }

    @Test("returns captured output for a nonzero command exit")
    func preservesOutputForNonzeroExit() async throws {
        let output =
            try await runPython("import sys; sys.stdout.write('out'); sys.stderr.write('err'); raise SystemExit(7)")

        #expect(output.exitCode == 7)
        #expect(String(decoding: output.stdout, as: UTF8.self) == "out")
        #expect(String(decoding: output.stderr, as: UTF8.self) == "err")
    }
}

private let processEnvironment = ["PATH": "/usr/bin:/bin"]

private func runPython(
    _ script: String,
    input: Data = Data(),
    timeout: TimeInterval = 5,
    stderrReceived: (@Sendable (Data) -> ())? = nil
) async throws
    -> CodexManagedProcess.Output {
    try await CodexManagedProcess().run(
        executable: URL(fileURLWithPath: "/usr/bin/python3"),
        arguments: ["-c", script],
        environment: processEnvironment,
        workingDirectory: FileManager.default.temporaryDirectory,
        input: input,
        timeout: timeout,
        stderrReceived: stderrReceived
    )
}

private func shellMarkerProcess(
    _ process: CodexManagedProcess,
    marker: URL,
    delay: Double,
    directory: URL
) async throws
    -> CodexManagedProcess.Output {
    try await runShell(
        "sleep $1; echo done > \"$0\"",
        arguments: [marker.path, String(delay)],
        directory: directory,
        process: process
    )
}

private func runShell(
    _ script: String,
    arguments: [String],
    directory: URL,
    timeout: TimeInterval = 5,
    process: CodexManagedProcess = CodexManagedProcess()
) async throws
    -> CodexManagedProcess.Output {
    try await process.run(
        executable: URL(fileURLWithPath: "/bin/sh"),
        arguments: ["-c", script] + arguments,
        environment: processEnvironment,
        workingDirectory: directory,
        timeout: timeout
    )
}

private func withTemporaryDirectory<T: Sendable>(
    _ body: (URL) async throws -> T
) async throws
    -> T {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    return try await body(directory)
}

private func waitForFile(_ url: URL, timeout: TimeInterval = 3) async throws {
    let deadline = Date().addingTimeInterval(timeout)
    while !FileManager.default.fileExists(atPath: url.path) {
        guard Date() < deadline else { throw ProcessTestTimeout() }
        try await Task.sleep(for: .milliseconds(10))
    }
}

// MARK: - ProcessTestTimeout

private struct ProcessTestTimeout: Error {}

// MARK: - DataCollector

private final class DataCollector: @unchecked Sendable {
    // MARK: Internal

    var data: Data { lock.withLock { storage } }

    func append(_ chunk: Data) {
        lock.withLock { storage.append(chunk) }
    }

    // MARK: Private

    private let lock = NSLock()
    private var storage = Data()
}
