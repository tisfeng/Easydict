//
//  Screenshot+EventMonitor.swift
//  Easydict
//
//  Created by tisfeng on 2025/3/20.
//  Copyright © 2025 izual. All rights reserved.
//

import Carbon
import Foundation

extension Screenshot {
    // MARK: - Event Monitor

    /// Setup key event monitors for ESC key and D key
    func setupEventMonitor() {
        // Monitor both key down and right mouse down events
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .rightMouseDown]) { [weak self] event in
            guard let self = self else { return event }

            switch event.type {
            case .keyDown:
                // Handle keyboard events
                if event.keyCode == kVK_Escape {
                    NSLog("ESC key detected locally, canceling screenshot")
                    finishCapture(nil)
                } else if event.keyCode == kVK_ANSI_D {
                    NSLog("D key detected locally, capturing last screenshot rect")
                    captureLastScreenshotRect()
                }

            case .rightMouseDown:
                // Handle right mouse click
                NSLog("Right mouse click detected, canceling screenshot")
                finishCapture(nil)

            default:
                break
            }

            return nil // Consume the event, avoid beep sound
        }
    }

    // MARK: Private

    func removeEventMonitor() {
        NSEvent.removeMonitor(eventMonitor as Any)
        eventMonitor = nil
    }

    // MARK: - Screenshot Rect Preview

    /// Capture the last screenshot rect
    func captureLastScreenshotRect() {
        var lastRect = lastScreenshotRect

        if lastRect.isEmpty {
            NSLog("No previous screenshot rect available")
            return
        }

        // Find appropriate screen for capturing
        guard let targetScreen = lastScreen ?? NSScreen.currentMouseScreen() ?? NSScreen.main else {
            NSLog("No valid screen found for capture")
            return
        }

        // Last screen may have gone offline, adjust rect to current screen
        if lastScreen == nil {
            lastRect = targetScreen.adjustedScreenshotRect(lastRect)
        }

        let state = overlayViewStates[targetScreen]
        state?.showPreview(rect: lastRect)
    }
}

extension Screenshot {
    /// Show an alert to guide the user to enable screen capture permission
    func showScreenCapturePermissionAlert() {
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
