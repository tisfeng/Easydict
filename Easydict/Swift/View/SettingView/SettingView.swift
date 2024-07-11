//
//  SettingView.swift
//  Easydict
//
//  Created by Kyle on 2023/12/29.
//  Copyright © 2023 izual. All rights reserved.
//

import SwiftUI

// MARK: - SettingTab

enum SettingTab: Int {
    case general
    case service
    case disabled
    case advanced
    case shortcut
    case privacy
    case about
}

// MARK: - SettingView

struct SettingView: View {
    // MARK: Internal

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

            ShortcutTab()
                .tabItem { Label("shortcut", systemImage: "command.square") }
                .tag(SettingTab.shortcut)

            AdvancedTab()
                .tabItem { Label("advanced", systemImage: "gearshape.2") }
                .tag(SettingTab.advanced)
            PrivacyTab()
                .tabItem { Label("privacy", systemImage: "hand.raised.square") }
                .tag(SettingTab.privacy)

            SettingsAboutTab()
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

        // Disable zoom button, refer: https://stackoverflow.com/a/66039864/8378840
        window.standardWindowButton(.zoomButton)?.isEnabled = false

        // Keep the settings page windows all the same width to avoid strange animations.
        let maxWidth = 820.0
        let height: Double = switch selection {
        case .disabled:
            500
        case .advanced:
            350
        case .privacy:
            320
        case .about:
            300
        default:
            maxWidth * 0.82
        }

        let newSize = CGSize(width: maxWidth, height: height)

        let originalFrame = window.frame
        let newY = originalFrame.origin.y + originalFrame.size.height - newSize.height
        let newRect = NSRect(origin: CGPoint(x: originalFrame.origin.x, y: newY), size: newSize)

        window.setFrame(newRect, display: true, animate: true)

        // Disable user to resize window, wait for the animation to finish.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            window.styleMask.remove(.resizable)
        }
    }

    // MARK: Private

    @State private var selection = SettingTab.general
    @State private var window: NSWindow?
}

#Preview {
    SettingView()
}
