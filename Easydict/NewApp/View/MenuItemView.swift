//
//  MenuItemView.swift
//  Easydict
//
//  Created by Kyle on 2023/12/29.
//  Copyright © 2023 izual. All rights reserved.
//

import Sparkle
import SwiftUI

@available(macOS 13, *)
struct MenuItemView: View {
    var body: some View {
        Group {
            versionItem
            Divider()
            settingItem
                .keyboardShortcut(.init(","))
            checkUpdateItem
            Divider()
            quitItem
                .keyboardShortcut(.init("q"))
        }
        .task {
            let version = await EZMenuItemManager.shared().fetchRepoLatestVersion(EZGithubRepoEasydict)
            await MainActor.run {
                latestVersion = version
            }
        }
    }

    @State
    private var currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""

    @State
    private var latestVersion: String?

    @Environment(\.openURL)
    private var openURL

    @ViewBuilder
    private var versionItem: some View {
        Button(versionString) {
            guard let versionURL = URL(string: "\(EZGithubRepoEasydictURL)/releases") else {
                return
            }
            openURL(versionURL)
        }
    }

    private var versionString: String {
        let defaultLabel = "Easydict \(currentVersion)"
        if let latestVersion,
           currentVersion.compare(latestVersion, options: .numeric) == .orderedAscending
        {
            return defaultLabel + "  (✨ \(latestVersion)"
        } else {
            return defaultLabel
        }
    }

    @ViewBuilder
    private var settingItem: some View {
        if #available(macOS 14.0, *) {
            SettingsLink()
        } else {
            Button("Settings...") {
                NSLog("打开设置")
                NSApplication.shared.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            }
        }
    }

    @ViewBuilder
    private var checkUpdateItem: some View {
        Button("check_updates") {
            NSLog("检查更新")
            SPUStandardUpdaterController(updaterDelegate: nil, userDriverDelegate: nil).checkForUpdates(nil)
        }
    }

    @ViewBuilder
    private var quitItem: some View {
        Button("quit") {
            NSLog("退出应用")
            NSApplication.shared.terminate(nil)
        }
    }
}

@available(macOS 13, *)
#Preview {
    MenuItemView()
}
