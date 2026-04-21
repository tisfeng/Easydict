//
//  ThrottleGateTests.swift
//  EasydictTests
//
//  Created by tisfeng on 2026/3/22.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation
import Testing

@testable import Easydict

// MARK: - ThrottleGateTests

@Suite("Throttle Gate", .tags(.utilities, .unit))
struct ThrottleGateTests {
    // MARK: Internal

    @Test("First call is allowed immediately", .tags(.utilities, .unit))
    func testFirstCallIsAllowedImmediately() {
        let clock = TestClock()
        var gate = ThrottleGate(interval: 0.1, now: { clock.now() })

        clock.currentTime = 1.25
        #expect(gate.shouldAllow() == true)
    }

    @Test("Calls within interval are suppressed", .tags(.utilities, .unit))
    func testCallsWithinIntervalAreSuppressed() {
        let clock = TestClock()
        var gate = ThrottleGate(interval: 0.1, now: { clock.now() })

        #expect(gate.shouldAllow() == true)

        clock.currentTime = 0.05
        #expect(gate.shouldAllow() == false)
    }

    @Test("Call is allowed again after interval", .tags(.utilities, .unit))
    func testCallIsAllowedAgainAfterInterval() {
        let clock = TestClock()
        var gate = ThrottleGate(interval: 0.1, now: { clock.now() })

        #expect(gate.shouldAllow() == true)

        clock.currentTime = 0.1
        #expect(gate.shouldAllow() == true)
    }

    @Test("Reset allows next call immediately", .tags(.utilities, .unit))
    func testResetAllowsNextCallImmediately() {
        let clock = TestClock()
        var gate = ThrottleGate(interval: 0.1, now: { clock.now() })

        #expect(gate.shouldAllow() == true)

        clock.currentTime = 0.05
        #expect(gate.shouldAllow() == false)

        gate.reset()
        #expect(gate.shouldAllow() == true)
    }

    @Test("Reset clears stale session state", .tags(.utilities, .unit))
    func testResetClearsStaleSessionState() {
        let clock = TestClock()
        var gate = ThrottleGate(interval: 0.1, now: { clock.now() })

        clock.currentTime = 10
        #expect(gate.shouldAllow() == true)

        clock.currentTime = 10.02
        #expect(gate.shouldAllow() == false)

        gate.reset()
        #expect(gate.shouldAllow() == true)
    }

    // MARK: Private

    private final class TestClock {
        var currentTime: TimeInterval = 0

        func now() -> TimeInterval {
            currentTime
        }
    }
}
