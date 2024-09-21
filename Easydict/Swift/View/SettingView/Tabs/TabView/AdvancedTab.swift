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
                        color: .mint,
                        systemImage: "arrow.forward.square",
                        labelText: "setting.general.advance.replace_with_translation",
                        subtitleText: "setting.general.advance.replace_with_translation_desc"
                    )
                }
            }

            Section {
                Toggle(isOn: $replaceNewlineWithSpace) {
                    AdvancedTabItemView(
                        color: .mint,
                        systemImage: "arrow.forward.square",
                        labelText: "replace_newline_with_space"
                    )
                }
                Toggle(isOn: $automaticallyRemoveCodeCommentSymbols) {
                    AdvancedTabItemView(
                        color: .orange,
                        systemImage: "chevron.left.forwardslash.chevron.right",
                        labelText: "automatically_remove_code_comment_symbols"
                    )
                }
                Toggle(isOn: $automaticWordSegmentation) {
                    AdvancedTabItemView(
                        color: .indigo,
                        systemImage: "text.word.spacing",
                        labelText: "automatically_split_words"
                    )
                }
            } header: {
                Text("setting.general.advance.header.query_text_processing")
            } footer: {
                HStack {
                    Text("setting.general.advance.footer.query_text_processing_desc")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.leading, 10)

                    Spacer()
                }
            }

            Section {
                Toggle(isOn: $enableHTTPServer) {
                    AdvancedTabItemView(
                        color: .green,
                        systemImage: "network",
                        labelText: "setting.general.advance.enable_http_server"
                    )
                }
                TextField(text: $httpPort, prompt: Text(verbatim: "8080")) {
                    AdvancedTabItemView(
                        color: .red,
                        systemImage: "externaldrive.connected.to.line.below",
                        labelText: "setting.general.advance.http_port",
                        subtitleText: "setting.general.advance.http_port_desc"
                    )
                }

            } header: {
                Text("setting.general.advance.header.http_server")
            }
        }
        .formStyle(.grouped)
    }

    // MARK: Private

    @Default(.defaultTTSServiceType) private var defaultTTSServiceType
    @Default(.enableBetaFeature) private var enableBetaFeature
    @Default(.disableTipsView) private var disableTipsView
    @Default(.enableYoudaoOCR) private var enableYoudaoOCR
    @Default(.replaceWithTranslationInCompatibilityMode) private var replaceWithTranslationInCompatibilityMode

    @Default(.replaceNewlineWithSpace) var replaceNewlineWithSpace: Bool
    @Default(.automaticallyRemoveCodeCommentSymbols) var automaticallyRemoveCodeCommentSymbols: Bool
    @Default(.automaticWordSegmentation) var automaticWordSegmentation: Bool

    @Default(.enableHTTPServer) private var enableHTTPServer
    @Default(.httpPort) private var httpPort
}

#Preview {
    AdvancedTab()
}
