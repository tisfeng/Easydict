//
//  InPlaceTranslationViewModel.swift
//  Easydict
//
//  Created by Eric Pan on 2026/8/30.
//  Copyright © 2026 izual. All rights reserved.
//

import AppKit
import Combine
import Defaults
import Foundation

// MARK: - InPlaceTranslationViewModel

/// Main-actor projection of session state plus explicit user commands.
/// It never schedules OCR or translation work itself.
@MainActor
final class InPlaceTranslationViewModel: ObservableObject {
    // MARK: Lifecycle

    init(
        configuration: InPlaceTranslationConfiguration,
        serviceResolver: any InPlaceTranslationServiceResolving = InPlaceTranslationServiceResolver(),
        pasteboard: NSPasteboard = .general
    ) {
        self.configuration = configuration
        self.serviceResolver = serviceResolver
        self.pasteboard = pasteboard
        refreshServiceMetadata()
        observeServiceUpdates()
    }

    // MARK: Internal

    @Published private(set) var snapshot: InPlaceRenderSnapshot?
    @Published private(set) var lifecycle: InPlaceTranslationLifecycle = .starting
    @Published private(set) var processingState: InPlaceTranslationProcessingState = .idle
    @Published private(set) var captureAvailability: InPlaceTranslationCaptureAvailability = .available
    @Published private(set) var serviceOptions: [InPlaceTranslationServiceOption] = []
    @Published private(set) var availableTargetLanguages: [Language] = []
    @Published var configuration: InPlaceTranslationConfiguration
    @Published var selectedBlockID: UUID?
    @Published private(set) var isTemporarilyShowingOriginal = false

    var onPinChanged: ((Bool) -> ())?
    var onReselect: (() -> ())?
    var onClose: (() -> ())?

    var effectiveRenderMode: InPlaceTranslationRenderMode {
        isTemporarilyShowingOriginal ? .original : configuration.renderMode
    }

    var sourceLanguages: [Language] {
        let mapper = AppleLanguageMapper.shared
        let explicit = Language.allCases.filter { language in
            language != .auto && mapper.isSupportedOCRLanguage(language)
        }
        return [.auto] + explicit
    }

    var selectedBlock: InPlaceTranslatedBlock? {
        guard let selectedBlockID else { return nil }
        return snapshot?.blocks.first { $0.id == selectedBlockID }
    }

    func attach(session: InPlaceTranslationSession) {
        self.session = session
    }

    func setLiveUpdatesEnabled(_ enabled: Bool) {
        configuration.liveUpdatesEnabled = enabled
        Defaults[.inPlaceTranslationLiveUpdatesEnabled] = enabled
        enqueueSessionCommand { session in
            await session.setLiveUpdatesEnabled(enabled)
        }
    }

    func refresh() {
        enqueueSessionCommand { session in
            await session.refresh()
        }
    }

    func setSourceLanguage(_ language: Language) {
        guard configuration.sourceLanguage != language else { return }
        configuration.sourceLanguage = language
        enqueueSessionCommand { session in
            await session.setSourceLanguage(language)
        }
    }

    func setTargetLanguage(_ language: Language) {
        guard language != .auto, configuration.targetLanguage != language else { return }
        configuration.targetLanguage = language
        enqueueSessionCommand { session in
            await session.setTargetLanguage(language)
        }
    }

    func swapLanguages() {
        guard !availableTargetLanguages.isEmpty else { return }
        let oldSource = configuration.sourceLanguage
        let oldTarget = configuration.targetLanguage
        if oldSource == .auto {
            configuration.sourceLanguage = oldTarget
            let detected = snapshot?.detectedLanguage ?? .auto
            configuration.targetLanguage = detected == .auto
                ? fallbackTargetLanguage(excluding: oldTarget)
                : detected
        } else {
            configuration.sourceLanguage = oldTarget
            configuration.targetLanguage = oldSource
        }
        configuration.targetLanguage = clampedTargetLanguage(
            configuration.targetLanguage,
            excluding: configuration.sourceLanguage
        )
        let source = configuration.sourceLanguage
        let target = configuration.targetLanguage
        enqueueSessionCommand { session in
            await session.setLanguages(source: source, target: target)
        }
    }

