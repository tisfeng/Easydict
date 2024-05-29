//
//  AdvancedTab.swift
//  Easydict
//
//  Created by tisfeng on 2024/1/23.
//  Copyright © 2024 izual. All rights reserved.
//

import Defaults
import SwiftUI
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
                Toggle(isOn: $disableTipsView) {
                    AdvancedTabItemView(
                        color: .yellow,
                        systemImage: "lightbulb.fill",
                        labelText: "disable_tips_view"
                    )
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
            }
        }
        .formStyle(.grouped)
    }

    // MARK: Private

    private let swiftColor = Color(red: 240 / 255, green: 81 / 255, blue: 56 / 255)

    @Default(.defaultTTSServiceType) private var defaultTTSServiceType
    @Default(.enableBetaFeature) private var enableBetaFeature
    @Default(.disableTipsView) private var disableTipsView
}

#Preview {
    AdvancedTab()
}
