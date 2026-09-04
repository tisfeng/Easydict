//
//  InPlaceTranslationSession.swift
//  Easydict
//
//  Created by Eric Pan on 2026/8/30.
//  Copyright © 2026 izual. All rights reserved.
//

import AppKit
import Foundation

// MARK: - InPlaceOCRExecutionGate

/// Serializes the actual Vision operation for one session. A running legacy
/// request keeps ownership until it really returns, even when its pipeline Task
/// was cancelled. At most the newest request is retained as a pending waiter.
private actor InPlaceOCRExecutionGate {
    // MARK: Internal

    func run<Value: Sendable>(
        requestID: UUID,
        operation: @escaping @Sendable () async throws -> Value
    ) async throws
        -> Value {
        try await acquire(requestID: requestID)
        do {
            try Task.checkCancellation()
            let value = try await operation()
            try Task.checkCancellation()
            finish(requestID: requestID)
            return value
        } catch {
            finish(requestID: requestID)
            throw error
        }
    }

    // MARK: Private

    private typealias WaitContinuation = CheckedContinuation<(), Error>

    private struct PendingRequest {
        let id: UUID
        let continuation: WaitContinuation
    }

    private var runningRequestID: UUID?
    private var pendingRequest: PendingRequest?

    private func acquire(requestID: UUID) async throws {
        try Task.checkCancellation()
        guard runningRequestID != nil else {
            runningRequestID = requestID
            return
        }

        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: WaitContinuation) in
                guard !Task.isCancelled else {
                    continuation.resume(throwing: CancellationError())
                    return
                }
                pendingRequest?.continuation.resume(throwing: CancellationError())
                pendingRequest = PendingRequest(id: requestID, continuation: continuation)
            }
        } onCancel: { [weak self] in
            guard let self else { return }
            Task { await self.cancelPending(requestID: requestID) }
        }
    }

    private func cancelPending(requestID: UUID) {
        guard pendingRequest?.id == requestID else { return }
        let continuation = pendingRequest?.continuation
        pendingRequest = nil
        continuation?.resume(throwing: CancellationError())
    }

    private func finish(requestID: UUID) {
        guard runningRequestID == requestID else { return }
        guard let pendingRequest else {
            runningRequestID = nil
            return
        }
        self.pendingRequest = nil
        runningRequestID = pendingRequest.id
        pendingRequest.continuation.resume()
    }
}

// MARK: - InPlaceTranslationSession

