//
//  InPlaceTranslationCoordinator.swift
//  Easydict
//
//  Created by Eric Pan on 2026/8/30.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation

// MARK: - InPlaceBlockTranslating

/// Production boundary for translating one layout block with one explicit provider.
protocol InPlaceBlockTranslating: Sendable {
    func translate(
        text: String,
        sourceLanguage: Language,
        targetLanguage: Language,
        serviceIdentifier: String
    ) async throws
        -> String
}

// MARK: - InPlaceServiceUsageRecording

/// Records one provider attempt after request preprocessing has succeeded.
/// Implementations must not retain or log the query text.
protocol InPlaceServiceUsageRecording: Sendable {
    func recordSuccessfulPrehandle(for service: QueryService)
}

// MARK: - LocalStorageInPlaceServiceUsageRecorder

/// Preserves the same per-service quota and analytics accounting used by the
/// legacy query windows. Serialization is provided by the request boundary.
final class LocalStorageInPlaceServiceUsageRecorder: InPlaceServiceUsageRecording, @unchecked Sendable {
    // MARK: Lifecycle

    init(storage: LocalStorage = .shared()) {
        self.storage = storage
    }

    // MARK: Internal

    func recordSuccessfulPrehandle(for service: QueryService) {
        storage.increaseQueryService(service)
    }

    // MARK: Private

    private let storage: LocalStorage
}

// MARK: - QueryServiceInPlaceBlockTranslator

/// Creates a fresh configured QueryService for every block so mutable provider
/// results can never cross concurrent requests.
final class QueryServiceInPlaceBlockTranslator: InPlaceBlockTranslating, @unchecked Sendable {
    // MARK: Lifecycle

    init(
        resolver: InPlaceTranslationServiceResolver = .init(),
        usageRecorder: any InPlaceServiceUsageRecording = LocalStorageInPlaceServiceUsageRecorder(),
        serviceFactory: (@Sendable (String) -> QueryService?)? = nil
    ) {
        let serviceFactory = serviceFactory ?? { identifier in
            resolver.makeService(identifier: identifier)
        }
        self.requestBoundary = QueryServiceInPlaceRequestBoundary(
            serviceFactory: serviceFactory,
            usageRecorder: usageRecorder
        )
    }

    // MARK: Internal

    func translate(
        text: String,
        sourceLanguage: Language,
        targetLanguage: Language,
        serviceIdentifier: String
    ) async throws
        -> String {
        try Task.checkCancellation()
        let preparedRequest = try await requestBoundary.prepare(
            identifier: serviceIdentifier,
            text: text,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage
        )
        let service = preparedRequest.service
        let cancellation = QueryServiceCancellation(service: service)
        return try await withTaskCancellationHandler {
            try Task.checkCancellation()
            let result: QueryResult
            if preparedRequest.handled {
                result = preparedRequest.prehandledResult
            } else {
                result = try await service.translate(
                    text,
                    from: sourceLanguage,
                    to: targetLanguage
                )
            }
            try Task.checkCancellation()
            if let error = result.error {
                throw error
            }
            guard let translatedText = result.translatedText?.trim(), !translatedText.isEmpty else {
                throw QueryError.error(type: .noResult)
            }
            return translatedText
        } onCancel: {
            cancellation.cancel()
        }
    }

    // MARK: Private

    private let requestBoundary: QueryServiceInPlaceRequestBoundary
}

// MARK: - QueryServiceInPlaceRequestBoundary

