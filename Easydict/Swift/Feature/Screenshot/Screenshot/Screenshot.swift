//
//  Screenshot.swift
//  Easydict
//
//  Created by tisfeng on 2025/3/12.
//  Copyright © 2025 izual. All rights reserved.
//

import AppKit
import Foundation
import SwiftUI

// MARK: - Screenshot

@objc
class Screenshot: NSObject {
    // MARK: Public

    @objc public static let shared = Screenshot()

    @objc public private(set) var isTakingScreenshot = false

    @objc
    public func startCapture(completion: @escaping (NSImage?) -> ()) {
        if isTakingScreenshot {
            completion(nil)
            return
        }

        let hasScreenCapturePermission = CGPreflightScreenCaptureAccess()
        if !hasScreenCapturePermission {
            if !hasRequestedPermission {
                hasRequestedPermission = true
                /**
                 This method will prompt to get screen capture access if not already granted only once.

                 If you trigger the prompt and the user `denies` it, you cannot bring up the prompt again - the user must manually enable it in System Preferences.
                 */
                CGRequestScreenCaptureAccess()
            } else {
                showScreenCapturePermissionAlert()
            }
            completion(nil)
            return
        }

        isTakingScreenshot = true
        captureSessionID = UUID()
        pushCrosshairCursor()
        setupEventMonitor()
        showOverlayWindow(completion: completion)
    }

    // MARK: Internal

    var overlayWindows: [NSScreen: NSWindow] = [:]
    var overlayViewStates: [NSScreen: ScreenshotState] = [:]

    var eventMonitor: Any?
    let keyboardEventTap = ScreenshotKeyboardEventTap()
    var isKeyboardAvailable = true
    private(set) var captureSessionID: UUID?

    /// Work item for the delayed screenshot capture after pressing 'D' for preview.
    var previewScreenshotWorkItem: DispatchWorkItem?

    /// Finish screenshot capture and call the completion handler
    @objc
    func finishCapture(_ image: NSImage?) {
        guard isTakingScreenshot else { return }
        cancelPreviewScreenshotTimer()
        captureSessionID = nil
        isTakingScreenshot = false
        popCrosshairCursor()

        let completion = captureCompletionHandler
        captureCompletionHandler = nil
        hideAllOverlayWindows()
        removeEventMonitor()
        overlayViewStates.removeAll()

        // Result windows may activate the app; no old capture cleanup runs after them.
        completion?(image)
    }

    /// Cancels the scheduled preview screenshot task, if any.
    func cancelPreviewScreenshotTimer() {
        previewScreenshotWorkItem?.cancel()
        previewScreenshotWorkItem = nil
    }

    /// Performs the actual screenshot operation asynchronously.
    /// - Parameters:
    ///   - screen: The screen to capture from.
    ///   - rect: The rectangle area to capture within the screen coordinates.
    func performScreenshot(screen: NSScreen, rect: CGRect) {
        guard let sessionID = captureSessionID else { return }
        NSLog("Performing screenshot, screen frame: \(screen.frame), rect: \(rect)")

        // Reset the state for the specific screen to hide selection UI etc.
        overlayViewStates[screen]?.reset()

        // Save last screenshot rect and screen
        lastScreenshotRect = rect
        lastScreen = screen

        // Async dispatch to allow UI updates (state reset) before capturing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            guard self.captureSessionID == sessionID else { return }
            let image = screen.takeScreenshot(rect: rect)
            // Finish the capture process with the result
            self.finishCapture(image)
        }
    }

    // MARK: Private

    /// The completion handler passed from startCapture.
    private var captureCompletionHandler: ((NSImage?) -> ())?

    /// Tracks whether the crosshair cursor is currently pushed onto the cursor stack.
    private var hasPushedCrosshairCursor = false

    /// Applies the crosshair cursor immediately.
    private func updateCrosshairCursor() {
        NSCursor.crosshair.set()
    }

    private func pushCrosshairCursor() {
        guard !hasPushedCrosshairCursor else { return }
        NSCursor.crosshair.push()
        updateCrosshairCursor()
        hasPushedCrosshairCursor = true
    }

    /// Pops the crosshair cursor from the cursor stack after capture finishes.
    private func popCrosshairCursor() {
        guard hasPushedCrosshairCursor else { return }
        NSCursor.pop()
        hasPushedCrosshairCursor = false
    }

    private func showOverlayWindow(completion: @escaping (NSImage?) -> ()) {
        // Store the completion handler
        captureCompletionHandler = completion

        overlayViewStates.removeAll()
        hideAllOverlayWindows()

        for screen in NSScreen.screens {
            createOverlayWindow(for: screen)
        }
    }

    private func createOverlayWindow(for screen: NSScreen) {
        let window = ScreenshotOverlayWindow(
            contentRect: screen.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        window.level = .screenSaver
        window.acceptsMouseMovedEvents = true
        window.backgroundColor = .clear
        window.isOpaque = false
        // Keep the full-screen snapshot stationary when the panel appears or disappears.
        window.animationBehavior = .none
        window.hidesOnDeactivate = false
        window.becomesKeyOnlyIfNeeded = true
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let state = ScreenshotState(screen: screen)
        state.isKeyboardAvailable = isKeyboardAvailable
        let contentView = ScreenshotOverlayView(state: state)
        let hostingView = ScreenshotOverlayHostingView(rootView: contentView)
        hostingView.onMouseMoved = { [weak state] in state?.handleMouseMoved() }
        window.contentView = hostingView
        if let contentView = window.contentView {
            window.invalidateCursorRects(for: contentView)
        }

        overlayWindows[screen] = window
        overlayViewStates[screen] = state
        window.orderFrontRegardless()
    }

    private func hideAllOverlayWindows() {
        for (_, window) in overlayWindows {
            window.orderOut(nil)
        }
        overlayWindows.removeAll()
    }
}

// MARK: - ScreenshotOverlayWindow

/// Receives screenshot mouse input while preserving the frontmost application.
final class ScreenshotOverlayWindow: NSPanel {
    override var canBecomeKey: Bool {
        false
    }

    override var canBecomeMain: Bool {
        false
    }
}