/// Serializes one capture region's generation, diff/debounce state, OCR, cache,
/// and block translation tasks. Every publish is guarded by a monotonic token.
actor InPlaceTranslationSession {
    // MARK: Lifecycle

    init(
        selection: ScreenshotSelection,
        configuration: InPlaceTranslationConfiguration,
        viewModel: InPlaceTranslationViewModel,
        frameSource: any RegionFrameSource,
        ocrPipeline: InPlaceOCRPipeline = .init(),
        blockMatcher: InPlaceOCRBlockMatcher = .init(),
        translationCoordinator: InPlaceTranslationCoordinator = .init(),
        changeDetector: InPlaceFrameChangeDetector = .init()
    ) {
        self.selection = selection
        self.configuration = configuration
        self.viewModel = viewModel
        self.frameSource = frameSource
        self.ocrPipeline = ocrPipeline
        self.blockMatcher = blockMatcher
        self.translationCoordinator = translationCoordinator
        self.changeDetector = changeDetector
    }

    // MARK: Internal

    func start() async {
        guard lifecycle == .starting else { return }
        await publish(lifecycle: .starting, processing: .idle, availability: .available)
        guard lifecycle == .starting, !Task.isCancelled else { return }
        guard let initialImage = selection.initialImage.toCGImage() else {
            await publish(
                processing: .recoverableError(generation: nil, category: .capture),
                availability: .temporarilyUnavailable
            )
            return
        }

        lifecycle = configuration.liveUpdatesEnabled ? .running : .paused
        let initialFrame = CapturedRegionFrame(
            image: initialImage,
            capturedAt: ProcessInfo.processInfo.systemUptime,
            dirtyRects: nil
        )
        latestFrame = initialFrame
        scheduleProcessing(initialFrame, force: true)

        if configuration.liveUpdatesEnabled {
            await startFrameSource()
        }
        guard isActiveLifecycle, !Task.isCancelled else { return }
        await publish(lifecycle: lifecycle)
    }

    /// Pauses an existing session while a replacement selector is onscreen.
    func suspendForReselection() async -> Bool {
        guard isActiveLifecycle else { return false }
        let shouldResume = configuration.liveUpdatesEnabled && lifecycle == .running
        lifecycle = .paused
        invalidateWork()
        await stopFrameSource()
        guard lifecycle == .paused else { return shouldResume }
        await publish(lifecycle: .paused, processing: .idle)
        return shouldResume
    }

    /// Restores an old session after the user cancels replacement selection.
    func resumeAfterCancelledReselection(_ shouldResume: Bool) async {
        guard lifecycle == .paused else { return }
        if shouldResume {
            lifecycle = .running
            await startFrameSource()
            guard lifecycle == .running, configuration.liveUpdatesEnabled else { return }
            if let latestFrame {
                scheduleProcessing(latestFrame, force: true)
            }
        }
        await publish(lifecycle: lifecycle)
    }

    func setLiveUpdatesEnabled(_ enabled: Bool) async {
        guard isActiveLifecycle else { return }
        configuration.liveUpdatesEnabled = enabled
        if enabled {
            lifecycle = .running
            await startFrameSource()
            guard lifecycle == .running, configuration.liveUpdatesEnabled else { return }
            if let latestFrame {
                scheduleProcessing(latestFrame, force: true)
            }
            await publish(lifecycle: .running, availability: .available)
        } else {
            lifecycle = .paused
            invalidateWork()
            await stopFrameSource()
            guard lifecycle == .paused, !configuration.liveUpdatesEnabled else { return }
            await publish(lifecycle: .paused, processing: .idle)
        }
    }

    func refresh() {
        guard isActiveLifecycle, let latestFrame else { return }
        scheduleProcessing(latestFrame, force: true, resetOCRRetryBudget: true)
    }

    func setSourceLanguage(_ language: Language) {
        guard isActiveLifecycle else { return }
        configuration.sourceLanguage = language
        if let latestFrame {
            scheduleProcessing(
                latestFrame,
                force: true,
                reusePreviousTranslations: false,
                resetOCRRetryBudget: true
            )
        }
    }

    func setTargetLanguage(_ language: Language) {
        guard isActiveLifecycle, language != .auto else { return }
        configuration.targetLanguage = language
        scheduleRetranslation()
    }

    func setLanguages(source: Language, target: Language) {
        guard isActiveLifecycle, target != .auto else { return }
        configuration.sourceLanguage = source
        configuration.targetLanguage = target
        if let latestFrame {
            scheduleProcessing(
                latestFrame,
                force: true,
                reusePreviousTranslations: false,
                resetOCRRetryBudget: true
            )
        }
    }

    func setServiceIdentifier(_ identifier: String, targetLanguage: Language) async {
        guard let generation = beginServiceChange(
            identifier: identifier,
            targetLanguage: targetLanguage
        ) else {
            return
        }
        await completeServiceChange(generation: generation)
    }

    /// Compatibility overload for callers that do not need to adjust provider
    /// language support. The provider and current target still change in one
    /// actor-isolated generation.
    func setServiceIdentifier(_ identifier: String) async {
        guard let generation = beginServiceChange(
            identifier: identifier,
            targetLanguage: configuration.targetLanguage
        ) else {
            return
        }
        await completeServiceChange(generation: generation)
    }

    func stop() async {
        guard lifecycle != .stopped, lifecycle != .stopping else { return }
        lifecycle = .stopping
        _ = generationGate.invalidate()
        invalidateWork(incrementGeneration: false)
        await stopFrameSource()
        await translationCoordinator.removeAllCachedTranslations()
        currentSnapshot = nil
        latestFrame = nil
        lastProcessedSignature = nil
        lifecycle = .stopped
        await publish(lifecycle: .stopped, processing: .idle)
    }

    // MARK: Private

    private let selection: ScreenshotSelection
    private weak var viewModel: InPlaceTranslationViewModel?
    private let frameSource: any RegionFrameSource
    private let ocrPipeline: InPlaceOCRPipeline
    private let ocrExecutionGate = InPlaceOCRExecutionGate()
    private let blockMatcher: InPlaceOCRBlockMatcher
    private let translationCoordinator: InPlaceTranslationCoordinator
    private let changeDetector: InPlaceFrameChangeDetector

    private var configuration: InPlaceTranslationConfiguration
    private var lifecycle: InPlaceTranslationLifecycle = .starting
    private var generationGate = InPlaceGenerationGate()
    private var currentSnapshot: InPlaceRenderSnapshot?
    private var latestFrame: CapturedRegionFrame?
    private var latestCandidate: CapturedRegionFrame?
    private var latestCandidateSignature: InPlaceFrameSignature?
    private var lastProcessedSignature: InPlaceFrameSignature?
    private var inFlightSignature: InPlaceFrameSignature?
    private var inFlightSignatureGeneration: UInt64?
    private var failedOCRSignature: InPlaceFrameSignature?
    private var hasFailedOCRIdentity = false
    private var genericOCRFailureCount = 0
    private var firstCandidateTime: TimeInterval?
    private var lastOCRStartTime: TimeInterval?
    private var debounceTask: Task<(), Never>?
    private var pipelineTask: Task<(), Never>?
    private var isFrameSourceRunning = false
    private var didAttemptCaptureRecovery = false
    private var frameSourceEpoch: UInt64 = 0

    /// Commits provider configuration and invalidates the old generation before
    /// the first suspension point, so no old provider request can be scheduled
    /// while cache cleanup is waiting on the coordinator actor.
    private func beginServiceChange(
        identifier: String,
        targetLanguage: Language
    )
        -> UInt64? {
        guard isActiveLifecycle, targetLanguage != .auto else { return nil }
        configuration.serviceIdentifier = identifier
        configuration.targetLanguage = targetLanguage
        let generation = generationGate.invalidate()
        invalidateWork(incrementGeneration: false)
        return generation
    }

    private func completeServiceChange(generation: UInt64) async {
        await translationCoordinator.removeAllCachedTranslations()
        guard acceptsPipelineWork(generation) else { return }
        if currentSnapshot != nil {
            scheduleRetranslation(generation: generation)
        } else if let latestFrame {
            scheduleProcessing(
                latestFrame,
                signature: changeDetector.makeSignature(for: latestFrame.image),
                force: true,
                reusePreviousTranslations: false,
                generation: generation
            )
        }
    }

    private func runOCRAndTranslation(
        frame: CapturedRegionFrame,
        signature: InPlaceFrameSignature?,
        generation: UInt64,
        reusePreviousTranslations: Bool
    ) async {
        guard acceptsPipelineWork(generation) else { return }
        await publish(processing: .recognizing(generation: generation))
        guard acceptsPipelineWork(generation) else { return }
        let sourceLanguage = configuration.sourceLanguage
        do {
            try Task.checkCancellation()
            let ocrPipeline = ocrPipeline
            let ocrResult = try await ocrExecutionGate.run(requestID: UUID()) {
                try await ocrPipeline.recognize(
                    image: frame.image,
                    language: sourceLanguage
                )
            }
            try Task.checkCancellation()
            guard acceptsPipelineWork(generation) else { return }
            clearOCRRetryBudget()
            commitProcessedSignature(signature, generation: generation)
            await applyOCRResult(
                ocrResult,
                frame: frame,
                generation: generation,
                reusePreviousTranslations: reusePreviousTranslations
            )
        } catch is CancellationError {
            clearInFlightSignature(generation: generation)
            return
        } catch is InPlaceOCRPipelineError {
            guard acceptsPipelineWork(generation) else { return }
            clearOCRRetryBudget()
            commitProcessedSignature(signature, generation: generation)
            await publish(
                processing: .recoverableError(
                    generation: generation,
                    category: .selectionTooLarge
                )
            )
        } catch let error as QueryError where error.type == .noResult {
            guard acceptsPipelineWork(generation) else { return }
            clearOCRRetryBudget()
            commitProcessedSignature(signature, generation: generation)
            await publishNoText(frame: frame, generation: generation)
        } catch {
            guard acceptsPipelineWork(generation) else { return }
            if recordGenericOCRFailure(signature) {
                commitProcessedSignature(signature, generation: generation)
            } else {
                clearInFlightSignature(generation: generation)
            }
            await publish(
                processing: .recoverableError(generation: generation, category: .unknown)
            )
        }
    }

    private func applyOCRResult(
        _ result: InPlaceOCRPipelineResult,
        frame: CapturedRegionFrame,
        generation: UInt64,
        reusePreviousTranslations: Bool
    ) async {
        guard acceptsPipelineWork(generation) else { return }
        guard !result.blocks.isEmpty else {
            await publishNoText(frame: frame, generation: generation)
            return
        }

        let previousBlocks = currentSnapshot?.blocks.map(\.block) ?? []
        let match = blockMatcher.match(previous: previousBlocks, current: result.blocks)
        let previousTranslations = Dictionary(
            uniqueKeysWithValues: (currentSnapshot?.blocks ?? []).map { ($0.id, $0) }
        )
        let canReuseDetectedLanguage = configuration.sourceLanguage != .auto
            || currentSnapshot?.detectedLanguage == result.detectedLanguage

        var renderBlocks: [InPlaceTranslatedBlock] = []
        var blocksNeedingTranslation: [InPlaceOCRBlock] = []
        for block in match.blocks {
            let isSemanticallyUnchanged = match.unchangedBlockIDs.contains(block.id)
                || match.geometryOnlyBlockIDs.contains(block.id)
            if reusePreviousTranslations,
               canReuseDetectedLanguage,
               isSemanticallyUnchanged,
               let previous = previousTranslations[block.id],
               previous.providerIdentifier == configuration.serviceIdentifier,
               let translatedText = previous.translatedText,
               previous.status == .translated {
                renderBlocks.append(
                    InPlaceTranslatedBlock(
                        block: block,
                        translatedText: translatedText,
                        status: .translated,
                        providerIdentifier: configuration.serviceIdentifier
                    )
                )
            } else {
                renderBlocks.append(pendingTranslation(for: block))
                blocksNeedingTranslation.append(block)
            }
        }

        let snapshot = InPlaceRenderSnapshot(
            generation: generation,
            image: frame.image,
            blocks: renderBlocks,
            capturedAt: frame.capturedAt,
            detectedLanguage: result.detectedLanguage
        )
        currentSnapshot = snapshot
        await publish(snapshot: snapshot)
        guard acceptsPipelineWork(generation) else { return }

        guard !blocksNeedingTranslation.isEmpty else {
            await publish(processing: .ready(generation: generation))
            return
        }
        await translate(
            blocks: blocksNeedingTranslation,
            generation: generation,
            totalBlockCount: renderBlocks.count
        )
    }

    private func translate(
        blocks: [InPlaceOCRBlock],
        generation: UInt64,
        totalBlockCount: Int
    ) async {
        guard acceptsPipelineWork(generation) else { return }
        await publish(
            processing: .translating(generation: generation, completed: 0, total: blocks.count)
        )
        guard acceptsPipelineWork(generation) else { return }
        let sourceLanguage = configuration.sourceLanguage
        let targetLanguage = configuration.targetLanguage
        let serviceIdentifier = configuration.serviceIdentifier
        guard acceptsPipelineWork(generation) else { return }
        _ = await translationCoordinator.translate(
            blocks: blocks,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
            serviceIdentifier: serviceIdentifier
        ) { [weak self] translatedBlock, completed, total in
            await self?.applyTranslationUpdate(
                translatedBlock,
                generation: generation,
                completed: completed,
                total: total
            )
        }
        guard acceptsPipelineWork(generation), let currentSnapshot else { return }
        let failureCategories = currentSnapshot.blocks.compactMap { block -> InPlaceTranslationErrorCategory? in
            if case let .failed(category) = block.status {
                return category
            }
            return nil
        }
        if failureCategories.isEmpty {
            await publish(processing: .ready(generation: generation))
        } else if failureCategories.count < currentSnapshot.blocks.count {
            await publish(
                processing: .partialFailure(
                    generation: generation,
                    failed: failureCategories.count,
                    total: currentSnapshot.blocks.count
                )
            )
        } else {
            await publish(
                processing: .recoverableError(
                    generation: generation,
                    category: primaryFailureCategory(failureCategories)
                )
            )
        }
        _ = totalBlockCount
    }

    private func applyTranslationUpdate(
        _ translatedBlock: InPlaceTranslatedBlock,
        generation: UInt64,
        completed: Int,
        total: Int
    ) async {
        guard acceptsPipelineWork(generation), var snapshot = currentSnapshot else { return }
        let blocks = snapshot.blocks.map { block in
            block.id == translatedBlock.id ? translatedBlock : block
        }
        snapshot = InPlaceRenderSnapshot(
            generation: snapshot.generation,
            image: snapshot.image,
            blocks: blocks,
            capturedAt: snapshot.capturedAt,
            detectedLanguage: snapshot.detectedLanguage
        )
        currentSnapshot = snapshot
        await publish(
            processing: .translating(
                generation: generation,
                completed: completed,
                total: total
            ),
            snapshot: snapshot
        )
    }

    private func scheduleRetranslation(generation providedGeneration: UInt64? = nil) {
        guard let currentSnapshot, !currentSnapshot.blocks.isEmpty else { return }
        let generation = providedGeneration ?? generationGate.invalidate()
        guard generationGate.accepts(generation), isActiveLifecycle else { return }
        pipelineTask?.cancel()
        let pendingBlocks = currentSnapshot.blocks.map { pendingTranslation(for: $0.block) }
        let snapshot = InPlaceRenderSnapshot(
            generation: generation,
            image: currentSnapshot.image,
            blocks: pendingBlocks,
            capturedAt: currentSnapshot.capturedAt,
            detectedLanguage: currentSnapshot.detectedLanguage
        )
        self.currentSnapshot = snapshot
        pipelineTask = Task { [weak self] in
            guard let self else { return }
            guard await acceptsPipelineWork(generation) else { return }
            await publish(snapshot: snapshot)
            guard await acceptsPipelineWork(generation) else { return }
            await translate(
                blocks: pendingBlocks.map(\.block),
                generation: generation,
                totalBlockCount: pendingBlocks.count
            )
        }
    }

    private func pendingTranslation(for block: InPlaceOCRBlock) -> InPlaceTranslatedBlock {
        InPlaceTranslatedBlock(
            block: block,
            translatedText: nil,
            status: .pending,
            providerIdentifier: configuration.serviceIdentifier
        )
    }

    private func primaryFailureCategory(
        _ categories: [InPlaceTranslationErrorCategory]
    )
        -> InPlaceTranslationErrorCategory {
        let priority: [InPlaceTranslationErrorCategory] = [
            .authentication,
            .unsupportedLanguage,
            .rateLimited,
            .network,
            .serviceUnavailable,
            .unknown,
        ]
        return priority.first(where: categories.contains) ?? .serviceUnavailable
    }

    private func publishNoText(frame: CapturedRegionFrame, generation: UInt64) async {
        guard acceptsPipelineWork(generation) else { return }
        let snapshot = InPlaceRenderSnapshot(
            generation: generation,
            image: frame.image,
            blocks: [],
            capturedAt: frame.capturedAt,
            detectedLanguage: .auto
        )
        currentSnapshot = snapshot
        await publish(processing: .noText(generation: generation), snapshot: snapshot)
    }

    private func publishUnchangedFrame(_ frame: CapturedRegionFrame) async {
        // While OCR for a newer visual generation is in flight, keep the last
        // image-and-block snapshot intact. Publishing the new pixels with the
        // old blocks would briefly place translations over unrelated content.
        guard lifecycle == .running,
              let currentSnapshot,
              currentSnapshot.generation == generationGate.current
        else {
            return
        }
        let snapshot = InPlaceRenderSnapshot(
            generation: currentSnapshot.generation,
            image: frame.image,
            blocks: currentSnapshot.blocks,
            capturedAt: frame.capturedAt,
            detectedLanguage: currentSnapshot.detectedLanguage
        )
        self.currentSnapshot = snapshot
        await publish(snapshot: snapshot)
    }

    private func invalidateWork(incrementGeneration: Bool = true) {
        if incrementGeneration {
            _ = generationGate.invalidate()
        }
        pipelineTask?.cancel()
        pipelineTask = nil
        clearPendingCandidate()
        inFlightSignature = nil
        inFlightSignatureGeneration = nil
    }

    /// Discards a visual candidate that has not yet become an OCR generation.
    /// This never touches the currently running OCR signature or committed baseline.
    private func clearPendingCandidate() {
        debounceTask?.cancel()
        debounceTask = nil
        latestCandidate = nil
        latestCandidateSignature = nil
        firstCandidateTime = nil
    }

    /// Promotes a visual signature only after OCR completed for the active
    /// generation. A cancelled or stale OCR must never become the comparison
    /// baseline, otherwise an identical later frame could be skipped forever.
    private func commitProcessedSignature(
        _ signature: InPlaceFrameSignature?,
        generation: UInt64
    ) {
        guard acceptsPipelineWork(generation),
              inFlightSignatureGeneration == generation
        else {
            return
        }
        if let signature {
            lastProcessedSignature = signature
        }
        inFlightSignature = nil
        inFlightSignatureGeneration = nil
    }

    private func clearInFlightSignature(generation: UInt64) {
        guard inFlightSignatureGeneration == generation else { return }
        inFlightSignature = nil
        inFlightSignatureGeneration = nil
    }

    /// Records an unexpected OCR failure and returns whether the current
    /// visual signature exhausted its single automatic retry. Missing
    /// signatures are suppressed immediately because they cannot form a safe
    /// comparison baseline.
    private func recordGenericOCRFailure(_ signature: InPlaceFrameSignature?) -> Bool {
        if hasFailedOCRIdentity, matchesFailedOCRIdentity(signature) {
            genericOCRFailureCount += 1
        } else {
            failedOCRSignature = signature
            hasFailedOCRIdentity = true
            genericOCRFailureCount = 1
        }
        if signature == nil {
            genericOCRFailureCount = 2
            return true
        }
        return genericOCRFailureCount >= 2
    }

    private func clearOCRRetryBudget() {
        failedOCRSignature = nil
        hasFailedOCRIdentity = false
        genericOCRFailureCount = 0
    }

    private func matchesFailedOCRIdentity(_ signature: InPlaceFrameSignature?) -> Bool {
        guard hasFailedOCRIdentity else { return false }
        switch (failedOCRSignature, signature) {
        case (nil, nil):
            return true
        case let (failed?, candidate?):
            return !changeDetector.compare(previous: failed, current: candidate).hasChanged
        default:
            return false
        }
    }

    private func publish(
        lifecycle: InPlaceTranslationLifecycle? = nil,
        processing: InPlaceTranslationProcessingState? = nil,
        availability: InPlaceTranslationCaptureAvailability? = nil,
        snapshot: InPlaceRenderSnapshot? = nil
    ) async {
        await viewModel?.publish(
            lifecycle: lifecycle,
            processingState: processing,
            captureAvailability: availability,
            snapshot: snapshot
        )
    }
}

