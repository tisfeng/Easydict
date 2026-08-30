//
//  InPlaceTranslationCoordinatorTests.swift
//  EasydictTests
//
//  Created by Eric Pan on 2026/8/30.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation
import Testing

@testable import Easydict

// MARK: - InPlaceTranslationCoordinatorTests

/// Exercises bounded block translation, retry classification, progress, and session-only caching.
@Suite("In-place Translation Coordinator", .tags(.inPlaceTranslation, .unit))
struct InPlaceTranslationCoordinatorTests {
    // MARK: Internal

    @Test("Runs at the configured concurrency and reports monotonic progress")
    func boundsConcurrentRequests() async {
        let translator = TestBlockTranslator(delayNanoseconds: 20_000_000)
        let coordinator = InPlaceTranslationCoordinator(
            translator: translator,
            maximumConcurrency: 2,
            retryDelay: 0
        )
        let recorder = TranslationUpdateRecorder()
        let blocks = (0 ..< 5).map { block(text: "block-\($0)", order: $0) }

        let results = await coordinator.translate(
            blocks: blocks,
            sourceLanguage: .english,
            targetLanguage: .simplifiedChinese,
            serviceIdentifier: "provider"
        ) { block, completed, total in
            await recorder.record(block: block, completed: completed, total: total)
        }

        let metrics = await translator.metrics()
        let updates = await recorder.updates()
        #expect(results.count == 5)
        #expect(results.values.allSatisfy { $0.status == .translated })
        #expect(metrics.requestCount == 5)
        #expect(metrics.maximumConcurrentCount == 2)
        #expect(updates.map(\.completed) == [1, 2, 3, 4, 5])
        #expect(updates.allSatisfy { $0.total == 5 })
    }

    @Test("Reuses normalized text only within the same language and provider context")
    func reusesOnlyCompatibleCachedTranslation() async throws {
        let translator = TestBlockTranslator()
        let coordinator = InPlaceTranslationCoordinator(
            translator: translator,
            maximumConcurrency: 1,
            retryDelay: 0
        )
        let first = block(text: "  hello\nworld ")
        let equivalent = block(text: "hello world")

        _ = await translate(
            [first],
            coordinator: coordinator,
            target: .simplifiedChinese,
            provider: "provider-a"
        )
        let cached = await translate(
            [equivalent],
            coordinator: coordinator,
            target: .simplifiedChinese,
            provider: "provider-a"
        )
        _ = await translate(
            [equivalent],
            coordinator: coordinator,
            target: .japanese,
            provider: "provider-a"
        )
        _ = await translate(
            [equivalent],
            coordinator: coordinator,
            target: .simplifiedChinese,
            provider: "provider-b"
        )

        let cachedBlock = try #require(cached[equivalent.id])
        let metrics = await translator.metrics()
        #expect(cachedBlock.block.id == equivalent.id)
        #expect(cachedBlock.translatedText == "translated:  hello\nworld ")
        #expect(metrics.requestCount == 3)
    }

    @Test("Equivalent blocks in one batch share one provider request and finish independently")
    func coalescesEquivalentBlocksWithinOneBatch() async throws {
        let usageRecorder = AdapterUsageRecorder()
        let service = AdapterQueryService()
        let translator = QueryServiceInPlaceBlockTranslator(
            usageRecorder: usageRecorder,
            serviceFactory: { _ in service }
        )
        let coordinator = InPlaceTranslationCoordinator(
            translator: translator,
            maximumConcurrency: 2,
            retryDelay: 0
        )
        let first = block(text: "  hello\nworld ", order: 0)
        let second = block(text: "hello world", order: 1)
        let recorder = TranslationUpdateRecorder()

        let results = await coordinator.translate(
            blocks: [first, second],
            sourceLanguage: .english,
            targetLanguage: .simplifiedChinese,
            serviceIdentifier: "provider"
        ) { block, completed, total in
            await recorder.record(block: block, completed: completed, total: total)
        }

        let firstResult = try #require(results[first.id])
        let secondResult = try #require(results[second.id])
        let updates = await recorder.updates()
        #expect(first.id != second.id)
        #expect(first.normalizedRect != second.normalizedRect)
        #expect(firstResult.status == .translated)
        #expect(secondResult.status == .translated)
        #expect(firstResult.translatedText == secondResult.translatedText)
        #expect(service.translateCallCount == 1)
        #expect(usageRecorder.count == 1)
        #expect(updates.map(\.completed) == [1, 2])
        #expect(updates.allSatisfy { $0.total == 2 })
        #expect(Set(updates.map(\.blockID)) == [first.id, second.id])
    }

