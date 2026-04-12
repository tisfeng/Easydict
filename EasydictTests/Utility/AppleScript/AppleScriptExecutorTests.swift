//
//  AppleScriptExecutorTests.swift
//  EasydictTests
//
//  Created by tisfeng on 2026/4/12.
//

import Foundation
import Testing

@testable import Easydict

// MARK: - AppleScriptExecutorTests

/// Validates the preferred `NSAppleScript` backend with stable, permission-free scripts. These
/// tests focus on the deterministic parts of the executor, namely successful string return values
/// and `QueryError.appleScript` mapping for invalid scripts. Timeout behavior is intentionally left
/// to higher-level integration coverage because it is best-effort and tied to main-thread execution.
@Suite("AppleScript Executor", .tags(.utilities, .unit))
struct AppleScriptExecutorTests {
    /// Verifies that the `NSAppleScript` backend returns a simple string result.
    @Test("Runs AppleScript through NSAppleScript", .tags(.utilities, .unit))
    func runsAppleScriptThroughNSAppleScript() async throws {
        let executor = AppleScriptExecutor()
        let result = try await executor.run("return \"hello\"")

        #expect(result == "hello")
    }

    /// Verifies that invalid script source is mapped into `QueryError.appleScript`.
    @Test("Maps NSAppleScript failures to QueryError", .tags(.utilities, .unit))
    func mapsNSAppleScriptFailuresToQueryError() async {
        let executor = AppleScriptExecutor()
        let script = "this is not valid AppleScript"

        do {
            _ = try await executor.run(script)
            Issue.record("Expected NSAppleScript execution to fail")
        } catch let error as QueryError {
            #expect(error.type == .appleScript)
            #expect(error.errorDataMessage == script)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }
}
