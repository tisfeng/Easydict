//
//  InPlaceTranslationWindowManager.swift
//  Easydict
//
//  Created by Eric Pan on 2026/8/30.
//  Copyright © 2026 izual. All rights reserved.
//

import AppKit
import Defaults
import Foundation

// MARK: - InPlaceTranslationPrivacyDisclosurePolicy

/// Makes first-use disclosure decisions without touching Defaults or AppKit.
/// The displayed provider is resolved only from user-facing service options,
/// so storage identifiers and credentials never enter the disclosure.
enum InPlaceTranslationPrivacyDisclosurePolicy {
    static func shouldPresent(hasAcknowledged: Bool) -> Bool {
        !hasAcknowledged
    }

    static func serviceDisplayName(
        storedIdentifier: String,
        options: [InPlaceTranslationServiceOption],
        fallback: String
    )
        -> String {
        options.first { $0.identifier == storedIdentifier }?.displayName
            ?? options.first?.displayName
            ?? fallback
    }
}

// MARK: - InPlaceTranslationWindowManager

/// Owns the single product panel and atomically replaces its capture session.
/// This is the narrow Swift/Objective-C entry boundary used by menus and shortcuts.
@MainActor
@objc(InPlaceTranslationWindowManager)
public final class InPlaceTranslationWindowManager: NSObject {
    // MARK: Lifecycle

    override private init() {
        super.init()
        observeWorkspaceLifecycle()
    }

    // MARK: Public

    @objc public static let shared = InPlaceTranslationWindowManager()

    /// Starts selection, preserving and restoring the current session if selection is cancelled.
    @objc
    public func startCapture() {
        guard !isSelecting, !isPresentingPrivacyDisclosure else { return }
        guard confirmPrivacyDisclosureIfNeeded() else { return }
        isSelecting = true

        let previousSession = session
        let previousPanel = panel
        Task { [weak self] in
            let shouldResume = await previousSession?.suspendForReselection() ?? false
            guard let self else { return }
            previousPanel?.orderOut(nil)
            beginSelection(
                previousSession: previousSession,
                previousPanel: previousPanel,
                shouldResumePreviousSession: shouldResume
            )
        }
    }

    // MARK: Private

    private enum SystemSuspensionReason: Hashable {
        case miniaturized
        case systemSleep
        case screensSleep
        case sessionInactive
    }

    private let serviceResolver = InPlaceTranslationServiceResolver()
    private var session: InPlaceTranslationSession?
    private var panel: InPlaceTranslationPanel?
    private var isSelecting = false
    private var isPresentingPrivacyDisclosure = false
    private var shouldResumeAfterSystemEvent = false
    private var systemSuspensionTransitionInFlight = false
    private var systemSuspensionReasons: Set<SystemSuspensionReason> = []
    private var workspaceObservers: [NSObjectProtocol] = []

    private func confirmPrivacyDisclosureIfNeeded() -> Bool {
        let hasAcknowledged = Defaults[.inPlaceTranslationPrivacyDisclosureAcknowledged]
        guard InPlaceTranslationPrivacyDisclosurePolicy.shouldPresent(
            hasAcknowledged: hasAcknowledged
        ) else {
            return true
        }

        isPresentingPrivacyDisclosure = true
        defer { isPresentingPrivacyDisclosure = false }

        let fallbackServiceName = NSLocalizedString(
            "in_place_screenshot_translation.privacy.current_service",
            comment: ""
        )
        let serviceName = InPlaceTranslationPrivacyDisclosurePolicy.serviceDisplayName(
            storedIdentifier: Defaults[.inPlaceTranslationServiceIdentifier],
            options: serviceResolver.options(),
            fallback: fallbackServiceName
        )
        let messageFormat = NSLocalizedString(
            "in_place_screenshot_translation.privacy.first_use.message",
            comment: ""
        )

        let alert = NSAlert()
        alert.messageText = NSLocalizedString(
            "in_place_screenshot_translation.privacy.first_use.title",
            comment: ""
        )
        alert.informativeText = String(
            format: messageFormat,
            locale: Locale.current,
            serviceName
        )
        alert.alertStyle = .informational
        alert.addButton(
            withTitle: NSLocalizedString(
                "in_place_screenshot_translation.privacy.first_use.continue",
                comment: ""
            )
        )
        alert.addButton(
            withTitle: NSLocalizedString(
                "in_place_screenshot_translation.privacy.first_use.cancel",
                comment: ""
            )
        )

        NSApplication.shared.activate(ignoringOtherApps: true)
        guard alert.runModal() == .alertFirstButtonReturn else { return false }
        Defaults[.inPlaceTranslationPrivacyDisclosureAcknowledged] = true
        return true
    }

