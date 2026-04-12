//
//  TaskTimeoutTests.swift
//  EasydictTests
//
//  Created by Codex on 2026/4/12.
//

import Testing

@testable import Easydict

// MARK: - TaskTimeoutTests

@Suite("Task Timeout", .tags(.utilities, .unit))
struct TaskTimeoutTests {
    @Test("Returns operation result before timeout", .tags(.utilities, .unit))
    func returnsOperationResultBeforeTimeout() async throws {
        let result = try await Task.withTimeout(seconds: 1) {
            try await Task.sleepThrowing(seconds: 0.01)
            return "done"
        }

        #expect(result == "done")
    }

    @Test("Throws timeout error when timeout elapses first", .tags(.utilities, .unit))
    func throwsTimeoutErrorWhenTimeoutElapsesFirst() async {
        await #expect(throws: TaskTimeoutError.self) {
            try await Task.withTimeout(seconds: 0.01) {
                try await Task.sleepThrowing(seconds: 1)
                return "late"
            }
        }
    }

    @Test("Propagates operation error without wrapping", .tags(.utilities, .unit))
    func propagatesOperationErrorWithoutWrapping() async {
        await #expect(throws: SampleError.self) {
            try await Task.withTimeout(seconds: 1) {
                throw SampleError.failed
            }
        }
    }
}

// MARK: - SampleError

private enum SampleError: Error {
    case failed
}
