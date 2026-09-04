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

// MARK: - ScreenshotSelectionCaptureResult

/// A typed result for selection-aware capture callers. The legacy image-only
/// API intentionally remains nullable for Objective-C compatibility.
enum ScreenshotSelectionCaptureResult {
    case selected(ScreenshotSelection)
    case cancelled
    case failed(ScreenshotSelectionCaptureError)
}

// MARK: - ScreenshotSelectionCaptureError

/// Sanitized failure categories for selection-aware capture. No screen
/// coordinates or captured content are included in these values.
enum ScreenshotSelectionCaptureError: Error {
    case captureInProgress
    case permissionDenied
    case selectionTooSmall
    case displayUnavailable
    case imageUnavailable
}

// MARK: - Screenshot

@objc
class Screenshot: NSObject {
    // MARK: Public

    @objc public static let shared = Screenshot()

    @objc public private(set) var isTakingScreenshot = false
    @objc public var shouldRestorePreviousApp = false

    @objc
    public func startCapture(completion: @escaping (NSImage?) -> ()) {
        beginCapture(imageCompletion: completion, selectionCompletion: nil)
    }

    // MARK: Internal

    var overlayWindows: [NSScreen: NSWindow] = [:]
    var overlayViewStates: [NSScreen: ScreenshotState] = [:]

    var eventMonitor: Any?

    /// Work item for the delayed screenshot capture after pressing 'D' for preview.
    var previewScreenshotWorkItem: DispatchWorkItem?

    /// Starts the existing screenshot selector while returning immutable display geometry.
    func startSelectionCapture(
        completion: @escaping (ScreenshotSelectionCaptureResult) -> ()
    ) {
        // This workflow opens its own persistent panel, so it must not inherit
        // focus-restoration state left by an earlier silent OCR capture.
        beginCapture(
            imageCompletion: nil,
            selectionCompletion: completion,
            shouldRestorePreviousAppOverride: false
        )
    }

    /// Finish screenshot capture and call the completion handler
    @objc
    func finishCapture(_ image: NSImage?) {
        finishCapture(image, selectionResult: .cancelled)
    }

