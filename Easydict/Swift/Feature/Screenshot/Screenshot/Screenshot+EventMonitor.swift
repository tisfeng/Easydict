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

    /// Filters keyboard input before it reaches the still-active foreground app.
    func setupEventMonitor() {
        isKeyboardAvailable = keyboardEventTap.start(onFailure: { [weak self] in
            self?.disableKeyboardShortcuts()
        }) { [weak self] event in
            let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            let key = Int(event.keyCode)
            let switchesApplication = modifiers.contains(.command)
                && [kVK_Tab, kVK_Space, kVK_ANSI_Grave].contains(key)
            let switchesSpace = modifiers.contains(.control)
                && [kVK_LeftArrow, kVK_RightArrow, kVK_UpArrow, kVK_DownArrow, kVK_Space].contains(key)
            let opensForceQuit = modifiers.contains([.command, .option]) && key == kVK_Escape
            if switchesApplication || switchesSpace || opensForceQuit {
                return .init(consumesEvent: false) { self?.finishCapture(nil) }
            }
            // Ordinary input is consumed as well, preserving the previous modal behavior.
            return .init {
                if key == kVK_Escape {
                    self?.finishCapture(nil)
                } else if key == kVK_ANSI_D {
                    self?.captureLastScreenshotRect()
                }
            }
        }
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .rightMouseDown) { [weak self] event in
            guard let self, isTakingScreenshot else { return event }
            finishCapture(nil)
            return nil
        }
    }

    func removeEventMonitor() {
        keyboardEventTap.finish()
        if let eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
            self.eventMonitor = nil
        }
    }

    /// Keeps mouse capture available if the system cannot authorize keyboard filtering.
    private func disableKeyboardShortcuts() {
        guard isTakingScreenshot else { return }
        isKeyboardAvailable = false
        for state in overlayViewStates.values {
            state.isKeyboardAvailable = false
        }
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

        guard let state = overlayViewStates[targetScreen] else {
            NSLog("No state found for target screen")
            return
        }

        // Cancel any previously scheduled preview screenshot task
        cancelPreviewScreenshotTimer()

        // Show the preview rectangle visually
        state.showPreview(rect: lastRect)

        // Create a work item to perform the actual screenshot after a delay
        let sessionID = captureSessionID
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }

            // Ensure we are still in screenshot mode
            guard isTakingScreenshot, captureSessionID == sessionID else {
                NSLog("Preview screenshot cancelled because capture finished.")
                return
            }

            NSLog("Executing delayed screenshot for preview rect: \(lastRect)")

            performScreenshot(screen: targetScreen, rect: lastRect)
        }

        // Store the work item so it can be cancelled
        previewScreenshotWorkItem = workItem

        // Schedule the work item to run after 1 second
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: workItem)
        NSLog("Scheduled screenshot capture in 1s for preview.")
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
