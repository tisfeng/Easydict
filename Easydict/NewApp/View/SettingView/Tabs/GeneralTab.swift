//
//  GeneralTab.swift
//  Easydict
//
//  Created by Kyle on 2023/12/29.
//  Copyright © 2023 izual. All rights reserved.
//

import Defaults
import SwiftUI

// MARK: - GeneralTab

@available(macOS 13, *)
struct GeneralTab: View {
    // MARK: Internal

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Form {
            Section {
                Picker("setting.general.appearance.light_dark_appearance".localized, selection: $appearanceType) {
                    ForEach(AppearenceType.allCases, id: \.rawValue) { option in
                        Text(option.title)
                            .tag(option)
                    }
                }
            } header: {
                Text("setting.general.appearance.header".localized)
            }
            Section {
                FirstAndSecondLanguageSettingView()
                Picker(
                    "setting.general.language.language_detect_optimize".localized,
                    selection: $languageDetectOptimize
                ) {
                    ForEach(LanguageDetectOptimize.allCases, id: \.rawValue) { option in
                        Text(option.localizedStringResource)
                            .tag(option)
                    }
                }
            } header: {
                Text("setting.general.language.header".localized)
            }

            Section {
                Toggle("auto_show_query_icon".localized, isOn: $autoSelectText)
                Toggle("force_auto_get_selected_text".localized, isOn: $forceAutoGetSelectedText)
                Toggle("click_icon_query_info".localized, isOn: $clickQuery)
                Toggle(
                    "setting.general.mouse_query.adjust_pop_button_origin".localized,
                    isOn: $adjustPopButtonOrigin
                ) // 调整查询图标位置:
            } header: {
                Text("setting.general.mouse_query.header".localized)
            }

            Section {
                Toggle(
                    "setting.general.voice.disable_empty_copy_beep_msg".localized,
                    isOn: $disableEmptyCopyBeep
                ) // 禁用提示音：划词内容为空时生效
                Toggle("setting.general.voice.auto_play_word_audio".localized, isOn: $autoPlayAudio) // 查询英语单词后自动播放发音
            } header: {
                Text("setting.general.voice.header".localized)
            }

            Section {
                Picker(
                    "setting.general.window.mouse_select_translate_window_type".localized,
                    selection: $mouseSelectTranslateWindowType
                ) {
                    ForEach(EZWindowType.availableOptions, id: \.rawValue) { option in
                        Text(option.localizedStringResource)
                            .tag(option)
                    }
                }
                Picker(
                    "setting.general.window.shortcut_select_translate_window_type".localized,
                    selection: $shortcutSelectTranslateWindowType
                ) {
                    ForEach(EZWindowType.availableOptions, id: \.rawValue) { option in
                        Text(option.localizedStringResource)
                            .tag(option)
                    }
                }
                Picker("setting.general.window.fixed_window_position".localized, selection: $fixedWindowPosition) {
                    ForEach(EZShowWindowPosition.allCases, id: \.rawValue) { option in
                        Text(option.localizedStringResource)
                            .tag(option)
                    }
                }
            } header: {
                Text("setting.general.windows.header".localized)
            }

            Section {
                Toggle("clear_input_when_translating".localized, isOn: $clearInput)
                Toggle("keep_prev_result_when_selected_text_is_empty".localized, isOn: $keepPrevResultWhenEmpty)
                Toggle("select_query_text_when_window_activate".localized, isOn: $selectQueryTextWhenWindowActivate)
            } header: {
                Text("setting.general.input.header".localized)
            }

            Section {
                Toggle("auto_query_ocr_text".localized, isOn: $autoQueryOCRText)
                Toggle("auto_query_selected_text".localized, isOn: $autoQuerySelectedText)
                Toggle("auto_query_pasted_text".localized, isOn: $autoQueryPastedText)
            } header: {
                Text("setting.general.auto_query.header".localized)
            }

            Section {
                Toggle("auto_copy_ocr_text".localized, isOn: $autoCopyOCRText)
                Toggle("auto_copy_selected_text".localized, isOn: $autoCopySelectedText)
                Toggle("auto_copy_first_translated_text".localized, isOn: $autoCopyFirstTranslatedText)
            } header: {
                Text("setting.general.auto_copy.header".localized)
            }

            Section {
                Toggle("show_google_quick_link".localized, isOn: $showGoogleQuickLink)
                Toggle("show_eudic_quick_link".localized, isOn: $showEudicQuickLink)
                Toggle("show_apple_dictionary_quick_link".localized, isOn: $showAppleDictionaryQuickLink)
            } header: {
                Text("setting.general.quick_link.header".localized)
            }

            Section {
                let bindingFontSize = Binding<Double>(get: {
                    Double(fontSizeOptionIndex)
                }, set: { newValue in
                    fontSizeOptionIndex = UInt(newValue)
                })
                Slider(value: bindingFontSize, in: 0.0 ... 4.0, step: 1) {
                    Text("setting.general.font.font_size.label".localized)
                } minimumValueLabel: {
                    Text("small".localized)
                        .font(.system(size: 10))
                } maximumValueLabel: {
                    Text("large".localized)
                        .font(.system(size: 14))
                }
            } header: {
                Text("setting.general.font.header".localized)
            } footer: {
                Text("hints_keyboard_shortcuts_font_size".localized)
                    .font(.footnote)
            }

            Section {
                Toggle(isOn: $launchAtStartup) {
                    Text("launch_at_startup".localized)
                }
                Toggle(isOn: $hideMainWindow) {
                    Text("hide_main_window".localized)
                }
                Toggle(isOn: $hideMenuBarIcon.didSet(execute: { state in
                    if state {
                        // user is not set input shortcut and selection shortcut not allow hide menu bar
                        if !shortcutsHaveSetuped {
                            Defaults[.hideMenuBarIcon] = false
                            showRefuseAlert = true
                        } else {
                            showHideMenuBarIconAlert = true
                        }
                    }
                })) {
                    Text("hide_menu_bar_icon".localized)
                }
                Picker(
                    "modify_menubar_icon".localized,
                    selection: $selectedMenuBarIcon
                ) {
                    ForEach(MenuBarIconType.allCases) { option in
                        Image(option.rawValue)
                            .renderingMode(.template)
                            .foregroundStyle(.primary)
                    }
                }
                Picker("language_preference".localized, selection: $languageState.language) {
                    ForEach(LanguageState.LanguageType.allCases, id: \.rawValue) { language in
                        Text(language.name)
                            .tag(language)
                    }
                }
            } header: {
                Text("setting.general.other.header".localized)
            }
        }
        .formStyle(.grouped)
        .alert("hide_menu_bar_icon".localized, isPresented: $showRefuseAlert) {
            Button("ok".localized) {
                showRefuseAlert = false
            }
        } message: {
            Text("refuse_hide_menu_bar_icon_msg".localized)
        }
        .alert("hide_menu_bar_icon".localized, isPresented: $showHideMenuBarIconAlert) {
            HStack {
                Button("ok".localized) {
                    showHideMenuBarIconAlert = false
                }
                Button("cancel".localized) {
                    Defaults[.hideMenuBarIcon] = false
                }
            }
        } message: {
            Text("hide_menu_bar_icon_msg".localized)
        }
    }

    // MARK: Private

    @EnvironmentObject private var languageState: LanguageState

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

    @State private var showRefuseAlert = false
    @State private var showHideMenuBarIconAlert = false

    private var shortcutsHaveSetuped: Bool {
        Defaults[.inputShortcut] != nil || Defaults[.selectionShortcut] != nil
    }
}

