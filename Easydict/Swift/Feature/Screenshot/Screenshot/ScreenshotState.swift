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
        self.isTipVisible = !MyConfiguration.shared.isScreenshotTipLayerHidden
            && !Screenshot.shared.lastScreenshotRect.isEmpty

        updateHideDarkOverlay()
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

    @Published var isKeyboardAvailable = true {
        didSet {
            if !isKeyboardAvailable { isTipVisible = true }
        }
    }

    /// Reset selection UI before reading display pixels.
    func reset() {
        hasFinishedSelection = true
        isMouseMoved = false
        isTipVisible = false
        selectedRect = .zero
        isShowingPreview = false
        shouldHideDarkOverlay = true
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

    /// Called by an always-active tracking area, independent of application focus.
    func handleMouseMoved() {
        guard !hasFinishedSelection else { return }
        isMouseMoved = true
        updateHideDarkOverlay()
        guard isKeyboardAvailable, !MyConfiguration.shared.isScreenshotTipLayerHidden else { return }
        let expandedValue = 20.0
        let expandedTipFrame = CGRect(
            origin: tipFrame.origin,
            size: .init(width: tipFrame.width + expandedValue, height: tipFrame.height + expandedValue)
        )
        isTipVisible = !expandedTipFrame.contains(NSEvent.mouseLocation)
    }

    // MARK: Private

    private var hasFinishedSelection = false
}
