//
//  AboutViewController.swift
//  Easydict
//
//  Created by Kyle on 2023/10/29.
//  Copyright © 2023 izual. All rights reserved.
//

import Foundation
import Settings
import SwiftUI

let AboutViewController: () -> SettingsPane = {
    let panelView = Settings.Pane(
        identifier: .init("About"),
        title: NSLocalizedString("about", comment: "about"),
        toolbarIcon: .toolbarAbout
    ) {
        AboutPanelView()
    }
    return Settings.PaneHostingController(pane: panelView)
}

struct AboutPanelView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                Image(.logo)
                    .resizable()
                    .frame(width: 110, height: 110)
                Text(appName)
                    .font(.system(size: 26, weight: .semibold))
                Text("current_version") + Text(verbatim: " \(version)")
                    .font(.system(size: 14))
                Toggle("auto_check_update", isOn: $autoChecksForUpdates)
                Text(verbatim: "(") + Text("lastest_version") + Text(verbatim: " \(lastestVersion ?? version))")

                HStack {
                    Text("author")
                    Link("Tisfeng", destination: URL(string: EZGithubRepoEasydictURL)!.deletingLastPathComponent())
                }
                HStack {
                    Text("Github:")
                    Link("Easydict", destination: URL(string: EZGithubRepoEasydictURL)!)
                }
            }
            .padding(.horizontal, 50)
            .padding(.vertical, 30)
        }
        .frame(idealWidth: 500, idealHeight: 400)
        .onAppear { // FIXME: Use task when update to macOS 12
            Task.detached {
                let version = await EZMenuItemManager.shared().fetchRepoLatestVersion(EZGithubRepoEasydict)
                await MainActor.run {
                    lastestVersion = version
                }
            }
        }
    }

    @AppStorage("EZConfiguration_kAutomaticallyChecksForUpdatesKey")
    private var autoChecksForUpdates = false
    @State
    private var lastestVersion: String?
    private var appName: String {
        Bundle.main.infoDictionary?["CFBundleName"] as? String ?? ""
    }

    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }
}

#Preview {
    AboutPanelView()
}