/// Serializes LocalStorage-backed service construction and usage accounting
/// together with the intervening quota prehandle. Provider network work starts
/// only after the logical permit is released and remains concurrent.
private actor QueryServiceInPlaceRequestBoundary {
    // MARK: Lifecycle

    init(
        serviceFactory: @escaping @Sendable (String) -> QueryService?,
        usageRecorder: any InPlaceServiceUsageRecording
    ) {
        self.serviceFactory = serviceFactory
        self.usageRecorder = usageRecorder
    }

    // MARK: Internal

    struct PreparedRequest: @unchecked Sendable {
        let service: QueryService
        let handled: Bool
        let prehandledResult: QueryResult
    }

    func prepare(
        identifier: String,
        text: String,
        sourceLanguage: Language,
        targetLanguage: Language
    ) async throws
        -> PreparedRequest {
        let requestID = UUID()
        try await acquirePermit(requestID: requestID)
        defer { releasePermit() }

        try Task.checkCancellation()
        guard let service = serviceFactory(identifier) else {
            throw QueryError.error(type: .unsupportedServiceType)
        }
        service.queryModel.actionType = .screenshotOCR
        service.queryModel.userSourceLanguage = sourceLanguage
        service.queryModel.userTargetLanguage = targetLanguage
        let (handled, prehandledResult) = try await service.prehandleQueryText(
            text,
            from: sourceLanguage,
            to: targetLanguage
        )
        try Task.checkCancellation()
        usageRecorder.recordSuccessfulPrehandle(for: service)
        return PreparedRequest(
            service: service,
            handled: handled,
            prehandledResult: prehandledResult
        )
    }

    // MARK: Private

    private typealias WaitContinuation = CheckedContinuation<(), Error>

    private struct Waiter {
        let id: UUID
        let continuation: WaitContinuation
    }

    private let serviceFactory: @Sendable (String) -> QueryService?
    private let usageRecorder: any InPlaceServiceUsageRecording
    private var ownsPermit = false
    private var waiters: [Waiter] = []

    private func acquirePermit(requestID: UUID) async throws {
        try Task.checkCancellation()
        guard ownsPermit else {
            ownsPermit = true
            return
        }

        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: WaitContinuation) in
                guard !Task.isCancelled else {
                    continuation.resume(throwing: CancellationError())
                    return
                }
                waiters.append(Waiter(id: requestID, continuation: continuation))
            }
        } onCancel: { [weak self] in
            guard let self else { return }
            Task { await self.cancelWaiter(requestID: requestID) }
        }
    }

    private func cancelWaiter(requestID: UUID) {
        guard let index = waiters.firstIndex(where: { $0.id == requestID }) else { return }
        let waiter = waiters.remove(at: index)
        waiter.continuation.resume(throwing: CancellationError())
    }

    private func releasePermit() {
        guard !waiters.isEmpty else {
            ownsPermit = false
            return
        }
        let nextWaiter = waiters.removeFirst()
        nextWaiter.continuation.resume()
    }
}

// MARK: - QueryServiceCancellation

/// Makes the legacy mutable service safe to capture from a task cancellation
/// handler. Legacy requests register cancellation with QueryModel, while
/// streaming providers expose their transport through `cancelStream()`.
private final class QueryServiceCancellation: @unchecked Sendable {
    // MARK: Lifecycle

    init(service: QueryService) {
        self.service = service
    }

    // MARK: Internal

    func cancel() {
        service.queryModel.stopAllService()
        service.cancelStream()
    }

    // MARK: Private

    private let service: QueryService
}

// MARK: - InPlaceTranslationCoordinator

