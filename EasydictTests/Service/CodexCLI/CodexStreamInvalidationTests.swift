//
//  CodexStreamInvalidationTests.swift
//  EasydictTests
//
//  Created by Alfred on 2026/09/07.
//

import Defaults
@testable import Easydict
import Foundation
import Testing

// MARK: - CodexStreamInvalidationTests

/// Exercises the generation boundary shared by normal streams and Codex invalidation.
@MainActor
@Suite("Codex stream invalidation", .serialized)
struct CodexStreamInvalidationTests {
    @Test("a queued stream failure cannot replace a result reset under the same lock")
    func queuedFailureDoesNotOverwriteResetResult() async throws {
        let service = ControlledStreamService()
        let source = service.source
        let staleResult = service.resetServiceResult()
        staleResult.isLoading = true
        let stream = service.translateStream("first", from: .english, to: .simplifiedChinese)
        let consumer = Task { await drain(stream) }
        try await waitForSource(source, count: 1)

        let currentResult = service.updateResultLock.withLock { () -> QueryResult in
            source.finish(index: 0, throwing: StreamTestError.failed)
            let result = service.resetServiceResult()
            result.translatedResults = ["current"]
            return result
        }
        await consumer.value

        #expect(service.result === currentResult)
        #expect(service.result.translatedText == "current")
        #expect(service.result.error == nil)
        #expect(service.result.isStreamFinished)
    }

    @Test("cancellation clears loading whether a stream produced text or not", arguments: [false, true])
    func cancellationStopsLoadingWithAndWithoutFirstChunk(hadFirstChunk: Bool) async throws {
        let service = ControlledStreamService()
        let source = service.source
        let result = service.resetServiceResult()
        result.isLoading = true
        let stream = service.translateStream("first", from: .english, to: .simplifiedChinese)
        let consumer = Task { await drain(stream) }
        try await waitForSource(source, count: 1)

        if hadFirstChunk {
            source.yield("existing", index: 0)
            try await waitForResult(result) { $0.translatedText == "existing" }
        }
        source.finish(index: 0, throwing: CancellationError())
        await consumer.value

        #expect(result.isStreamFinished)
        #expect(!result.isLoading)
        #expect(result.error == nil)
        if hadFirstChunk {
            #expect(result.translatedText == "existing")
        }
    }

    @Test("a first query callback cannot update the result after a second query begins")
    func staleCallbackCannotPolluteNewQuery() async throws {
        let service = ControlledStreamService()
        let source = service.source
        let firstModel = queryModel(text: "first")
        let secondModel = queryModel(text: "second")
        var callbacks: [String] = []

        service.resetServiceResult().isLoading = true
        service.startQueryStream(firstModel) { result, _ in
            callbacks.append(result.translatedText ?? "")
        }
        try await waitForSource(source, count: 1)

        service.resetServiceResult().isLoading = true
        service.startQueryStream(secondModel) { result, _ in
            callbacks.append(result.translatedText ?? "")
        }
        try await waitForSource(source, count: 2)

        let secondGeneration = service.resultGeneration
        firstModel.stopServiceRequest(service.serviceTypeWithUniqueIdentifier())
        #expect(service.resultGeneration == secondGeneration)

        source.yield("stale", index: 0)
        source.finish(index: 0)
        source.yield("current", index: 1)
        source.finish(index: 1)
        try await waitForResult(service.result) { $0.translatedText == "current" && $0.isStreamFinished }

        #expect(!callbacks.contains("stale"))
        #expect(service.result.translatedText == "current")
    }

    @Test("a producer created before reset cannot start a content request")
    func producerCreatedBeforeResetCannotStartContentRequest() async throws {
        let service = ControlledStreamService()
        let source = service.source
        let firstModel = queryModel(text: "first")
        let secondModel = queryModel(text: "second")
        var firstStream: AsyncThrowingStream<QueryResult, Error>!
        var secondStream: AsyncThrowingStream<QueryResult, Error>!
        var secondResult: QueryResult!

        service.updateResultLock.withLock {
            service.resetServiceResult().isLoading = true
            firstStream = service.startQueryStream(firstModel)
            secondResult = service.resetServiceResult()
            secondResult.isLoading = true
            secondStream = service.startQueryStream(secondModel)
        }

        await drain(firstStream)

        let consumer = Task { await drain(secondStream) }
        try await waitForSource(source, count: 1)
        #expect(source.requestedTexts == ["second"])

        source.yield("current", index: 0)
        source.finish(index: 0)
        await consumer.value
        try await waitForResult(secondResult) {
            $0.translatedText == "current" && $0.isStreamFinished
        }

        #expect(service.result === secondResult)
        #expect(secondResult.translatedText == "current")
        #expect(source.requestedTexts == ["second"])
    }

