//
//  CodexManagedRuntimeTests.swift
//  EasydictTests
//
//  Created by Alfred on 2026/09/14.
//

@testable import Easydict
import Foundation
import Testing

// MARK: - CodexManagedRuntimeTests

/// Verifies the isolation rules applied before a managed Codex command starts.
@MainActor
@Suite("Codex managed runtime")
struct CodexManagedRuntimeTests {
    @Test("user skills do not block managed login while skill instructions stay disabled")
    func userSkillsDoNotBlockManagedLogin() async throws {
        for release in [CodexRuntimeRelease.legacy, .modern] {
            try await withAccountFixture(release: release) { fixture in
                let skillDirectory = fixture.runtime().home
                    .appendingPathComponent(".agents/skills/example", isDirectory: true)
                try FileManager.default.createDirectory(
                    at: skillDirectory,
                    withIntermediateDirectories: true
                )
                try Data("test skill".utf8).write(
                    to: skillDirectory.appendingPathComponent("SKILL.md")
                )
                let account = fixture.account()

                account.login(origin: release.rawValue)
                try await waitForAccount { !account.isBusy && account.isSignedIn }

                #expect(fixture.invocationCount("login") == 1)
                #expect(fixture.invocationCount("exec") == 1)
                #expect(fixture.execArguments.contains("skills.include_instructions=false"))
            }
        }
    }
}