/// Owns the session-only LRU cache and translates changed blocks with bounded
/// provider-independent concurrency and no provider fallback.
actor InPlaceTranslationCoordinator {
    // MARK: Lifecycle

    init(
        translator: any InPlaceBlockTranslating = QueryServiceInPlaceBlockTranslator(),
        maximumConcurrency: Int = InPlaceTranslationConstants.maximumTranslationConcurrency,
        retryDelay: TimeInterval = 2
    ) {
        self.translator = translator
        self.maximumConcurrency = max(1, maximumConcurrency)
        self.retryDelay = max(0, retryDelay)
    }

    // MARK: Internal

    /// Translates blocks and reports every cache hit or finished request as it becomes available.
    func translate(
        blocks: [InPlaceOCRBlock],
        sourceLanguage: Language,
        targetLanguage: Language,
        serviceIdentifier: String,
        onUpdate: @escaping @Sendable (InPlaceTranslatedBlock, Int, Int) async -> ()
    ) async
        -> [UUID: InPlaceTranslatedBlock] {
        guard !Task.isCancelled else { return [:] }
        var results: [UUID: InPlaceTranslatedBlock] = [:]
        var requests: [Request] = []
        var requestIndexByCacheKey: [InPlaceTranslationCacheKey: Int] = [:]
        let total = blocks.count
        var completed = 0

        for block in blocks {
            guard !Task.isCancelled else { return results }
            let actualSource = sourceLanguage == .auto ? block.detectedLanguage : sourceLanguage
            let key = InPlaceTranslationCacheKey(
                sourceText: block.sourceText,
                sourceLanguage: actualSource,
                targetLanguage: targetLanguage,
                serviceIdentifier: serviceIdentifier
            )
            if let cached = cache.value(for: key) {
                let translated = InPlaceTranslatedBlock(
                    block: block,
                    translatedText: cached,
                    status: .translated,
                    providerIdentifier: serviceIdentifier
                )
                results[block.id] = translated
                completed += 1
                guard !Task.isCancelled else { return results }
                await onUpdate(translated, completed, total)
                guard !Task.isCancelled else { return results }
            } else {
                if let requestIndex = requestIndexByCacheKey[key] {
                    requests[requestIndex].blocks.append(block)
                } else {
                    requestIndexByCacheKey[key] = requests.count
                    requests.append(
                        Request(
                            sourceText: block.sourceText,
                            blocks: [block],
                            sourceLanguage: actualSource,
                            targetLanguage: targetLanguage,
                            serviceIdentifier: serviceIdentifier,
                            cacheKey: key
                        )
                    )
                }
            }
        }

        await withTaskGroup(of: Outcome?.self) { group in
            var iterator = requests.makeIterator()
            for _ in 0 ..< min(maximumConcurrency, requests.count) {
                guard !Task.isCancelled else {
                    group.cancelAll()
                    return
                }
                if let request = iterator.next() {
                    addTask(for: request, to: &group)
                }
            }

            while let possibleOutcome = await group.next() {
                guard !Task.isCancelled else {
                    group.cancelAll()
                    return
                }
                guard let outcome = possibleOutcome else { continue }
                if let value = outcome.translatedText, outcome.status == .translated {
                    cache.insert(value, for: outcome.request.cacheKey)
                }
                for block in outcome.request.blocks {
                    let translated = InPlaceTranslatedBlock(
                        block: block,
                        translatedText: outcome.translatedText,
                        status: outcome.status,
                        providerIdentifier: outcome.request.serviceIdentifier
                    )
                    results[translated.id] = translated
                    completed += 1
                    await onUpdate(translated, completed, total)
                    guard !Task.isCancelled else {
                        group.cancelAll()
                        return
                    }
                }

                if let nextRequest = iterator.next() {
                    addTask(for: nextRequest, to: &group)
                }
            }
        }
        return results
    }

    func removeAllCachedTranslations() {
        cache.removeAll()
    }

    // MARK: Private

    /// Immutable child-task input for one block.
    private struct Request: Sendable {
        let sourceText: String
        var blocks: [InPlaceOCRBlock]
        let sourceLanguage: Language
        let targetLanguage: Language
        let serviceIdentifier: String
        let cacheKey: InPlaceTranslationCacheKey
    }

    /// Child-task output with its cache identity.
    private struct Outcome: Sendable {
        let request: Request
        let translatedText: String?
        let status: InPlaceBlockTranslationStatus
    }

    private let translator: any InPlaceBlockTranslating
    private let maximumConcurrency: Int
    private let retryDelay: TimeInterval
    private var cache = InPlaceTranslationCache()

    private static func translateWithRetry(
        request: Request,
        translator: any InPlaceBlockTranslating,
        retryDelay: TimeInterval
    ) async throws
        -> String {
        try Task.checkCancellation()
        do {
            let result = try await translator.translate(
                text: request.sourceText,
                sourceLanguage: request.sourceLanguage,
                targetLanguage: request.targetLanguage,
                serviceIdentifier: request.serviceIdentifier
            )
            try Task.checkCancellation()
            return result
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            try Task.checkCancellation()
            guard isRetryable(error) else { throw error }
            if retryDelay > 0 {
                try await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
            }
            try Task.checkCancellation()
            let result = try await translator.translate(
                text: request.sourceText,
                sourceLanguage: request.sourceLanguage,
                targetLanguage: request.targetLanguage,
                serviceIdentifier: request.serviceIdentifier
            )
            try Task.checkCancellation()
            return result
        }
    }

    private static func isRetryable(_ error: Error) -> Bool {
        if let queryError = error as? QueryError {
            return queryError.type == .timeout
        }
        let error = error as NSError
        guard error.domain == NSURLErrorDomain else { return false }
        let retryableCodes: Set<Int> = [
            NSURLErrorTimedOut,
            NSURLErrorNetworkConnectionLost,
            NSURLErrorCannotConnectToHost,
            NSURLErrorNotConnectedToInternet,
        ]
        return retryableCodes.contains(error.code)
    }

    private static func category(for error: Error) -> InPlaceTranslationErrorCategory {
        if let queryError = error as? QueryError {
            switch queryError.type {
            case .missingSecretKey:
                return .authentication
            case .unsupportedLanguage:
                return .unsupportedLanguage
            case .timeout:
                return .network
            case .unsupportedServiceType:
                return .serviceUnavailable
            case .api:
                return categoryFromMessage(
                    [queryError.message, queryError.errorDataMessage]
                        .compactMap { $0 }
                        .joined(separator: " ")
                )
            default:
                return .serviceUnavailable
            }
        }
        let error = error as NSError
        if error.code == 429 {
            return .rateLimited
        }
        if error.code == 401 || error.code == 403 {
            return .authentication
        }
        if error.domain == NSURLErrorDomain {
            return .network
        }
        return categoryFromMessage(error.localizedDescription)
    }

    /// Provider errors are not normalized across legacy services. Inspect only
    /// their failure metadata to select a sanitized UI category; the message is
    /// never published or logged by this feature.
    private static func categoryFromMessage(_ message: String) -> InPlaceTranslationErrorCategory {
        let message = message.lowercased()
        if message.contains("429")
            || message.contains("rate limit")
            || message.contains("too many requests")
            || message.contains("quota exceeded")
            || message.contains("insufficient_quota") {
            return .rateLimited
        }
        if message.contains("401")
            || message.contains("403")
            || message.contains("unauthorized")
            || message.contains("authentication")
            || message.contains("not logged in")
            || message.contains("invalid api key") {
            return .authentication
        }
        if message.contains("unsupported language")
            || message.contains("invalid language") {
            return .unsupportedLanguage
        }
        if message.contains("network")
            || message.contains("connection")
            || message.contains("timed out")
            || message.contains("offline")
            || message.contains("cannot connect")
            || message.contains("dns") {
            return .network
        }
        return .serviceUnavailable
    }

    private func addTask(
        for request: Request,
        to group: inout TaskGroup<Outcome?>
    ) {
        guard !Task.isCancelled else { return }
        let translator = translator
        let retryDelay = retryDelay
        group.addTask {
            do {
                try Task.checkCancellation()
                let text = try await Self.translateWithRetry(
                    request: request,
                    translator: translator,
                    retryDelay: retryDelay
                )
                try Task.checkCancellation()
                return Outcome(
                    request: request,
                    translatedText: text,
                    status: .translated
                )
            } catch is CancellationError {
                guard !Task.isCancelled else { return nil }
                return Outcome(
                    request: request,
                    translatedText: nil,
                    status: .failed(.serviceUnavailable)
                )
            } catch {
                guard !Task.isCancelled else { return nil }
                return Outcome(
                    request: request,
                    translatedText: nil,
                    status: .failed(Self.category(for: error))
                )
            }
        }
    }
}