    private func beginSelection(
        previousSession: InPlaceTranslationSession?,
        previousPanel: InPlaceTranslationPanel?,
        shouldResumePreviousSession: Bool
    ) {
        Screenshot.shared.startSelectionCapture { [weak self] result in
            guard let self else { return }
            isSelecting = false
            guard case let .selected(selection) = result else {
                previousPanel?.makeKeyAndOrderFront(nil)
                Task {
                    await previousSession?.resumeAfterCancelledReselection(
                        shouldResumePreviousSession
                    )
                }
                if case let .failed(error) = result {
                    presentSelectionFailureIfNeeded(error)
                }
                return
            }
            installSession(
                selection: selection,
                previousSession: previousSession,
                previousPanel: previousPanel
            )
        }
    }

    /// Cancellation is silent. Typed failures restore any previous session and
    /// receive a localized explanation without exposing selection geometry.
    private func presentSelectionFailureIfNeeded(_ error: ScreenshotSelectionCaptureError) {
        let localizationKey: String
        switch error {
        case .permissionDenied:
            return
        case .selectionTooSmall:
            localizationKey = "in_place_screenshot_translation.error.selection_too_small"
        case .displayUnavailable:
            localizationKey = "in_place_screenshot_translation.error.display_disconnected"
        case .captureInProgress, .imageUnavailable:
            localizationKey = "in_place_screenshot_translation.error.capture"
        }

        let alert = NSAlert()
        alert.messageText = NSLocalizedString(localizationKey, comment: "")
        alert.alertStyle = .warning
        alert.runModal()
    }

    private func installSession(
        selection: ScreenshotSelection,
        previousSession: InPlaceTranslationSession?,
        previousPanel: InPlaceTranslationPanel?
    ) {
        let configuration = makeConfiguration()
        let viewModel = InPlaceTranslationViewModel(
            configuration: configuration,
            serviceResolver: serviceResolver
        )
        let resolvedConfiguration = viewModel.configuration
        let frameSource = ScreenCaptureKitRegionFrameSource(selection: selection)
        let session = InPlaceTranslationSession(
            selection: selection,
            configuration: resolvedConfiguration,
            viewModel: viewModel,
            frameSource: frameSource
        )
        let panel = InPlaceTranslationPanel(viewModel: viewModel, selection: selection)

        viewModel.attach(session: session)
        viewModel.onPinChanged = { [weak panel] isPinned in
            panel?.setPinned(isPinned)
        }
        viewModel.onReselect = { [weak self] in
            self?.startCapture()
        }
        viewModel.onClose = { [weak panel] in
            panel?.performClose(nil)
        }
        panel.onRequestClose = { [weak self, weak panel] in
            guard let self, self.panel === panel else { return }
            tearDownCurrentSession()
        }
        panel.onMiniaturize = { [weak self] in
            self?.addSystemSuspensionReason(.miniaturized)
        }
        panel.onDeminiaturize = { [weak self] in
            self?.removeSystemSuspensionReason(.miniaturized)
        }

        // Suspension reasons belong to the panel/session they were observed
        // against. A replacement panel must not inherit a stale miniaturized
        // or workspace state from the session it is replacing.
        systemSuspensionReasons.removeAll()
        shouldResumeAfterSystemEvent = false
        systemSuspensionTransitionInFlight = false
        self.session = session
        self.panel = panel
        panel.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)