    @Test("Automatic source language resolves independently for every OCR block")
    func resolvesAutomaticSourcePerBlock() async {
        let translator = TestBlockTranslator()
        let coordinator = InPlaceTranslationCoordinator(
            translator: translator,
            maximumConcurrency: 2,
            retryDelay: 0
        )
        let blocks = [
            block(text: "Hello", language: .english),
            block(text: "こんにちは", language: .japanese),
        ]

        _ = await coordinator.translate(
            blocks: blocks,
            sourceLanguage: .auto,
            targetLanguage: .simplifiedChinese,
            serviceIdentifier: "provider"
        ) { _, _, _ in }

        let metrics = await translator.metrics()
        #expect(Set(metrics.requests.map(\.sourceLanguage)) == [.english, .japanese])
    }

    @Test("Retries one transient failure but never retries authentication")
    func appliesErrorSpecificRetryPolicy() async throws {
        let translator = TestBlockTranslator(behaviors: [
            "timeout": .timeoutOnce,
            "auth": .authentication,
        ])
        let coordinator = InPlaceTranslationCoordinator(
            translator: translator,
            maximumConcurrency: 2,
            retryDelay: 0
        )
        let timeout = block(text: "timeout")
        let authentication = block(text: "auth")

        let results = await coordinator.translate(
            blocks: [timeout, authentication],
            sourceLanguage: .english,
            targetLanguage: .simplifiedChinese,
            serviceIdentifier: "provider"
        ) { _, _, _ in }

        let timeoutResult = try #require(results[timeout.id])
        let authenticationResult = try #require(results[authentication.id])
        let metrics = await translator.metrics()
        #expect(timeoutResult.status == .translated)
        #expect(timeoutResult.translatedText == "translated:timeout")
        #expect(authenticationResult.status == .failed(.authentication))
        #expect(authenticationResult.translatedText == nil)
        #expect(metrics.attemptsByText["timeout"] == 2)
        #expect(metrics.attemptsByText["auth"] == 1)
    }

    @Test("A provider-only cancellation fails one block without cancelling the request queue")
    func continuesAfterProviderCancellationError() async throws {
        let translator = TestBlockTranslator(behaviors: ["cancel": .cancellation])
        let coordinator = InPlaceTranslationCoordinator(
            translator: translator,
            maximumConcurrency: 1,
            retryDelay: 0
        )
        let cancelled = block(text: "cancel", order: 0)
        let following = block(text: "following", order: 1)
        let recorder = TranslationUpdateRecorder()

        let results = await coordinator.translate(
            blocks: [cancelled, following],
            sourceLanguage: .english,
            targetLanguage: .simplifiedChinese,
            serviceIdentifier: "provider"
        ) { block, completed, total in
            await recorder.record(block: block, completed: completed, total: total)
        }

        let cancelledResult = try #require(results[cancelled.id])
        let followingResult = try #require(results[following.id])
        let updates = await recorder.updates()
        let metrics = await translator.metrics()
        guard case .failed = cancelledResult.status else {
            Issue.record("Provider-local CancellationError remained pending")
            return
        }
        #expect(followingResult.status == .translated)
        #expect(followingResult.translatedText == "translated:following")
        #expect(metrics.requests.map(\.text) == ["cancel", "following"])
        #expect(updates.map(\.completed) == [1, 2])
    }

    @Test("Explicit cache cleanup forces the next request through the provider")
    func clearsSessionCache() async {
        let translator = TestBlockTranslator()
        let coordinator = InPlaceTranslationCoordinator(
            translator: translator,
            maximumConcurrency: 1,
            retryDelay: 0
        )
        let first = block(text: "same")
        let second = block(text: "same")

        _ = await translate([first], coordinator: coordinator)
        await coordinator.removeAllCachedTranslations()
        _ = await translate([second], coordinator: coordinator)

        let metrics = await translator.metrics()
        #expect(metrics.requestCount == 2)
    }