// MARK: - Capture Failure Handling

extension InPlaceTranslationSession {
    fileprivate func handleCaptureFailure(
        _ error: RegionFrameSourceError,
        epoch: UInt64
    ) async {
        guard acceptsCaptureCallback(epoch) else { return }
        switch error {
        case .permissionDenied:
            configuration.liveUpdatesEnabled = false
            isFrameSourceRunning = false
            lifecycle = .paused
            invalidateWork()
            await viewModel?.reflectLiveUpdatesEnabled(false)
            guard frameSourceEpoch == epoch,
                  lifecycle == .paused,
                  !configuration.liveUpdatesEnabled
            else {
                return
            }
            await publish(
                processing: .recoverableError(generation: nil, category: .permission),
                availability: .permissionDenied
            )

        case .displayUnavailable:
            configuration.liveUpdatesEnabled = false
            isFrameSourceRunning = false
            lifecycle = .paused
            invalidateWork()
            await viewModel?.reflectLiveUpdatesEnabled(false)
            guard frameSourceEpoch == epoch,
                  lifecycle == .paused,
                  !configuration.liveUpdatesEnabled
            else {
                return
            }
            await publish(
                processing: .recoverableError(
                    generation: nil,
                    category: .displayDisconnected
                ),
                availability: .displayDisconnected
            )

        case .frameConversionFailed:
            guard acceptsCaptureCallback(epoch) else { return }
            await publish(availability: .temporarilyUnavailable)

        case .currentApplicationUnavailable, .invalidSelection, .streamStopped:
            if !didAttemptCaptureRecovery, configuration.liveUpdatesEnabled {
                didAttemptCaptureRecovery = true
                await publish(
                    processing: .recoverableError(generation: nil, category: .capture),
                    availability: .temporarilyUnavailable
                )
                guard acceptsCaptureCallback(epoch) else { return }
                await stopFrameSource()
                guard lifecycle == .running, configuration.liveUpdatesEnabled else { return }
                let recoveryEpoch = frameSourceEpoch
                try? await Task.sleep(nanoseconds: 500_000_000)
                guard lifecycle == .running,
                      configuration.liveUpdatesEnabled,
                      frameSourceEpoch == recoveryEpoch
                else {
                    return
                }
                await startFrameSource()
            } else {
                isFrameSourceRunning = false
                await publish(
                    processing: .recoverableError(generation: nil, category: .capture),
                    availability: .temporarilyUnavailable
                )
            }
        }
    }
}

