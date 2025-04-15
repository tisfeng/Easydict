//
//  ScreenshotState.swift
//  Easydict
//
//  Created by tisfeng on 2025/3/18.
//  Copyright © 2025 izual. All rights reserved.
//

import Carbon
import SwiftUI

/// Manages the state for screenshot capture UI
class ScreenshotState: ObservableObject {
    // MARK: Lifecycle

    init(screen: NSScreen) {
        self.screen = screen
        self.isTipVisible = !Screenshot.shared.lastScreenshotRect.isEmpty

        updateHideDarkOverlay()
        setupMouseMovedMonitor()
    }

    // MARK: Internal

    /// The screen where the screenshot state is attached.
    /// Screen frame is `bottom-left` origin.
    var screen: NSScreen

    /// Controls whether the dark overlay is shown during screenshot selection for this specific screen state. Defaults to false.
    var enableDarkOverlay = false

    // MARK: - Published Properties

    /// Whether the mouse has moved since capture started
    @Published var isMouseMoved = false

    /// The currently selected rectangle for screenshot
    @Published var selectedRect = CGRect.zero

    /// Whether the preview is being shown
    @Published var isShowingPreview = false

    /// Whether the dark overlay should be hidden
    @Published private(set) var shouldHideDarkOverlay = true

    @Published var isTipVisible = false

    var tipFrame: CGRect = .zero

    /// Reset all state variables
    func reset() {
        isMouseMoved = false
        selectedRect = .zero
        isShowingPreview = false
        shouldHideDarkOverlay = true

        removeMonitor()
    }

    // MARK: - State Management

    /// Update the state to hide the dark overlay, based on the local setting and current interaction state.
    func updateHideDarkOverlay() {
        // If dark overlay is disabled for this state, always hide it.
        guard enableDarkOverlay else {
            shouldHideDarkOverlay = true
            return
        }

        // Otherwise, hide based on interaction state (previewing or mouse moved onto the screen).
        shouldHideDarkOverlay =
            isShowingPreview || isMouseMoved && screen.isSameScreen(NSScreen.currentMouseScreen())
    }

    /// Show preview rect, update state
    func showPreview(rect: CGRect) {
        isShowingPreview = true
        selectedRect = rect
        isTipVisible = false
        updateHideDarkOverlay()
    }

    // MARK: Private

    private var mouseMovedMonitor: Any?

    // MARK: - Mouse moved event monitoring

    /// Setup local mouse monitor to track mouse movement
    /// Since SwiftUI `onHover` is not reliable, we need to track mouse movement manually
    private func setupMouseMovedMonitor() {
        /*
         Unlike keyDown events which are typically sent only to the active application,
         mouseMoved events can be captured by a local monitor even if the application
         isn't active, especially when an overlay window is present under the cursor.
         Therefore, explicit NSApplication.shared.activate() is not strictly required
         for this specific monitor to function, unlike the keyDown monitor for ESC.
         */
        mouseMovedMonitor = NSEvent.addLocalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            guard let self else { return event }

            isMouseMoved = true
            updateHideDarkOverlay()

            let expandedValue = 20.0
            let tipLayerExpandedFrame = CGRect(
                origin: tipFrame.origin,
                size: .init(
                    width: tipFrame.width + expandedValue,
                    height: tipFrame.height + expandedValue
                )
            )
            // Check if mouse is outside the expanded tip frame
            isTipVisible = !tipLayerExpandedFrame.contains(NSEvent.mouseLocation)

            // Pass the event to the next screen monitor
            return event
        }
    }

    private func removeMonitor() {
        NSEvent.removeMonitor(mouseMovedMonitor as Any)
        mouseMovedMonitor = nil
    }
}