    @Test("QueryService adapter initializes base result state before provider translation")
    func adapterInitializesUnhandledQueryState() async throws {
        let callLog = AdapterCallLog()
        let usageRecorder = AdapterUsageRecorder(callLog: callLog)
        let service = AdapterQueryService(callLog: callLog)
        let adapter = QueryServiceInPlaceBlockTranslator(
            usageRecorder: usageRecorder,
            serviceFactory: { _ in service }
        )

        let translated = try await adapter.translate(
            text: "hello",
            sourceLanguage: .english,
            targetLanguage: .simplifiedChinese,
            serviceIdentifier: "fake"
        )

        #expect(translated == "provider:hello")
        #expect(service.translateCallCount == 1)
        #expect(service.resultWasInitializedBeforeTranslate)
        #expect(service.queryInputObservedByTranslate == "hello")
        #expect(service.result?.queryText == "hello")
        #expect(service.result?.from == .english)
        #expect(service.result?.to == .simplifiedChinese)
        #expect(usageRecorder.count == 1)
        #expect(callLog.events == ["usage", "translate"])
    }

    @Test("QueryService adapter returns a base prehandle result without calling provider translate")
    func adapterUsesHandledChineseConversion() async throws {
        let callLog = AdapterCallLog()
        let usageRecorder = AdapterUsageRecorder(callLog: callLog)
        let service = AdapterQueryService(autoConvertsChinese: true, callLog: callLog)
        let adapter = QueryServiceInPlaceBlockTranslator(
            usageRecorder: usageRecorder,
            serviceFactory: { _ in service }
        )

        let translated = try await adapter.translate(
            text: "繁體字",
            sourceLanguage: .traditionalChinese,
            targetLanguage: .simplifiedChinese,
            serviceIdentifier: "fake"
        )

        #expect(translated == "繁体字")
        #expect(service.translateCallCount == 0)
        #expect(service.result?.queryText == "繁體字")
        #expect(usageRecorder.count == 1)
        #expect(callLog.events == ["usage"])
    }

    @Test("A prehandle error never records provider usage")
    func adapterSkipsUsageForPrehandleError() async {
        let usageRecorder = AdapterUsageRecorder()
        let service = AdapterQueryService()
        let adapter = QueryServiceInPlaceBlockTranslator(
            usageRecorder: usageRecorder,
            serviceFactory: { _ in service }
        )

        do {
            _ = try await adapter.translate(
                text: "unsupported",
                sourceLanguage: .japanese,
                targetLanguage: .english,
                serviceIdentifier: "fake"
            )
            Issue.record("Unsupported prehandle unexpectedly reached provider translation")
        } catch let error as QueryError {
            #expect(error.type == .unsupportedLanguage)
        } catch {
            Issue.record("Prehandle threw unexpected error: \(error)")
        }

        #expect(usageRecorder.isEmpty)
        #expect(service.translateCallCount == 0)
    }

    @Test("A coordinator cache hit never re-enters adapter usage accounting")
    func cacheHitDoesNotRecordAdapterUsageAgain() async {
        let usageRecorder = AdapterUsageRecorder()
        let service = AdapterQueryService()
        let adapter = QueryServiceInPlaceBlockTranslator(
            usageRecorder: usageRecorder,
            serviceFactory: { _ in service }
        )
        let coordinator = InPlaceTranslationCoordinator(
            translator: adapter,
            maximumConcurrency: 1,
            retryDelay: 0
        )
        let first = block(text: "  cached\ntext ", order: 0)
        let equivalent = block(text: "cached text", order: 1)

        _ = await translate([first], coordinator: coordinator)
        _ = await translate([equivalent], coordinator: coordinator)

        #expect(usageRecorder.count == 1)
        #expect(service.translateCallCount == 1)
    }

