//
//  Task+Timeout.swift
//  Easydict
//
//  Created by Codex on 2026/4/12.
//

import Foundation

// MARK: - TaskTimeoutError

/// An error that indicates a task exceeded the provided timeout duration.
struct TaskTimeoutError: Error, Equatable {}

// MARK: - Task Timeout Extension

extension Task where Success == Never, Failure == Never {
    /// Runs an asynchronous operation and fails if it does not complete before the timeout expires.
    ///
    /// The operation and timeout watcher run concurrently in a throwing task group. The first child
    /// task to complete determines the outcome, and the remaining child task is cancelled automatically.
    ///
    /// - Parameters:
    ///   - seconds: The timeout duration in seconds.
    ///   - operation: The asynchronous operation to execute.
    /// - Returns: The value returned by `operation` when it finishes before the timeout expires.
    /// - Throws: `TaskTimeoutError` when the timeout elapses first, or any error thrown by `operation`.
    ///
    /// - Example:
    /// ```swift
    /// let value = try await Task.withTimeout(seconds: 2) {
    ///     try await fetchRemoteConfig()
    /// }
    /// ```
    ///
    /// - SeeAlso: https://github.com/swiftlang/swift-subprocess/issues/65#issuecomment-2970966110
    static func withTimeout<T: Sendable>(
        seconds: TimeInterval,
        operation: @escaping @Sendable () async throws -> T
    ) async throws
        -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }

            group.addTask {
                try await Task.sleepThrowing(seconds: max(seconds, 0))
                throw TaskTimeoutError()
            }

            defer {
                group.cancelAll()
            }

            guard let result = try await group.next() else {
                throw TaskTimeoutError()
            }

            return result
        }
    }
}
