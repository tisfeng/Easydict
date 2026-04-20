//
//  GeneralTab.swift
//  Easydict
//
//  Created by Kyle on 2023/12/29.
//  Copyright © 2023 izual. All rights reserved.
//

import Defaults
import LaunchAtLogin
import SwiftUI

// MARK: - GeneralTab

struct GeneralTab: View {
    // MARK: Internal

    class CheckUpdaterViewModel: ObservableObject {
        // MARK: Lifecycle

        init() {
            updater
                .publisher(for: \.automaticallyChecksForUpdates)
                .assign(to: &$autoChecksForUpdates)
        }

        // MARK: Internal

        @Published var autoChecksForUpdates = true {
            didSet {
                updater.automaticallyChecksForUpdates = autoChecksForUpdates
            }
        }

        // MARK: Private

        private let updater = MyConfiguration.shared.updater
    }

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Image(.logo)
            .resizable()
            .renderingMode(.original)
            .frame(width: 900, height: 620) // same as service tab
            .shadow(color: .gray, radius: 1, x: 0, y: 0.8)
            .padding(.bottom, 2)
            .padding(.leading, 16)
            .padding(.trailing, 16)
    }

    // MARK: Private

    // App setting
    @EnvironmentObject private var languageState: LanguageState
    @State private var showRefuseAlert = false
    @State private var showHideMenuBarIconAlert = false

    @StateObject private var checkUpdaterViewModel = CheckUpdaterViewModel()

    @State private var lastestVersion: String?

    // Query language
    @Default(.languageDetectOptimize) private var languageDetectOptimize

    // Input textfield
    @Default(.clearQueryWhenInputTranslate) private var clearInput
    @Default(.keepPrevResultWhenSelectTranslateTextIsEmpty) private var keepPrevResultWhenEmpty
    @Default(.selectQueryTextWhenWindowActivate) private var selectQueryTextWhenWindowActivate

    // Auto query
    @Default(.autoQueryOCRText) private var autoQueryOCRText
    @Default(.autoQuerySelectedText) private var autoQuerySelectedText
    @Default(.autoQueryPastedText) private var autoQueryPastedText
    @Default(.autoPlayAudio) private var autoPlayAudio
    @Default(.pronunciation) private var pronunciation

    // Auto copy
    @Default(.autoCopyOCRText) private var autoCopyOCRText
    @Default(.autoCopySelectedText) private var autoCopySelectedText
    @Default(.autoCopyFirstTranslatedText) private var autoCopyFirstTranslatedText

    // Quick link
    @Default(.showGoogleQuickLink) private var showGoogleQuickLink
    @Default(.showEudicQuickLink) private var showEudicQuickLink
    @Default(.showAppleDictionaryQuickLink) private var showAppleDictionaryQuickLink
    @Default(.showQuickActionButton) private var showQuickActionButton

    @Default(.appearanceType) private var appearanceType
    @Default(.hideMenuBarIcon) private var hideMenuBarIcon
    @Default(.selectedMenuBarIcon) private var selectedMenuBarIcon
    @Default(.fontSizeOptionIndex) private var fontSizeOptionIndex

    @Default(.includeBetaUpdates) private var includeBetaUpdates

    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }

    private var shortcutsHaveSetuped: Bool {
        Defaults[.inputShortcut] != nil || Defaults[.selectionShortcut] != nil
    }

    private func logSettings(_ parameters: [String: Any]) {
        AnalyticsService.logEvent(withName: "settings", parameters: parameters)
    }
}

#Preview {
    GeneralTab()
}

// MARK: - FirstAndSecondLanguageSettingView

private struct FirstAndSecondLanguageSettingView: View {
    // MARK: Internal

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
                languageDuplicatedAlert = .init(
                    duplicatedLanguage: newValue, setField: .second, setLanguage: oldValue
                )
            }
        }
        .onChange(of: secondLanguage) { [secondLanguage] newValue in
            let oldValue = secondLanguage
            if newValue == firstLanguage {
                firstLanguage = oldValue
                languageDuplicatedAlert = .init(
                    duplicatedLanguage: newValue, setField: .first, setLanguage: oldValue
                )
            }
        }
        .alert(
            "setting.general.language.duplicated_alert.title",
            isPresented: showLanguageDuplicatedAlert,
            presenting: languageDuplicatedAlert
        ) { _ in
        } message: { alert in
            Text(alert.description)
        }
    }

    // MARK: Private

    private struct LanguageDuplicateAlert: CustomStringConvertible {
        enum Field: CustomLocalizedStringResourceConvertible {
            case first
            case second

            // MARK: Internal

            var localizedStringResource: LocalizedStringResource {
                switch self {
                case .first:
                    "setting.general.language.duplicated_alert.field.first"
                case .second:
                    "setting.general.language.duplicated_alert.field.second"
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
                localized:
                "setting.general.language.duplicated_alert \(duplicatedLanguage.localizedName)\(String(localized: setField.localizedStringResource))\(setLanguage.localizedName)"
            )
        }
    }

    @State private var languageDuplicatedAlert: LanguageDuplicateAlert?

    @Default(.firstLanguage) private var firstLanguage
    @Default(.secondLanguage) private var secondLanguage

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