    @Test("Adapter serializes service preparation while provider calls remain concurrent")
    func serializesAdapterPreparationOnly() async throws {
        let factoryProbe = AdapterConcurrencyProbe(delayNanoseconds: 10_000_000)
        let prehandleProbe = AdapterConcurrencyProbe(delayNanoseconds: 10_000_000)
        let usageProbe = AdapterConcurrencyProbe(delayNanoseconds: 10_000_000)
        let providerProbe = AdapterConcurrencyProbe(delayNanoseconds: 50_000_000)
        let usageRecorder = AdapterUsageRecorder(concurrencyProbe: usageProbe)
        let adapter = QueryServiceInPlaceBlockTranslator(
            usageRecorder: usageRecorder,
            serviceFactory: { _ in
                factoryProbe.measure {
                    AdapterQueryService(
                        prehandleProbe: prehandleProbe,
                        providerProbe: providerProbe
                    )
                }
            }
        )

        try await withThrowingTaskGroup(of: String.self) { group in
            for index in 0 ..< 6 {
                group.addTask {
                    try await adapter.translate(
                        text: "block-\(index)",
                        sourceLanguage: .english,
                        targetLanguage: .simplifiedChinese,
                        serviceIdentifier: "fake"
                    )
                }
            }
            for try await _ in group {}
        }

        #expect(factoryProbe.maximumConcurrentCount == 1)
        #expect(prehandleProbe.maximumConcurrentCount == 1)
        #expect(usageProbe.maximumConcurrentCount == 1)
        #expect(providerProbe.maximumConcurrentCount > 1)
        #expect(usageRecorder.count == 6)
    }

    @Test("Cancelling QueryService adapter invokes cancelStream and returns no result")
    func adapterCancelsLegacyServiceWithoutPublishing() async {
        let barrier = CoordinatorTestBarrier()
        let streamCancellation = AdapterCancellationRecorder()
        let stopBlock = AdapterCancellationRecorder()
        let service = AdapterQueryService(
            translationBarrier: barrier,
            cancellationRecorder: streamCancellation,
            stopBlockRecorder: stopBlock
        )
        let adapter = QueryServiceInPlaceBlockTranslator(
            usageRecorder: AdapterUsageRecorder(),
            serviceFactory: { _ in service }
        )
        let task = Task {
            try await adapter.translate(
                text: "cancel me",
                sourceLanguage: .english,
                targetLanguage: .simplifiedChinese,
                serviceIdentifier: "fake"
            )
        }

        await barrier.waitForArrival()
        task.cancel()
        await streamCancellation.waitForCancellation()
        await stopBlock.waitForCancellation()
        await barrier.release()

        do {
            _ = try await task.value
            Issue.record("Cancelled adapter unexpectedly returned a translation")
        } catch is CancellationError {
            // Expected: cancellation is not normalized into a provider failure result.
        } catch {
            Issue.record("Cancelled adapter threw unexpected error: \(error)")
        }
        #expect(await streamCancellation.count() == 1)
        #expect(await stopBlock.count() == 1)
    }

    @Test("Cancellation stops the request queue without publishing a failure")
    func cancellationStopsQueuedRequestsAndUpdates() async {
        let barrier = CoordinatorTestBarrier()
        let translator = CancellableBarrierTranslator(barrier: barrier)
        let coordinator = InPlaceTranslationCoordinator(
            translator: translator,
            maximumConcurrency: 1,
            retryDelay: 0
        )
        let recorder = TranslationUpdateRecorder()
        let blocks = (0 ..< 3).map { block(text: "block-\($0)", order: $0) }
        let task = Task {
            await coordinator.translate(
                blocks: blocks,
                sourceLanguage: .english,
                targetLanguage: .simplifiedChinese,
                serviceIdentifier: "provider"
            ) { block, completed, total in
                await recorder.record(block: block, completed: completed, total: total)
            }
        }

        await barrier.waitForArrival()
        task.cancel()
        await barrier.release()

        let results = await task.value
        #expect(await translator.requestedTexts() == ["block-0"])
        #expect(results.isEmpty)
        #expect(await recorder.updates().isEmpty)
    }

    // MARK: Private

    private func block(
        text: String,
        language: Language = .english,
        order: Int = 0
    )
        -> InPlaceOCRBlock {
        InPlaceOCRBlock(
            normalizedRect: CGRect(
                x: 0.1,
                y: 0.1 + CGFloat(order) * 0.1,
                width: 0.5,
                height: 0.08
            ),
            sourceText: text,
            detectedLanguage: language,
            confidence: 1,
            readingOrder: order
        )
    }

