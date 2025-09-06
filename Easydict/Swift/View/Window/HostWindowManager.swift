//
//  HostWindowManager.swift
//  Easydict
//
//  Created by tisfeng on 2025/1/26.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation
import SwiftUI

// MARK: - HostWindowManager

/// Bridge host window manager for managing SwiftUI windows.
/// Since SwiftUI windows may cause some strange behaviors, such as showing the window automatically when the app launches, we need to use AppKit to manage the windows.
/// FIX: https://github.com/tisfeng/Easydict/issues/767
final class HostWindowManager {
    // MARK: Internal

    static let shared = HostWindowManager()

    func showWindow<Content: View>(
        windowId: String,
        title: String? = nil,
        width: CGFloat = 700,
        height: CGFloat = 600,
        resizable: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        closeWindow(windowId: windowId)

        var styleMask: NSWindow.StyleMask = [.titled, .closable, .miniaturizable]
        if resizable {
            styleMask.insert(.resizable)
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: width, height: height),
            styleMask: styleMask,
            backing: .buffered,
            defer: false
        )

        window.title = title ?? NSLocalizedString(windowId, comment: "")
        window.titlebarAppearsTransparent = true
        window.center()

        let wrappedContent = content()
            .frame(
                minWidth: width, maxWidth: .infinity,
                minHeight: height, maxHeight: .infinity
            )

        window.contentView = NSHostingView(rootView: wrappedContent)

        let windowController = NSWindowController(window: window)
        windowControllers[windowId] = windowController
        windowController.showWindow(nil)
    }

    func closeWindow(windowId: String) {
        if let windowController = windowControllers[windowId] {
            windowController.close()
            windowControllers.removeValue(forKey: windowId)
        }
    }

    // MARK: Private

    private var windowControllers: [String: NSWindowController] = [:]
}

// MARK: - Window Creation Methods

extension HostWindowManager {
    /// Show the acknowledgements window.
    func showAcknowWindow() {
        showWindow(windowId: .acknowledgementsWindowId) {
            AcknowListView()
        }
    }

    /// Show the About window.
    func showAboutWindow() {
        showWindow(windowId: .aboutWindowId, width: 600, height: 220, resizable: false) {
            AboutTab()
        }
    }
}

extension String {
    // Acknowledgements window id.
    static let acknowledgementsWindowId = "setting.about.acknowledgements"

    // About window id.
    static let aboutWindowId = "setting.about"
}
