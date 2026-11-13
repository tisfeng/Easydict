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
                // A preference change while awaiting the complete response must still end input loading.
                if cancelled.withLock({ $0 }), !sourceDelivered, ownsInput {
                    sourceCompletion(model, CocoaError(.userCancelled))
                }
                finished()
            }
            guard acceptsUpdates, let image else { cancel(); return }
            do {
                for try await event in service.ocrTranslationStream(image, from: from, to: to) {
                    guard acceptsUpdates else { cancel(); return }
                    switch event {
                    case let .original(text, complete):
                        publishSource(text, complete: complete)
                    case let .translation(text):
                        guard sourceDelivered else { continue }
                        publishTranslation(text, finished: false)
                    case let .finished(original, translated):
                        publishSource(original.mergedText, complete: true)
                        guard acceptsUpdates else { cancel(); return }
                        publishTranslation(translated.translatedText ?? "", finished: true)
                    }
                }
            } catch {
                guard acceptsUpdates, !(error is CancellationError) else { cancel(); return }
                activeResult.error = QueryError.queryError(from: error)
                activeResult.isLoading = false
                activeResult.isStreamFinished = true
                if !sourceDelivered { sourceCompletion(model, error) }
                translation(activeResult, error)
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

    private func publishSource(_ text: String, complete: Bool) {
        guard !sourceDelivered, !text.isEmpty else { return }
        expectedInput = complete ? text.trimmingCharacters(in: .whitespacesAndNewlines) : text
        model.inputText = expectedInput
        sourceProgress(expectedInput)
        guard acceptsUpdates else { cancel(); return }
        if complete {
            let pair = service.ocrTranslationResults(
                .init(original: expectedInput, translation: ""),
                from: from,
                to: to
            )
            model.detectedLanguage = pair.0.from
            model.needDetectLanguage = false
            activeResult.queryText = model.queryText
            activeResult.from = pair.0.from
            activeResult.to = pair.1.to
            activeResult.isLoading = true
            activeResult.isStreamFinished = false
            sourceDelivered = true
            // Other translators can start while this image request is still generating its translation.
            sourceCompletion(model, nil)
        }
    }

    private func publishTranslation(_ text: String, finished: Bool) {
        activeResult.translatedResults = [text]
        activeResult.isStreamFinished = finished
        activeResult.isLoading = !finished
        activeResult.isShowing = true
        translation(activeResult, nil)
    }
}
