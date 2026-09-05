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
@MainActor
final class HostWindowManager {
    // MARK: Internal

    static let shared = HostWindowManager()

    func showWindow<Content: View>(
        windowId: String,
        title: String? = nil,
        width: CGFloat = 700,
        height: CGFloat = 600,
        resizable: Bool = true,
        reuseExisting: Bool = false,
        initialSizeIsMinimum: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        if reuseExisting, activateWindow(windowId: windowId, title: title) {
            return
        }
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
                minWidth: initialSizeIsMinimum ? width : nil,
                maxWidth: .infinity,
                minHeight: initialSizeIsMinimum ? height : nil,
                maxHeight: .infinity
            )
        window.contentView = NSHostingView(rootView: wrappedContent)

        let windowController = NSWindowController(window: window)
        if reuseExisting {
            window.isReleasedWhenClosed = false
        }
        windowControllers[windowId] = windowController
        windowController.showWindow(nil)
    }

    func closeWindow(windowId: String) {
        if let windowController = windowControllers[windowId] {
            windowController.close()
            windowControllers.removeValue(forKey: windowId)
        }
    }

    func updateWindowTitle(windowId: String, title: String) {
        windowControllers[windowId]?.window?.title = title
    }

    /// Refreshes the reusable Wordbook window title for an exact app language.
    func updateWordbookTitle(languageCode: String) {
        updateWindowTitle(
            windowId: .wordbookWindowId,
            title: wordbookTitle(languageCode: languageCode)
        )
    }

    // MARK: Private

    private var windowControllers: [String: NSWindowController] = [:]

    /// Uses the exact resource bundle because Locale does not select an lproj.
    private func wordbookTitle(languageCode: String) -> String {
        guard let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return NSLocalizedString("wordbook.window.title", comment: "")
        }
        return bundle.localizedString(
            forKey: "wordbook.window.title",
            value: nil,
            table: nil
        )
    }

    @discardableResult
    private func activateWindow(windowId: String, title: String?) -> Bool {
        guard let controller = windowControllers[windowId],
              let window = controller.window else {
            return false
        }
        window.title = title ?? NSLocalizedString(windowId, comment: "")
        NSApplication.shared.activateApp()
        controller.showWindow(nil)
        window.makeKeyAndOrderFront(nil)
        return true
    }
}

// MARK: - Window Creation Methods

extension HostWindowManager {
    /// Shows or reactivates the reusable Wordbook browsing window.
    func showWordbookWindow() {
        showWindow(
            windowId: .wordbookWindowId,
            title: wordbookTitle(languageCode: I18nHelper.shared.localizeCode),
            width: 900,
            height: 640,
            resizable: true,
            reuseExisting: true,
            initialSizeIsMinimum: false
        ) {
            WordbookView()
        }
    }

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
    /// Wordbook browsing window id.
    static let wordbookWindowId = "wordbook.window"

    // Acknowledgements window id.
    static let acknowledgementsWindowId = "setting.about.acknowledgements"

    // About window id.
    static let aboutWindowId = "setting.about"
}
