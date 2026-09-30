//
//  ScreenshotTranslationOverlay.swift
//  Easydict
//
//  Created by bsythegreat on 2026/7/29.
//  Copyright © 2026 izual. All rights reserved.
//

import AppKit
import SFSafeSymbols
import SwiftUI

// MARK: - ScreenshotTranslationItem

/// Represents translated text positioned in the source image's normalized coordinate space.
struct ScreenshotTranslationItem: Identifiable {
    let id = UUID()
    let text: String
    let boundingBox: CGRect
}

// MARK: - ScreenshotTranslationContent

/// Bundles overlay output with the service identity that produced the displayed translation.
struct ScreenshotTranslationContent {
    let image: NSImage
    let items: [ScreenshotTranslationItem]
    let serviceName: String
    let serviceIconName: String
}

// MARK: - ScreenshotTranslationStatus

/// Describes the OCR or translation service shown beside an active screenshot overlay.
private struct ScreenshotTranslationStatus {
    let name: String
    let iconName: String?
    let isProcessing: Bool
}

// MARK: - ScreenshotTranslationSession

/// Owns the main and status windows for one independent screenshot translation.
private final class ScreenshotTranslationSession {
    // MARK: Lifecycle

    init(id: UUID, excludedRegions: [CGRect]) {
        self.id = id
        self.excludedRegions = excludedRegions
    }

    // MARK: Internal

    let id: UUID
    let excludedRegions: [CGRect]
    var task: Task<(), Never>?
    var window: NSWindow?
    var statusWindow: NSWindow?
    var status: ScreenshotTranslationStatus?
    weak var statusScreen: NSScreen?
    var frameObserverTokens: [NSObjectProtocol] = []
}

// MARK: - ScreenshotTranslationOverlay

/// Displays a captured image with translated text covering the original OCR regions.
@MainActor
final class ScreenshotTranslationOverlay {
    // MARK: Internal

    static let shared = ScreenshotTranslationOverlay()

    /// Keeps the selected region visible while OCR and translation are in progress.
    func begin(screen: NSScreen, rect: CGRect) -> UUID {
        let excludedRegions = occupiedRegions(screen: screen, rect: rect)
        if !MyConfiguration.shared.allowMultipleScreenshotOverlays {
            closeAll()
        }

        let sessionID = UUID()
        let session = ScreenshotTranslationSession(
            id: sessionID,
            excludedRegions: excludedRegions
        )
        sessions[sessionID] = session
        sessionOrder.append(sessionID)
        let frame = screenRect(screen: screen, rect: rect)
        installWindow(
            session: session,
            frame: frame,
            view: ScreenshotTranslationWaitingView()
        )
        installStatusWindow(
            session: session,
            beside: frame,
            screen: screen,
            status: ScreenshotTranslationStatus(
                name: NSLocalizedString("screenshot.overlay.status.ocr", comment: ""),
                iconName: nil,
                isProcessing: true
            )
        )
        installEventMonitors()
        return sessionID
    }

    func isActive(_ sessionID: UUID) -> Bool {
        sessions[sessionID] != nil
    }

    /// Returns normalized capture regions occupied when the screenshot was taken.
    func excludedRegions(for sessionID: UUID) -> [CGRect] {
        sessions[sessionID]?.excludedRegions ?? []
    }

    /// Attaches the OCR and translation task so closing the session cancels its work.
    func setTask(_ task: Task<(), Never>, for sessionID: UUID) {
        guard let session = sessions[sessionID] else {
            task.cancel()
            return
        }
        session.task = task
    }

    /// Releases a completed task while keeping its result window session alive.
    func finishTask(_ sessionID: UUID) {
        sessions[sessionID]?.task = nil
    }

    /// Shows the service currently attempting to translate the recognized text.
    func showTranslationProgress(
        service: QueryService,
        screen: NSScreen,
        rect: CGRect,
        sessionID: UUID
    ) {
        guard let session = sessions[sessionID] else { return }

        installStatusWindow(
            session: session,
            beside: screenRect(screen: screen, rect: rect),
            screen: screen,
            status: ScreenshotTranslationStatus(
                name: service.name(),
                iconName: service.serviceType().rawValue,
                isProcessing: true
            )
        )
    }

