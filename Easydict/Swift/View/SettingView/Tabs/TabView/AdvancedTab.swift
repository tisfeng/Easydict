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

            // Items image color order: blue, green, orange, purple, red, mint
            Section {
                Picker(
                    selection: $defaultTTSServiceType,
                    label: AdvancedTabItemView(
                        color: .blue,
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
                        color: .green,
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
                        color: .purple,
                        systemImage: SFSymbol.arrowForwardSquare.rawValue,
                        labelText: "setting.advance.replace_with_translation",
                        subtitleText: "setting.advance.replace_with_translation_desc"
                    )
                }

                // Require macOS 15+
                if #available(macOS 15.0, *) {
                    Toggle(isOn: $enableLocalAppleTranslation) {
                        AdvancedTabItemView(
                            color: .red,
                            systemImage: SFSymbol.appleLogo.rawValue,
                            labelText: "setting.advance.apple_offline_translation",
                            subtitleText: "setting.advance.apple_offline_translation_desc"
                        )
                    }
                }

                LabeledContent {
                    TextField("", text: $minClassicalChineseTextDetectLength, prompt: Text(verbatim: "10"))
                        .frame(width: 100)
                        .fixedSize(horizontal: true, vertical: false)
                        .onChange(of: minClassicalChineseTextDetectLength) { newValue in
                            minClassicalChineseTextDetectLength = newValue.filter { $0.isNumber }
                            logInfo("Min classical Chinese text detect length: \(minClassicalChineseTextDetectLength)")
                        }
                } label: {
                    AdvancedTabItemView(
                        color: .mint,
                        systemImage: SFSymbol.book.rawValue,
                        labelText: "setting.advance.min_classical_chinese_text_detect_length"
                    )
                }
            }

            // Force get selected text
            Section {
                Toggle(isOn: $enableForceGetSelectedText) {
                    AdvancedTabItemView(
                        color: .blue,
                        systemImage: SFSymbol.characterCursorIbeam.rawValue,
                        labelText: "setting.advance.enable_force_get_selected_text",
                        subtitleText: "setting.advance.enable_force_get_selected_text_desc"
                    )
                }

                Picker(
                    selection: $forceGetSelectedTextType,
                    label: AdvancedTabItemView(
                        color: .green,
                        systemImage: SFSymbol.highlighter.rawValue,
                        labelText: "setting.advance.force_get_selected_text_type"
                    )
                ) {
                    ForEach(ForceGetSelectedTextType.allCases, id: \.rawValue) { option in
                        Text(option.localizedStringResource)
                            .tag(option)
                    }
                }
            } header: {
                Text("setting.advance.header.force_get_selected_text")
            }

            // Mouse query icon
            Section {
                Toggle(isOn: $autoSelectText) {
                    AdvancedTabItemView(
                        color: .blue,
                        systemImage: SFSymbol.cursorarrowRays.rawValue,
                        labelText: "setting.advance.auto_show_query_icon"
                    )
                }

                Toggle(isOn: $clickQuery) {
                    AdvancedTabItemView(
                        color: .green,
                        systemImage: SFSymbol.cursorarrowClick.rawValue,
                        labelText: "setting.advance.click_icon_query_info"
                    )
                }

                Toggle(isOn: $adjustPopButtonOrigin) {
                    AdvancedTabItemView(
                        color: .orange,
                        systemImage: SFSymbol.arrowUpAndDownAndArrowLeftAndRight.rawValue,
                        labelText: "setting.advance.mouse_query.adjust_pop_button_origin"
                    )
                }
            } header: {
                Text("setting.advance.mouse_select_query.header")
            }

            // Query text processing
            Section {
                Toggle(isOn: $replaceNewlineWithSpace) {
                    AdvancedTabItemView(
                        color: .blue,
                        systemImage: SFSymbol.arrowForwardSquare.rawValue,
                        labelText: "setting.advance.automatically_replace_newline_with_space"
                    )
                }
                Toggle(isOn: $automaticallyRemoveCodeCommentSymbols) {
                    AdvancedTabItemView(
                        color: .green,
                        systemImage: SFSymbol.chevronLeftForwardslashChevronRight.rawValue,
                        labelText: "setting.advance.automatically_remove_code_comment_symbols"
                    )
                }
                Toggle(isOn: $automaticWordSegmentation) {
                    AdvancedTabItemView(
                        color: .purple,
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

            // Windows management
            Section {
                Picker(
                    selection: $mouseSelectTranslateWindowType,
                    label: AdvancedTabItemView(
                        color: .blue,
                        systemImage: SFSymbol.cursorarrowRays.rawValue,
                        labelText: "setting.advance.window.mouse_select_translate_window_type"
                    )
                ) {
                    ForEach(EZWindowType.availableOptions, id: \.rawValue) { option in
                        Text(option.localizedStringResource)
                            .tag(option)
                    }
                }

                Picker(
                    selection: $shortcutSelectTranslateWindowType,
                    label: AdvancedTabItemView(
                        color: .green,
                        systemImage: SFSymbol.keyboardFill.rawValue,
                        labelText: "setting.advance.window.shortcut_select_translate_window_type"
                    )
                ) {
                    ForEach(EZWindowType.availableOptions, id: \.rawValue) { option in
                        Text(option.localizedStringResource)
                            .tag(option)
                    }
                }

                Picker(
                    selection: $fixedWindowPosition,
                    label: AdvancedTabItemView(
                        color: .orange,
                        systemImage: SFSymbol.textAndCommandMacwindow.rawValue,
                        labelText: "setting.advance.window.fixed_window_position"
                    )
                ) {
                    ForEach(EZShowWindowPosition.allCases, id: \.rawValue) { option in
                        Text(option.localizedStringResource)
                            .tag(option)
                    }
                }

                Picker(
                    selection: $miniWindowPosition,
                    label: AdvancedTabItemView(
                        color: .purple,
                        systemImage: SFSymbol.macwindow.rawValue,
                        labelText: "setting.advance.window.mini_window_position"
                    )
                ) {
                    ForEach(EZShowWindowPosition.allCases, id: \.rawValue) { option in
                        Text(option.localizedStringResource)
                            .tag(option)
                    }
                }

                Toggle(isOn: $pinWindowWhenDisplayed) {
                    AdvancedTabItemView(
                        color: .red,
                        systemImage: SFSymbol.pinFill.rawValue,
                        labelText: "setting.advance.pin_window_when_showing"
                    )
                }

                Toggle(isOn: $hideMainWindow) {
                    AdvancedTabItemView(
                        color: .mint,
                        systemImage: SFSymbol.eyeSlashFill.rawValue,
                        labelText: "setting.advance.hide_main_window"
                    )
                }

                Picker(
                    selection: $maxWindowHeightPercentageValue,
                    label: AdvancedTabItemView(
                        color: .yellow,
                        systemImage: SFSymbol.arrowUpAndDown.rawValue,
                        labelText: "setting.advance.window.max_height_percentage"
                    )
                ) {
                    ForEach(MaxWindowHeightPercentageOption.allCases) { option in
                        Text(option.title)
                            .tag(option)
                    }
                    .onChange(of: maxWindowHeightPercentageValue) { _ in
                        // Post notification when max window height percentage changes
                        NotificationCenter.default.post(name: .maxWindowHeightSettingsChanged, object: nil)
                    }
                }

            } header: {
                Text("setting.advance.window_management.header")
            }

            // HTTP server
            Section {
                Toggle(isOn: $enableHTTPServer) {
                    AdvancedTabItemView(
                        color: getHttpIconColor(),
                        systemImage: SFSymbol.network.rawValue,
                        labelText: "setting.advance.enable_http_server"
                    )
                }

                LabeledContent {
                    TextField("", text: $httpPort, prompt: Text(verbatim: "8080"))
                        .frame(width: 100)
                        .fixedSize(horizontal: true, vertical: false)
                        // Add onChange modifier to filter input
                        .onChange(of: httpPort) { newValue in
                            httpPort = newValue.filter { $0.isNumber }
                        }
                } label: {
                    AdvancedTabItemView(
                        color: getHttpIconColor(),
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

    @Default(.enableBetaFeature) private var enableBetaFeature

    @Default(.defaultTTSServiceType) private var defaultTTSServiceType
    @Default(.disableTipsView) private var disableTipsView
    @Default(.enableYoudaoOCR) private var enableYoudaoOCR
    @Default(.replaceWithTranslationInCompatibilityMode) private
    var replaceWithTranslationInCompatibilityMode
    @Default(.enableAppleOfflineTranslation) private var enableLocalAppleTranslation

    @Default(.minClassicalChineseTextDetectLength) private var minClassicalChineseTextDetectLength

    // Force get selected text
    @Default(.enableForceGetSelectedText) private var enableForceGetSelectedText
    @Default(.forceGetSelectedTextType) private var forceGetSelectedTextType

    // Mouse select query
    @Default(.autoSelectText) private var autoSelectText
    @Default(.clickQuery) private var clickQuery
    @Default(.adjustPopButtonOrigin) private var adjustPopButtonOrigin

    // Query text processing
    @Default(.replaceNewlineWithSpace) var replaceNewlineWithSpace: Bool
    @Default(.automaticallyRemoveCodeCommentSymbols) var automaticallyRemoveCodeCommentSymbols: Bool
    @Default(.automaticWordSegmentation) var automaticWordSegmentation: Bool

    // Windows management
    @Default(.fixedWindowPosition) private var fixedWindowPosition
    @Default(.miniWindowPosition) private var miniWindowPosition
    @Default(.mouseSelectTranslateWindowType) private var mouseSelectTranslateWindowType
    @Default(.shortcutSelectTranslateWindowType) private var shortcutSelectTranslateWindowType
    @Default(.pinWindowWhenDisplayed) private var pinWindowWhenDisplayed
    @Default(.hideMainWindow) private var hideMainWindow

    @Default(.enableHTTPServer) private var enableHTTPServer
    @Default(.httpPort) private var httpPort

    /// Returns Color.green if `enableHTTPServer` is true, returns Color.red otherwise.
    private func getHttpIconColor() -> Color {
        enableHTTPServer ? .green : .red
    }

    @Default(.maxWindowHeightPercentage) private var maxWindowHeightPercentageValue
}

#Preview {
    AdvancedTab()
}
