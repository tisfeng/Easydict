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

// MARK: - ScreenshotTranslationOverlay

/// Displays a captured image with translated text covering the original OCR regions.
@MainActor
final class ScreenshotTranslationOverlay {
    // MARK: Internal

    static let shared = ScreenshotTranslationOverlay()

    /// Keeps the selected region visible while OCR and translation are in progress.
    func begin(screen: NSScreen, rect: CGRect) -> UUID {
        close()
        let sessionID = UUID()
        activeSessionID = sessionID
        installWindow(
            frame: screenRect(screen: screen, rect: rect),
            view: ScreenshotTranslationWaitingView()
        )
        installEventMonitors()
        return sessionID
    }

    func isActive(_ sessionID: UUID) -> Bool {
        activeSessionID == sessionID
    }

    func show(
        image: NSImage,
        items: [ScreenshotTranslationItem],
        screen: NSScreen,
        rect: CGRect,
        mode: ScreenshotTranslateDisplayMode,
        sessionID: UUID
    ) {
        guard isActive(sessionID) else { return }

        let sourceRect = screenRect(screen: screen, rect: rect)
        let frame = resultFrame(sourceRect: sourceRect, screen: screen, mode: mode)
        let view = ScreenshotTranslationOverlayView(
            image: image,
            items: items,
            mode: mode,
            close: { [weak self] in self?.close() }
        )
        installWindow(frame: frame, view: view)
    }

    func close() {
        activeSessionID = nil
        if let keyEventMonitor {
            NSEvent.removeMonitor(keyEventMonitor)
            self.keyEventMonitor = nil
        }
        if let mouseEventMonitor {
            NSEvent.removeMonitor(mouseEventMonitor)
            self.mouseEventMonitor = nil
        }
        window?.orderOut(nil)
        window = nil
    }

    // MARK: Private

    private var window: NSWindow?
    private var activeSessionID: UUID?
    private var keyEventMonitor: Any?
    private var mouseEventMonitor: Any?

    private func installWindow<Content: View>(frame: CGRect, view: Content) {
        window?.orderOut(nil)
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
        self.window = window
    }

    private func installEventMonitors() {
        keyEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard event.keyCode == 53 else { return event }
            self?.close()
            return nil
        }

        mouseEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown) {
            [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self,
                      let activeWindow = window,
                      !activeWindow.frame.contains(NSEvent.mouseLocation) else {
                    return
                }
                close()
            }
        }
    }

    private func screenRect(screen: NSScreen, rect: CGRect) -> CGRect {
        CGRect(
            x: screen.frame.minX + rect.minX,
            y: screen.frame.maxY - rect.maxY,
            width: rect.width,
            height: rect.height
        )
    }

    private func resultFrame(
        sourceRect: CGRect,
        screen: NSScreen,
        mode: ScreenshotTranslateDisplayMode
    )
        -> CGRect {
        guard mode == .imageSideBySide else { return sourceRect }
        let gap = 8.0
        let resultWidth = min(sourceRect.width, max(180, screen.visibleFrame.width * 0.42))
        let rightX = sourceRect.maxX + gap
        let leftX = sourceRect.minX - resultWidth - gap
        let x = rightX + resultWidth <= screen.visibleFrame.maxX
            ? rightX
            : max(screen.visibleFrame.minX, leftX)
        return CGRect(x: x, y: sourceRect.minY, width: resultWidth, height: sourceRect.height)
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

// MARK: - ScreenshotTranslationOverlayView

/// Renders translated labels in the same normalized regions returned by Vision OCR.
private struct ScreenshotTranslationOverlayView: View {
    // MARK: Internal

    let image: NSImage
    let items: [ScreenshotTranslationItem]
    let mode: ScreenshotTranslateDisplayMode
    let close: () -> ()

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                Image(nsImage: image)
                    .resizable()
                    .frame(width: geometry.size.width, height: geometry.size.height)

                ForEach(items) { item in
                    let rect = displayRect(item.boundingBox, in: geometry.size)
                    Text(item.text)
                        .font(.system(size: max(11, min(rect.height * 0.72, 28))))
                        .lineLimit(nil)
                        .minimumScaleFactor(0.35)
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 3)
                        .padding(.vertical, 1)
                        .frame(width: max(rect.width, 24), height: max(rect.height, 18), alignment: .leading)
                        .background {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(.regularMaterial)
                        }
                        .position(x: rect.midX, y: rect.midY)
                }

                Button(action: close) {
                    Image(systemSymbol: .xmarkCircleFill)
                        .font(.system(size: 20))
                        .foregroundStyle(.white, .black.opacity(0.65))
                }
                .buttonStyle(.plain)
                .padding(8)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .overlay {
            RoundedRectangle(cornerRadius: 4)
                .stroke(.white.opacity(0.35), lineWidth: 1)
        }
    }

    // MARK: Private

    private func displayRect(_ visionRect: CGRect, in size: CGSize) -> CGRect {
        CGRect(
            x: visionRect.minX * size.width,
            y: (1 - visionRect.maxY) * size.height,
            width: visionRect.width * size.width,
            height: visionRect.height * size.height
        )
    }
}
