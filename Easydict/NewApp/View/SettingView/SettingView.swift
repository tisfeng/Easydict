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
    case disabled
    case privacy
    case about
}

@available(macOS 13, *)
struct SettingView: View {
    @State private var selection = SettingTab.general
    @State private var window: NSWindow?

    var body: some View {
        TabView(selection: $selection) {
            GeneralTab()
                .tabItem { Label("setting_general", systemImage: "gear") }
                .tag(SettingTab.general)

            ServiceTab()
                .tabItem { Label("service", systemImage: "briefcase") }
                .tag(SettingTab.service)

            DisabledAppTab()
                .tabItem { Label("disabled_app_list", systemImage: "nosign") }
                .tag(SettingTab.disabled)

            PrivacyTab()
                .tabItem { Label("privacy", systemImage: "hand.raised.square") }
                .tag(SettingTab.privacy)

            AboutTab()
                .tabItem { Label("about", systemImage: "info.bubble") }
                .tag(SettingTab.about)
        }
        .background(
            WindowAccessor(window: $window.didSet(execute: { _ in
                // reset frame when first launch
                resizeWindowFrame()
            }))
        )
        .onChange(of: selection) { _ in
            resizeWindowFrame()
        }
    }

    func resizeWindowFrame() {
        guard let window else { return }

        let originalFrame = window.frame
        let newSize = switch selection {
        case .general, .privacy, .about, .disabled:
            CGSize(width: 500, height: 520)
        case .service:
            CGSize(width: 800, height: 520)
        }

        let newY = originalFrame.origin.y + originalFrame.size.height - newSize.height
        let newRect = NSRect(origin: CGPoint(x: originalFrame.origin.x, y: newY), size: newSize)

        window.setFrame(newRect, display: true, animate: true)
    }
}

@available(macOS 13, *)
#Preview {
    SettingView()
}
