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
    @Published private(set) var shouldHideDarkOverlay = false

    /// Reset all state variables
    func reset() {
        isMouseMoved = false
        selectedRect = .zero
        isShowingPreview = false
        shouldHideDarkOverlay = false

        removeMonitor()
    }

    // MARK: - State Management

    /// Update the state to hide the dark overlay, based on the current screen mouse is moved or is showing preview.
    func updateHideDarkOverlay() {
        shouldHideDarkOverlay =
            isShowingPreview ||
            isMouseMoved && screen.isSameScreen(getCurrentMouseScreen())
    }

    /// Show preview rect, update state
    func showPreview(rect: CGRect) {
        isShowingPreview = true
        selectedRect = rect
        updateHideDarkOverlay()
    }

    // MARK: Private

    private var mouseMovedMonitor: Any?

    // MARK: - Mouse moved event monitoring

    /// Setup local mouse monitor to track mouse movement
    private func setupMouseMovedMonitor() {
        mouseMovedMonitor = NSEvent.addLocalMonitorForEvents(
            matching: .mouseMoved,
            handler: { [self] event in
                isMouseMoved = true
                updateHideDarkOverlay()
                return event // Pass the event to the next screen monitor
            }
        )
    }

    private func removeMonitor() {
        NSEvent.removeMonitor(mouseMovedMonitor as Any)
        mouseMovedMonitor = nil
    }
}