// MARK: - Live Capture Scheduling

extension InPlaceTranslationSession {
    fileprivate var isActiveLifecycle: Bool {
        lifecycle == .running || lifecycle == .paused
    }

    fileprivate func acceptsPipelineWork(_ generation: UInt64) -> Bool {
        !Task.isCancelled
            && isActiveLifecycle
            && generationGate.accepts(generation)
    }

    fileprivate func acceptsCaptureCallback(_ epoch: UInt64) -> Bool {
        lifecycle == .running
            && configuration.liveUpdatesEnabled
            && isFrameSourceRunning
            && frameSourceEpoch == epoch
    }

    fileprivate func startFrameSource() async {
        guard !isFrameSourceRunning,
              configuration.liveUpdatesEnabled,
              lifecycle == .running
        else {
            return
        }
        frameSourceEpoch &+= 1
        let epoch = frameSourceEpoch
        isFrameSourceRunning = true
        do {
            try await frameSource.start(
                onFrame: { [weak self] frame in
                    Task { await self?.receive(frame, epoch: epoch) }
                },
                onFailure: { [weak self] error in
                    Task { await self?.handleCaptureFailure(error, epoch: epoch) }
                }
            )
            guard acceptsCaptureCallback(epoch) else { return }
        } catch is CancellationError {
            guard frameSourceEpoch == epoch else { return }
            isFrameSourceRunning = false
        } catch let error as RegionFrameSourceError {
            guard acceptsCaptureCallback(epoch) else { return }
            await handleCaptureFailure(error, epoch: epoch)
        } catch {
            guard acceptsCaptureCallback(epoch) else { return }
            await handleCaptureFailure(.streamStopped, epoch: epoch)
        }
    }

