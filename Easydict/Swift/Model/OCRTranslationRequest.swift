//
//  OCRTranslationRequest.swift
//  Easydict
//
//  Copyright © 2026 izual. All rights reserved.
//

import AppKit
import Foundation
import os

/// Publishes a single screenshot request through the existing input and service-result callbacks.
@MainActor
final class OCRTranslationRequest {
    // MARK: Lifecycle

    init(
        identifier: UUID, model: QueryModel, service: StreamService, isCurrent: @escaping () -> Bool,
        sourceProgress: @escaping (String) -> (),
        sourceCompletion: @escaping (QueryModel, Error?) -> (),
        translation: @escaping (QueryResult, Error?) -> (),
        finished: @escaping () -> ()
    ) {
        self.identifier = identifier
        self.model = model
        self.service = service
        self.image = model.ocrImage
        self.action = model.actionType
        self.expectedInput = model.inputText
        self.sourcePreference = model.userSourceLanguage
        self.from = model.queryFromLanguage
        self.to = model.userTargetLanguage
        self.preferredLanguages = EZLanguageManager.shared().userPreferredTwoLanguages
        self.configuration = service.ocrTranslationConfiguration
        let prepared = service.updateResultLock.withLock {
            // A replacement needs its own generation before the old cancellation task unwinds.
            let result = service.resetServiceResult()
            return (result, service.resultGeneration)
        }
        self.activeResult = prepared.0
        self.generation = prepared.1
        self.isCurrent = isCurrent
        self.sourceProgress = sourceProgress
        self.sourceCompletion = sourceCompletion
        self.translation = translation
        self.finished = finished
    }

    // MARK: Internal

    let identifier: UUID

    /// Invalidates queued UI events immediately, even when cancellation comes from a service stop callback.
    nonisolated func cancel() {
        let wasCancelled = cancelled.withLock { value in
            let previous = value
            value = true
            return previous
        }
        guard !wasCancelled else { return }
        Task { @MainActor [weak self] in
            guard let self else { return }
            task?.cancel()
            service.updateResultLock.withLock {
                guard service.resultGeneration == generation else { return }
                service.resultGeneration &+= 1
                activeResult.isLoading = false
                activeResult.isStreamFinished = true
            }
        }
    }

    func start() {
        task = Task { [weak self] in
            guard let self else { return }
            defer {
                // A preference change before the first source delta must still end input loading.
                if cancelled.withLock({ $0 }), !sourceDelivered, ownsInput {
                    sourceCompletion(model, CocoaError(.userCancelled))
                }
                finished()
            }
            guard acceptsUpdates, let image else { cancel(); return }
            let (updates, continuation) = AsyncStream<OCRTranslationStream.Update>.makeStream()
            let operation = Task {
                do {
                    let result = try await service.ocrAndTranslate(image, from: from, to: to) {
                        continuation.yield($0)
                    }
                    continuation.finish()
                    return result
                } catch {
                    continuation.finish()
                    throw error
                }
            }
            await withTaskCancellationHandler {
                for await update in updates {
                    guard acceptsUpdates else { operation.cancel(); cancel(); return }
                    publish(update)
                }
                do {
                    let (original, translated) = try await operation.value
                    guard acceptsUpdates else { cancel(); return }
                    publish(.init(
                        source: original.mergedText,
                        translation: translated.translatedText ?? "",
                        sourceComplete: true,
                        complete: true
                    ), final: true)
                } catch {
                    guard acceptsUpdates, !(error is CancellationError) else { cancel(); return }
                    activeResult.error = QueryError.queryError(from: error)
                    activeResult.isLoading = false
                    activeResult.isStreamFinished = true
                    if !sourceDelivered { sourceCompletion(model, error) }
                    translation(activeResult, error)
                }
            } onCancel: {
                operation.cancel()
                continuation.finish()
            }
        }
        model.setStop({ [weak self] in self?.cancel() }, serviceType: service.serviceTypeWithUniqueIdentifier())
    }

    // MARK: Private

    private let model: QueryModel
    private let service: StreamService
    private let image: NSImage?
    private let action: ActionType
    private let sourcePreference: Language
    private let from: Language
    private let to: Language
    private let preferredLanguages: [Language]
    private let configuration: [String]
    private let generation: UInt
    private let activeResult: QueryResult
    private let isCurrent: () -> Bool
    private let sourceProgress: (String) -> ()
    private let sourceCompletion: (QueryModel, Error?) -> ()
    private let translation: (QueryResult, Error?) -> ()
    private let finished: () -> ()
    private nonisolated let cancelled = OSAllocatedUnfairLock(initialState: false)
    private var task: Task<(), Never>?
    private var expectedInput: String
    private var sourceDelivered = false
    private var lastUpdate = Date.distantPast

    private var ownsInput: Bool {
        isCurrent() && model.ocrImage === image && model.actionType == action && model.inputText == expectedInput
    }

    private var acceptsUpdates: Bool {
        !cancelled.withLock { $0 } && isCurrent()
            && service.updateResultLock.withLock { service.resultGeneration == generation }
            && service.enabled && service.enabledQuery
            && service.ocrTranslationConfiguration == configuration
            && model.ocrImage === image && model.actionType == action && model.inputText == expectedInput
            && model.userSourceLanguage == sourcePreference && model.userTargetLanguage == to
            && EZLanguageManager.shared().userPreferredTwoLanguages == preferredLanguages
    }

    private func publish(_ update: OCRTranslationStream.Update, final: Bool = false) {
        guard !update.source.isEmpty else { return }
        guard update.complete || (update.sourceComplete && !sourceDelivered)
            || Date().timeIntervalSince(lastUpdate) >= 0.08 else { return }
        lastUpdate = Date()
        expectedInput = update.source
        model.inputText = update.source
        sourceProgress(update.source)
        guard acceptsUpdates else { cancel(); return }
        activeResult.queryText = model.queryText
        activeResult.translatedResults = [update.translation]
        activeResult.isStreamFinished = final
        activeResult.isLoading = update.translation.isEmpty
        activeResult.isShowing = true
        if final, !sourceDelivered {
            sourceDelivered = true
            let detected = from == .auto ? AppleLanguageDetector().detectLanguage(text: update.source) : from
            model.detectedLanguage = detected
            model.needDetectLanguage = false
            activeResult.from = detected
            activeResult.to = to == .auto ? EZLanguageManager.shared()
                .userTargetLanguage(withSourceLanguage: detected) : to
            // The input is complete before other services start; this request keeps its result generation.
            sourceCompletion(model, nil)
        }
        guard acceptsUpdates else { cancel(); return }
        // Intelligent mode can decide eligibility only after the entire source is available.
        if sourceDelivered || !MyConfiguration.shared.intelligentQueryModeForWindowType(service.windowType) {
            translation(activeResult, nil)
        }
    }
}