    /// Ends selection-aware capture with a typed, content-free failure.
    func finishSelectionCapture(error: ScreenshotSelectionCaptureError) {
        finishCapture(nil, selectionResult: .failed(error))
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
        NSLog("Performing screenshot selection capture")

        // Reset the state for the specific screen to hide selection UI etc.
        overlayViewStates[screen]?.reset()

        // Only the legacy screenshot workflow persists its reusable D-key
        // region. In-place translation keeps selection geometry in memory for
        // the session lifetime and must not write screen coordinates to Defaults.
        if shouldPersistLastSelection {
            lastScreenshotRect = rect
            lastScreen = screen
        }

        // Async dispatch to allow UI updates (state reset) before capturing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let image = screen.takeScreenshot(rect: rect)
            let selectionResult: ScreenshotSelectionCaptureResult
            if let image, let displayID = screen.displayID {
                selectionResult = .selected(
                    ScreenshotSelection(
                        displayID: displayID,
                        screenFrameInGlobalPoints: screen.frame,
                        sourceRectInDisplayPoints: rect,
                        backingScaleFactor: screen.backingScaleFactor,
                        initialImage: image
                    )
                )
            } else if image == nil {
                selectionResult = .failed(.imageUnavailable)
            } else {
                selectionResult = .failed(.displayUnavailable)
            }
            // Finish the capture process with one atomic image-and-geometry result.
            self.finishCapture(image, selectionResult: selectionResult)
        }
    }

    // MARK: Private

    /// The completion handler passed from the legacy image-only API.
    private var captureCompletionHandler: ((NSImage?) -> ())?

    /// The completion handler passed from the layout-aware selection API.
    private var selectionCaptureCompletionHandler: ((ScreenshotSelectionCaptureResult) -> ())?

    /// True only for the legacy image-only entry point. Selection-aware
    /// in-place capture never persists screen geometry.
    private var shouldPersistLastSelection = true

    private var previousActiveApp: NSRunningApplication?

    /// Tracks whether the crosshair cursor is currently pushed onto the cursor stack.
    private var hasPushedCrosshairCursor = false

    private func beginCapture(
        imageCompletion: ((NSImage?) -> ())?,
        selectionCompletion: ((ScreenshotSelectionCaptureResult) -> ())?,
        shouldRestorePreviousAppOverride: Bool? = nil
    ) {
        if isTakingScreenshot {
            imageCompletion?(nil)
            selectionCompletion?(.failed(.captureInProgress))
            return
        }

        if let shouldRestorePreviousAppOverride {
            shouldRestorePreviousApp = shouldRestorePreviousAppOverride
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
            imageCompletion?(nil)
            selectionCompletion?(.failed(.permissionDenied))
            return
        }

        captureCompletionHandler = imageCompletion
        selectionCaptureCompletionHandler = selectionCompletion
        shouldPersistLastSelection = selectionCompletion == nil
        isTakingScreenshot = true
        pushCrosshairCursor()
        setupEventMonitor()
        showOverlayWindow()
    }

    private func finishCapture(
        _ image: NSImage?,
        selectionResult: ScreenshotSelectionCaptureResult
    ) {
        // Cancel any pending preview screenshot task first
        cancelPreviewScreenshotTimer()

        isTakingScreenshot = false
        popCrosshairCursor()

        // Restore focus to previous application only if shouldRestorePreviousApp is true
        if shouldRestorePreviousApp, let previousApp = previousActiveApp {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                previousApp.activate()
            }
        }

        previousActiveApp = nil

        // Call the original completion handler
        captureCompletionHandler?(image)
        captureCompletionHandler = nil
        selectionCaptureCompletionHandler?(selectionResult)
        selectionCaptureCompletionHandler = nil
        shouldPersistLastSelection = true

        hideAllOverlayWindows()
        removeEventMonitor()
        tearDownOverlayStates()
    }

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

    private func showOverlayWindow() {
        // Save the currently active application
        previousActiveApp = NSWorkspace.shared.frontmostApplication

        tearDownOverlayStates()
        hideAllOverlayWindows()

        // Show overlay window on each screen
        for screen in NSScreen.screens {
            createOverlayWindow(for: screen)
        }

        /*
         Activate App after creating all screenshot windows, avoid losing focus application.

         Activate the application to ensure it receives key events.
         Local event monitors (`addLocalMonitorForEvents`) only capture events
         dispatched to the *active* application. Without activating,
         key down events (like ESC to cancel) might not be received
         if another application was active when the screenshot started.
         */
        NSApplication.shared.activateApp()
    }

    /// Removes transient screenshot state and releases any local event monitors it owns.
    private func tearDownOverlayStates() {
        for state in overlayViewStates.values {
            state.cleanup()
        }
        overlayViewStates.removeAll()
    }

    private func createOverlayWindow(for screen: NSScreen) {
        let window = ScreenshotOverlayWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window.level = .screenSaver
        window.acceptsMouseMovedEvents = true
        window.backgroundColor = .clear
        window.isOpaque = false
        window.makeKeyAndOrderFront(nil)

        let state = ScreenshotState(screen: screen)
        let contentView = ScreenshotOverlayView(state: state)
        window.contentView = ScreenshotOverlayHostingView(rootView: contentView)
        if let contentView = window.contentView {
            window.invalidateCursorRects(for: contentView)
        }

        overlayWindows[screen] = window
        overlayViewStates[screen] = state
    }

    private func hideAllOverlayWindows() {
        for (_, window) in overlayWindows {
            window.orderOut(nil)
        }
        overlayWindows.removeAll()
    }
}

// MARK: - ScreenshotOverlayWindow

/// A borderless overlay window that can become key and main for cursor updates.
final class ScreenshotOverlayWindow: NSWindow {
    override var canBecomeKey: Bool {
        true
    }

    override var canBecomeMain: Bool {
        true
    }
}