    fileprivate func stopFrameSource() async {
        frameSourceEpoch &+= 1
        guard isFrameSourceRunning else { return }
        isFrameSourceRunning = false
        await frameSource.stop()
    }

    fileprivate func receive(_ frame: CapturedRegionFrame, epoch: UInt64) async {
        guard acceptsCaptureCallback(epoch) else { return }
        // Frame callbacks arrive through independent Tasks and therefore can
        // enter this actor out of order even within one capture epoch.
        if let latestFrame, frame.capturedAt <= latestFrame.capturedAt {
            return
        }
        latestFrame = frame
        didAttemptCaptureRecovery = false
        await publish(availability: .available)
        guard acceptsCaptureCallback(epoch) else { return }

        guard let signature = changeDetector.makeSignature(for: frame.image) else { return }
        resetOCRRetryBudgetIfVisualChanged(to: signature)
        if inFlightSignature == nil,
           hasFailedOCRIdentity,
           matchesFailedOCRIdentity(signature),
           genericOCRFailureCount < 2 {
            scheduleProcessing(frame, signature: signature, force: true)
            return
        }
        guard let comparisonSignature = inFlightSignature ?? lastProcessedSignature else {
            scheduleProcessing(frame, signature: signature, force: true)
            return
        }
        let result = changeDetector.compare(
            previous: comparisonSignature,
            current: signature,
            dirtyRects: frame.dirtyRects
        )
        guard result.hasChanged else {
            // The newest frame matches whichever visual state currently owns
            // comparison (running OCR or committed baseline), so any older
            // debounced candidate is obsolete.
            clearPendingCandidate()
            if inFlightSignature == nil {
                await publishUnchangedFrame(frame)
            }
            return
        }

        latestCandidate = frame
        latestCandidateSignature = signature
        firstCandidateTime = firstCandidateTime ?? frame.capturedAt
        await publish(processing: .debouncing)
        guard acceptsCaptureCallback(epoch) else { return }

        if frame.capturedAt - (firstCandidateTime ?? frame.capturedAt)
            >= InPlaceTranslationConstants.maximumDebounceLatency {
            consumeLatestCandidate()
            return
        }

        debounceTask?.cancel()
        debounceTask = Task { [weak self] in
            do {
                try await Task.sleep(
                    nanoseconds: UInt64(InPlaceTranslationConstants.debounceInterval * 1_000_000_000)
                )
                await self?.consumeLatestCandidateAfterOCRGate()
            } catch {
                // A newer candidate owns the next debounce window.
            }
        }
    }

