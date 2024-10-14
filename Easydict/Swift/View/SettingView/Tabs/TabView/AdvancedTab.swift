//
//  AdvancedTab.swift
//  Easydict
//
//  Created by tisfeng on 2024/1/23.
//  Copyright © 2024 izual. All rights reserved.
//

import Defaults
import SFSafeSymbols
import SwiftUI

struct AdvancedTab: View {
    // MARK: Internal

    var body: some View {
        Form {
            Section {
                Toggle(isOn: $enableBetaFeature) {
                    AdvancedTabItemView(
                        color: .blue,
                        systemImage: SFSymbol.hammerFill.rawValue,
                        labelText: "setting.advance.enable_beta_feature"
                    )
                }
            }
            Section {
                Picker(
                    selection: $defaultTTSServiceType,
                    label: AdvancedTabItemView(
                        color: .orange,
                        systemImage: SFSymbol.ellipsisBubbleFill.rawValue,
                        labelText: "setting.advance.default_tts_service"
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
                        systemImage: SFSymbol.lightbulbFill.rawValue,
                        labelText: "setting.advance.disable_tips_view"
                    )
                }

                Toggle(isOn: $enableYoudaoOCR) {
                    AdvancedTabItemView(
                        color: .orange,
                        systemImage: SFSymbol.circleRectangleFilledPatternDiagonalline.rawValue,
                        labelText: "setting.advance.youdao_ocr",
                        subtitleText: "setting.advance.youdao_ocr_desc"
                    )
                }
                Toggle(isOn: $replaceWithTranslationInCompatibilityMode) {
                    AdvancedTabItemView(
                        color: .mint,
                        systemImage: SFSymbol.arrowForwardSquare.rawValue,
                        labelText: "setting.advance.replace_with_translation",
                        subtitleText: "setting.advance.replace_with_translation_desc"
                    )
                }

                // Require macOS 15+
                if #available(macOS 15.0, *) {
                    Toggle(isOn: $enableLocalAppleTranslation) {
                        AdvancedTabItemView(
                            color: .green,
                            systemImage: SFSymbol.appleLogo.rawValue,
                            labelText: "setting.advance.apple_offline_translation",
                            subtitleText: "setting.advance.apple_offline_translation_desc"
                        )
                    }
                }

                Picker(
                    selection: $forceGetSelectedTextType,
                    label: AdvancedTabItemView(
                        color: .blue,
                        systemImage: SFSymbol.highlighter.rawValue,
                        labelText: "setting.advance.force_get_selected_text_type"
                    )
                ) {
                    ForEach(ForceGetSelectedTextType.allCases, id: \.rawValue) { option in
                        Text(option.localizedStringResource)
                            .tag(option)
                    }
                }
            }

            Section {
                Toggle(isOn: $replaceNewlineWithSpace) {
                    AdvancedTabItemView(
                        color: .mint,
                        systemImage: SFSymbol.arrowForwardSquare.rawValue,
                        labelText: "setting.advance.automatically_replace_newline_with_space"
                    )
                }
                Toggle(isOn: $automaticallyRemoveCodeCommentSymbols) {
                    AdvancedTabItemView(
                        color: .orange,
                        systemImage: SFSymbol.chevronLeftForwardslashChevronRight.rawValue,
                        labelText: "setting.advance.automatically_remove_code_comment_symbols"
                    )
                }
                Toggle(isOn: $automaticWordSegmentation) {
                    AdvancedTabItemView(
                        color: .indigo,
                        systemImage: SFSymbol.textWordSpacing.rawValue,
                        labelText: "setting.advance.automatically_split_words"
                    )
                }
            } header: {
                Text("setting.advance.header.query_text_processing")
            } footer: {
                HStack {
                    Text("setting.advance.footer.query_text_processing_desc")
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
                        systemImage: SFSymbol.network.rawValue,
                        labelText: "setting.advance.enable_http_server"
                    )
                }

                LabeledContent {
                    TextField("", text: $httpPort, prompt: Text(verbatim: "8080"))
                        .frame(width: 100)
                        .fixedSize(horizontal: true, vertical: false)
                } label: {
                    AdvancedTabItemView(
                        color: .red,
                        systemImage: SFSymbol.externaldriveConnectedToLineBelow.rawValue,
                        labelText: "setting.advance.http_port",
                        subtitleText: "setting.advance.http_port_desc"
                    )
                }
            } header: {
                Text("setting.advance.header.http_server")
            }
        }
        .formStyle(.grouped)
    }

    // MARK: Private

    @Default(.defaultTTSServiceType) private var defaultTTSServiceType
    @Default(.enableBetaFeature) private var enableBetaFeature
    @Default(.disableTipsView) private var disableTipsView
    @Default(.enableYoudaoOCR) private var enableYoudaoOCR
    @Default(.replaceWithTranslationInCompatibilityMode) private
    var replaceWithTranslationInCompatibilityMode

    @Default(.forceGetSelectedTextType) private var forceGetSelectedTextType

    @Default(.replaceNewlineWithSpace) var replaceNewlineWithSpace: Bool
    @Default(.automaticallyRemoveCodeCommentSymbols) var automaticallyRemoveCodeCommentSymbols: Bool
    @Default(.automaticWordSegmentation) var automaticWordSegmentation: Bool

    @Default(.enableHTTPServer) private var enableHTTPServer
    @Default(.httpPort) private var httpPort

    @Default(.enableAppleOfflineTranslation) private var enableLocalAppleTranslation
}

#Preview {
    AdvancedTab()
}