    func setServiceIdentifier(_ identifier: String) {
        guard serviceOptions.contains(where: { $0.identifier == identifier }),
              configuration.serviceIdentifier != identifier
        else {
            return
        }
        configuration.serviceIdentifier = identifier
        Defaults[.inPlaceTranslationServiceIdentifier] = identifier
        refreshSupportedTargetLanguages()
        let targetLanguage = configuration.targetLanguage
        enqueueSessionCommand { session in
            await session.setServiceIdentifier(
                identifier,
                targetLanguage: targetLanguage
            )
        }
    }

    func setRenderMode(_ mode: InPlaceTranslationRenderMode) {
        configuration.renderMode = mode
    }

    func toggleRenderMode() {
        configuration.renderMode = configuration.renderMode == .original
            ? .translated
            : .original
    }

    func showOriginalTemporarily(_ show: Bool) {
        isTemporarilyShowingOriginal = show
    }

    func togglePinned() {
        configuration.isPinned.toggle()
        Defaults[.inPlaceTranslationPinned] = configuration.isPinned
        onPinChanged?(configuration.isPinned)
    }

    func reselect() {
        onReselect?()
    }

    func close() {
        onClose?()
    }

    func copyTranslation() {
        let text: String
        if let selectedBlock {
            if selectedBlock.status == .translated {
                text = selectedBlock.translatedText ?? ""
            } else {
                text = ""
            }
        } else {
            text = snapshot?.blocks
                .sorted { $0.block.readingOrder < $1.block.readingOrder }
                .compactMap { block in
                    block.status == .translated ? block.translatedText : nil
                }
                .joined(separator: "\n") ?? ""
        }
        guard !text.isEmpty else { return }
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    func openScreenRecordingSettings() {
        guard let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
        ) else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    func refreshServiceMetadata() {
        serviceOptions = serviceResolver.options()
        guard !serviceOptions.isEmpty else {
            clearUnavailableServiceSelection()
            return
        }
        refreshSupportedTargetLanguages()
    }

    func publish(
        lifecycle: InPlaceTranslationLifecycle? = nil,
        processingState: InPlaceTranslationProcessingState? = nil,
        captureAvailability: InPlaceTranslationCaptureAvailability? = nil,
        snapshot: InPlaceRenderSnapshot? = nil
    ) {
        if let lifecycle {
            self.lifecycle = lifecycle
        }
        if let captureAvailability {
            self.captureAvailability = captureAvailability
        }
        if let snapshot,
           self.snapshot == nil || snapshot.generation >= (self.snapshot?.generation ?? 0) {
            self.snapshot = snapshot
            latestProcessingGeneration = max(latestProcessingGeneration, snapshot.generation)
            if let selectedBlockID,
               !snapshot.blocks.contains(where: { $0.id == selectedBlockID }) {
                self.selectedBlockID = nil
            }
        }
        if let processingState {
            if let generation = Self.generation(of: processingState) {
                guard generation >= latestProcessingGeneration else { return }
                latestProcessingGeneration = generation
            }
            self.processingState = processingState
        }
    }

    /// Reflects a session-level capture stop without mutating the saved default.
    func reflectLiveUpdatesEnabled(_ enabled: Bool) {
        configuration.liveUpdatesEnabled = enabled
    }

    // MARK: Private

    private let serviceResolver: any InPlaceTranslationServiceResolving
    private let pasteboard: NSPasteboard
    private var session: InPlaceTranslationSession?
    private var sessionCommandTask: Task<(), Never>?
    private var serviceUpdateCancellable: AnyCancellable?
    private var latestProcessingGeneration: UInt64 = 0

    /// Provides a second stale-result barrier on the UI actor. Session-level
    /// generation checks remain authoritative, while this prevents any delayed
    /// publish already enqueued on MainActor from regressing visible progress.
    private static func generation(
        of state: InPlaceTranslationProcessingState
    )
        -> UInt64? {
        switch state {
        case let .noText(generation),
             let .ready(generation),
             let .recognizing(generation):
            return generation
        case let .partialFailure(generation, _, _),
             let .translating(generation, _, _):
            return generation
        case let .recoverableError(generation, _):
            return generation
        case .debouncing, .idle:
            return nil
        }
    }

    private func observeServiceUpdates() {
        serviceUpdateCancellable = NotificationCenter.default
            .publisher(for: .serviceHasUpdated)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.handleServiceUpdate()
            }
    }

