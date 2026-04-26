//
//  Task+Timeout.swift
//  Easydict
//
//  Created by tisfeng on 2026/4/12.
//

import Foundation

// MARK: - TaskTimeoutError

/// An error that indicates a task exceeded the provided timeout duration.
struct TaskTimeoutError: Error, Equatable {}

// MARK: - Task Timeout Extension

extension Task where Success == Never, Failure == Never {
    /// Runs an asynchronous operation and fails if it does not complete before the timeout expires.
    ///
    /// This helper does not use a throwing task group. Instead, it races the operation and timeout
    /// on separate tasks, resumes the caller as soon as one side finishes, and cancels the losing
    /// side in the background without waiting for it to unwind first.
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
        let normalizedSeconds = max(seconds, 0)
        guard normalizedSeconds > 0 else {
            throw TaskTimeoutError()
        }

        let operationTask = Task<T, Error> {
            try await operation()
        }
        let timeoutTask = Task<(), Error> {
            try await Task.sleepThrowing(seconds: normalizedSeconds)
            throw TaskTimeoutError()
        }

        return try await withCheckedThrowingContinuation { continuation in
            let continuationActor = TimeoutContinuationActor(continuation)

            // These two detached watchers wait on opposite sides of the race:
            // one watches the operation result, the other watches the timeout result.
            // Whichever side finishes first resumes the caller and cancels the loser.
            // Use detached tasks so timeout delivery does not inherit a blocked caller actor.
            Swift.Task.detached {
                do {
                    let value = try await operationTask.value
                    await continuationActor.resume(with: .success(value))
                    timeoutTask.cancel()
                } catch {
                    await continuationActor.resume(with: .failure(error))
                    timeoutTask.cancel()
                }
            }

            Swift.Task.detached {
                do {
                    try await timeoutTask.value
                } catch is CancellationError {
                    // The operation completed first, so the timeout watcher was cancelled on purpose.
                } catch {
                    await continuationActor.resume(with: .failure(error))
                    operationTask.cancel()
                }
            }
        }
    }
}

// MARK: - TimeoutContinuationActor

/// Coordinates a single completion result for `Task.withTimeout`.
///
/// The timeout watcher and operation watcher race on separate detached tasks. This actor ensures the
/// checked continuation is resumed exactly once, even if both watchers complete almost simultaneously.
private actor TimeoutContinuationActor<T: Sendable> {
    // MARK: Lifecycle

    init(_ continuation: CheckedContinuation<T, Error>) {
        self.continuation = continuation
    }

    // MARK: Internal

    /// Resumes the stored continuation at most once.
    ///
    /// - Parameter result: The first race result to deliver.
    func resume(with result: Result<T, Error>) {
        guard let continuation else {
            return
        }

        self.continuation = nil
        continuation.resume(with: result)
    }

    // MARK: Private

    private var continuation: CheckedContinuation<T, Error>?
}