        Task {
            await previousSession?.stop()
            previousPanel?.contentView = nil
            previousPanel?.orderOut(nil)
            await session.start()
        }
    }

    private func makeConfiguration() -> InPlaceTranslationConfiguration {
        let sourceLanguage = Defaults[.queryFromLanguage]
        var targetLanguage = EZLanguageManager.shared().userTargetLanguage(
            withSourceLanguage: sourceLanguage
        )
        if targetLanguage == .auto {
            targetLanguage = Language.allAvailableOptions.first { $0 != sourceLanguage } ?? .english
        }

        let resolution = serviceResolver.resolveSelection(
            Defaults[.inPlaceTranslationServiceIdentifier]
        )
        let identifier = resolution.identifier ?? ""
        if resolution.shouldResetStoredSelection, !identifier.isEmpty {
            Defaults[.inPlaceTranslationServiceIdentifier] = identifier
        }
        return InPlaceTranslationConfiguration(
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
            serviceIdentifier: identifier,
            liveUpdatesEnabled: Defaults[.inPlaceTranslationLiveUpdatesEnabled],
            isPinned: Defaults[.inPlaceTranslationPinned],
            renderMode: .translated
        )
    }

    private func tearDownCurrentSession() {
        let oldSession = session
        panel?.orderOut(nil)
        panel?.contentView = nil
        panel = nil
        session = nil
        systemSuspensionReasons.removeAll()
        shouldResumeAfterSystemEvent = false
        systemSuspensionTransitionInFlight = false
        Task {
            await oldSession?.stop()
        }
    }

    private func addSystemSuspensionReason(_ reason: SystemSuspensionReason) {
        let insertion = systemSuspensionReasons.insert(reason)
        guard insertion.inserted, systemSuspensionReasons.count == 1, let session else { return }
        systemSuspensionTransitionInFlight = true
        Task { [weak self, weak session] in
            guard let session else { return }
            let shouldResume = await session.suspendForReselection()
            guard let self, self.session === session else { return }
            shouldResumeAfterSystemEvent = shouldResumeAfterSystemEvent || shouldResume
            systemSuspensionTransitionInFlight = false
            resumeAfterSystemEventsIfPossible()
        }
    }

    private func removeSystemSuspensionReason(_ reason: SystemSuspensionReason) {
        systemSuspensionReasons.remove(reason)
        resumeAfterSystemEventsIfPossible()
    }

    private func resumeAfterSystemEventsIfPossible() {
        guard systemSuspensionReasons.isEmpty,
              !systemSuspensionTransitionInFlight,
              let session
        else {
            return
        }
        let shouldResume = shouldResumeAfterSystemEvent
        shouldResumeAfterSystemEvent = false
        Task {
            await session.resumeAfterCancelledReselection(shouldResume)
        }
    }

    private func observeWorkspaceLifecycle() {
        let center = NSWorkspace.shared.notificationCenter
        workspaceObservers.append(
            center.addObserver(
                forName: NSWorkspace.willSleepNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in self?.addSystemSuspensionReason(.systemSleep) }
            }
        )
        workspaceObservers.append(
            center.addObserver(
                forName: NSWorkspace.didWakeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in self?.removeSystemSuspensionReason(.systemSleep) }
            }
        )
        workspaceObservers.append(
            center.addObserver(
                forName: NSWorkspace.screensDidSleepNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in self?.addSystemSuspensionReason(.screensSleep) }
            }
        )
        workspaceObservers.append(
            center.addObserver(
                forName: NSWorkspace.screensDidWakeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in self?.removeSystemSuspensionReason(.screensSleep) }
            }
        )
        workspaceObservers.append(
            center.addObserver(
                forName: NSWorkspace.sessionDidResignActiveNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in self?.addSystemSuspensionReason(.sessionInactive) }
            }
        )
        workspaceObservers.append(
            center.addObserver(
                forName: NSWorkspace.sessionDidBecomeActiveNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in self?.removeSystemSuspensionReason(.sessionInactive) }
            }
        )
    }
}
