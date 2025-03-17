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

        showOverlayWindow(completion: completion)
    }

    // MARK: Private

    private var overlayWindows: [NSScreen: NSWindow] = [:]
    private var onImageCaptured: ((NSImage?) -> ())?
    private var previousActiveApp: NSRunningApplication?

    private func showOverlayWindow(completion: @escaping (NSImage?) -> ()) {
        onImageCaptured = completion

        // Save the currently active application
        previousActiveApp = NSWorkspace.shared.frontmostApplication

        // Remove any existing overlay windows
        hideAllOverlayWindows()

        // Create and show overlay window on each screen
        for screen in NSScreen.screens {
            createOverlayWindow(for: screen)
        }

        NSApp.activate(ignoringOtherApps: true)
    }

    private func createOverlayWindow(for screen: NSScreen) {
        let screenFrame = screen.frame

        let window = NSWindow(
            contentRect: screenFrame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window.level = .screenSaver
        window.backgroundColor = .clear
        window.isOpaque = false
        window.orderFront(nil)

        // Pass the screen object instead of just screenFrame
        let contentView = ScreenshotOverlayView(screen: screen, onImageCaptured: { [weak self] image in
            self?.finishCapture(image)
        })
        NSLog("init ScreenshotOverlayView, screen: \(screen.frame)")

        window.contentView = NSHostingView(rootView: contentView)

        // Store the window in our dictionary
        overlayWindows[screen] = window
    }

    private func hideAllOverlayWindows() {
        for (_, window) in overlayWindows {
            window.orderOut(nil)
        }
        overlayWindows.removeAll()
    }

    /// Finish screenshot capture
    private func finishCapture(_ image: NSImage?) {
        isTakingScreenshot = false

        onImageCaptured?(image)
        hideAllOverlayWindows()

        // Restore focus to previous application only if shouldRestorePreviousApp is true
        if shouldRestorePreviousApp, let previousApp = previousActiveApp {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                previousApp.activate()
            }
        }

        // Clear the previous app reference
        previousActiveApp = nil
    }

    /// Show an alert to guide the user to enable screen capture permission
    private func showScreenCapturePermissionAlert() {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("need_screen_capture_permission", comment: "")
        alert.informativeText = NSLocalizedString(
            "request_screen_capture_access_description", comment: ""
        )
        alert.alertStyle = .warning

        alert.addButton(withTitle: NSLocalizedString("open_system_settings", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("cancel", comment: ""))

        if alert.runModal() == .alertFirstButtonReturn {
            if let url = URL(
                string:
                "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
            ) {
                NSWorkspace.shared.open(url)
            }
        }
    }
}
