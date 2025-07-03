//
//  SystemUtilitiesTests.swift
//  EasydictSwiftTests
//
//  Created by AI Assistant on 2025/7/3.
//  Copyright © 2024 izual. All rights reserved.
//

import SelectedTextKit
import Testing

@testable import Easydict

/// Tests for system utilities and macOS integrations
@Suite("System Utilities", .tags(.system, .integration))
struct SystemUtilitiesTests {
    @Test("Alert Volume Control", .tags(.system))
    func testAlertVolume() async throws {
        let originalVolume = try await AppleScriptTask.alertVolume()
        print("Original volume: \(originalVolume)")

        let testVolume = 50
        try await AppleScriptTask.setAlertVolume(testVolume)

        let newVolume = try await AppleScriptTask.alertVolume()
        #expect(newVolume == testVolume)

        try await AppleScriptTask.setAlertVolume(originalVolume)
        #expect(true, "Alert volume test completed")
    }

    @Test(
        "Get Selected Text",
        .tags(.system, .performance),
        .disabled("Only run manually")
    )
    func testGetSelectedText() async throws {
        // Run thousands of times to test crash.
        for i in 0 ..< 2000 {
            print("test index: \(i)")
            let selectedText = await (try? getSelectedText()) ?? ""
            print("\(i) selectedText: \(selectedText)")
        }
        #expect(true, "Test getSelectedText completed without crash")
    }

    @Test(
        "Concurrent Get Selected Text",
        .tags(.system, .performance),
        .disabled("Only run manually")
    )
    func testConcurrentGetSelectedText() async throws {
        await withTaskGroup(of: Void.self) { group in
            for i in 0 ..< 2000 {
                group.addTask {
                    print("test index: \(i)")
                    let selectedText = (try? await getSelectedText()) ?? ""
                    print("\(i) selectedText: \(selectedText)")
                }
            }
        }
        #expect(true, "Concurrent test getSelectedText completed without crash")
    }
}
