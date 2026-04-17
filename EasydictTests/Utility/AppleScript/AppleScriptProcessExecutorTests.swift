//
//  AppleScriptProcessExecutorTests.swift
//  EasydictTests
//
//  Created by tisfeng on 2026/4/12.
//

import Foundation
import Testing

@testable import Easydict

// MARK: - AppleScriptProcessExecutorTests

/// Validates the subprocess-backed AppleScript runner that is kept as an internal compatibility
/// backend. These tests lock down stdout capture and error mapping so the fallback implementation
/// can be refactored safely without reintroducing silent process failures. They intentionally avoid
/// browser or system permissions and use simple scripts that run in any local test environment.
@Suite("AppleScript Process Executor", .tags(.utilities, .unit))
struct AppleScriptProcessExecutorTests {
    /// Verifies that `osascript` stdout is returned to callers for a simple script.
    @Test("Runs AppleScript through osascript", .tags(.utilities, .unit))
    func runsAppleScriptThroughOsaScript() async throws {
        let executor = AppleScriptProcessExecutor(script: "return \"hello\"")
        let result = try await executor.run()

        #expect(result?.trimmingCharacters(in: .whitespacesAndNewlines) == "hello")
    }

    /// Verifies that script failures are mapped into `QueryError.appleScript`.
    @Test("Maps osascript stderr to QueryError", .tags(.utilities, .unit))
    func mapsOsaScriptStdErrToQueryError() async {
        let executor = AppleScriptProcessExecutor(script: "this is not valid AppleScript")

        do {
            _ = try await executor.run()
            Issue.record("Expected AppleScript subprocess execution to fail")
        } catch let error as QueryError {
            #expect(error.type == .appleScript)
            #expect(error.errorDataMessage == "this is not valid AppleScript")
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }
}
