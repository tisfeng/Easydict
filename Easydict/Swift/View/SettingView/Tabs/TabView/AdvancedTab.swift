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
                Toggle(isOn: $enableBetaFeature) {
                    AdvancedTabItemView(
                        color: .blue,
                        systemImage: "hammer.fill",
                        labelText: "setting.general.advance.enable_beta_feature"
                    )
                }
            }
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

                Toggle(isOn: $enableYoudaoOCR) {
                    AdvancedTabItemView(
                        color: .orange,
                        systemImage: "circle.rectangle.filled.pattern.diagonalline",
                        labelText: "enable_youdao_ocr",
                        subtitleText: "enable_youdao_ocr_desc"
                    )
                }
                Toggle(isOn: $replaceWithTranslationInCompatibilityMode) {
                    AdvancedTabItemView(
                        color: .teal,
                        systemImage: "arrow.forward.square",
                        labelText: "setting.general.advance.replace_with_translation",
                        subtitleText: "setting.general.advance.replace_with_translation_desc"
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
    @Default(.enableYoudaoOCR) private var enableYoudaoOCR
    @Default(.replaceWithTranslationInCompatibilityMode) private var replaceWithTranslationInCompatibilityMode
}

#Preview {
    AdvancedTab()
}