    @Test("QueryModel stop keeps received text and makes its active stream terminal")
    func queryModelStopPreservesReceivedTextAndFinishesActiveStream() async throws {
        let service = ControlledStreamService()
        let source = service.source
        let model = queryModel(text: "first")
        let result = service.resetServiceResult()
        result.isLoading = true
        let generation = service.resultGeneration

        service.startQueryStream(model) { _, _ in }
        try await waitForSource(source, count: 1)
        source.yield("existing", index: 0)
        try await waitForResult(result) { $0.translatedText == "existing" }

        model.stopServiceRequest(service.serviceTypeWithUniqueIdentifier())
        try await waitForTerminatedSource(source, count: 1)
        source.yield("late", index: 0)
        source.finish(index: 0)

        #expect(service.resultGeneration > generation)
        #expect(result.translatedText == "existing")
        #expect(result.isStreamFinished)
        #expect(!result.isLoading)
        #expect(result.error == nil)
    }

    @Test("an invalid managed model fails before authentication and stays registered for configuration invalidation")
    func invalidManagedModelRetainsRegistrationUntilConfigurationChanges() async throws {
        let service = CodexCLIService()
        let uuid = UUID().uuidString
        service.uuid = uuid
        let modeKey = CodexAccessMode.key(uuid: uuid)
        let managedModelKey = CodexServiceConfiguration.modelKey(uuid: uuid, mode: .managed)
        let localModelKey = CodexServiceConfiguration.modelKey(uuid: uuid, mode: .localCLI)
        Defaults[modeKey] = .managed
        Defaults[managedModelKey] = "gpt-5.4-mini-untrusted-suffix"
        Defaults[localModelKey] = ""
        defer {
            service.cancelStream()
            Defaults[modeKey] = .managed
            Defaults[managedModelKey] = CodexManagedRuntime.defaultModel
            Defaults[localModelKey] = ""
        }

        service.resetServiceResult()
        let generation = service.resultGeneration
        let stream = service.contentStreamTranslate("Hello", from: .english, to: .simplifiedChinese)
        var receivedError: Error?
        do {
            for try await _ in stream {}
        } catch {
            receivedError = error
        }

        #expect(
            (receivedError as? QueryError)?.message
                == CodexManagedError.invalidModel.localizedDescription
        )
        #expect(service.resultGeneration == generation)

        service.cancelStream()
        Defaults[modeKey] = .localCLI
        try await waitForGeneration(service, beyond: generation)

