//
//  QueryModelCancellationTests.swift
//  EasydictTests
//
//  Created by tisfeng on 2026/10/22.
//

import Foundation
import Testing

@testable import Easydict

// MARK: - QueryModelCancellationTests

/// Exercises the synchronous cancellation API shared by service tasks and UI callers.
@Suite("Query Model Cancellation", .tags(.unit))
struct QueryModelCancellationTests {
    // MARK: Internal

    @Test("Replacing or clearing a registration does not invoke it")
    func registrationReplacementAndRemoval() {
        let model = QueryModel()
        let calls = CallCounts()
        #expect(model.isServiceStopped("service"))
        model.setStop({ calls.record("old") }, serviceType: "service")
        #expect(!model.isServiceStopped("service"))
        model.setStop({ calls.record("replacement") }, serviceType: "service")
        #expect(calls.snapshot.isEmpty)
        model.stopServiceRequest("service")
        #expect(calls.snapshot == ["replacement": 1])
        model.setStop({ calls.record("cleared") }, serviceType: "service")
        model.setStop(nil, serviceType: "service")
        #expect(model.isServiceStopped("service"))
        model.stopAllService()
        #expect(calls.snapshot == ["replacement": 1])
    }

    @Test("Stopping removes the registration before invoking its callback")
    func singleStopPreservesReentrantRegistration() {
        let model = QueryModel()
        let calls = CallCounts()
        model.setStop({
            #expect(model.isServiceStopped("service"))
            calls.record("old")
            model.setStop({ calls.record("new") }, serviceType: "service")
        }, serviceType: "service")

        model.stopServiceRequest("service")
        #expect(calls.snapshot == ["old": 1])
        #expect(!model.isServiceStopped("service"))
        model.stopServiceRequest("service")
        model.stopServiceRequest("service")
        #expect(model.isServiceStopped("service"))
        #expect(calls.snapshot == ["old": 1, "new": 1])
    }

    @Test("Stopping all services drains the snapshot before invoking callbacks")
    func stopAllPreservesReentrantRegistrations() {
        let model = QueryModel()
        let calls = CallCounts()
        let services = ["DeepL", "Google", "Bing"]
        for service in services {
            model.setStop({
                // The first callback must see every original registration already removed.
                if calls.snapshot.isEmpty {
                    #expect(services.allSatisfy { model.isServiceStopped($0) })
                    model.stopAllService()
                }
                calls.record(service)
                model.setStop({ calls.record("new-\(service)") }, serviceType: service)
            }, serviceType: service)
        }

        model.stopAllService()
        #expect(calls.snapshot == ["DeepL": 1, "Google": 1, "Bing": 1])
        #expect(services.allSatisfy { !model.isServiceStopped($0) })
        model.stopAllService()
        model.stopAllService()
        #expect(calls.snapshot.count == 6)
        #expect(calls.snapshot.values.allSatisfy { $0 == 1 })
        #expect(services.allSatisfy { model.isServiceStopped($0) })
    }

    @Test("Concurrent individual and bulk stops invoke a registration only once")
    func concurrentStopsInvokeCallbackOnce() {
        let model = QueryModel()
        let calls = CallCounts()
        model.setStop({ calls.record("service") }, serviceType: "service")

        DispatchQueue.concurrentPerform(iterations: 128) { index in
            if index.isMultiple(of: 2) {
                model.stopServiceRequest("service")
            } else {
                model.stopAllService()
            }
        }

        #expect(calls.snapshot == ["service": 1])
        #expect(model.isServiceStopped("service"))
    }

    @Test("Concurrent services can register, read, replace, clear and stop independently")
    func concurrentServiceRegistrations() {
        let model = QueryModel()
        let calls = CallCounts()
        let iterations = 1000

        DispatchQueue.concurrentPerform(iterations: iterations) { index in
            let service = "service-\(index)"
            model.setStop({ calls.record("replaced-\(index)") }, serviceType: service)
            #expect(!model.isServiceStopped(service))
            model.setStop({ calls.record(service) }, serviceType: service)
            if index.isMultiple(of: 2) {
                model.setStop(nil, serviceType: service)
            }
            model.stopServiceRequest(service)
            #expect(model.isServiceStopped(service))
        }

        model.stopAllService()
        let expected = Dictionary(uniqueKeysWithValues: (0 ..< iterations)
            .filter { !$0.isMultiple(of: 2) }
            .map { ("service-\($0)", 1) })
        #expect(calls.snapshot == expected)
    }

    @Test("Registrations racing with bulk stops are each cancelled exactly once")
    func concurrentRegistrationAndBulkStop() {
        let model = QueryModel()
        let calls = CallCounts()
        let iterations = 1000

        DispatchQueue.concurrentPerform(iterations: iterations) { index in
            let service = "service-\(index)"
            model.setStop({ calls.record(service) }, serviceType: service)
            _ = model.isServiceStopped(service)
            if index.isMultiple(of: 3) {
                model.stopAllService()
            } else {
                model.stopServiceRequest(service)
            }
        }

        model.stopAllService()
        let expected = Dictionary(uniqueKeysWithValues: (0 ..< iterations).map { ("service-\($0)", 1) })
        #expect(calls.snapshot == expected)
        #expect((0 ..< iterations).allSatisfy { model.isServiceStopped("service-\($0)") })
    }

    @Test("Releasing replaced or cleared captures can reenter the model", arguments: [false, true])
    func releasedCaptureCanReenter(replace: Bool) {
        let model = QueryModel()
        let calls = CallCounts()
        installReentrantCapture(on: model, calls: calls)
        #expect(calls.snapshot.isEmpty)
        if replace {
            model.setStop({ calls.record("replacement") }, serviceType: "service")
        } else {
            model.setStop(nil, serviceType: "service")
        }

        #expect(calls.snapshot == ["released": 1])
        #expect(!model.isServiceStopped("from-release"))
        model.stopAllService()
        #expect(calls.snapshot["from-release"] == 1)
        #expect(calls.snapshot["replacement"] == (replace ? 1 : nil))
    }

    // MARK: Private

    /// Keeps test observations independent from the model's synchronization.
    private final class CallCounts {
        // MARK: Internal

        var snapshot: [String: Int] { lock.withLock { counts } }

        func record(_ key: String) {
            lock.withLock { counts[key, default: 0] += 1 }
        }

        // MARK: Private

        private let lock = NSLock()
        private var counts: [String: Int] = [:]
    }

    private final class ReleaseAction {
        // MARK: Lifecycle

        init(_ action: @escaping () -> ()) {
            self.action = action
        }

        deinit { action() }

        // MARK: Private

        private let action: () -> ()
    }

    private func installReentrantCapture(on model: QueryModel, calls: CallCounts) {
        let capture = ReleaseAction {
            calls.record("released")
            model.setStop({ calls.record("from-release") }, serviceType: "from-release")
        }
        model.setStop({ withExtendedLifetime(capture) {} }, serviceType: "service")
    }
}