    private func translate(
        _ blocks: [InPlaceOCRBlock],
        coordinator: InPlaceTranslationCoordinator,
        target: Language = .simplifiedChinese,
        provider: String = "provider"
    ) async
        -> [UUID: InPlaceTranslatedBlock] {
        await coordinator.translate(
            blocks: blocks,
            sourceLanguage: .english,
            targetLanguage: target,
            serviceIdentifier: provider
        ) { _, _, _ in }
    }
}

// MARK: - AdapterUsageRecorder

/// Captures usage accounting in memory without touching LocalStorage or analytics.
private final class AdapterUsageRecorder: InPlaceServiceUsageRecording, @unchecked Sendable {
    // MARK: Lifecycle

    init(
        callLog: AdapterCallLog? = nil,
        concurrencyProbe: AdapterConcurrencyProbe? = nil
    ) {
        self.callLog = callLog
        self.concurrencyProbe = concurrencyProbe
    }

    // MARK: Internal

    var count: Int {
        lock.withLock { recordedCount }
    }

    var isEmpty: Bool {
        count == 0
    }

    func recordSuccessfulPrehandle(for _: QueryService) {
        let record = { [self] in
            lock.withLock { recordedCount += 1 }
            callLog?.record("usage")
        }
        if let concurrencyProbe {
            concurrencyProbe.measure(record)
        } else {
            record()
        }
    }

    // MARK: Private

    private let callLog: AdapterCallLog?
    private let concurrencyProbe: AdapterConcurrencyProbe?
    private let lock = NSLock()
    private var recordedCount = 0
}

// MARK: - AdapterCallLog

/// Provides an ordered view of synchronous adapter-boundary callbacks.
private final class AdapterCallLog: @unchecked Sendable {
    // MARK: Internal

    var events: [String] {
        lock.withLock { recordedEvents }
    }

    func record(_ event: String) {
        lock.withLock { recordedEvents.append(event) }
    }

    // MARK: Private

    private let lock = NSLock()
    private var recordedEvents: [String] = []
}

// MARK: - AdapterConcurrencyProbe

/// Measures overlap at synchronous service preparation and provider call boundaries.
private final class AdapterConcurrencyProbe: @unchecked Sendable {
    // MARK: Lifecycle

    init(delayNanoseconds: UInt64) {
        self.delayNanoseconds = delayNanoseconds
    }

    // MARK: Internal

    var maximumConcurrentCount: Int {
        lock.withLock { maximumCount }
    }

    func measure<T>(_ operation: () -> T) -> T {
        begin()
        defer { end() }
        wait()
        return operation()
    }

    func begin() {
        lock.withLock {
            currentCount += 1
            maximumCount = max(maximumCount, currentCount)
        }
    }

    func end() {
        lock.withLock { currentCount -= 1 }
    }

    func wait() {
        Thread.sleep(forTimeInterval: TimeInterval(delayNanoseconds) / 1_000_000_000)
    }

    // MARK: Private

    private let delayNanoseconds: UInt64
    private let lock = NSLock()
    private var currentCount = 0
    private var maximumCount = 0
}

// MARK: - AdapterQueryService

/// Minimal real QueryService subclass that exposes adapter sequencing and cancellation.
private final class AdapterQueryService: QueryService, @unchecked Sendable {
    // MARK: Lifecycle

    init(
        autoConvertsChinese: Bool = false,
        callLog: AdapterCallLog? = nil,
        prehandleProbe: AdapterConcurrencyProbe? = nil,
        providerProbe: AdapterConcurrencyProbe? = nil,
        translationBarrier: CoordinatorTestBarrier? = nil,
        cancellationRecorder: AdapterCancellationRecorder? = nil,
        stopBlockRecorder: AdapterCancellationRecorder? = nil
    ) {
        self.autoConvertsChinese = autoConvertsChinese
        self.callLog = callLog
        self.prehandleProbe = prehandleProbe
        self.providerProbe = providerProbe
        self.translationBarrier = translationBarrier
        self.cancellationRecorder = cancellationRecorder
        self.stopBlockRecorder = stopBlockRecorder
        super.init()
    }

