//
//  ThrottleGate.swift
//  Easydict
//
//  Created by tisfeng on 2026/3/22.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation

// MARK: - ThrottleGate

/// A synchronous throttle gate for event handling.
/// Use `Throttler` when you need delayed block execution instead.
struct ThrottleGate {
    // MARK: Lifecycle

    init(
        interval: TimeInterval,
        now: @escaping () -> TimeInterval = { ProcessInfo.processInfo.systemUptime }
    ) {
        self.interval = interval
        self.now = now
    }

    // MARK: Internal

    let interval: TimeInterval

    mutating func shouldAllow() -> Bool {
        let currentTime = now()
        guard let lastAllowedTime else {
            self.lastAllowedTime = currentTime
            return true
        }

        guard currentTime - lastAllowedTime >= interval else { return false }
        self.lastAllowedTime = currentTime
        return true
    }

    mutating func reset() {
        lastAllowedTime = nil
    }

    // MARK: Private

    private let now: () -> TimeInterval
    private var lastAllowedTime: TimeInterval?
}
