//
//  Task+Extension.swift
//  Easydict
//
//  Created by tisfeng on 2025/9/3.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

// MARK: - Task Extensions

extension Task where Success == Never, Failure == Never {
    /// Sleep for given seconds within a Task
    static func sleep(seconds: TimeInterval) async {
        try? await Task.sleepThrowing(seconds: seconds)
    }

    /// Sleep for given seconds within a Task, throwing an error if cancelled
    static func sleepThrowing(seconds: TimeInterval) async throws {
        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
}
