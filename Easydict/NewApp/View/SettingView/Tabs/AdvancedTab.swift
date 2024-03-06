//
//  AdvancedTab.swift
//  Easydict
//
//  Created by tisfeng on 2024/1/23.
//  Copyright © 2024 izual. All rights reserved.
//

import Defaults
import SwiftUI

@available(macOS 13, *)
struct AdvancedTab: View {
    // MARK: Internal

    class CheckUpdaterViewModel: ObservableObject {
        // MARK: Lifecycle

        init() {
            updater
                .publisher(for: \.automaticallyChecksForUpdates)
                .assign(to: &$autoChecksForUpdates)
        }

        // MARK: Internal

        @Published var autoChecksForUpdates = true {
            didSet {
                updater.automaticallyChecksForUpdates = autoChecksForUpdates
            }
        }

        // MARK: Private

        private let updater = Configuration.shared.updater
    }

    var body: some View {
        Form {
            Section {
                Picker("setting.general.advance.default_tts_service", selection: $defaultTTSServiceType) {
                    ForEach(TTSServiceType.allCases, id: \.rawValue) { option in
                        Text(option.localizedStringResource)
                            .tag(option)
                    }
                }
                Toggle("setting.general.advance.enable_beta_feature", isOn: $enableBetaFeature)
                Toggle(isOn: $enableBetaNewApp) {
                    Text("enable_beta_new_app")
                }

                Toggle(isOn: $checkUpdaterViewModel.autoChecksForUpdates) {
                    Text("auto_check_update (lastest_version \(lastestVersion ?? version))")
                }

            } header: {
                Text("setting.general.advance.header")
            }
        }
        .formStyle(.grouped)
        .task {
            let version = await EZMenuItemManager.shared().fetchRepoLatestVersion(EZGithubRepoEasydict)
            await MainActor.run {
                lastestVersion = version
            }
        }
    }

    // MARK: Private

    @Default(.defaultTTSServiceType) private var defaultTTSServiceType
    @Default(.enableBetaFeature) private var enableBetaFeature
    @Default(.enableBetaNewApp) private var enableBetaNewApp

    @StateObject private var checkUpdaterViewModel = CheckUpdaterViewModel()

    @State private var lastestVersion: String?

    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }
}

@available(macOS 13, *)
#Preview {
    AdvancedTab()
}
