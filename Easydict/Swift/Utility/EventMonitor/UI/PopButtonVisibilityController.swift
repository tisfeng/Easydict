//
//  PopButtonVisibilityController.swift
//  Easydict
//
//  Created by tisfeng on 2025/xx/xx.
//  Copyright © 2025 izual. All rights reserved.
//

import AppKit
import Carbon
import Foundation

// MARK: - PopButtonVisibilityController

/// Controls the visibility lifecycle for the pop button.
final class PopButtonVisibilityController {
    // MARK: Internal

    var dismissHandler: (() -> ())?

    var isPopButtonVisible: Bool = false
    var lastEvent: NSEvent?

    func resetScrollState() {
        movedY = 0
    }

    func handleScrollWheel(_ event: NSEvent) {
        guard isPopButtonVisible else { return }
        movedY += event.scrollingDeltaY
        if abs(movedY) > Constants.maxScrollDelta {
            dismissHandler?()
        }
    }

    func handleMouseMoved(isMouseInExpandedFrame: Bool) {
        guard isPopButtonVisible else { return }
        if !isMouseInExpandedFrame {
            dismissHandler?()
        }
    }

    func shouldIgnoreDismiss() -> Bool {
        guard let event = lastEvent else { return false }
        return isCmdCEvent(event)
    }

    // MARK: Private

    private enum Constants {
        static let maxScrollDelta: CGFloat = 80
    }

    private var movedY: CGFloat = 0

    private func isCmdCEvent(_ event: NSEvent) -> Bool {
        guard event.type == .keyDown || event.type == .keyUp else {
            return false
        }
        let isCmdPressed = event.modifierFlags.contains(.command)
        let isCPressed = event.keyCode == kVK_ANSI_C
        return isCmdPressed && isCPressed
    }
}
