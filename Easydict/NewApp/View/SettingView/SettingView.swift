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

@available(macOS 13, *)
struct SettingView: View {
    // MARK: Internal

    var body: some View {
        TabView(selection: $selection) {
            GeneralTab()
                .tabItem { Label("setting_general".localized, systemImage: "gear") }
                .tag(SettingTab.general)

            ServiceTab()
                .tabItem { Label("service".localized, systemImage: "briefcase") }
                .tag(SettingTab.service)

            DisabledAppTab()
                .tabItem { Label("disabled_app_list".localized, systemImage: "nosign") }
                .tag(SettingTab.disabled)

            ShortcutTab()
                .tabItem { Label("shortcut".localized, systemImage: "command.square") }
                .tag(SettingTab.shortcut)

            AdvancedTab()
                .tabItem { Label("advanced".localized, systemImage: "gearshape.2") }
                .tag(SettingTab.advanced)
            PrivacyTab()
                .tabItem { Label("privacy".localized, systemImage: "hand.raised.square") }
                .tag(SettingTab.privacy)

            AboutTab()
                .tabItem { Label("about".localized, systemImage: "info.bubble") }
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
            400
        case .privacy:
            320
        case .about:
            450
        default:
            maxWidth * 0.82
        }

        let newSize = CGSize(width: maxWidth, height: height)

        let originalFrame = window.frame
        let newY = originalFrame.origin.y + originalFrame.size.height - newSize.height
        let newRect = NSRect(origin: CGPoint(x: originalFrame.origin.x, y: newY), size: newSize)

        window.setFrame(newRect, display: true, animate: true)
    }

    // MARK: Private

    @State private var selection = SettingTab.general
    @State private var window: NSWindow?
    @EnvironmentObject private var languageState: LanguageState
}

@available(macOS 13, *)
#Preview {
    SettingView()
}
