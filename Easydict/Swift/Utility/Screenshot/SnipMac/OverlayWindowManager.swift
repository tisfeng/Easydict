//
//  OverlayWindowManager.swift
//  SnipMac
//
//  Created by Sai Sandeep Vaddi on 11/18/23.
//
import AppKit
import SwiftUI

@objc
class OverlayWindowManager: NSObject {
    // MARK: Internal

    @objc static let shared = OverlayWindowManager()

    var overlayWindow: NSWindow?
    var capturedImage: NSImage?
    var onImageCaptured: ((NSImage) -> ())?

    @objc
    func showOverlayWindow(completion: ((NSImage?) -> ())? = nil) {
        // 先获取截图
        capturedImage = ScreenCaptureManager.takeScreenshot(of: nil)

        if overlayWindow == nil {
            createOverlayWindow(captureType: .screenshot)
        }
        overlayWindow?.makeKeyAndOrderFront(nil)

        // 设置回调，当用户完成选择后调用
        onImageCaptured = { image in
            completion?(image)
        }
    }

    func finishCapture(with selectedImage: NSImage) {
        capturedImage = selectedImage
        onImageCaptured?(selectedImage)
        hideOverlayWindow()
    }

    func hideOverlayWindow() {
        overlayWindow?.orderOut(nil)
        overlayWindow = nil
    }

    // MARK: Private

    private func observeAppStateChanges() {}

    private func createOverlayWindow(captureType: CaptureType) {
        let screenRect = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 0, height: 0)
        overlayWindow = NSWindow(
            contentRect: screenRect,
            styleMask: [.borderless],
            backing: .buffered, defer: false
        )
        overlayWindow?.isOpaque = false
        overlayWindow?.backgroundColor = NSColor(white: 1, alpha: 0.3)
        overlayWindow?.level = .screenSaver
        overlayWindow?.ignoresMouseEvents = false
        print("Creating new overlay")
        let contentView = ScreenshotOverlayView(captureType: captureType)
        overlayWindow?.contentView = NSHostingView(rootView: contentView)
    }
}
