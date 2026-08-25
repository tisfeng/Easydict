//
//  ActionManager.swift
//  Easydict
//
//  Created by tisfeng on 2025/8/29.
//  Copyright © 2025 izual. All rights reserved.
//

import AppKit
import Defaults
import Foundation
import SelectedTextKit

// MARK: - TextReplacementStreamMetrics

/// Counts only non-empty response chunks that were handed to the existing insertion strategy.
struct TextReplacementStreamMetrics: Equatable {
    static let zero = TextReplacementStreamMetrics(chunkCount: 0, characterCount: 0)

    var chunkCount: Int
    var characterCount: Int
}

// MARK: - TextReplacementStreamOutcome

/// Describes one provider attempt without buffering or rolling back inserted content.
enum TextReplacementStreamOutcome {
    case completed(TextReplacementStreamMetrics)
    case empty
    case failedBeforeFirstChunk(Error)
    case interrupted(TextReplacementStreamMetrics, Error)
    case cancelled(TextReplacementStreamMetrics)

    // MARK: Internal

    var metrics: TextReplacementStreamMetrics {
        switch self {
        case let .cancelled(metrics),
             let .completed(metrics),
             let .interrupted(metrics, _):
            metrics
        case .empty, .failedBeforeFirstChunk:
            .zero
        }
    }
}

// MARK: - TextReplacementStreamSource

/// Couples a provider stream with the non-sensitive metadata allowed in action logs.
struct TextReplacementStreamSource {
    // MARK: Lifecycle

    init(
        serviceType: String,
        model: String,
        stream: AsyncThrowingStream<String, Error>,
        retainedService: AnyObject? = nil
    ) {
        self.serviceType = serviceType
        self.model = model
        self.stream = stream
        self.retainedService = retainedService
    }

    // MARK: Internal

    let serviceType: String
    let model: String
    let stream: AsyncThrowingStream<String, Error>

    // MARK: Private

    /// Some provider streams keep unowned request controls owned by their service instance.
    private let retainedService: AnyObject?
}

// MARK: - TextReplacementStreamExecution

/// Records at most the selected-provider attempt and one built-in fallback attempt.
struct TextReplacementStreamExecution {
    struct Attempt {
        let identifier: String
        let serviceType: String
        let model: String
        let outcome: TextReplacementStreamOutcome
    }

    let attempts: [Attempt]

    var finalOutcome: TextReplacementStreamOutcome {
        attempts.last?.outcome ?? .empty
    }

    var didFallback: Bool {
        attempts.count > 1
    }
}

// MARK: - TextReplacementErrorCategory

/// Reduces provider errors to stable categories so logs never include raw payloads or URLs.
enum TextReplacementErrorCategory: String {
    case none
    case serviceUnavailable = "service_unavailable"
    case configuration
    case authentication
    case timeout
    case emptyResponse = "empty_response"
    case provider
    case cancelled

    // MARK: Lifecycle

    init(error: Error) {
        if error is CancellationError {
            self = .cancelled
            return
        }
        if error is TextReplacementActionError {
            self = .serviceUnavailable
            return
        }
        if let queryError = error as? QueryError {
            switch queryError.type {
            case .missingSecretKey:
                self = .authentication
            case .contentTypeMismatch,
                 .parameter,
                 .unsupportedLanguage,
                 .unsupportedQueryType,
                 .unsupportedServiceType:
                self = .configuration
            case .timeout:
                self = .timeout
            case .api, .appleScript, .noResult, .unknown:
                self = .provider
            }
            return
        }
        if let urlError = error as? URLError, urlError.code == .timedOut {
            self = .timeout
            return
        }
        self = .provider
    }
}

// MARK: - TextReplacementLogFormatter

/// Produces the complete allowlisted log line for a text replacement provider attempt.
enum TextReplacementLogFormatter {
    // MARK: Internal