    func show(
        content: ScreenshotTranslationContent,
        screen: NSScreen,
        rect: CGRect,
        mode: ScreenshotTranslateDisplayMode,
        sessionID: UUID
    ) {
        guard let session = sessions[sessionID] else { return }

        let sourceRect = screenRect(screen: screen, rect: rect)
        let frame = resultFrame(sourceRect: sourceRect, screen: screen, mode: mode)
        let view = ScreenshotTranslationOverlayView(
            content: content,
            mode: mode,
            close: { [weak self] in self?.close(sessionID) }
        )
        installWindow(session: session, frame: frame, view: view)
        if mode == .imageSideBySide {
            configureResultWindow(session.window, aspectRatio: frame.size)
        }
        installStatusWindow(
            session: session,
            beside: frame,
            screen: screen,
            status: ScreenshotTranslationStatus(
                name: content.serviceName,
                iconName: content.serviceIconName,
                isProcessing: false
            )
        )
    }

    func close(_ sessionID: UUID) {
        guard let session = sessions.removeValue(forKey: sessionID) else { return }
        session.task?.cancel()
        session.task = nil
        sessionOrder.removeAll { $0 == sessionID }
        removeStatusWindow(session)
        session.window?.orderOut(nil)
        session.window = nil
        removeFrameObservers(session)

        if sessions.isEmpty {
            removeEventMonitors()
        } else {
            latestSession?.window?.makeKeyAndOrderFront(nil)
        }
    }

    // MARK: Private

    private var sessions: [UUID: ScreenshotTranslationSession] = [:]
    private var sessionOrder: [UUID] = []
    private var keyEventMonitor: Any?
    private var localMouseEventMonitor: Any?
    private var globalMouseEventMonitor: Any?

    private var latestSession: ScreenshotTranslationSession? {
        if let keySession = sessions.values.first(where: { $0.window?.isKeyWindow == true }) {
            return keySession
        }
        return sessionOrder.reversed().lazy.compactMap { self.sessions[$0] }.first
    }

    private func installWindow<Content: View>(
        session: ScreenshotTranslationSession,
        frame: CGRect,
        view: Content
    ) {
        removeStatusWindow(session)
        removeFrameObservers(session)
        session.window?.orderOut(nil)
        let window = ScreenshotTranslationWindow(
            contentRect: frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window.level = .screenSaver
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true
        window.isMovableByWindowBackground = true
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.contentView = ScreenshotTranslationHostingView(rootView: view)
        window.makeKeyAndOrderFront(nil)
        session.window = window
        installFrameObservers(for: session, window: window)
    }

    private func configureResultWindow(_ window: NSWindow?, aspectRatio: CGSize) {
        guard let window, aspectRatio.width > 0, aspectRatio.height > 0 else { return }
        window.styleMask.insert(.resizable)
        window.contentAspectRatio = aspectRatio
        let minimumWidth = min(120, aspectRatio.width)
        window.contentMinSize = CGSize(
            width: minimumWidth,
            height: minimumWidth * aspectRatio.height / aspectRatio.width
        )
    }

    private func installStatusWindow(
        session: ScreenshotTranslationSession,
        beside contentFrame: CGRect,
        screen: NSScreen,
        status: ScreenshotTranslationStatus
    ) {
        removeStatusWindow(session)

        session.status = status
        session.statusScreen = screen

        let frame = statusFrame(
            beside: contentFrame,
            screen: screen,
            isProcessing: status.isProcessing
        )
        let statusWindow = ScreenshotTranslationWindow(
            contentRect: frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        statusWindow.level = .screenSaver
        statusWindow.backgroundColor = .clear
        statusWindow.isOpaque = false
        statusWindow.hasShadow = true
        statusWindow.ignoresMouseEvents = true
        statusWindow.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        statusWindow.contentView = NSHostingView(
            rootView: ScreenshotTranslationStatusView(status: status)
        )
        statusWindow.orderFront(nil)
        session.window?.addChildWindow(statusWindow, ordered: .above)
        session.statusWindow = statusWindow
    }

    private func removeStatusWindow(_ session: ScreenshotTranslationSession) {
        guard let statusWindow = session.statusWindow else { return }
        statusWindow.parent?.removeChildWindow(statusWindow)
        statusWindow.orderOut(nil)
        session.statusWindow = nil
    }

    private func installFrameObservers(
        for session: ScreenshotTranslationSession,
        window: NSWindow
    ) {
        let notificationCenter = NotificationCenter.default
        let names = [NSWindow.didMoveNotification, NSWindow.didResizeNotification]
        let sessionID = session.id
        session.frameObserverTokens = names.map { name in
            notificationCenter.addObserver(forName: name, object: window, queue: .main) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.repositionStatusWindow(for: sessionID)
                }
            }
        }
    }