    required init() {
        self.autoConvertsChinese = false
        self.callLog = nil
        self.prehandleProbe = nil
        self.providerProbe = nil
        self.translationBarrier = nil
        self.cancellationRecorder = nil
        self.stopBlockRecorder = nil
        super.init()
    }

    // MARK: Internal

    private(set) var translateCallCount = 0
    private(set) var resultWasInitializedBeforeTranslate = false
    private(set) var queryInputObservedByTranslate = ""

    override func serviceType() -> ServiceType {
        .bing
    }

    override func name() -> String {
        "Adapter Fake"
    }

    override func supportLanguagesDictionary() -> MMOrderedDictionary {
        [
            Language.english: "en",
            Language.simplifiedChinese: "zh-Hans",
            Language.traditionalChinese: "zh-Hant",
        ].toMMOrderedDictionary()
    }

    override func apiKeyRequirement() -> ServiceAPIKeyRequirement {
        .none
    }

    override func autoConvertTraditionalChinese() -> Bool {
        autoConvertsChinese
    }

    override func prehandleQueryText(
        _ text: String,
        from: Language,
        to: Language
    ) async throws
        -> (Bool, QueryResult) {
        prehandleProbe?.begin()
        defer { prehandleProbe?.end() }
        prehandleProbe?.wait()
        return try await super.prehandleQueryText(text, from: from, to: to)
    }

    override func translate(
        _ text: String,
        from _: Language,
        to _: Language
    ) async throws
        -> QueryResult {
        translateCallCount += 1
        resultWasInitializedBeforeTranslate = result != nil
        queryInputObservedByTranslate = queryModel.inputText
        callLog?.record("translate")
        providerProbe?.begin()
        defer { providerProbe?.end() }
        providerProbe?.wait()
        if let stopBlockRecorder {
            queryModel.setStop({
                Task { await stopBlockRecorder.recordCancellation() }
            }, serviceType: serviceTypeWithUniqueIdentifier())
        }
        if let translationBarrier {
            await translationBarrier.arriveAndWait()
        }
        let currentResult = result ?? QueryResult()
        currentResult.translatedResults = ["provider:\(text)"]
        result = currentResult
        return currentResult
    }

    override func cancelStream() {
        guard let cancellationRecorder else { return }
        Task { await cancellationRecorder.recordCancellation() }
    }

    // MARK: Private

    private let autoConvertsChinese: Bool
    private let callLog: AdapterCallLog?
    private let prehandleProbe: AdapterConcurrencyProbe?
    private let providerProbe: AdapterConcurrencyProbe?
    private let translationBarrier: CoordinatorTestBarrier?
    private let cancellationRecorder: AdapterCancellationRecorder?
    private let stopBlockRecorder: AdapterCancellationRecorder?
}

// MARK: - AdapterCancellationRecorder

/// Bridges synchronous cancelStream into a deterministic async test observation.
private actor AdapterCancellationRecorder {
    // MARK: Internal

    func recordCancellation() {
        cancellationCount += 1
        continuation?.resume()
        continuation = nil
    }

    func waitForCancellation() async {
        guard cancellationCount == 0 else { return }
        await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
    }

    func count() -> Int {
        cancellationCount
    }

    // MARK: Private

    private var cancellationCount = 0
    private var continuation: CheckedContinuation<(), Never>?
}

// MARK: - CoordinatorTestBarrier

/// Suspends one fake provider request until the test has applied cancellation.
private actor CoordinatorTestBarrier {
    // MARK: Internal

    func arriveAndWait() async {
        hasArrived = true
        arrivalContinuation?.resume()
        arrivalContinuation = nil
        guard !isReleased else { return }
        await withCheckedContinuation { continuation in
            releaseContinuation = continuation
        }
    }

    func waitForArrival() async {
        guard !hasArrived else { return }
        await withCheckedContinuation { continuation in
            arrivalContinuation = continuation
        }
    }

    func release() {
        isReleased = true
        releaseContinuation?.resume()
        releaseContinuation = nil
    }

    // MARK: Private

    private var hasArrived = false
    private var isReleased = false
    private var arrivalContinuation: CheckedContinuation<(), Never>?
    private var releaseContinuation: CheckedContinuation<(), Never>?
}