    static func message(
        action: TextReplacementAction,
        serviceType: String,
        model: String,
        outcome: TextReplacementStreamOutcome
    )
        -> String {
        let status: String
        let category: TextReplacementErrorCategory

        switch outcome {
        case .completed:
            status = "completed"
            category = .none
        case .empty:
            status = "failed"
            category = .emptyResponse
        case let .failedBeforeFirstChunk(error):
            status = "failed"
            category = .init(error: error)
        case let .interrupted(_, error):
            status = "interrupted"
            category = .init(error: error)
        case .cancelled:
            status = "cancelled"
            category = .cancelled
        }

        let metrics = outcome.metrics
        return "Text replacement \(status) action=\(action.rawValue) " +
            "service=\(serviceType) model=\(sanitizedModel(model)) " +
            "chunks=\(metrics.chunkCount) characters=\(metrics.characterCount) " +
            "category=\(category.rawValue)"
    }

    // MARK: Private

    private static func sanitizedModel(_ model: String) -> String {
        let flattened = model
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        return flattened.isEmpty ? "<none>" : String(flattened.prefix(120))
    }
}

// MARK: - TextReplacementStreamConsumer

/// Consumes one provider stream and inserts each non-empty chunk immediately on the main actor.
struct TextReplacementStreamConsumer {
    @MainActor
    func consume(
        _ contentStream: AsyncThrowingStream<String, Error>,
        insert: (String) async -> ()
    ) async
        -> TextReplacementStreamOutcome {
        var metrics = TextReplacementStreamMetrics.zero

        do {
            try Task.checkCancellation()
            for try await content in contentStream {
                try Task.checkCancellation()
                guard !content.isEmpty else { continue }

                await insert(content)
                metrics.chunkCount += 1
                metrics.characterCount += content.count
            }
            try Task.checkCancellation()
            return metrics.chunkCount == 0 ? .empty : .completed(metrics)
        } catch is CancellationError {
            return .cancelled(metrics)
        } catch {
            if metrics.chunkCount == 0 {
                return .failedBeforeFirstChunk(error)
            }
            return .interrupted(metrics, error)
        }
    }
}

// MARK: - TextReplacementStreamCoordinator

/// Runs a selected provider and permits one fallback only before any chunk is inserted.
struct TextReplacementStreamCoordinator {
    // MARK: Internal

    @MainActor
    func execute(
        initialIdentifier: String,
        fallbackIdentifier: String,
        makeSource: (String) async -> TextReplacementStreamSource,
        willUseFallback: () -> () = {},
        insert: (String) async -> ()
    ) async
        -> TextReplacementStreamExecution {
        let firstAttempt = await makeAttempt(
            identifier: initialIdentifier,
            makeSource: makeSource,
            insert: insert
        )
        var attempts = [firstAttempt]

        guard initialIdentifier != fallbackIdentifier,
              !Task.isCancelled,
              shouldFallback(after: firstAttempt.outcome)
        else {
            return TextReplacementStreamExecution(attempts: attempts)
        }

        willUseFallback()
        let fallbackAttempt = await makeAttempt(
            identifier: fallbackIdentifier,
            makeSource: makeSource,
            insert: insert
        )
        attempts.append(fallbackAttempt)
        return TextReplacementStreamExecution(attempts: attempts)
    }

    // MARK: Private

    @MainActor
    private func makeAttempt(
        identifier: String,
        makeSource: (String) async -> TextReplacementStreamSource,
        insert: (String) async -> ()
    ) async
        -> TextReplacementStreamExecution.Attempt {
        let source = await makeSource(identifier)
        let outcome = await TextReplacementStreamConsumer().consume(
            source.stream,
            insert: insert
        )
        return .init(
            identifier: identifier,
            serviceType: source.serviceType,
            model: source.model,
            outcome: outcome
        )
    }

    private func shouldFallback(after outcome: TextReplacementStreamOutcome) -> Bool {
        switch outcome {
        case .empty, .failedBeforeFirstChunk:
            true
        case .cancelled, .completed, .interrupted:
            false
        }
    }
}

// MARK: - TextReplacementActionError

/// Represents local action setup failures without carrying selected text or provider payloads.
enum TextReplacementActionError: Error {
    case serviceUnavailable
}

// MARK: - ActionManager

/// Singleton class responsible for handling various application actions
@objc(EZActionManager)
class ActionManager: NSObject {
    // MARK: Internal

    // MARK: - Singleton

    @objc static let shared = ActionManager()

    // MARK: - Text Field Detection and Access

    // MARK: - Public Methods