    private func removeFrameObservers(_ session: ScreenshotTranslationSession) {
        let notificationCenter = NotificationCenter.default
        for token in session.frameObserverTokens {
            notificationCenter.removeObserver(token)
        }
        session.frameObserverTokens.removeAll()
    }

    /// Keeps the fixed-size status badge outside the result window's top-right corner.
    private func repositionStatusWindow(for sessionID: UUID) {
        guard let session = sessions[sessionID] else { return }
        guard let window = session.window,
              let statusWindow = session.statusWindow,
              let status = session.status,
              let screen = window.screen ?? session.statusScreen ?? NSScreen.main else {
            return
        }
        statusWindow.setFrame(
            statusFrame(
                beside: window.frame,
                screen: screen,
                isProcessing: status.isProcessing
            ),
            display: true
        )
    }

    private func installEventMonitors() {
        guard keyEventMonitor == nil else { return }

        keyEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard event.keyCode == 53,
                  MyConfiguration.shared.screenshotOverlayDismissMode.allowsEscape else {
                return event
            }
            self?.closeLatest()
            return nil
        }

        localMouseEventMonitor = NSEvent.addLocalMonitorForEvents(
            matching: .leftMouseDown
        ) { [weak self] event in
            self?.closeLatestForOutsideClick()
            return event
        }

        globalMouseEventMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: .leftMouseDown
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.closeLatestForOutsideClick()
            }
        }
    }

    private func removeEventMonitors() {
        if let keyEventMonitor {
            NSEvent.removeMonitor(keyEventMonitor)
            self.keyEventMonitor = nil
        }
        if let localMouseEventMonitor {
            NSEvent.removeMonitor(localMouseEventMonitor)
            self.localMouseEventMonitor = nil
        }
        if let globalMouseEventMonitor {
            NSEvent.removeMonitor(globalMouseEventMonitor)
            self.globalMouseEventMonitor = nil
        }
    }

    private func closeLatest() {
        guard let sessionID = latestSession?.id else { return }
        close(sessionID)
    }

    private func closeLatestForOutsideClick() {
        guard MyConfiguration.shared.screenshotOverlayDismissMode.allowsOutsideClick else {
            return
        }
        let location = NSEvent.mouseLocation
        let isInsideOverlay = sessions.values.contains { session in
            session.window?.frame.contains(location) == true
                || session.statusWindow?.frame.contains(location) == true
        }
        guard !isInsideOverlay else { return }
        closeLatest()
    }

    private func closeAll() {
        for session in sessions.values {
            session.task?.cancel()
            session.task = nil
            removeStatusWindow(session)
            removeFrameObservers(session)
            session.window?.orderOut(nil)
            session.window = nil
        }
        sessions.removeAll()
        sessionOrder.removeAll()
        removeEventMonitors()
    }

    private func screenRect(screen: NSScreen, rect: CGRect) -> CGRect {
        CGRect(
            x: screen.frame.minX + rect.minX,
            y: screen.frame.maxY - rect.maxY,
            width: rect.width,
            height: rect.height
        )
    }

    /// Captures normalized regions occupied by result windows already visible in the screenshot.
    private func occupiedRegions(screen: NSScreen, rect: CGRect) -> [CGRect] {
        let captureFrame = screenRect(screen: screen, rect: rect)
        guard captureFrame.width > 0, captureFrame.height > 0 else { return [] }

        return sessions.values.flatMap { session -> [CGRect] in
            [session.window?.frame, session.statusWindow?.frame].compactMap { frame in
                guard let frame else { return nil }
                let overlap = captureFrame.intersection(frame)
                guard !overlap.isNull, !overlap.isEmpty else { return nil }
                return CGRect(
                    x: (overlap.minX - captureFrame.minX) / captureFrame.width,
                    y: (overlap.minY - captureFrame.minY) / captureFrame.height,
                    width: overlap.width / captureFrame.width,
                    height: overlap.height / captureFrame.height
                )
            }
        }
    }

    private func resultFrame(
        sourceRect: CGRect,
        screen: NSScreen,
        mode: ScreenshotTranslateDisplayMode
    )
        -> CGRect {
        guard mode == .imageSideBySide,
              sourceRect.width > 0,
              sourceRect.height > 0 else {
            return sourceRect
        }
        let gap = 8.0
        let maxWidth = max(180, screen.visibleFrame.width * 0.42)
        let widthScale = maxWidth / sourceRect.width
        let heightScale = screen.visibleFrame.height / sourceRect.height
        let scale = min(1, min(widthScale, heightScale))
        let resultWidth = sourceRect.width * scale
        let resultHeight = sourceRect.height * scale
        let rightX = sourceRect.maxX + gap
        let leftX = sourceRect.minX - resultWidth - gap
        let x = rightX + resultWidth <= screen.visibleFrame.maxX
            ? rightX
            : max(screen.visibleFrame.minX, leftX)
        let y = min(
            max(sourceRect.minY, screen.visibleFrame.minY),
            screen.visibleFrame.maxY - resultHeight
        )
        return CGRect(x: x, y: y, width: resultWidth, height: resultHeight)
    }

    private func statusFrame(
        beside contentFrame: CGRect,
        screen: NSScreen,
        isProcessing: Bool
    )
        -> CGRect {
        let gap = 6.0
        let size = CGSize(width: isProcessing ? 66 : 34, height: 34)
        let visibleFrame = screen.visibleFrame
        var origin = CGPoint(
            x: contentFrame.maxX - size.width,
            y: contentFrame.maxY + gap
        )

        if origin.y + size.height > visibleFrame.maxY {
            let rightX = contentFrame.maxX + gap
            if rightX + size.width <= visibleFrame.maxX {
                origin = CGPoint(
                    x: rightX,
                    y: contentFrame.maxY - size.height
                )
            } else {
                origin.y = contentFrame.minY - size.height - gap
            }
        }

        origin.x = min(
            max(origin.x, visibleFrame.minX),
            visibleFrame.maxX - size.width
        )
        origin.y = min(
            max(origin.y, visibleFrame.minY),
            visibleFrame.maxY - size.height
        )
        return CGRect(origin: origin, size: size)
    }
}

