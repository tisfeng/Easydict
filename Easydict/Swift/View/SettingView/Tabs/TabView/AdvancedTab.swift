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

    var body: some View {
        Form {
            Section {
                Picker(
                    selection: $defaultTTSServiceType,
                    label: AdvancedTabItemView(
                        color: .orange,
                        systemImage: "ellipsis.bubble.fill",
                        labelText: "setting.general.advance.default_tts_service"
                    )
                ) {
                    ForEach(TTSServiceType.allCases, id: \.rawValue) { option in
                        Text(option.localizedStringResource)
                            .tag(option)
                    }
                }
            }
            Section {
                Toggle(isOn: $enableBetaFeature) {
                    AdvancedTabItemView(
                        color: .blue,
                        systemImage: "hammer.fill",
                        labelText: "setting.general.advance.enable_beta_feature"
                    )
                }
                Toggle(isOn: $enableBetaNewApp) {
                    AdvancedTabItemView(
                        color: swiftColor,
                        systemImage: "swift",
                        labelText: "enable_beta_new_app",
                        subtitleText: "enable_beta_new_app_info"
                    )
                }
                Toggle(isOn: $disableTipsView) {
                    Text("disable_tips_view")
                }
            }
        }
        .formStyle(.grouped)
    }

    // MARK: Private

    private let swiftColor = Color(red: 240 / 255, green: 81 / 255, blue: 56 / 255)

    @Default(.defaultTTSServiceType) private var defaultTTSServiceType
    @Default(.enableBetaFeature) private var enableBetaFeature
    @Default(.enableBetaNewApp) private var enableBetaNewApp
    @Default(.disableTipsView) private var disableTipsView
}

@available(macOS 13, *)
#Preview {
    AdvancedTab()
}
