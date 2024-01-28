//
//  AboutTab.swift
//  Easydict
//
//  Created by Kyle on 2023/10/29.
//  Copyright © 2023 izual. All rights reserved.
//

import Defaults
import SwiftUI

@available(macOS 13, *)
struct AboutTab: View {
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
                Toggle("auto_check_update", isOn: $checkUpdaterViewModel.autoChecksForUpdates)
                Text(verbatim: "(") + Text("lastest_version") + Text(verbatim: " \(lastestVersion ?? version))")

                HStack {
                    Text("author")
                    Link("Tisfeng", destination: URL(string: EZGithubRepoEasydictURL)!.deletingLastPathComponent())
                }
                HStack {
                    Text("GitHub:")
                    Link("Easydict", destination: URL(string: EZGithubRepoEasydictURL)!)
                }
            }
            .padding(.horizontal, 50)
            .padding(.vertical, 30)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .task {
            let version = await EZMenuItemManager.shared().fetchRepoLatestVersion(EZGithubRepoEasydict)
            await MainActor.run {
                lastestVersion = version
            }
        }
    }

    @StateObject private var checkUpdaterViewModel = CheckUpdaterViewModel()

    @State
    private var lastestVersion: String?
    private var appName: String {
        Bundle.main.infoDictionary?["CFBundleName"] as? String ?? ""
    }

    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }

    class CheckUpdaterViewModel: ObservableObject {
        private let updater = Configuration.shared.updater

        @Published var autoChecksForUpdates = true {
            didSet {
                updater.automaticallyChecksForUpdates = autoChecksForUpdates
            }
        }

        init() {
            updater
                .publisher(for: \.automaticallyChecksForUpdates)
                .assign(to: &$autoChecksForUpdates)
        }
    }
}

@available(macOS 13, *)
#Preview {
    AboutTab()
}
