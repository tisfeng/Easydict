//
//  GeneralTab.swift
//  Easydict
//
//  Created by Kyle on 2023/12/29.
//  Copyright © 2023 izual. All rights reserved.
//

import Defaults
import SwiftUI

@available(macOS 13, *)
struct GeneralTab: View {
    var body: some View {
        Form {
            Section {
                Text("first_language")
                Text("second_language")
                Text("language_detect_optimize")
            } header: {
                Text("setting.general.language.header")
            }

            Section {
                Toggle("auto_show_query_icon", isOn: $autoSelectText)
                Toggle("force_auto_get_selected_text", isOn: $forceAutoGetSelectedText)
                Toggle("click_icon_query_info", isOn: $clickQuery)
                Toggle("setting.general.mouse_query.adjust_pop_button_origin", isOn: $adjustPopButtonOrigin) // 调整查询图标位置:
            } header: {
                Text("setting.general.mouse_query.header")
            }

            Section {
                Toggle("setting.general.voice.disable_empty_copy_beep_msg", isOn: $disableEmptyCopyBeep) // 禁用提示音：划词内容为空时生效
                Toggle("setting.general.voice.auto_play_word_audio", isOn: $autoPlayAudio) // 查询英语单词后自动播放发音
            } header: {
                Text("setting.general.voice.header")
            }

            Section {
                Toggle(isOn: $hideMainWindow) {
                    Text("hide_main_window")
                }
                Text("mouse_select_translate_window_type")
                Text("shortcut_select_translate_window_type")
                Text("fixed_window_position")
            } header: {
                Text("setting.general.windows.header")
            }

            Section {
                Toggle("clear_input_when_translating", isOn: $clearInput)
            } header: {
                Text("setting.general.input.header")
            }

            Section {
                Toggle("auto_query_ocr_text", isOn: $autoQueryOCRText)
                Toggle("auto_query_selected_text", isOn: $autoQuerySelectedText)
                Toggle("auto_query_pasted_text", isOn: $autoQueryPastedText)
            } header: {
                Text("setting.general.auto_query.header")
            }

            Section {
                Toggle("auto_copy_ocr_text", isOn: $autoCopyOCRText)
                Toggle("auto_copy_selected_text", isOn: $autoCopySelectedText)
                Toggle("auto_copy_first_translated_text", isOn: $autoCopyFirstTranslatedText)
            } header: {
                Text("setting.general.auto_copy.header")
            }

            Section {
                Toggle("show_google_quick_link", isOn: $showGoogleQuickLink)
                Toggle("show_eudic_quick_link", isOn: $showEudicQuickLink)
                Toggle("show_apple_dictionary_quick_link", isOn: $showAppleDictionaryQuickLink)
            } header: {
                Text("setting.general.quick_link.header")
            }

            Section {
                Toggle(isOn: $launchAtStartup) {
                    Text("launch_at_startup")
                }
                Toggle(isOn: $hideMenuBarIcon) {
                    Text("hide_menu_bar_icon")
                }
            } header: {
                Text("other")
            }

            Section {
                Text("default_tts_service")
                Toggle(isOn: $enableBetaNewApp) {
                    Text("enable_beta_new_app")
                }
            } header: {
                Text("setting.general.advance.header")
            }
        }
        .formStyle(.grouped)
    }

    @Default(.autoSelectText) private var autoSelectText
    @Default(.forceAutoGetSelectedText) private var forceAutoGetSelectedText
    @Default(.clickQuery) private var clickQuery
    @Default(.adjustPopButtonOrigin) private var adjustPopButtonOrigin

    @Default(.clearInput) private var clearInput

    @Default(.disableEmptyCopyBeep) private var disableEmptyCopyBeep
    @Default(.autoPlayAudio) private var autoPlayAudio

    @Default(.autoQueryOCRText) private var autoQueryOCRText
    @Default(.autoQuerySelectedText) private var autoQuerySelectedText
    @Default(.autoQueryPastedText) private var autoQueryPastedText

    @Default(.autoCopyOCRText) private var autoCopyOCRText
    @Default(.autoCopySelectedText) private var autoCopySelectedText
    @Default(.autoCopyFirstTranslatedText) private var autoCopyFirstTranslatedText

    @Default(.showGoogleQuickLink) private var showGoogleQuickLink
    @Default(.showEudicQuickLink) private var showEudicQuickLink
    @Default(.showAppleDictionaryQuickLink) private var showAppleDictionaryQuickLink

    @Default(.hideMainWindow) private var hideMainWindow
    @Default(.launchAtStartup) private var launchAtStartup
    @Default(.hideMenuBarIcon) private var hideMenuBarIcon
    @Default(.enableBetaNewApp) private var enableBetaNewApp
}

@available(macOS 13, *)
#Preview {
    GeneralTab()
}
