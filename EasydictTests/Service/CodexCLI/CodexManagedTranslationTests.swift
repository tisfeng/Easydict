//
//  CodexManagedTranslationTests.swift
//  EasydictTests
//
//  Created by Alfred on 2026/09/07.
//

@testable import Easydict
import Foundation
import Testing

// MARK: - CodexManagedTranslationTests

/// Verifies the managed parser accepts only a completed text-only terminal turn.
@Suite("Codex managed translation")
struct CodexManagedTranslationTests {
    @Test("accepts a completed agent message as the terminal translation")
    func acceptsCompletedTextTurn() throws {
        let output = translationOutput(lines: [
            #"{"type":"thread.started"}"#,
            #"{"type":"turn.started"}"#,
            #"{"type":"item.completed","item":{"type":"agent_message","text":"你好"}}"#,
            #"{"type":"turn.completed"}"#,
        ])

        let result = try CodexManagedTranslation.result(output, durationMs: 12)

        #expect(result.text == "你好")
    }

    @Test("accepts official retry diagnostics before a completed turn", arguments: [
        #"{"type":"error","message":"Reconnecting"}"#,
        #"{"type":"item.completed","item":{"type":"error","message":"Reconnecting"}}"#,
    ])
    func acceptsRetryDiagnosticBeforeTurnStarts(notification: String) throws {
        let output = translationOutput(lines: [
            #"{"type":"thread.started"}"#,
            notification,
            #"{"type":"turn.started"}"#,
            #"{"type":"item.completed","item":{"type":"agent_message","text":"你好"}}"#,
            #"{"type":"turn.completed"}"#,
        ])

        let result = try CodexManagedTranslation.result(output)

        #expect(result.text == "你好")
    }

    @Test("rejects a completed turn that contains a tool item")
    func rejectsToolActivity() {
        let output = translationOutput(lines: [
            #"{"type":"thread.started"}"#,
            #"{"type":"turn.started"}"#,
            #"{"type":"item.started","item":{"type":"command_execution"}}"#,
            #"{"type":"item.completed","item":{"type":"agent_message","text":"你好"}}"#,
            #"{"type":"turn.completed"}"#,
        ])

        #expect(throws: CodexManagedError.invalidResponse) {
            try CodexManagedTranslation.result(output)
        }
    }

    @Test("rejects nonzero exec output instead of treating partial JSONL as a translation")
    func rejectsFailedExecution() {
        let output = translationOutput(exitCode: 1, lines: [
            #"{"type":"turn.completed"}"#,
        ], stderr: "request failed")

        #expect(throws: (any Error).self) {
            try CodexManagedTranslation.result(output)
        }
    }

    @Test("rejects a message when the turn never reaches terminal completion")
    func rejectsNonterminalTurn() {
        let output = translationOutput(lines: [
            #"{"type":"thread.started"}"#,
            #"{"type":"turn.started"}"#,
            #"{"type":"item.completed","item":{"type":"agent_message","text":"你好"}}"#,
        ])

        #expect(throws: CodexManagedError.invalidResponse) {
            try CodexManagedTranslation.result(output)
        }
    }

    @Test("distinguishes the exact signed-out status from Keychain failures")
    func statusClassificationPreservesKeychainFailure() throws {
        #expect(try CodexManagedTranslation.isSignedIn(statusOutput(exitCode: 1, text: "Not logged in")) == false)

        #expect(throws: CodexManagedError.keychainUnavailable) {
            try CodexManagedTranslation.isSignedIn(statusOutput(exitCode: 1, text: "Keychain access denied"))
        }

        #expect(throws: CodexManagedError.authenticationFailed) {
            try CodexManagedTranslation.isSignedIn(statusOutput(exitCode: 0, text: "Not logged in"))
        }
    }

    @Test("managed authentication failures direct users to the app sign-in flow")
    func authenticationFailureUsesManagedLoginGuidance() {
        let output = translationOutput(exitCode: 1, lines: [
            #"{"type":"turn.failed","error":"Not logged in. Please run codex login."}"#,
        ])
        var receivedError: Error?

        do {
            _ = try CodexManagedTranslation.result(output)
            Issue.record("Expected managed authentication failure")
        } catch {
            receivedError = error
        }

        #expect(receivedError as? CodexManagedError == .loginRequired)
        let message = receivedError?.localizedDescription
        #expect(message?.localizedCaseInsensitiveContains("ChatGPT") == true)
        #expect(message?.localizedCaseInsensitiveContains("codex login") == false)
    }

    @Test("unconfirmed managed process failures preserve their original classification")
    func unconfirmedProcessFailuresDoNotRequireLogin() {
        let cases: [(CodexManagedProcess.Output, ManagedFailureExpectation)] = [
            (
                translationOutput(exitCode: 1, lines: [
                    #"{"type":"turn.failed","error":"authentication_failed"}"#,
                ]),
                .managed(.authenticationFailed)
            ),
            (
                translationOutput(exitCode: 1, lines: [
                    #"{"type":"turn.failed","error":"unauthorized"}"#,
                ]),
                .managed(.authenticationFailed)
            ),
            (
                translationOutput(exitCode: 1, lines: [], stderr: "Keychain access denied during authentication"),
                .managed(.keychainUnavailable)
            ),
            (
                translationOutput(exitCode: 1, lines: [], stderr: "Network connection unavailable"),
                .local(.cliError(message: "Network connection unavailable"))
            ),
            (
                translationOutput(exitCode: 1, lines: [
                    #"{"type":"turn.failed","error":"rate limit exceeded"}"#,
                ]),
                .local(.quotaExceeded(message: "rate limit exceeded"))
            ),
        ]

        for (output, expected) in cases {
            var receivedError: Error?
            do {
                _ = try CodexManagedTranslation.result(output)
                Issue.record("Expected process failure")
            } catch {
                receivedError = error
            }
            switch expected {
            case let .managed(error): #expect(receivedError as? CodexManagedError == error)
            case let .local(error): #expect(receivedError as? CodexCLIError == error)
            }
        }
    }
}

// MARK: - ManagedFailureExpectation

private enum ManagedFailureExpectation {
    case managed(CodexManagedError)
    case local(CodexCLIError)
}

private func translationOutput(
    exitCode: Int32 = 0,
    lines: [String],
    stderr: String = ""
)
    -> CodexManagedProcess.Output {
    CodexManagedProcess.Output(
        exitCode: exitCode,
        stdout: Data((lines.joined(separator: "\n") + "\n").utf8),
        stderr: Data(stderr.utf8)
    )
}

private func statusOutput(exitCode: Int32, text: String) -> CodexManagedProcess.Output {
    CodexManagedProcess.Output(exitCode: exitCode, stdout: Data(text.utf8), stderr: Data())
}
