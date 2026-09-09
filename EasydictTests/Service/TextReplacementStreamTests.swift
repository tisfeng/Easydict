//
//  TextReplacementStreamTests.swift
//  EasydictTests
//
//  Created by Eric Pan on 2026/8/25.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation
import Testing

@testable import Easydict

// MARK: - TextReplacementStreamTests

/// Unit tests for incremental insertion, fallback boundaries, and safe action logging.
@Suite("Text Replacement Streaming", .serialized, .tags(.unit))
struct TextReplacementStreamTests {
    // MARK: Internal

    @MainActor
    @Test("Inserts non-empty chunks immediately and in order")
    func insertsChunksInOrder() async {
        var insertedChunks: [String] = []

        let outcome = await TextReplacementStreamConsumer().consume(
            stream(yielding: ["Hel", "", "lo", "!"])
        ) { chunk in
            insertedChunks.append(chunk)
        }

        #expect(insertedChunks == ["Hel", "lo", "!"])
        guard case let .completed(metrics) = outcome else {
            Issue.record("Expected a completed streaming outcome.")
            return
        }
        #expect(metrics == .init(chunkCount: 3, characterCount: 6))
    }

    @MainActor
    @Test("Reports an empty response before any insertion")
    func reportsEmptyResponse() async {
        var insertedChunks: [String] = []

        let outcome = await TextReplacementStreamConsumer().consume(
            stream(yielding: ["", ""])
        ) { chunk in
            insertedChunks.append(chunk)
        }

        #expect(insertedChunks.isEmpty)
        guard case .empty = outcome else {
            Issue.record("Expected an empty streaming outcome.")
            return
        }
        #expect(outcome.metrics == .zero)
    }

    @MainActor
    @Test("Distinguishes an error before the first chunk from a partial interruption")
    func distinguishesFailureBoundary() async {
        var beforeFirstInsertions: [String] = []
        let beforeFirstOutcome = await TextReplacementStreamConsumer().consume(
            stream(yielding: [], thenThrowing: TestStreamError.providerFailure)
        ) { chunk in
            beforeFirstInsertions.append(chunk)
        }

        var partialInsertions: [String] = []
        let partialOutcome = await TextReplacementStreamConsumer().consume(
            stream(yielding: ["partial"], thenThrowing: TestStreamError.providerFailure)
        ) { chunk in
            partialInsertions.append(chunk)
        }

        #expect(beforeFirstInsertions.isEmpty)
        guard case let .failedBeforeFirstChunk(error) = beforeFirstOutcome else {
            Issue.record("Expected a failure before the first chunk.")
            return
        }
        #expect(error is TestStreamError)

        #expect(partialInsertions == ["partial"])
        guard case let .interrupted(metrics, error) = partialOutcome else {
            Issue.record("Expected an interruption after partial output.")
            return
        }
        #expect(error is TestStreamError)
        #expect(metrics == .init(chunkCount: 1, characterCount: 7))
    }

    @MainActor
    @Test("Classifies cancellation without inserting or requesting fallback")
    func classifiesCancellationWithoutFallback() async {
        var requestedIdentifiers: [String] = []
        var insertedChunks: [String] = []

        let execution = await TextReplacementStreamCoordinator().execute(
            initialIdentifier: "selected",
            fallbackIdentifier: "built-in",
            makeSource: { identifier in
                requestedIdentifiers.append(identifier)
                return .init(
                    serviceType: identifier,
                    model: "test-model",
                    stream: stream(yielding: [], thenThrowing: CancellationError())
                )
            },
            insert: { chunk in
                insertedChunks.append(chunk)
            }
        )

        #expect(requestedIdentifiers == ["selected"])
        #expect(insertedChunks.isEmpty)
        #expect(!execution.didFallback)
        guard case let .cancelled(metrics) = execution.finalOutcome else {
            Issue.record("Expected a cancelled streaming outcome.")
            return
        }
        #expect(metrics == .zero)
    }

    @MainActor
    @Test("Falls back once for empty output and pre-chunk failure")
    func fallsBackOnceBeforeFirstChunk() async {
        for initialStream in [
            stream(yielding: []),
            stream(yielding: [], thenThrowing: TestStreamError.providerFailure),
        ] {
            var requestedIdentifiers: [String] = []
            var insertedChunks: [String] = []
            var fallbackCount = 0

            let execution = await TextReplacementStreamCoordinator().execute(
                initialIdentifier: "selected",
                fallbackIdentifier: "built-in",
                makeSource: { identifier in
                    requestedIdentifiers.append(identifier)
                    let responseStream = identifier == "selected"
                        ? initialStream
                        : stream(yielding: ["fallback"])
                    return .init(
                        serviceType: identifier,
                        model: "test-model",
                        stream: responseStream
                    )
                },
                willUseFallback: {
                    fallbackCount += 1
                },
                insert: { chunk in
                    insertedChunks.append(chunk)
                }
            )

            #expect(requestedIdentifiers == ["selected", "built-in"])
            #expect(insertedChunks == ["fallback"])
            #expect(fallbackCount == 1)
            #expect(execution.didFallback)
            #expect(execution.attempts.count == 2)
            guard case let .completed(metrics) = execution.finalOutcome else {
                Issue.record("Expected the one fallback attempt to complete.")
                continue
            }
            #expect(metrics == .init(chunkCount: 1, characterCount: 8))
        }
    }