        #expect(service.resultGeneration > generation)
    }

    @Test(
        "account transitions report their managed query error through the service callback",
        arguments: CodexAccountOperation.allCases
    )
    func accountTransitionReportsReadableManagedQueryError(
        operation: CodexAccountOperation
    ) async throws {
        let service = CodexCLIService()
        let uuid = UUID().uuidString
        service.uuid = uuid
        let modeKey = CodexAccessMode.key(uuid: uuid)
        let modelKey = CodexServiceConfiguration.modelKey(uuid: uuid, mode: .managed)
        let result = service.resetServiceResult()
        result.isLoading = true
        Defaults[modeKey] = .managed
        Defaults[modelKey] = CodexManagedRuntime.defaultModel
        defer {
            service.cancelStream()
            CodexRequestCoordinator.shared.setAccountOperation(nil)
            Defaults.reset(modeKey, modelKey)
        }

        CodexRequestCoordinator.shared.setAccountOperation(operation)
        let model = queryModel(text: "Hello")
        var callbackError: Error?
        service.startQueryStream(model) { _, error in
            callbackError = error
        }

        let expectedMessage = CodexManagedError.operationInProgress(operation).localizedDescription
        try await waitForResult(result) {
            $0.isStreamFinished && $0.error?.message == expectedMessage
                && (callbackError as? QueryError)?.message == expectedMessage
        }

        #expect(result.isStreamFinished)
        #expect(result.error?.message == expectedMessage)
        #expect((callbackError as? QueryError)?.message == expectedMessage)

        // Clearing admission must not resurrect a rejected request. A user retry
        // is a fresh request and therefore reaches the normal validation boundary.
        CodexRequestCoordinator.shared.setAccountOperation(nil)
        let rejectedGeneration = service.resultGeneration
        try await Task.sleep(for: .milliseconds(50))
        #expect(service.resultGeneration == rejectedGeneration)
        #expect(result.error?.message == expectedMessage)

        Defaults[modelKey] = "gpt-5.4-mini-untrusted-suffix"
        let retryResult = service.resetServiceResult()
        retryResult.isLoading = true
        let retryModel = queryModel(text: "retry")
        service.startQueryStream(retryModel) { _, _ in }
        try await waitForResult(retryResult) {
            $0.isStreamFinished && $0.error?.message == CodexManagedError.invalidModel.localizedDescription
        }
        #expect(retryResult.error?.message == CodexManagedError.invalidModel.localizedDescription)
    }

    @Test("a queued blocked callback cannot overwrite a newer configuration query or its stop state")
    func queuedBlockedCallbackCannotOverwriteNewerConfigurationQuery() async throws {
        let service = CodexCLIService()
        let uuid = UUID().uuidString
        service.uuid = uuid
        let modeKey = CodexAccessMode.key(uuid: uuid)
        let modelKey = CodexServiceConfiguration.modelKey(uuid: uuid, mode: .managed)
        let firstModel = queryModel(text: "first")
        let secondModel = queryModel(text: "second")
        let firstResult = service.resetServiceResult()
        firstResult.isLoading = true
        Defaults[modeKey] = .managed
        Defaults[modelKey] = CodexManagedRuntime.defaultModel
        defer {
            service.cancelStream()
            CodexRequestCoordinator.shared.setAccountOperation(nil)
            Defaults.reset(modeKey, modelKey)
        }

        let differentModel = CodexManagedRuntime.bundledModelNames.first {
            $0 != CodexManagedRuntime.defaultModel
        }
        #expect(differentModel != nil)
        guard let differentModel else { return }

        CodexRequestCoordinator.shared.setAccountOperation(.login)
        let expectedMessage = CodexManagedError.operationInProgress(.login).localizedDescription
        let callbacks = CallbackRecorder()
        let firstStart = DispatchSemaphore(value: 0)
        let serviceBox = UncheckedSendable(value: service)
        let firstModelBox = UncheckedSendable(value: firstModel)
        let firstResultBox = UncheckedSendable(value: firstResult)
        let firstTask = Task.detached {
            serviceBox.value.startQueryStream(firstModelBox.value) { _, error in
                if error != nil { callbacks.append("first") }
            }
            firstStart.signal()
        }

        guard firstStart.wait(timeout: .now() + 3) == .success else { throw StreamTestTimeout() }
        try waitForErrorWithoutYielding(firstResultBox.value, message: expectedMessage)
        await firstTask.value

        Defaults[modelKey] = differentModel
        let secondResult = service.resetServiceResult()
        secondResult.isLoading = true
        service.startQueryStream(secondModel) { _, error in
            if error != nil { callbacks.append("second") }
        }
        firstModel.stopServiceRequest(service.serviceTypeWithUniqueIdentifier())
        try await waitForResult(secondResult) {
            $0.isStreamFinished && $0.error?.message == expectedMessage && callbacks.values == ["second"]
        }

        #expect(service.result === secondResult)
        #expect(callbacks.values == ["second"])
        #expect(secondResult.error?.message == expectedMessage)
    }
}

// MARK: - ControlledStreamService

/// Supplies controllable streams without adding production-only seams.
private final class ControlledStreamService: StreamService {
    // MARK: Lifecycle

    required init() {
        super.init()
    }

    // MARK: Internal

    let source = ControlledContentSource()

    override func serviceType() -> ServiceType {
        .codexCLI
    }

    override func name() -> String {
        "Controlled stream"
    }

    override func apiKeyRequirement() -> ServiceAPIKeyRequirement {
        .agentCLI
    }

    override func contentStreamTranslate(
        _ text: String,
        from: Language,
        to: Language
    )
        -> AsyncThrowingStream<String, Error> {
        source.makeStream(text: text)
    }
}

