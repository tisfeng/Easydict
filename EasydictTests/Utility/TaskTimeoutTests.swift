//
//  TaskTimeoutTests.swift
//  EasydictTests
//
//  Created by tisfeng on 2026/4/12.
//

import Foundation
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

    @Test("Returns after timeout without waiting for blocking work", .tags(.utilities, .unit))
    func returnsAfterTimeoutWithoutWaitingForBlockingWork() async {
        let clock = ContinuousClock()
        let start = clock.now

        await #expect(throws: TaskTimeoutError.self) {
            try await Task.withTimeout(seconds: 0.01) {
                usleep(300_000)
                return "late"
            }
        }

        let elapsed = start.duration(to: clock.now)
        #expect(elapsed < .milliseconds(200))
    }

    @Test("Throws timeout immediately when duration is zero or negative", .tags(.utilities, .unit))
    func throwsTimeoutImmediatelyWhenDurationIsZeroOrNegative() async {
        await #expect(throws: TaskTimeoutError.self) {
            try await Task.withTimeout(seconds: 0) {
                "done"
            }
        }

        await #expect(throws: TaskTimeoutError.self) {
            try await Task.withTimeout(seconds: -1) {
                "done"
            }
        }
    }
}

// MARK: - SampleError

private enum SampleError: Error {
    case failed
}