    @MainActor
    @Test("Stops after one failed fallback attempt")
    func stopsAfterOneFailedFallbackAttempt() async {
        var requestedIdentifiers: [String] = []
        var fallbackCount = 0

        let execution = await TextReplacementStreamCoordinator().execute(
            initialIdentifier: "selected",
            fallbackIdentifier: "built-in",
            makeSource: { identifier in
                requestedIdentifiers.append(identifier)
                let responseStream = identifier == "selected"
                    ? stream(yielding: [])
                    : stream(yielding: [], thenThrowing: TestStreamError.providerFailure)
                return .init(
                    serviceType: identifier,
                    model: "test-model",
                    stream: responseStream
                )
            },
            willUseFallback: {
                fallbackCount += 1
            },
            insert: { _ in
                Issue.record("No chunk should be inserted when both attempts fail.")
            }
        )

        #expect(requestedIdentifiers == ["selected", "built-in"])
        #expect(fallbackCount == 1)
        #expect(execution.didFallback)
        #expect(execution.attempts.count == 2)
        guard case .failedBeforeFirstChunk = execution.finalOutcome else {
            Issue.record("Expected the fallback failure to be the final outcome.")
            return
        }
    }

    @MainActor
    @Test("Does not fall back after partial output")
    func doesNotFallbackAfterPartialOutput() async {
        var requestedIdentifiers: [String] = []
        var insertedChunks: [String] = []

        let execution = await TextReplacementStreamCoordinator().execute(
            initialIdentifier: "selected",
            fallbackIdentifier: "built-in",
            makeSource: { identifier in
                requestedIdentifiers.append(identifier)
                return .init(
                    serviceType: identifier,
                    model: "test-model",
                    stream: stream(
                        yielding: ["partial"],
                        thenThrowing: TestStreamError.providerFailure
                    )
                )
            },
            insert: { chunk in
                insertedChunks.append(chunk)
            }
        )

        #expect(requestedIdentifiers == ["selected"])
        #expect(insertedChunks == ["partial"])
        #expect(!execution.didFallback)
        #expect(execution.attempts.count == 1)
        guard case let .interrupted(metrics, _) = execution.finalOutcome else {
            Issue.record("Expected the partial stream to remain interrupted without fallback.")
            return
        }
        #expect(metrics == .init(chunkCount: 1, characterCount: 7))
    }

    @Test("Safe logs categorize errors without echoing provider payloads")
    func safeLogsDoNotEchoProviderPayloads() {
        let sensitivePayload = "Authorization: Bearer secret-key; source=private selected text"
        let outcome = TextReplacementStreamOutcome.failedBeforeFirstChunk(
            SensitiveProviderError(payload: sensitivePayload)
        )

        let message = TextReplacementLogFormatter.message(
            action: .translate,
            serviceType: ServiceType.customOpenAI.rawValue,
            model: "test-model",
            outcome: outcome
        )

        #expect(message.contains("action=translate"))
        #expect(message.contains("category=provider"))
        #expect(message.contains("chunks=0 characters=0"))
        #expect(!message.contains(sensitivePayload))
        #expect(!message.contains("secret-key"))
        #expect(!message.contains("private selected text"))
    }

    @Test("Focused element diagnostics report counts without selected text")
    func focusedElementDiagnosticsDoNotExposeText() {
        let fullText = "FULL_TEXT_MUST_NOT_APPEAR"
        let selectedText = "SELECTED_TEXT_MUST_NOT_APPEAR"
        let elementInfo = FocusedElementInfo(
            fullText: fullText,
            selectedRange: .init(location: 3, length: 8),
            selectedText: selectedText,
            roleValue: "AXTextArea"
        )

        let description = elementInfo.description

        #expect(description.contains("textCharacters: \(fullText.count)"))
        #expect(description.contains("selectedTextCharacters: \(selectedText.count)"))
        #expect(description.contains("selectedRange: (3, 8)"))
        #expect(description.contains("roleValue: AXTextArea"))
        #expect(!description.contains(fullText))
        #expect(!description.contains(selectedText))
    }

    // MARK: Private

    private func stream(
        yielding chunks: [String],
        thenThrowing error: Error? = nil
    )
        -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            for chunk in chunks {
                continuation.yield(chunk)
            }
            if let error {
                continuation.finish(throwing: error)
            } else {
                continuation.finish()
            }
        }
    }
}

// MARK: - TestStreamError

private enum TestStreamError: Error {
    case providerFailure
}

// MARK: - SensitiveProviderError

private struct SensitiveProviderError: LocalizedError {
    let payload: String

    var errorDescription: String? {
        payload
    }
}
