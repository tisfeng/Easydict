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

    /// Finish screenshot capture and call the completion handler
    func finishCapture(_ image: NSImage?) {
        isTakingScreenshot = false

        // Restore focus to previous application only if shouldRestorePreviousApp is true
        if shouldRestorePreviousApp, let previousApp = previousActiveApp {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                previousApp.activate()
            }
        }

        previousActiveApp = nil

        onImageCaptured?(image)
        hideAllOverlayWindows()
        removeEventMonitor()
        overlayViewStates.removeAll()
    }

    // MARK: Private

    private var onImageCaptured: ((NSImage?) -> ())?
    private var previousActiveApp: NSRunningApplication?

    private func showOverlayWindow(completion: @escaping (NSImage?) -> ()) {
        onImageCaptured = completion

        // Save the currently active application
        previousActiveApp = NSWorkspace.shared.frontmostApplication

        hideAllOverlayWindows()

        if #available(macOS 14.0, *) {
            NSApplication.shared.activate()
        } else {
            NSApplication.shared.activate(ignoringOtherApps: true)
        }

        // Show overlay window on each screen
        for screen in NSScreen.screens {
            createOverlayWindow(for: screen)
        }
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

        // Pass the screen to the overlay view
        let contentView = ScreenshotOverlayView(
            state: state,
            onImageCaptured: { [weak self] image in
                self?.finishCapture(image)
            }
        )
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
