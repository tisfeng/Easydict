//
//  OverlayWindowManager.swift
//  Easydict
//
//  Created by tisfeng on 2025/3/11.
//  Copyright © 2025 izual. All rights reserved.
//

import AppKit
import SwiftUI

@objc
class OverlayWindowManager: NSObject {
    // MARK: Internal

    @objc static let shared = OverlayWindowManager()

    var overlayWindow: NSWindow?
    var onImageCaptured: ((NSImage) -> ())?

    @objc
    func showOverlayWindow(completion: ((NSImage?) -> ())? = nil) {
        NSCursor.arrow.set()

        if overlayWindow == nil {
            createOverlayWindow()
        }
        overlayWindow?.makeKeyAndOrderFront(nil)

        // Set callback to be called when user completes selection
        onImageCaptured = { image in
            completion?(image)
        }
    }

    func finishCapture(with selectedImage: NSImage) {
        onImageCaptured?(selectedImage)
        hideOverlayWindow()
    }

    func hideOverlayWindow() {
        overlayWindow?.orderOut(nil)
        overlayWindow = nil
    }

    // MARK: Private

    private func createOverlayWindow() {
        let screenRect = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 0, height: 0)
        overlayWindow = NSWindow(
            contentRect: screenRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        overlayWindow?.level = .screenSaver
        overlayWindow?.backgroundColor = .clear
        overlayWindow?.isOpaque = false

        let contentView = ScreenshotOverlayView()
        overlayWindow?.contentView = NSHostingView(rootView: contentView)
    }
}
