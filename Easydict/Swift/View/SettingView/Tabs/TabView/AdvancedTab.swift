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
                        icon: .hammerFill,
                        labelText: "setting.advance.enable_beta_feature"
                    )
                }
            }

            // Items image color order: blue, green, orange, purple, red, mint, yellow, cyan
            Section {
                Picker(
                    selection: $defaultTTSServiceType,
                    label: AdvancedTabItemView(
                        color: .blue,
                        icon: .ellipsisBubbleFill,
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
                        icon: .lightbulbFill,
                        labelText: "setting.advance.disable_tips_view"
                    )
                }

                Toggle(isOn: $enableYoudaoOCR) {
                    AdvancedTabItemView(
                        color: .orange,
                        icon: .circleRectangleFilledPatternDiagonalline,
                        labelText: "setting.advance.youdao_ocr",
                        subtitleText: "setting.advance.youdao_ocr_desc"
                    )
                }
                Toggle(isOn: $replaceWithTranslationInCompatibilityMode) {
                    AdvancedTabItemView(
                        color: .purple,
                        icon: .arrowForwardSquare,
                        labelText: "setting.advance.replace_with_translation",
                        subtitleText: "setting.advance.replace_with_translation_desc"
                    )
                }

                // Require macOS 15+
                if #available(macOS 15.0, *) {
                    Toggle(isOn: $enableLocalAppleTranslation) {
                        AdvancedTabItemView(
                            color: .red,
                            icon: .appleLogo,
                            labelText: "setting.advance.apple_offline_translation",
                            subtitleText: "setting.advance.apple_offline_translation_desc"
                        )
                    }
                }

                LabeledContent {
                    TextField(
                        "",
                        text: $minClassicalChineseTextDetectLength,
                        prompt: Text(verbatim: "\(SharedConstants.minClassicalChineseLength)")
                    )
                    .frame(width: 100)
                    .fixedSize(horizontal: true, vertical: false)
                    .onChange(of: minClassicalChineseTextDetectLength) { newValue in
                        minClassicalChineseTextDetectLength = newValue.filter { $0.isNumber }
                        logInfo(
                            "Min classical Chinese text detect length: \(minClassicalChineseTextDetectLength)"
                        )
                    }
                } label: {
                    AdvancedTabItemView(
                        color: .mint,
                        icon: .book,
                        labelText: "setting.advance.min_classical_chinese_text_detect_length"
                    )
                }

                Toggle(isOn: $enableOCRTextNormalization) {
                    AdvancedTabItemView(
                        color: .yellow,
                        icon: .docViewfinder,
                        labelText: "setting.advance.enable_ocr_text_normalization",
                        subtitleText: "setting.advance.enable_ocr_text_normalization_desc"
                    )
                }

                Toggle(isOn: $showOCRMenuItems) {
                    AdvancedTabItemView(
                        color: .cyan,
                        icon: .textAndCommandMacwindow,
                        labelText: "setting.advance.show_ocr_menu_items",
                        subtitleText: "setting.advance.show_ocr_menu_items_desc"
                    )
                }

                Toggle(isOn: $autoSelectAllTextFieldText) {
                    AdvancedTabItemView(
                        color: .indigo,
                        icon: .checkmarkSquare,
                        labelText: "setting.advance.auto_select_all_text_field_text",
                        subtitleText: "setting.advance.auto_select_all_text_field_text_desc"
                    )
                }
            }

            // Force get selected text
            Section {
                Toggle(isOn: $enableForceGetSelectedText) {
                    AdvancedTabItemView(
                        color: .blue,
                        icon: .characterCursorIbeam,
                        labelText: "setting.advance.enable_force_get_selected_text",
                        subtitleText: "setting.advance.enable_force_get_selected_text_desc"
                    )
                }

                Picker(
                    selection: $forceGetSelectedTextType,
                    label: AdvancedTabItemView(
                        color: .green,
                        icon: .highlighter,
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
                        icon: .cursorarrowRays,
                        labelText: "setting.advance.auto_show_query_icon"
                    )
                }

                Toggle(isOn: $clickQuery) {
                    AdvancedTabItemView(
                        color: .green,
                        icon: .cursorarrowClick,
                        labelText: "setting.advance.click_icon_query_info"
                    )
                }

                Toggle(isOn: $adjustPopButtonOrigin) {
                    AdvancedTabItemView(
                        color: .orange,
                        icon: .arrowUpAndDownAndArrowLeftAndRight,
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
                        icon: .arrowForwardSquare,
                        labelText: "setting.advance.automatically_replace_newline_with_space"
                    )
                }
                Toggle(isOn: $automaticallyRemoveCodeCommentSymbols) {
                    AdvancedTabItemView(
                        color: .green,
                        icon: .chevronLeftForwardslashChevronRight,
                        labelText: "setting.advance.automatically_remove_code_comment_symbols"
                    )
                }
                Toggle(isOn: $automaticWordSegmentation) {
                    AdvancedTabItemView(
                        color: .purple,
                        icon: .textWordSpacing,
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
                        icon: .cursorarrowRays,
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
                        icon: .keyboardFill,
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
                        icon: .textAndCommandMacwindow,
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
                        icon: .macwindow,
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
                        icon: .pinFill,
                        labelText: "setting.advance.pin_window_when_showing"
                    )
                }

                Toggle(isOn: $hideMainWindow) {
                    AdvancedTabItemView(
                        color: .mint,
                        icon: .eyeSlashFill,
                        labelText: "setting.advance.hide_main_window"
                    )
                }

                Picker(
                    selection: $maxWindowHeightPercentageValue,
                    label: AdvancedTabItemView(
                        color: .yellow,
                        icon: .arrowUpAndDown,
                        labelText: "setting.advance.window.max_height_percentage"
                    )
                ) {
                    ForEach(MaxWindowHeightPercentageOption.allCases) { option in
                        Text(option.title)
                            .tag(option)
                    }
                    .onChange(of: maxWindowHeightPercentageValue) { _ in
                        // Post notification when max window height percentage changes
                        NotificationCenter.default.post(
                            name: .maxWindowHeightSettingsChanged, object: nil
                        )
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
                        icon: .network,
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
                        icon: .externaldriveConnectedToLineBelow,
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
    @Default(.enableOCRTextNormalization) private var enableOCRTextNormalization
    @Default(.showOCRMenuItems) private var showOCRMenuItems
    @Default(.autoSelectAllTextFieldText) private var autoSelectAllTextFieldText

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