    /// Translate selected text and replace it with the translation result
    func translateAndReplace() async {
        logInfo("Translate and Replace")
        await executeTextReplacementAction(.translate)
    }

    /// Polish selected text and replace it with the polished result
    func polishAndReplace() async {
        logInfo("Polish and Replace")
        await executeTextReplacementAction(.polish)
    }

    // MARK: Private

    private let serviceFactory = QueryServiceFactory.shared
    private let streamCoordinator = TextReplacementStreamCoordinator()
    private let systemUtility = SystemUtility.shared

    // MARK: - Core Action Methods

    /// Common method to execute text replacement actions
    private func executeTextReplacementAction(_ action: TextReplacementAction) async {
        let enableSelectAll = Defaults[.autoSelectAllTextFieldText]
        let elementInfo = await systemUtility.focusedElementInfo(enableSelectAll: enableSelectAll)

        // Prepare translation request
        var queryText = elementInfo.focusedText
        if queryText?.isEmpty ?? true {
            queryText = await systemUtility.getSelectedText()
        }

        guard let queryText, !queryText.isEmpty else {
            logInfo("No text selected or focused for \(action.rawValue), skipping action")
            return
        }

        let selectedIdentifier = selectedServiceIdentifier(for: action)
        guard let request = await prepareTranslationRequest(
            queryText: queryText,
            serviceIdentifier: selectedIdentifier,
            action: action
        ) else {
            return
        }

        let promptContext = TextReplacementPromptContext(
            action: action,
            additionalPrompt: additionalPrompt(for: action)
        )
        await performStreamingService(
            request: request,
            action: action,
            promptContext: promptContext,
            selectedIdentifier: selectedIdentifier,
            elementInfo: elementInfo
        )
    }

    // MARK: - Helper Methods

    /// Prepare translation request from text field information
    /// - Parameters:
    ///   - queryText: Selected or focused text to transform.
    ///   - serviceIdentifier: Full configured service identifier.
    ///   - action: Translation or polishing behavior.
    /// - Returns: A configured TranslationRequest or nil if preparation fails
    private func prepareTranslationRequest(
        queryText: String,
        serviceIdentifier: String,
        action: TextReplacementAction
    ) async
        -> TranslationRequest? {
        // Detect language and target
        let queryModel = try? await DetectManager().detectText(queryText)
        guard let detectedLanguage = queryModel?.detectedLanguage,
              let targetLanguage = queryModel?.queryTargetLanguage
        else {
            logError("Failed to detect target language for \(action.rawValue) replacement")
            return nil
        }

        return TranslationRequest(
            text: queryText,
            sourceLanguage: detectedLanguage.code,
            targetLanguage: targetLanguage.code,
            serviceType: serviceIdentifier,
            queryType: .translation
        )
    }

    // MARK: - Streaming Service Methods

    /// Performs the selected service and a single built-in fallback while preserving chunk writes.
    @MainActor
    private func performStreamingService(
        request: TranslationRequest,
        action: TextReplacementAction,
        promptContext: TextReplacementPromptContext,
        selectedIdentifier: String,
        elementInfo: FocusedElementInfo
    ) async {
        let fallbackIdentifier = action.defaultServiceIdentifier
        let selection = serviceFactory.textReplacementServiceSelection(
            for: action,
            selectedIdentifier: selectedIdentifier
        )
        let initialIdentifier = selection.identifier

        if selection.shouldResetStoredSelection {
            setSelectedServiceIdentifier(fallbackIdentifier, for: action)
            showFallbackNotice()
        }

        // Avoid polluting the user's pasteboard when the existing compatibility
        // insertion strategy has to use copy and paste.
        let pasteboard = NSPasteboard.general
        let isSupportedAX = elementInfo.isSupportedAXElement
        let snapshotItems = isSupportedAX ? nil : pasteboard.backupItems()
        defer {
            if let snapshotItems, !isSupportedAX {
                pasteboard.restoreItems(snapshotItems)
            }
        }

        let textStrategy = systemUtility.textStrategies(for: elementInfo)
        let execution = await streamCoordinator.execute(
            initialIdentifier: initialIdentifier,
            fallbackIdentifier: fallbackIdentifier,
            makeSource: { identifier in
                await self.streamSource(
                    identifier: identifier,
                    request: request,
                    action: action,
                    promptContext: promptContext
                )
            },
            willUseFallback: {
                self.showFallbackNotice()
            },
            insert: { content in
                await self.systemUtility.insertText(content, using: textStrategy)
            }
        )

        logExecution(execution, action: action)
        handleFinalOutcome(execution.finalOutcome)
    }