    /// Refreshes labels and language support for active panels. Persisted
    /// selection changes only when the configured service was actually removed.
    private func handleServiceUpdate() {
        let options = serviceResolver.options()
        serviceOptions = options
        guard !options.isEmpty else {
            clearUnavailableServiceSelection()
            return
        }
        let resolution = serviceResolver.resolveSelection(
            configuration.serviceIdentifier,
            availableOptions: options
        )
        guard let resolvedIdentifier = resolution.identifier else {
            availableTargetLanguages = []
            return
        }

        let previousIdentifier = configuration.serviceIdentifier
        let previousTarget = configuration.targetLanguage
        if resolution.shouldResetStoredSelection {
            configuration.serviceIdentifier = resolvedIdentifier
            Defaults[.inPlaceTranslationServiceIdentifier] = resolvedIdentifier
        }
        refreshSupportedTargetLanguages()

        if configuration.serviceIdentifier != previousIdentifier
            || configuration.targetLanguage != previousTarget {
            let identifier = configuration.serviceIdentifier
            let target = configuration.targetLanguage
            enqueueSessionCommand { session in
                await session.setServiceIdentifier(identifier, targetLanguage: target)
            }
        }
    }

    /// Clears a removed provider before asynchronously notifying the session.
    /// The empty identifier disables fallback until an eligible fixed-window
    /// translation service becomes available again.
    private func clearUnavailableServiceSelection() {
        let previousIdentifier = configuration.serviceIdentifier
        configuration.serviceIdentifier = ""
        Defaults[.inPlaceTranslationServiceIdentifier] = ""
        availableTargetLanguages = []
        guard !previousIdentifier.isEmpty else { return }
        let targetLanguage = configuration.targetLanguage
        enqueueSessionCommand { session in
            await session.setServiceIdentifier("", targetLanguage: targetLanguage)
        }
    }

    /// Preserves user-command order across actor hops. Every command waits for
    /// its predecessor, so a slow service or capture mutation cannot overwrite
    /// a newer UI selection after that selection has already been displayed.
    private func enqueueSessionCommand(
        _ command: @escaping @Sendable (InPlaceTranslationSession) async -> ()
    ) {
        guard let session else { return }
        let previousCommand = sessionCommandTask
        sessionCommandTask = Task {
            await previousCommand?.value
            await command(session)
        }
    }

    private func refreshSupportedTargetLanguages() {
        let supported = serviceResolver.supportedLanguages(
            identifier: configuration.serviceIdentifier
        )
        availableTargetLanguages = supported.isEmpty ? Language.allAvailableOptions : supported
        if !availableTargetLanguages.contains(configuration.targetLanguage),
           let fallback = availableTargetLanguages.first {
            configuration.targetLanguage = fallback
        }
    }

    private func fallbackTargetLanguage(excluding language: Language) -> Language {
        availableTargetLanguages.first { $0 != language }
            ?? availableTargetLanguages.first
            ?? .english
    }

    private func clampedTargetLanguage(
        _ proposed: Language,
        excluding source: Language
    )
        -> Language {
        if proposed != .auto, availableTargetLanguages.contains(proposed) {
            return proposed
        }
        return fallbackTargetLanguage(excluding: source)
    }
}
