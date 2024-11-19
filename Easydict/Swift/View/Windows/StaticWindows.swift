//
//  StaticWindows.swift
//  Easydict
//
//  Created by tisfeng on 2024/11/5.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation
import SwiftUI

private var windows: [String: NSWindow] = [:]

private func showWindow<Content: View>(
    title: String,
    width: CGFloat = 700,
    height: CGFloat = 600,
    resizable: Bool = true,
    @ViewBuilder content: () -> Content
) {
    if let window = windows[title] {
        window.makeKeyAndOrderFront(nil)
    } else {
        var styleMask: NSWindow.StyleMask = [.titled, .closable]
        if resizable {
            styleMask.insert(.resizable)
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: width, height: height),
            styleMask: styleMask,
            backing: .buffered,
            defer: false
        )

        window.title = NSLocalizedString(title, comment: "")
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        window.center()

        let wrappedContent = content()
            .frame(
                minWidth: width, maxWidth: .infinity,
                minHeight: height, maxHeight: .infinity
            )

        window.contentView = NSHostingView(rootView: wrappedContent)
        window.makeKeyAndOrderFront(nil)
        windows[title] = window
    }
}

func showAboutWindow() {
    showWindow(title: "about", width: 500, height: 220, resizable: false) {
        SettingsAboutTab()
    }
}

func showAcknowWindow() {
    showWindow(title: "setting.about.acknowledgements") {
        AcknowListView()
    }
}
