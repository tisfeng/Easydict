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
                Picker("setting.general.advance.default_tts_service".localized, selection: $defaultTTSServiceType) {
                    ForEach(TTSServiceType.allCases, id: \.rawValue) { option in
                        Text(option.localizedString)
                            .tag(option)
                    }
                }
                Toggle("setting.general.advance.enable_beta_feature".localized, isOn: $enableBetaFeature)
                Toggle(isOn: $enableBetaNewApp) {
                    Text("enable_beta_new_app".localized)
                }
                Toggle(isOn: $disableTipsView) {
                    Text("disable_tips_view".localized)
                }
            } header: {
                Text("setting.general.advance.header".localized)
            }
        }
        .formStyle(.grouped)
    }

    // MARK: Private

    @Default(.defaultTTSServiceType) private var defaultTTSServiceType
    @Default(.enableBetaFeature) private var enableBetaFeature
    @Default(.enableBetaNewApp) private var enableBetaNewApp
    @Default(.disableTipsView) private var disableTipsView
}

@available(macOS 13, *)
#Preview {
    AdvancedTab()
}
