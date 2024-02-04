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
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Form {
            Section {
                Picker("setting.general.appearance.light_dark_appearance", selection: $appearanceType) {
                    ForEach(AppearenceType.allCases, id: \.rawValue) { option in
                        Text(option.title)
                            .tag(option)
                    }
                }
            } header: {
                Text("setting.general.appearance.header")
            }
            Section {
                FirstAndSecondLanguageSettingView()
                Picker("setting.general.language.language_detect_optimize", selection: $languageDetectOptimize) {
                    ForEach(LanguageDetectOptimize.allCases, id: \.rawValue) { option in
                        Text(option.localizedStringResource)
                            .tag(option)
                    }
                }
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
                Picker("setting.general.window.mouse_select_translate_window_type", selection: $mouseSelectTranslateWindowType) {
                    ForEach(EZWindowType.availableOptions, id: \.rawValue) { option in
                        Text(option.localizedStringResource)
                            .tag(option)
                    }
                }
                Picker("setting.general.window.shortcut_select_translate_window_type", selection: $shortcutSelectTranslateWindowType) {
                    ForEach(EZWindowType.availableOptions, id: \.rawValue) { option in
                        Text(option.localizedStringResource)
                            .tag(option)
                    }
                }
                Picker("setting.general.window.fixed_window_position", selection: $fixedWindowPosition) {
                    ForEach(EZShowWindowPosition.allCases, id: \.rawValue) { option in
                        Text(option.localizedStringResource)
                            .tag(option)
                    }
                }
            } header: {
                Text("setting.general.windows.header")
            }

            Section {
                Toggle("clear_input_when_translating", isOn: $clearInput)
                Toggle("keep_prev_result_when_selected_text_is_empty", isOn: $keepPrevResultWhenEmpty)
                Toggle("select_query_text_when_window_activate", isOn: $selectQueryTextWhenWindowActivate)
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
                let bindingFontSize = Binding<Double>(get: {
                    Double(fontSizeOptionIndex)
                }, set: { newValue in
                    fontSizeOptionIndex = UInt(newValue)
                })
                Slider(value: bindingFontSize, in: 0.0 ... 4.0, step: 1) {
                    Text("setting.general.font.font_size.label")
                } minimumValueLabel: {
                    Text("small")
                        .font(.system(size: 10))
                } maximumValueLabel: {
                    Text("large")
                        .font(.system(size: 14))
                }
            } header: {
                Text("setting.general.font.header")
            } footer: {
                Text("hints_keyboard_shortcuts_font_size")
                    .font(.footnote)
            }

            Section {
                Toggle(isOn: $launchAtStartup) {
                    Text("launch_at_startup")
                }
                Toggle(isOn: $hideMainWindow) {
                    Text("hide_main_window")
                }
                Toggle(isOn: $hideMenuBarIcon) {
                    Text("hide_menu_bar_icon")
                }
                Picker(
                    "modify_menubar_icon",
                    selection: $selectedMenuBarIcon
                ) {
                    ForEach(MenuBarIconType.allCases) { option in
                        Image(option.rawValue)
                            .renderingMode(.template)
                            .foregroundStyle(.primary)
                    }
                }
            } header: {
                Text("setting.general.other.header")
            }
        }
        .formStyle(.grouped)
    }

    @Default(.autoSelectText) private var autoSelectText
    @Default(.forceAutoGetSelectedText) private var forceAutoGetSelectedText
    @Default(.clickQuery) private var clickQuery
    @Default(.adjustPopButtonOrigin) private var adjustPopButtonOrigin

    @Default(.clearInput) private var clearInput
    @Default(.keepPrevResultWhenEmpty) private var keepPrevResultWhenEmpty
    @Default(.selectQueryTextWhenWindowActivate) private var selectQueryTextWhenWindowActivate

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

    @Default(.languageDetectOptimize) private var languageDetectOptimize
    @Default(.defaultTTSServiceType) private var defaultTTSServiceType

    @Default(.fixedWindowPosition) private var fixedWindowPosition
    @Default(.mouseSelectTranslateWindowType) private var mouseSelectTranslateWindowType
    @Default(.shortcutSelectTranslateWindowType) private var shortcutSelectTranslateWindowType
    @Default(.enableBetaFeature) private var enableBetaFeature
    @Default(.appearanceType) private var appearanceType

    @Default(.fontSizeOptionIndex) private var fontSizeOptionIndex
    @Default(.selectedMenuBarIcon) private var selectedMenuBarIcon
}

@available(macOS 13, *)
#Preview {
    GeneralTab()
}

@available(macOS 13, *)
private struct FirstAndSecondLanguageSettingView: View {
    var body: some View {
        Group {
            Picker("setting.general.language.first_language", selection: $firstLanguage) {
                ForEach(Language.allAvailableOptions, id: \.rawValue) { option in
                    Text(verbatim: "\(option.flagEmoji) \(option.localizedName)")
                        .tag(option)
                }
            }
            Picker("setting.general.language.second_language", selection: $secondLanguage) {
                ForEach(Language.allAvailableOptions, id: \.rawValue) { option in
                    Text(verbatim: "\(option.flagEmoji) \(option.localizedName)")
                        .tag(option)
                }
            }
        }
        .onChange(of: firstLanguage) { [firstLanguage] newValue in
            let oldValue = firstLanguage
            if newValue == secondLanguage {
                secondLanguage = oldValue
                languageDuplicatedAlert = .init(duplicatedLanguage: newValue, setField: .second, setLanguage: oldValue)
            }
        }
        .onChange(of: secondLanguage) { [secondLanguage] newValue in
            let oldValue = secondLanguage
            if newValue == firstLanguage {
                firstLanguage = oldValue
                languageDuplicatedAlert = .init(duplicatedLanguage: newValue, setField: .first, setLanguage: oldValue)
            }
        }
        .alert("setting.general.language.duplicated_alert.title", isPresented: showLanguageDuplicatedAlert, presenting: languageDuplicatedAlert) { _ in

        } message: { alert in
            Text(alert.description)
        }
    }

    @Default(.firstLanguage) private var firstLanguage
    @Default(.secondLanguage) private var secondLanguage

    private struct LanguageDuplicateAlert: CustomStringConvertible {
        var description: String {
            // First language should not be same as second language. (\(duplicatedLanguage))
            // \(setField) is replaced with \(setLanguage).
            String(localized: "setting.general.language.duplicated_alert \(duplicatedLanguage.localizedName)\(String(localized: setField.localizedStringResource))\(setLanguage.localizedName)")
        }

        let duplicatedLanguage: Language

        let setField: Field

        let setLanguage: Language

        enum Field: CustomLocalizedStringResourceConvertible {
            var localizedStringResource: LocalizedStringResource {
                switch self {
                case .first:
                    "setting.general.language.duplicated_alert.field.first"
                case .second:
                    "setting.general.language.duplicated_alert.field.second"
                }
            }

            case first
            case second
        }
    }

    @State private var languageDuplicatedAlert: LanguageDuplicateAlert?
    private var showLanguageDuplicatedAlert: Binding<Bool> {
        .init {
            languageDuplicatedAlert != nil
        } set: { newValue in
            if !newValue {
                languageDuplicatedAlert = nil
            }
        }
    }
}