// MARK: - ControlledContentSource

/// Stores each request continuation so tests can queue stale values and terminal errors.
private final class ControlledContentSource: @unchecked Sendable {
    // MARK: Internal

    var count: Int { lock.withLock { continuations.count } }

    var requestedTexts: [String] { lock.withLock { texts } }

    var terminatedCount: Int { terminationLock.withLock { terminated } }

    func makeStream(text: String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            continuation.onTermination = { [weak self] _ in
                guard let self else { return }
                terminationLock.withLock { self.terminated += 1 }
            }
            lock.withLock {
                texts.append(text)
                continuations.append(continuation)
            }
        }
    }

    func yield(_ text: String, index: Int) {
        lock.withLock { continuations[index].yield(text) }
    }

    func finish(index: Int, throwing error: Error? = nil) {
        lock.withLock { continuations[index].finish(throwing: error) }
    }

    // MARK: Private

    private let lock = NSLock()
    private var continuations: [AsyncThrowingStream<String, Error>.Continuation] = []
    private var texts: [String] = []
    private let terminationLock = NSLock()
    private var terminated = 0
}

// MARK: - StreamTestError

private enum StreamTestError: Error {
    case failed
}

@MainActor
private func queryModel(text: String) -> QueryModel {
    let model = QueryModel()
    model.inputText = text
    model.userSourceLanguage = .english
    model.userTargetLanguage = .simplifiedChinese
    return model
}

private func drain(_ stream: AsyncThrowingStream<QueryResult, Error>) async {
    do {
        for try await _ in stream {}
    } catch {}
}

@MainActor
private func waitForSource(
    _ source: ControlledContentSource,
    count: Int,
    timeout: TimeInterval = 3
) async throws {
    let deadline = Date().addingTimeInterval(timeout)
    while source.count < count {
        guard Date() < deadline else { throw StreamTestTimeout() }
        try await Task.sleep(for: .milliseconds(10))
    }
}

@MainActor
private func waitForTerminatedSource(
    _ source: ControlledContentSource,
    count: Int,
    timeout: TimeInterval = 3
) async throws {
    let deadline = Date().addingTimeInterval(timeout)
    while source.terminatedCount < count {
        guard Date() < deadline else { throw StreamTestTimeout() }
        try await Task.sleep(for: .milliseconds(10))
    }
}

@MainActor
private func waitForResult(
    _ result: QueryResult,
    timeout: TimeInterval = 3,
    _ condition: @escaping (QueryResult) -> Bool
) async throws {
    let deadline = Date().addingTimeInterval(timeout)
    while !condition(result) {
        guard Date() < deadline else { throw StreamTestTimeout() }
        try await Task.sleep(for: .milliseconds(10))
    }
}

@MainActor
private func waitForGeneration(
    _ service: QueryService,
    beyond generation: UInt,
    timeout: TimeInterval = 3
) async throws {
    let deadline = Date().addingTimeInterval(timeout)
    while service.resultGeneration <= generation {
        guard Date() < deadline else { throw StreamTestTimeout() }
        try await Task.sleep(for: .milliseconds(10))
    }
}

// MARK: - StreamTestTimeout

private struct StreamTestTimeout: Error {}

// MARK: - CallbackRecorder

private final class CallbackRecorder: @unchecked Sendable {
    // MARK: Internal

    var values: [String] { lock.withLock { callbacks } }

    func append(_ callback: String) {
        lock.withLock { callbacks.append(callback) }
    }

    // MARK: Private

    private let lock = NSLock()
    private var callbacks: [String] = []
}

// MARK: - UncheckedSendable

/// The service dispatches its public completion back to MainActor; this wrapper only
/// lets the test start its worker from a background executor while MainActor waits.
private final class UncheckedSendable<Value>: @unchecked Sendable {
    // MARK: Lifecycle

    init(value: Value) {
        self.value = value
    }

    // MARK: Internal

    let value: Value
}

@MainActor
private func waitForErrorWithoutYielding(
    _ result: QueryResult,
    message: String,
    timeout: TimeInterval = 3
) throws {
    let deadline = Date().addingTimeInterval(timeout)
    while result.error?.message != message {
        guard Date() < deadline else { throw StreamTestTimeout() }
        Thread.sleep(forTimeInterval: 0.01)
    }
}