// MARK: - ScreenshotTranslationWindow

/// A borderless result window that accepts Escape and close-button input.
private final class ScreenshotTranslationWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

// MARK: - ScreenshotTranslationHostingView

/// Lets users drag the borderless result window from any non-control background area.
private final class ScreenshotTranslationHostingView<Content: View>: NSHostingView<Content> {
    override var mouseDownCanMoveWindow: Bool { true }
}

// MARK: - ScreenshotTranslationWaitingView

/// Draws a lightweight selection outline while translation is pending.
private struct ScreenshotTranslationWaitingView: View {
    var body: some View {
        Color.clear
            .overlay {
                RoundedRectangle(cornerRadius: 3)
                    .stroke(.white.opacity(0.9), lineWidth: 1)
            }
    }
}

// MARK: - ScreenshotTranslationStatusView

/// Displays the current OCR or translation service without covering the captured image.
private struct ScreenshotTranslationStatusView: View {
    let status: ScreenshotTranslationStatus

    var body: some View {
        HStack(spacing: 7) {
            Group {
                if let iconName = status.iconName {
                    Image(iconName)
                        .resizable()
                        .scaledToFit()
                } else {
                    Image(systemSymbol: .characterCursorIbeam)
                        .font(.system(size: 16, weight: .medium))
                }
            }
            .frame(width: 18, height: 18)

            if status.isProcessing {
                ScreenshotTranslationWaveView()
            }
        }
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 9)
                .fill(.regularMaterial)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 9)
                .stroke(.white.opacity(0.35), lineWidth: 0.5)
        }
        .help(status.name)
        .accessibilityLabel(Text(verbatim: status.name))
    }
}

// MARK: - ScreenshotTranslationWaveView

/// Animates four dots as a small wave that travels left-to-right and back.
private struct ScreenshotTranslationWaveView: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { context in
            let elapsed = context.date.timeIntervalSinceReferenceDate
            let cycle = elapsed.truncatingRemainder(dividingBy: 1.6) / 1.6
            let cursor = cycle < 0.5 ? cycle * 6 : (1 - cycle) * 6

            HStack(spacing: 3) {
                ForEach(0 ..< 4, id: \.self) { index in
                    let distance = abs(Double(index) - cursor)
                    let lift = max(0, 1 - distance) * 4
                    Circle()
                        .fill(.secondary)
                        .frame(width: 4, height: 4)
                        .offset(y: -lift)
                }
            }
            .frame(width: 25, height: 14)
        }
    }
}
