//
//  Screenshot.swift
//  Easydict
//
//  Created by tisfeng on 2025/3/12.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation
import SwiftUI

// MARK: - Screenshot

@objc
class Screenshot: NSObject {
    // MARK: Public

    @objc public static let shared = Screenshot()

    @objc public private(set) var isTakingScreenshot = false
    @objc public var shouldRestorePreviousApp = false

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
        setupEventMonitor()
        showOverlayWindow(completion: completion)
    }

    // MARK: Internal

    var overlayWindows: [NSScreen: NSWindow] = [:]
    var overlayViewStates: [NSScreen: ScreenshotState] = [:]

    var eventMonitor: Any?

    /// Work item for the delayed screenshot capture after pressing 'D' for preview.
    var previewScreenshotWorkItem: DispatchWorkItem?

    /// Finish screenshot capture and call the completion handler
    func finishCapture(_ image: NSImage?) {
        // Cancel any pending preview screenshot task first
        cancelPreviewScreenshotTimer()

        isTakingScreenshot = false

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

        hideAllOverlayWindows()
        removeEventMonitor()
        overlayViewStates.removeAll()
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
        NSLog("Performing screenshot, screen frame: \(screen.frame), rect: \(rect)")

        // Reset the state for the specific screen to hide selection UI etc.
        overlayViewStates[screen]?.reset()

        // Save last screenshot rect and screen
        lastScreenshotRect = rect
        lastScreen = screen

        // Async dispatch to allow UI updates (state reset) before capturing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let image = screen.takeScreenshot(rect: rect)
            // Finish the capture process with the result
            self.finishCapture(image)
        }
    }

    // MARK: Private

    /// The completion handler passed from startCapture.
    private var captureCompletionHandler: ((NSImage?) -> ())?

    private var previousActiveApp: NSRunningApplication?

    private func showOverlayWindow(completion: @escaping (NSImage?) -> ()) {
        // Store the completion handler
        captureCompletionHandler = completion

        // Save the currently active application
        previousActiveApp = NSWorkspace.shared.frontmostApplication

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

    private func createOverlayWindow(for screen: NSScreen) {
        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window.level = .screenSaver
        window.backgroundColor = .clear
        window.isOpaque = false
        window.orderFront(nil)

        let state = ScreenshotState(screen: screen)
        let contentView = ScreenshotOverlayView(state: state)
        window.contentView = NSHostingView(rootView: contentView)

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
