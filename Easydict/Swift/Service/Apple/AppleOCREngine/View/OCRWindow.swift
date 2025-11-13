//
//  OCRWindow.swift
//  Easydict
//
//  Created by tisfeng on 2025/8/19.
//  Copyright © 2025 izual. All rights reserved.
//

import AppKit

// MARK: - OCRWindow

/// Custom NSWindow for OCR debug functionality with proper focus handling
class OCRWindow: NSWindow {
    // MARK: Lifecycle

    override init(
        contentRect: NSRect,
        styleMask style: NSWindow.StyleMask,
        backing backingStoreType: NSWindow.BackingStoreType,
        defer flag: Bool
    ) {
        super.init(
            contentRect: contentRect,
            styleMask: style,
            backing: backingStoreType,
            defer: flag
        )

        // Set up window properties
        backgroundColor = .clear
        hasShadow = true
        level = .normal
        isOpaque = false
        titlebarAppearsTransparent = true
        isMovableByWindowBackground = true
        isReleasedWhenClosed = false

        // Ensure the window can accept focus and input
        acceptsMouseMovedEvents = true
        ignoresMouseEvents = false

        // Set delegate to self for handling window events
        delegate = self
    }

    // MARK: Internal

    // MARK: - NSWindow overrides

    override var canBecomeKey: Bool {
        // For borderless windows, we need to explicitly return true
        true
    }

    override var canBecomeMain: Bool {
        true
    }

    override var acceptsFirstResponder: Bool {
        true
    }

    /// Indicates whether the window is pinned (should stay visible when losing focus)
    var isPinned: Bool = false {
        didSet {
            level = isPinned ? .floating : .normal
        }
    }
}

// MARK: NSWindowDelegate

extension OCRWindow: NSWindowDelegate {
    func windowDidResignKey(_ notification: Notification) {
        logInfo("OCRWindow: windowDidResignKey called, isPinned: \(isPinned)")
        // Window lost focus - hide if not pinned
        if !isPinned {
            logInfo("OCRWindow: Hiding window because it's not pinned")
            orderOut(nil)
        } else {
            logInfo("OCRWindow: Keeping window visible because it's pinned")
        }
    }

    func windowDidBecomeKey(_ notification: Notification) {
        logInfo("OCRWindow: windowDidBecomeKey called")
        // Window gained focus
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        logInfo("OCRWindow: windowShouldClose called")
        // Allow window to close
        return true
    }
}