    fileprivate func consumeLatestCandidateAfterOCRGate() async {
        guard !Task.isCancelled, isActiveLifecycle else { return }
        if let lastOCRStartTime {
            let elapsed = ProcessInfo.processInfo.systemUptime - lastOCRStartTime
            let remaining = InPlaceTranslationConstants.minimumOCRInterval - elapsed
            if remaining > 0 {
                do {
                    try await Task.sleep(nanoseconds: UInt64(remaining * 1_000_000_000))
                } catch {
                    return
                }
                guard !Task.isCancelled, isActiveLifecycle else { return }
            }
        }
        consumeLatestCandidate()
    }

    fileprivate func consumeLatestCandidate() {
        guard isActiveLifecycle,
              !Task.isCancelled,
              let frame = latestCandidate,
              let signature = latestCandidateSignature
        else {
            return
        }
        latestCandidate = nil
        latestCandidateSignature = nil
        firstCandidateTime = nil
        scheduleProcessing(frame, signature: signature, force: false)
    }

    fileprivate func scheduleProcessing(
        _ frame: CapturedRegionFrame,
        signature: InPlaceFrameSignature? = nil,
        force: Bool,
        reusePreviousTranslations: Bool = true,
        generation providedGeneration: UInt64? = nil,
        resetOCRRetryBudget: Bool = false
    ) {
        guard isActiveLifecycle, !Task.isCancelled else { return }
        let signature = signature ?? changeDetector.makeSignature(for: frame.image)
        if resetOCRRetryBudget {
            clearOCRRetryBudget()
        } else {
            resetOCRRetryBudgetIfVisualChanged(to: signature)
            if hasFailedOCRIdentity,
               matchesFailedOCRIdentity(signature),
               genericOCRFailureCount >= 2 {
                return
            }
        }
        if !force,
           let signature,
           let lastProcessedSignature,
           !changeDetector.compare(previous: lastProcessedSignature, current: signature).hasChanged {
            return
        }

        let generation: UInt64
        if let providedGeneration {
            guard generationGate.accepts(providedGeneration) else { return }
            generation = providedGeneration
        } else {
            generation = generationGate.invalidate()
        }
        pipelineTask?.cancel()
        clearPendingCandidate()
        inFlightSignature = signature
        inFlightSignatureGeneration = generation
        lastOCRStartTime = ProcessInfo.processInfo.systemUptime
        pipelineTask = Task { [weak self] in
            guard !Task.isCancelled else { return }
            await self?.runOCRAndTranslation(
                frame: frame,
                signature: signature,
                generation: generation,
                reusePreviousTranslations: reusePreviousTranslations
            )
        }
    }

    private func resetOCRRetryBudgetIfVisualChanged(
        to signature: InPlaceFrameSignature?
    ) {
        guard hasFailedOCRIdentity,
              !matchesFailedOCRIdentity(signature)
        else {
            return
        }
        clearOCRRetryBudget()
    }
}
