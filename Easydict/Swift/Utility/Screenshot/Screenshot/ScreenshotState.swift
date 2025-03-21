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

    /// Update the state to hide the dark overlay, based on the current screen mouse is moved or is showing preview.
    func updateHideDarkOverlay() {
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
        mouseMovedMonitor = NSEvent.addLocalMonitorForEvents(
            matching: .mouseMoved,
            handler: { [self] event in
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
                isTipVisible = !tipLayerExpandedFrame.contains(NSEvent.mouseLocation)

                // Pass the event to the next screen monitor
                return event
            }
        )
    }

    private func removeMonitor() {
        NSEvent.removeMonitor(mouseMovedMonitor as Any)
        mouseMovedMonitor = nil
    }
}