// MARK: - CancellableBarrierTranslator

/// Records the first request and deliberately ignores cancellation while blocked.
private actor CancellableBarrierTranslator: InPlaceBlockTranslating {
    // MARK: Lifecycle

    init(barrier: CoordinatorTestBarrier) {
        self.barrier = barrier
    }

    // MARK: Internal

    func translate(
        text: String,
        sourceLanguage _: Language,
        targetLanguage _: Language,
        serviceIdentifier _: String
    ) async throws
        -> String {
        texts.append(text)
        await barrier.arriveAndWait()
        return "translated:\(text)"
    }

    func requestedTexts() -> [String] {
        texts
    }

    // MARK: Private

    private let barrier: CoordinatorTestBarrier
    private var texts: [String] = []
}

// MARK: - TranslationUpdateRecorder

/// Serializes progress callbacks so concurrency tests can inspect a stable update sequence.
private actor TranslationUpdateRecorder {
    // MARK: Internal

    /// One generation-scoped progress callback captured from the coordinator.
    struct Update: Sendable {
        let blockID: UUID
        let completed: Int
        let total: Int
    }

    func record(block: InPlaceTranslatedBlock, completed: Int, total: Int) {
        recordedUpdates.append(
            Update(blockID: block.id, completed: completed, total: total)
        )
    }

    func updates() -> [Update] {
        recordedUpdates
    }

    // MARK: Private

    private var recordedUpdates: [Update] = []
}

// MARK: - TestBlockTranslator

/// A deterministic block translator that records overlap and produces selected error classes.
private actor TestBlockTranslator: InPlaceBlockTranslating {
    // MARK: Lifecycle

    init(
        delayNanoseconds: UInt64 = 0,
        behaviors: [String: Behavior] = [:]
    ) {
        self.delayNanoseconds = delayNanoseconds
        self.behaviors = behaviors
    }

    // MARK: Internal

    /// Deterministic response behavior selected by source text.
    enum Behavior: Sendable {
        case success
        case timeoutOnce
        case authentication
        case cancellation
    }

    /// One provider request observed by the fake translator.
    struct Request: Sendable {
        let text: String
        let sourceLanguage: Language
        let targetLanguage: Language
        let serviceIdentifier: String
    }

    /// Stable concurrency and attempt counters returned to the test actor.
    struct Metrics: Sendable {
        let requests: [Request]
        let maximumConcurrentCount: Int
        let attemptsByText: [String: Int]

        var requestCount: Int {
            requests.count
        }
    }

    func translate(
        text: String,
        sourceLanguage: Language,
        targetLanguage: Language,
        serviceIdentifier: String
    ) async throws
        -> String {
        requests.append(
            Request(
                text: text,
                sourceLanguage: sourceLanguage,
                targetLanguage: targetLanguage,
                serviceIdentifier: serviceIdentifier
            )
        )
        attemptsByText[text, default: 0] += 1
        currentConcurrentCount += 1
        maximumConcurrentCount = max(maximumConcurrentCount, currentConcurrentCount)
        defer { currentConcurrentCount -= 1 }

        if delayNanoseconds > 0 {
            try await Task<Never, Never>.sleep(nanoseconds: delayNanoseconds)
        }

        switch behaviors[text, default: .success] {
        case .success:
            return "translated:\(text)"
        case .timeoutOnce:
            if attemptsByText[text] == 1 {
                throw URLError(.timedOut)
            }
            return "translated:\(text)"
        case .authentication:
            throw QueryError.error(type: .missingSecretKey)
        case .cancellation:
            throw CancellationError()
        }
    }

    func metrics() -> Metrics {
        Metrics(
            requests: requests,
            maximumConcurrentCount: maximumConcurrentCount,
            attemptsByText: attemptsByText
        )
    }

    // MARK: Private

    private let delayNanoseconds: UInt64
    private let behaviors: [String: Behavior]
    private var requests: [Request] = []
    private var attemptsByText: [String: Int] = [:]
    private var currentConcurrentCount = 0
    private var maximumConcurrentCount = 0
}
