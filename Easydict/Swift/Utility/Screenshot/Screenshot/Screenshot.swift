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

    @objc public private(set) var isTakingScreenshot = false

    @objc public var shouldRestorePreviousApp = false

    // MARK: Internal

    @objc static let shared = Screenshot()

    @objc
    func startCapture(completion: @escaping (NSImage?) -> ()) {
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

    private var overlayWindow: NSWindow?
    private var onImageCaptured: ((NSImage?) -> ())?
    private var previousActiveApp: NSRunningApplication?

    private func showOverlayWindow(completion: @escaping (NSImage?) -> ()) {
        onImageCaptured = completion

        if overlayWindow == nil {
            createOverlayWindow()
        }

        // Save the currently active application
        previousActiveApp = NSWorkspace.shared.frontmostApplication

        NSApp.activate(ignoringOtherApps: true)

        overlayWindow?.makeKeyAndOrderFront(nil)
    }

    private func createOverlayWindow() {
        let screenFrame = getActiveScreenFrame()

        overlayWindow = NSWindow(
            contentRect: screenFrame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        overlayWindow?.level = .screenSaver
        overlayWindow?.backgroundColor = .clear
        overlayWindow?.isOpaque = false
        overlayWindow?.becomeFirstResponder()

        let contentView = ScreenshotOverlayView(screenFrame: screenFrame, onImageCaptured: { [weak self] image in
            self?.finishCapture(image)
        })
        overlayWindow?.contentView = NSHostingView(rootView: contentView)
    }

    private func hideOverlayWindow() {
        overlayWindow?.orderOut(nil)
        overlayWindow = nil
    }

    /// Finish screenshot capture
    private func finishCapture(_ image: NSImage?) {
        isTakingScreenshot = false

        onImageCaptured?(image)
        hideOverlayWindow()

        // Restore focus to previous application only if shouldRestorePreviousApp is true
        if shouldRestorePreviousApp, let previousApp = previousActiveApp {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                previousApp.activate()
            }
        }

        // Clear the previous app reference
        previousActiveApp = nil
    }
}

// MARK: - Permission Handling

extension Screenshot {
    // Key for storing permission request status
    private var hasRequestedPermissionKey: String {
        "easydict.screenshot.hasRequestedPermission"
    }

    // Track whether we've already requested screen capture permission
    fileprivate var hasRequestedPermission: Bool {
        get {
            UserDefaults.standard.bool(forKey: hasRequestedPermissionKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: hasRequestedPermissionKey)
        }
    }

    fileprivate func showScreenCapturePermissionAlert() {
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