@available(macOS 13, *)
#Preview {
    GeneralTab()
}

// MARK: - FirstAndSecondLanguageSettingView

@available(macOS 13, *)
private struct FirstAndSecondLanguageSettingView: View {
    // MARK: Internal

    var body: some View {
        Group {
            Picker("setting.general.language.first_language".localized, selection: $firstLanguage) {
                ForEach(Language.allAvailableOptions, id: \.rawValue) { option in
                    Text(verbatim: "\(option.flagEmoji) \(option.localizedName)")
                        .tag(option)
                }
            }
            Picker("setting.general.language.second_language".localized, selection: $secondLanguage) {
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
        .alert(
            "setting.general.language.duplicated_alert.title".localized,
            isPresented: showLanguageDuplicatedAlert,
            presenting: languageDuplicatedAlert
        ) { _ in

        } message: { alert in
            Text(alert.description)
        }
    }

    // MARK: Private

    private struct LanguageDuplicateAlert: CustomStringConvertible {
        enum Field {
            case first
            case second

            // MARK: Internal

            var localizedString: String {
                switch self {
                case .first:
                    "setting.general.language.duplicated_alert.field.first".localized
                case .second:
                    "setting.general.language.duplicated_alert.field.second".localized
                }
            }
        }

        let duplicatedLanguage: Language

        let setField: Field

        let setLanguage: Language

        var description: String {
            // First language should not be same as second language. (\(duplicatedLanguage))
            // \(setField) is replaced with \(setLanguage).
            String(
                // swiftlint:disable:next line_length
                localized: "setting.general.language.duplicated_alert \(duplicatedLanguage.localizedName)\(setField.localizedString)\(setLanguage.localizedName)",
                bundle: localizedBundle
            )
        }
    }

    @Default(.firstLanguage) private var firstLanguage
    @Default(.secondLanguage) private var secondLanguage

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