    @MainActor
    private func streamSource(
        identifier: String,
        request: TranslationRequest,
        action: TextReplacementAction,
        promptContext: TextReplacementPromptContext
    ) async
        -> TextReplacementStreamSource {
        let serviceType = serviceFactory.metadata(withTypeId: identifier)?.serviceType.rawValue ??
            "unknown"
        guard let service = serviceFactory.textReplacementService(
            withIdentifier: identifier,
            for: action
        ) else {
            return TextReplacementStreamSource(
                serviceType: serviceType,
                model: "",
                stream: failedStream(TextReplacementActionError.serviceUnavailable)
            )
        }

        let model = service.model
        guard !model.trim().isEmpty else {
            return TextReplacementStreamSource(
                serviceType: serviceType,
                model: model,
                stream: failedStream(
                    QueryError(type: .parameter, message: "Model is not configured")
                ),
                retainedService: service
            )
        }
        var providerRequest = request
        providerRequest.serviceType = identifier

        do {
            try Task.checkCancellation()
            let stream = try await service.contentStreamTranslate(
                request: providerRequest,
                promptContext: promptContext
            )
            try Task.checkCancellation()
            return TextReplacementStreamSource(
                serviceType: serviceType,
                model: model,
                stream: stream,
                retainedService: service
            )
        } catch {
            return TextReplacementStreamSource(
                serviceType: serviceType,
                model: model,
                stream: failedStream(error),
                retainedService: service
            )
        }
    }

    private func failedStream(_ error: Error) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            continuation.finish(throwing: error)
        }
    }

    @MainActor
    private func handleFinalOutcome(_ outcome: TextReplacementStreamOutcome) {
        switch outcome {
        case .completed:
            break
        case .empty, .failedBeforeFirstChunk:
            EZToast.showText(
                NSLocalizedString("text_replacement.notice.request_failed", comment: "")
            )
        case .interrupted:
            showPartialResultNotice()
        case let .cancelled(metrics):
            if metrics.chunkCount > 0 {
                showPartialResultNotice()
            }
        }
    }

    private func logExecution(
        _ execution: TextReplacementStreamExecution,
        action: TextReplacementAction
    ) {
        for attempt in execution.attempts {
            let message = TextReplacementLogFormatter.message(
                action: action,
                serviceType: attempt.serviceType,
                model: attempt.model,
                outcome: attempt.outcome
            )
            switch attempt.outcome {
            case .cancelled, .completed:
                logInfo(message)
            case .empty, .failedBeforeFirstChunk, .interrupted:
                logError(message)
            }
        }
    }

    @MainActor
    private func showFallbackNotice() {
        EZToast.showText(
            NSLocalizedString("text_replacement.notice.fallback_used", comment: "")
        )
    }

    @MainActor
    private func showPartialResultNotice() {
        EZToast.showText(
            NSLocalizedString("text_replacement.notice.response_interrupted", comment: "")
        )
    }

    // MARK: - Action Configuration

    private func selectedServiceIdentifier(for action: TextReplacementAction) -> String {
        switch action {
        case .translate:
            Defaults[.translateAndReplaceServiceIdentifier]
        case .polish:
            Defaults[.polishAndReplaceServiceIdentifier]
        }
    }

    private func setSelectedServiceIdentifier(
        _ identifier: String,
        for action: TextReplacementAction
    ) {
        switch action {
        case .translate:
            Defaults[.translateAndReplaceServiceIdentifier] = identifier
        case .polish:
            Defaults[.polishAndReplaceServiceIdentifier] = identifier
        }
    }

    private func additionalPrompt(for action: TextReplacementAction) -> String {
        switch action {
        case .translate:
            Defaults[.translateAndReplaceAdditionalPrompt]
        case .polish:
            Defaults[.polishAndReplaceAdditionalPrompt]
        }
    }
}
