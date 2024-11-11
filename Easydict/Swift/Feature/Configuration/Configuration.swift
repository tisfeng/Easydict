//
//  Configuration.swift
//  Easydict
//
//  Created by ljk on 2024/1/2.
//  Copyright © 2024 izual. All rights reserved.
//

import Combine
import Defaults
import Foundation

// MARK: - LanguageDetectOptimize

@objc
enum LanguageDetectOptimize: Int {
    case none = 0
    case baidu = 1
    case google = 2
}

// MARK: - Configuration

@objcMembers
class Configuration: NSObject {
    // MARK: Lifecycle

    override private init() {
        super.init()
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            observeKeys()
        }
    }

    // MARK: Internal

    private(set) static var shared = Configuration()

    @DefaultsWrapper(.firstLanguage) var firstLanguage: Language
    @DefaultsWrapper(.secondLanguage) var secondLanguage: Language
    @DefaultsWrapper(.queryFromLanguage) var fromLanguage: Language
    @DefaultsWrapper(.queryToLanguage) var toLanguage: Language
    @DefaultsWrapper(.languageDetectOptimize) var languageDetectOptimize: LanguageDetectOptimize

    @DefaultsWrapper(.autoSelectText) var autoSelectText: Bool
    @DefaultsWrapper(.enableForceGetSelectedText) var enableForceGetSelectedText: Bool
    @DefaultsWrapper(.clickQuery) var clickQuery: Bool
    @DefaultsWrapper(.adjustPopButtonOrigin) var adjustPopButtomOrigin: Bool

    @DefaultsWrapper(.mouseSelectTranslateWindowType) var mouseSelectTranslateWindowType:
        EZWindowType
    @DefaultsWrapper(.shortcutSelectTranslateWindowType) var shortcutSelectTranslateWindowType:
        EZWindowType
    @DefaultsWrapper(.fixedWindowPosition) var fixedWindowPosition: EZShowWindowPosition
    @DefaultsWrapper(.pinWindowWhenDisplayed) var pinWindowWhenDisplayed
    @DefaultsWrapper(.hideMainWindow) var hideMainWindow: Bool

    @DefaultsWrapper(.clearQueryWhenInputTranslate) var clearInput: Bool
    @DefaultsWrapper(.keepPrevResultWhenSelectTranslateTextIsEmpty) var keepPrevResultWhenEmpty:
        Bool
    @DefaultsWrapper(.selectQueryTextWhenWindowActivate) var selectQueryTextWhenWindowActivate: Bool
    @DefaultsWrapper(.automaticallyRemoveCodeCommentSymbols) var automaticallyRemoveCodeCommentSymbols: Bool
    @DefaultsWrapper(.automaticWordSegmentation) var automaticWordSegmentation: Bool
    @DefaultsWrapper(.replaceNewlineWithSpace) var replaceNewlineWithSpace: Bool

    @DefaultsWrapper(.autoQueryOCRText) var autoQueryOCRText: Bool
    @DefaultsWrapper(.autoQuerySelectedText) var autoQuerySelectedText: Bool
    @DefaultsWrapper(.autoQueryPastedText) var autoQueryPastedText: Bool
    @DefaultsWrapper(.autoPlayAudio) var autoPlayAudio: Bool

    @DefaultsWrapper(.autoCopySelectedText) var autoCopySelectedText: Bool
    @DefaultsWrapper(.autoCopyOCRText) var autoCopyOCRText: Bool
    @DefaultsWrapper(.autoCopyFirstTranslatedText) var autoCopyFirstTranslatedText: Bool

    @DefaultsWrapper(.showGoogleQuickLink) var showGoogleQuickLink: Bool
    @DefaultsWrapper(.showEudicQuickLink) var showEudicQuickLink: Bool
    @DefaultsWrapper(.showAppleDictionaryQuickLink) var showAppleDictionaryQuickLink: Bool
    @DefaultsWrapper(.showQuickActionButton) var showQuickActionButton: Bool

    @DefaultsWrapper(.appearanceType) var appearance: AppearenceType
    @DefaultsWrapper(.hideMenuBarIcon) var hideMenuBarIcon: Bool
    @DefaultsWrapper(.fontSizeOptionIndex) var fontSizeIndex: UInt

    // Advanced Tab
    @DefaultsWrapper(.disableTipsView) var disableTipsView: Bool
    @DefaultsWrapper(.enableBetaFeature) private(set) var beta: Bool
    @DefaultsWrapper(.enableYoudaoOCR) var enableYoudaoOCR: Bool
    @DefaultsWrapper(.replaceWithTranslationInCompatibilityMode) var replaceWithTranslationInCompatibilityMode: Bool
    @Default(.forceGetSelectedTextType) var forceGetSelectedTextType: ForceGetSelectedTextType

    @Default(.enableAppleOfflineTranslation) var enableAppleOfflineTranslation: Bool

    @DefaultsWrapper(.allowCrashLog) var allowCrashLog: Bool
    @DefaultsWrapper(.allowAnalytics) var allowAnalytics: Bool

    @ShortcutWrapper(.pinShortcut) var pinShortcutString: String
    @ShortcutWrapper(.googleShortcut) var googleShortcutString: String
    @ShortcutWrapper(.appleDictionaryShortcut) var appleDictShortcutString: String
    @ShortcutWrapper(.eudicShortcut) var eudicDictShortcutString: String

    let updater = GlobalContext.shared.updaterController.updater
    let fontSizes: [CGFloat] = [1, 1.1, 1.2, 1.3, 1.4]
    var disabledAutoSelect: Bool = false
    var isRecordingSelectTextShortcutKey: Bool = false
    var cancellables: Set<AnyCancellable> = []

    var fontSizeRatio: CGFloat {
        let safeIndex = max(0, min(Int(fontSizeIndex), fontSizes.count - 1))
        return fontSizes[safeIndex]
    }

    var automaticallyChecksForUpdates: Bool {
        get {
            updater.automaticallyChecksForUpdates
        }
        set {
            updater.automaticallyChecksForUpdates = newValue
            logSettings(["automatically_checks_for_updates": newValue])
        }
    }

    var defaultTTSServiceType: ServiceType {
        get {
            ServiceType(rawValue: Defaults[.defaultTTSServiceType].rawValue)
        }
        set {
            Defaults[.defaultTTSServiceType] =
                TTSServiceType(rawValue: newValue.rawValue) ?? .youdao
        }
    }

    static func destroySharedInstance() {
        shared = Configuration()
    }

    func enableBetaFeaturesIfNeeded() {
        guard beta else { return }
    }

    // MARK: Private

    // swiftlint:disable:next function_body_length
    private func observeKeys() {
        Defaults.publisher(.firstLanguage, options: [])
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.didSetFirstLanguage()
            }
            .store(in: &cancellables)

        Defaults.publisher(.secondLanguage, options: [])
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.didSetSecondLanguage()
            }
            .store(in: &cancellables)

        Defaults.publisher(.autoSelectText, options: [])
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.didSetAutoSelectText()
            }
            .store(in: &cancellables)

        Defaults.publisher(.enableForceGetSelectedText, options: [])
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.didSetForceAutoGetSelectedText()
            }
            .store(in: &cancellables)

        Defaults.publisher(.clickQuery, options: [])
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.didSetClickQuery()
            }
            .store(in: &cancellables)

        Defaults.publisher(.hideMainWindow, options: [])
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.didSetHideMainWindow()
            }
            .store(in: &cancellables)

        Defaults.publisher(.autoQueryOCRText, options: [])
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.didSetAutoQueryOCRText()
            }
            .store(in: &cancellables)

        Defaults.publisher(.autoQuerySelectedText, options: [])
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.didSetAutoQuerySelectedText()
            }
            .store(in: &cancellables)

        Defaults.publisher(.autoQueryPastedText, options: [])
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.didSetAutoQueryPastedText()
            }
            .store(in: &cancellables)

        Defaults.publisher(.autoPlayAudio, options: [])
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.didSetAutoPlayAudio()
            }
            .store(in: &cancellables)

        Defaults.publisher(.autoCopySelectedText, options: [])
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.didSetAutoCopySelectedText()
            }
            .store(in: &cancellables)

        Defaults.publisher(.autoCopyOCRText, options: [])
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.didSetAutoCopyOCRText()
            }
            .store(in: &cancellables)

        Defaults.publisher(.autoCopyFirstTranslatedText, options: [])
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.didSetAutoCopyFirstTranslatedText()
            }
            .store(in: &cancellables)

        Defaults.publisher(.languageDetectOptimize, options: [])
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.didSetLanguageDetectOptimize()
            }
            .store(in: &cancellables)

        Defaults.publisher(.defaultTTSServiceType, options: [])
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.didSetDefaultTTSServiceType()
            }
            .store(in: &cancellables)

        Defaults.publisher(.showGoogleQuickLink, options: [])
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.didSetShowGoogleQuickLink()
            }
            .store(in: &cancellables)

        Defaults.publisher(.showEudicQuickLink, options: [])
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.didSetShowEudicQuickLink()
            }
            .store(in: &cancellables)

        Defaults.publisher(.showAppleDictionaryQuickLink, options: [])
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.didSetShowAppleDictionaryQuickLink()
            }
            .store(in: &cancellables)

        Defaults.publisher(.showQuickActionButton, options: [])
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.didSetShowSettingQuickLink()
            }
            .store(in: &cancellables)

        Defaults.publisher(.hideMenuBarIcon, options: [])
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.didSetHideMenuBarIcon()
            }
            .store(in: &cancellables)

        Defaults.publisher(.fixedWindowPosition, options: [])
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.didSetFixedWindowPosition()
            }
            .store(in: &cancellables)

        Defaults.publisher(.mouseSelectTranslateWindowType, options: [])
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.didSetMouseSelectTranslateWindowType()
            }
            .store(in: &cancellables)

        Defaults.publisher(.shortcutSelectTranslateWindowType, options: [])
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.didSetShortcutSelectTranslateWindowType()
            }
            .store(in: &cancellables)

        Defaults.publisher(.adjustPopButtonOrigin, options: [])
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.didSetAdjustPopButtomOrigin()
            }
            .store(in: &cancellables)

        Defaults.publisher(.allowCrashLog, options: [])
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.didSetAllowCrashLog()
            }
            .store(in: &cancellables)

        Defaults.publisher(.allowAnalytics, options: [])
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.didSetAllowAnalytics()
            }
            .store(in: &cancellables)

        Defaults.publisher(.clearQueryWhenInputTranslate, options: [])
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.didSetClearInput()
            }
            .store(in: &cancellables)

        Defaults.publisher(.fontSizeOptionIndex, options: [])
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.didSetFontSizeIndex()
            }
            .store(in: &cancellables)

        Defaults.publisher(.appearanceType, options: [])
            .removeDuplicates()
            .sink { [weak self] change in
                let newValue = change.newValue
                self?.didSetAppearance(newValue)
            }
            .store(in: &cancellables)

        Defaults.publisher(
            keys: [
                .pinShortcut,
                .appleDictionaryShortcut,
                .googleShortcut,
                .eudicShortcut,
            ],
            options: []
        )
        .throttle(for: 0.5, scheduler: DispatchQueue.main, latest: true)
        .sink { _ in
            EZWindowManager.shared().updateWindowsTitlebarButtonsToolTip()
        }
        .store(in: &cancellables)

        Defaults.publisher(.enableHTTPServer)
            .removeDuplicates()
            .sink { change in
                let isOn = change.newValue
                Task {
                    await VaporServer.shared.startServer(isOn: isOn)
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: setter

extension Configuration {
    fileprivate func didSetFirstLanguage() {
        logSettings(["first_language": firstLanguage])
    }

    fileprivate func didSetSecondLanguage() {
        logSettings(["second_language": secondLanguage])
    }

    fileprivate func didSetAutoSelectText() {
        logSettings(["auto_select_sext": autoSelectText])
    }

    fileprivate func didSetForceAutoGetSelectedText() {
        logSettings(["force_get_selected_text": enableForceGetSelectedText])
    }

    fileprivate func didSetClickQuery() {
        EZWindowManager.shared().updatePopButtonQueryAction()

        logSettings(["click_query": clickQuery])
    }

    fileprivate func didSetAutomaticallyChecksForUpdates() {
        logSettings(["automatically_checks_for_updates": automaticallyChecksForUpdates])
    }

    fileprivate func didSetHideMainWindow() {
        let windowManger = EZWindowManager.shared()
        windowManger.updatePopButtonQueryAction()
        if hideMainWindow {
            windowManger.destroyMainWindow()
        }

        logSettings(["hide_main_window": hideMainWindow])
    }

    fileprivate func didSetAutoQueryOCRText() {
        logSettings(["auto_query_ocr_text": autoQueryOCRText])
    }

    fileprivate func didSetAutoQuerySelectedText() {
        logSettings(["auto_query_selected_text": autoQuerySelectedText])
    }

    fileprivate func didSetAutoQueryPastedText() {
        logSettings(["auto_query_pasted_text": autoQueryPastedText])
    }

    fileprivate func didSetAutoPlayAudio() {
        logSettings(["auto_play_word_audio": autoPlayAudio])
    }

    fileprivate func didSetAutoCopySelectedText() {
        logSettings(["auto_copy_selected_text": autoCopySelectedText])
    }

    fileprivate func didSetAutoCopyOCRText() {
        logSettings(["auto_copy_ocr_text": autoCopyOCRText])
    }

    fileprivate func didSetAutoCopyFirstTranslatedText() {
        logSettings(["auto_copy_first_translated_text": autoCopyFirstTranslatedText])
    }

    fileprivate func didSetLanguageDetectOptimize() {
        logSettings(["detect_optimize": languageDetectOptimize])
    }

    fileprivate func didSetDefaultTTSServiceType() {
        let value = defaultTTSServiceType
        logSettings(["tts": value])
    }

    fileprivate func didSetShowGoogleQuickLink() {
        postUpdateQuickLinkButtonNotification()
        logSettings(["show_google_link": showGoogleQuickLink])
    }

    fileprivate func didSetShowEudicQuickLink() {
        postUpdateQuickLinkButtonNotification()
        logSettings(["show_eudic_link": showEudicQuickLink])
    }

    fileprivate func didSetShowAppleDictionaryQuickLink() {
        postUpdateQuickLinkButtonNotification()
        logSettings(["show_apple_dictionary_link": showAppleDictionaryQuickLink])
    }

    func didSetShowSettingQuickLink() {
        postUpdateQuickLinkButtonNotification()

        logSettings(["showSettingQuickLink": showQuickActionButton])
    }

    fileprivate func didSetHideMenuBarIcon() {
        logSettings(["hide_menu_bar_icon": hideMenuBarIcon])
    }

    fileprivate func didSetFixedWindowPosition() {
        logSettings(["show_fixed_window_position": fixedWindowPosition])
    }

    fileprivate func didSetMouseSelectTranslateWindowType() {
        logSettings(["show_mouse_window_type": mouseSelectTranslateWindowType])
    }

    fileprivate func didSetShortcutSelectTranslateWindowType() {
        logSettings(["show_shortcut_window_type": shortcutSelectTranslateWindowType])
    }

    fileprivate func didSetAdjustPopButtomOrigin() {
        logSettings(["adjust_pop_buttom_origin": adjustPopButtomOrigin])
    }

    fileprivate func didSetAllowCrashLog() {
        EZLog.setCrashEnabled(allowCrashLog)
        logSettings(["allow_crash_log": allowCrashLog])
    }

    fileprivate func didSetAllowAnalytics() {
        logSettings(["allow_analytics": allowAnalytics])
    }

    fileprivate func didSetClearInput() {
        logSettings(["clear_input": clearInput])
    }

    fileprivate func didSetFontSizeIndex() {
        NotificationCenter.default.post(name: .didChangeFontSize, object: nil)
    }

    fileprivate func didSetAppearance(_ appearance: AppearenceType) {
        DarkModeManager.sharedManager().updateDarkMode(appearance.rawValue)
    }
}

extension Configuration {
    fileprivate func postUpdateQuickLinkButtonNotification() {
        let notification = Notification(name: Notification.Name.linkButtonUpdated, object: nil)
        NotificationCenter.default.post(notification)
    }

    fileprivate func logSettings(_ parameters: [String: Any]) {
        EZLog.logEvent(withName: "settings", parameters: parameters)
    }
}
