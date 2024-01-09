//
//  SettingView.swift
//  Easydict
//
//  Created by Kyle on 2023/12/29.
//  Copyright © 2023 izual. All rights reserved.
//

import SwiftUI

enum SettingTab: Int {
    case general
    case service
    case privacy
    case about
}

@available(macOS 13, *)
struct SettingView: View {
    @State private var selection = SettingTab.general.rawValue
    @State private var window: NSWindow?

    var body: some View {
        TabView(selection: $selection.didSet(execute: { _ in
            resizeWindowFrame()
        })) {
            GeneralTab()
                .tabItem { Label("setting_general", systemImage: "gear") }
                .tag(SettingTab.general.rawValue)

            ServiceTab()
                .tabItem { Label("service", systemImage: "briefcase") }
                .tag(SettingTab.service.rawValue)

            PrivacyTab()
                .tabItem { Label("privacy", systemImage: "hand.raised.square") }
                .tag(SettingTab.privacy.rawValue)

            AboutTab()
                .tabItem { Label("about", systemImage: "info.bubble") }
                .tag(SettingTab.about.rawValue)
        }
        .background(WindowAccessor(window: $window.didSet(execute: { _ in
            resizeWindowFrame()
        })))
    }

    func resizeWindowFrame() {
        guard let window else { return }

        let originalFrame = window.frame
        let newSize = selection == SettingTab.service.rawValue
            ? CGSize(width: 360, height: 520) : CGSize(width: 500, height: 400)

        let newY = originalFrame.origin.y + originalFrame.size.height - newSize.height
        let newRect = NSRect(origin: CGPoint(x: originalFrame.origin.x, y: newY), size: newSize)

        window.setFrame(newRect, display: true, animate: true)
    }
}

@available(macOS 13, *)
#Preview {
    SettingView()
}
