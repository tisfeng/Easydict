//
//  Screenshot.swift
//  Easydict
//
//  Created by tisfeng on 2025/3/12.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation
import SwiftUI

@objc
class Screenshot: NSObject {
    // MARK: Internal

    @objc static let shared = Screenshot()

    @objc
    func startCapture(completion: @escaping (NSImage?) -> ()) {
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

        showOverlayWindow(completion: completion)
    }

    // MARK: Private

    private var overlayWindow: NSWindow?
    private var onImageCaptured: ((NSImage?) -> ())?

    private let hasRequestedPermissionKey = "ScreenCaptureHasRequestedPermission"

    private var hasRequestedPermission: Bool {
        get {
            UserDefaults.standard.bool(forKey: hasRequestedPermissionKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: hasRequestedPermissionKey)
        }
    }

    private func showOverlayWindow(completion: @escaping (NSImage?) -> ()) {
        onImageCaptured = completion

        if overlayWindow == nil {
            createOverlayWindow()
        }
        overlayWindow?.makeKeyAndOrderFront(nil)
    }

    private func createOverlayWindow() {
        let screenRect = NSScreen.main?.frame ?? .zero
        overlayWindow = NSWindow(
            contentRect: screenRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        overlayWindow?.level = .screenSaver
        overlayWindow?.backgroundColor = .clear
        overlayWindow?.isOpaque = false

        let contentView = ScreenshotOverlayView { [weak self] image in
            self?.onImageCaptured?(image)
            self?.hideOverlayWindow()
        }
        overlayWindow?.contentView = NSHostingView(rootView: contentView)
    }

    private func hideOverlayWindow() {
        overlayWindow?.orderOut(nil)
        overlayWindow = nil
    }

    private func showScreenCapturePermissionAlert() {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("need_screen_capture_permission", comment: "")
        alert.informativeText = NSLocalizedString("request_screen_capture_access_description", comment: "")
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
