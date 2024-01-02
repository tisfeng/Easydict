//
//  NewConfiguration.swift
//  Easydict
//
//  Created by ljk on 2024/1/2.
//  Copyright © 2024 izual. All rights reserved.
//

import Defaults
import Foundation

class Configuration: NSObject {
    private(set) static var shared = Configuration()

    var appDelegate = NSApp.delegate as? AppDelegate

    var updater: SPUUpdater? {
        appDelegate?.updaterController.updater
    }

    @Default(.firstLanguage)
    var firstLanguage: Language

    @Default(.secondLanguage)
    var secondLanguage: Language

    @Default(.queryFromLanguage)
    var from: Language

    @Default(.queryToLanguage)
    var to: Language

    @Default(.autoSelectText)
    var autoSelectText: Bool

    @Default(.forceAutoGetSelectedText)
    var forceAutoGetSelectedText: Bool

    @Default(.disableEmptyCopyBeep)
    var disableEmptyCopyBeep: Bool // Some apps will beep when empty copy.

    @Default(.clickQuery)
    var clickQuery: Bool

    @Default(.launchAtStartup)
    var launchAtStartup: Bool

    var automaticallyChecksForUpdates: Bool {
        updater?.automaticallyChecksForUpdates ?? false
    }

    @Default(.hideMainWindow)
    var hideMainWindow: Bool

    @Default(.autoQueryOCRText)
    var autoQueryOCRText: Bool

    @Default(.autoQuerySelectedText)
    var autoQuerySelectedText: Bool

    @Default(.autoQueryPastedText)
    var autoQueryPastedText: Bool

    @Default(.autoPlayAudio)
    var autoPlayAudio: Bool

    @Default(.autoCopySelectedText)
    var autoCopySelectedText: Bool

    @Default(.autoCopyOCRText)
    var autoCopyOCRText: Bool

    @Default(.autoCopyFirstTranslatedText)
    var autoCopyFirstTranslatedText: Bool

    @Default(.languageDetectOptimize)
    var languageDetectOptimize: EZLanguageDetectOptimize

    @available(macOS 13, *)
    var defaultTTSServiceType: TTSServiceType {
        get {
            Defaults[.defaultTTSServiceType]
        }
        set {
            Defaults[.defaultTTSServiceType] = newValue
        }
    }

    @Default(.showGoogleQuickLink)
    var showGoogleQuickLink: Bool

    @Default(.showEudicQuickLink)
    var showEudicQuickLink: Bool

    @Default(.showAppleDictionaryQuickLink)
    var showAppleDictionaryQuickLink: Bool

    @Default(.hideMenuBarIcon)
    var hideMenuBarIcon: Bool

    @Default(.enableBetaNewApp)
    var enableBetaNewApp: Bool

    @Default(.fixedWindowPosition)
    var fixedWindowPosition: EZShowWindowPosition

    @Default(.mouseSelectTranslateWindowType)
    var mouseSelectTranslateWindowType: EZWindowType

    @Default(.shortcutSelectTranslateWindowType)
    var shortcutSelectTranslateWindowType: EZWindowType

    @Default(.adjustPopButtonOrigin)
    var adjustPopButtomOrigin: Bool

    @Default(.allowCrashLog)
    var allowCrashLog: Bool

    @Default(.allowAnalytics)
    var allowAnalytics: Bool

    @Default(.clearInput)
    var clearInput: Bool

    var disabledAutoSelect: Bool = false

    var isRecordingSelectTextShortcutKey: Bool = false

    let fontSizes: [CGFloat] = [1, 1.1, 1.2, 1.3, 1.4]

    var fontSizeRatio: CGFloat {
        fontSizes[Int(fontSizeIndex)]
    }

    @Default(.fontSizeOptionIndex)
    var fontSizeIndex: UInt

    @Default(.appearanceType)
    var appearance: AppearenceType

    @Default(.enableBetaFeature)
    private(set) var beta: Bool

    override init() {
        super.init()

        Defaults.observe(.firstLanguage) { [unowned self] _ in
            didSetFirstLanguage()
        }.tieToLifetime(of: self)

        Defaults.observe(.secondLanguage) { [unowned self] _ in
            didSetSecondLanguage()
        }.tieToLifetime(of: self)

        Defaults.observe(.autoSelectText) { [unowned self] _ in
            didSetAutoSelectText()
        }.tieToLifetime(of: self)

        Defaults.observe(.forceAutoGetSelectedText) { [unowned self] _ in
            didSetForceAutoGetSelectedText()
        }.tieToLifetime(of: self)

        Defaults.observe(.disableEmptyCopyBeep) { [unowned self] _ in
            didSetDisableEmptyCopyBeep()
        }.tieToLifetime(of: self)

        Defaults.observe(.clickQuery) { [unowned self] _ in
            didSetClickQuery()
        }.tieToLifetime(of: self)

        Defaults.observe(.launchAtStartup) { [unowned self] change in
            didSetLaunchAtStartup(change.oldValue, new: change.newValue)
        }.tieToLifetime(of: self)

        Defaults.observe(.hideMainWindow) { [unowned self] _ in
            didSetHideMainWindow()
        }.tieToLifetime(of: self)

        Defaults.observe(.autoQueryOCRText) { [unowned self] _ in
            didSetAutoQueryOCRText()
        }.tieToLifetime(of: self)

        Defaults.observe(.autoQuerySelectedText) { [unowned self] _ in
            didSetAutoQuerySelectedText()
        }.tieToLifetime(of: self)

        Defaults.observe(.autoQueryPastedText) { [unowned self] _ in
            didSetAutoQueryPastedText()
        }.tieToLifetime(of: self)

        Defaults.observe(.autoPlayAudio) { [unowned self] _ in
            didSetAutoPlayAudio()
        }.tieToLifetime(of: self)

        Defaults.observe(.autoCopySelectedText) { [unowned self] _ in
            didSetAutoCopySelectedText()
        }.tieToLifetime(of: self)

        Defaults.observe(.autoCopyOCRText) { [unowned self] _ in
            didSetAutoCopyOCRText()
        }.tieToLifetime(of: self)

        Defaults.observe(.autoCopyFirstTranslatedText) { [unowned self] _ in
            didSetAutoCopyFirstTranslatedText()
        }.tieToLifetime(of: self)

        Defaults.observe(.languageDetectOptimize) { [unowned self] _ in
            didSetLanguageDetectOptimize()
        }.tieToLifetime(of: self)

        if #available(macOS 13, *) {
            Defaults.observe(.defaultTTSServiceType) { [unowned self] _ in
                self.didSetDefaultTTSServiceType()
            }.tieToLifetime(of: self)
        }

        Defaults.observe(.showGoogleQuickLink) { [unowned self] _ in
            didSetShowGoogleQuickLink()
        }.tieToLifetime(of: self)

        Defaults.observe(.showEudicQuickLink) { [unowned self] _ in
            didSetShowEudicQuickLink()
        }.tieToLifetime(of: self)

        Defaults.observe(.showAppleDictionaryQuickLink) { [unowned self] _ in
            didSetShowAppleDictionaryQuickLink()
        }.tieToLifetime(of: self)

        Defaults.observe(.hideMenuBarIcon) { [unowned self] _ in
            didSetHideMenuBarIcon()
        }.tieToLifetime(of: self)

        Defaults.observe(.enableBetaNewApp) { [unowned self] _ in
            didSetEnableBetaNewApp()
        }.tieToLifetime(of: self)

        Defaults.observe(.fixedWindowPosition) { [unowned self] _ in
            didSetFixedWindowPosition()
        }.tieToLifetime(of: self)

        Defaults.observe(.mouseSelectTranslateWindowType) { [unowned self] _ in
            didSetMouseSelectTranslateWindowType()
        }.tieToLifetime(of: self)

        Defaults.observe(.shortcutSelectTranslateWindowType) { [unowned self] _ in
            didSetShortcutSelectTranslateWindowType()
        }.tieToLifetime(of: self)

        Defaults.observe(.adjustPopButtonOrigin) { [unowned self] _ in
            didSetAdjustPopButtomOrigin()
        }.tieToLifetime(of: self)

        Defaults.observe(.allowCrashLog) { [unowned self] _ in
            didSetAllowCrashLog()
        }.tieToLifetime(of: self)

        Defaults.observe(.allowAnalytics) { [unowned self] _ in
            didSetAllowAnalytics()
        }.tieToLifetime(of: self)

        Defaults.observe(.clearInput) { [unowned self] _ in
            didSetClearInput()
        }.tieToLifetime(of: self)

        Defaults.observe(.fontSizeOptionIndex) { [unowned self] _ in
            didSetFontSizeIndex()
        }.tieToLifetime(of: self)

        Defaults.observe(.appearanceType) { [unowned self] _ in
            didSetAppearance()
        }.tieToLifetime(of: self)

        initialSetting()
    }

    private func initialSetting() {
        didSetFirstLanguage()
        didSetSecondLanguage()
        didSetAutoSelectText()
        didSetForceAutoGetSelectedText()
        didSetDisableEmptyCopyBeep()
        didSetClickQuery()
        didSetLaunchAtStartup(false, new: launchAtStartup)
        didSetHideMainWindow()
        didSetAutoQueryOCRText()
        didSetAutoQuerySelectedText()
        didSetAutoQueryPastedText()
        didSetAutoPlayAudio()
        didSetAutoCopySelectedText()
        didSetAutoCopyOCRText()
        didSetAutoCopyFirstTranslatedText()
        didSetLanguageDetectOptimize()
        didSetDefaultTTSServiceType()
        didSetShowGoogleQuickLink()
        didSetShowEudicQuickLink()
        didSetShowAppleDictionaryQuickLink()
        didSetHideMenuBarIcon()
        didSetEnableBetaNewApp()
        didSetFixedWindowPosition()
        didSetMouseSelectTranslateWindowType()
        didSetShortcutSelectTranslateWindowType()
        didSetAdjustPopButtomOrigin()
        didSetAllowCrashLog()
        didSetAllowAnalytics()
        didSetClearInput()
        didSetAppearance()
    }

    func enableBetaFeaturesIfNeeded() {
        guard beta else { return }
    }
}

// MARK: setter

private extension Configuration {
    func didSetFirstLanguage() {
        logSettings(["first_language": firstLanguage])
    }

    func didSetSecondLanguage() {
        logSettings(["second_language": secondLanguage])
    }

    func didSetAutoSelectText() {
        logSettings(["auto_select_sext": autoSelectText])
    }

    func didSetForceAutoGetSelectedText() {
        logSettings(["force_get_selected_text": forceAutoGetSelectedText])
    }

    func didSetDisableEmptyCopyBeep() {
        logSettings(["disableEmptyCopyBeep": disableEmptyCopyBeep])
    }

    func didSetClickQuery() {
        EZWindowManager.shared().updatePopButtonQueryAction()

        logSettings(["click_query": clickQuery])
    }

    func didSetLaunchAtStartup(_ old: Bool, new: Bool) {
        if new != old {
            updateLoginItemWithLaunchAtStartup(new)
        }

        logSettings(["launch_at_startup": new])
    }

    func didSetAutomaticallyChecksForUpdates() {
        logSettings(["automatically_checks_for_updates": automaticallyChecksForUpdates])
    }

    func didSetHideMainWindow() {
        let windowManger = EZWindowManager.shared()
        windowManger.updatePopButtonQueryAction()
        if hideMainWindow {
            windowManger.closeMainWindowIfNeeded()
        }

        logSettings(["hide_main_window": hideMainWindow])
    }

    func didSetAutoQueryOCRText() {
        logSettings(["auto_query_ocr_text": autoQueryOCRText])
    }

    func didSetAutoQuerySelectedText() {
        logSettings(["auto_query_selected_text": autoQuerySelectedText])
    }

    func didSetAutoQueryPastedText() {
        logSettings(["auto_query_pasted_text": autoQueryPastedText])
    }

    func didSetAutoPlayAudio() {
        logSettings(["auto_play_word_audio": autoPlayAudio])
    }

    func didSetAutoCopySelectedText() {
        logSettings(["auto_copy_selected_text": autoCopySelectedText])
    }

    func didSetAutoCopyOCRText() {
        logSettings(["auto_copy_ocr_text": autoCopyOCRText])
    }

    func didSetAutoCopyFirstTranslatedText() {
        logSettings(["auto_copy_first_translated_text": autoCopyFirstTranslatedText])
    }

    func didSetLanguageDetectOptimize() {
        logSettings(["detect_optimize": languageDetectOptimize])
    }

    func didSetDefaultTTSServiceType() {
        if #available(macOS 13, *) {
            let value = defaultTTSServiceType
            logSettings(["tts": value])
        }
    }

    func didSetShowGoogleQuickLink() {
        postUpdateQuickLinkButtonNotification()

        EZMenuItemManager.shared().googleItem?.isHidden = !showGoogleQuickLink

        logSettings(["show_google_link": showGoogleQuickLink])
    }

    func didSetShowEudicQuickLink() {
        postUpdateQuickLinkButtonNotification()

        EZMenuItemManager.shared().eudicItem?.isHidden = !showEudicQuickLink

        logSettings(["show_eudic_link": showEudicQuickLink])
    }

    func didSetShowAppleDictionaryQuickLink() {
        postUpdateQuickLinkButtonNotification()

        EZMenuItemManager.shared().appleDictionaryItem?.isHidden = !showAppleDictionaryQuickLink

        logSettings(["show_apple_dictionary_link": showAppleDictionaryQuickLink])
    }

    func didSetHideMenuBarIcon() {
        if !NewAppManager.shared.enable {
            hideMenuBarIcon(hidden: hideMenuBarIcon)
        }

        logSettings(["hide_menu_bar_icon": hideMenuBarIcon])
    }

    func didSetEnableBetaNewApp() {
        logSettings(["enable_beta_new_app": enableBetaNewApp])
    }

    func didSetFixedWindowPosition() {
        logSettings(["show_fixed_window_position": fixedWindowPosition])
    }

    func didSetMouseSelectTranslateWindowType() {
        logSettings(["show_mouse_window_type": mouseSelectTranslateWindowType])
    }

    func didSetShortcutSelectTranslateWindowType() {
        logSettings(["show_shortcut_window_type": shortcutSelectTranslateWindowType])
    }

    func didSetAdjustPopButtomOrigin() {
        logSettings(["adjust_pop_buttom_origin": adjustPopButtomOrigin])
    }

    func didSetAllowCrashLog() {
        EZLog.setCrashEnabled(allowCrashLog)
        logSettings(["allow_crash_log": allowCrashLog])
    }

    func didSetAllowAnalytics() {
        logSettings(["allow_analytics": allowAnalytics])
    }

    func didSetClearInput() {
        logSettings(["clear_input": clearInput])
    }

    func didSetFontSizeIndex() {
        NotificationCenter.default.post(name: .init(ChangeFontSizeView.changeFontSizeNotificationName), object: nil)
    }

    func didSetAppearance() {
        DarkModeManager.sharedManager().updateDarkMode()
    }
}

// MARK: Window Frame

private extension Configuration {
    func windowFrameWithType(_ windowType: EZWindowType) -> CGRect {
        let key = windowFrameKey(windowType: windowType)
        let frameString = UserDefaults.standard.string(forKey: key) ?? ""
        let frame = NSRectFromString(frameString)
        return frame
    }

    func setWindowFrame(_ frame: CGRect, windowType: EZWindowType) {
        let key = windowFrameKey(windowType: windowType)
        let frameString = NSStringFromRect(frame)
        UserDefaults.standard.set(frameString, forKey: key)
    }

    func windowFrameKey(windowType: EZWindowType) -> String {
        let key = "EZConfiguration_kWindowFrameKey_\(windowType)"
        return key
    }
}

// MARK: Intelligent Query Text Type of Service

private extension Configuration {
    func setIntelligentQueryTextType(_ queryTextType: EZQueryTextType, serviceType: ServiceType) {
        let key = EZConstKey.constkey("IntelligentQueryTextType", serviceType: serviceType)
        /**
         easydict://writeKeyValue?Google-IntelligentQueryTextType=5
         URL key value is string type, so we need to save vlue as string type.
         */
        let stringValue = "\(queryTextType)"
        UserDefaults.standard.set(stringValue, forKey: key)
    }

    func intelligentQueryTextTypeForServiceType(_ serviceType: ServiceType) -> EZQueryTextType {
        let key = EZConstKey.constkey("IntelligentQueryTextType", serviceType: serviceType)
        let stringValue = UserDefaults.standard.string(forKey: key) ?? "7"
        // Convert string to int
        let type = (stringValue as NSString).intValue
        return EZQueryTextType(rawValue: UInt(type))
    }
}

// MARK: Intelligent Query Mode

private extension Configuration {
    func setIntelligentQueryMode(_ enabled: Bool, windowType: EZWindowType) {
        let key = EZConstKey.constkey("IntelligentQueryMode", windowType: windowType)
        let stringValue = "\(enabled)"
        UserDefaults.standard.set(stringValue, forKey: key)

        let parameters = [
            "enabled": enabled,
            "window_type": windowType.rawValue,
        ] as [String: Any]

        EZLog.logEvent(withName: "intelligent_query_mode", parameters: parameters)
    }

    func intelligentQueryModeForWindowType(_ windowType: EZWindowType) -> Bool {
        let key = EZConstKey.constkey("IntelligentQueryMode", windowType: windowType)
        let defaultValue = "0"
        // Turn on intelligent query mode by default in mini window.
        if windowType == .mini {
            return true
        }
        return UserDefaults.standard.string(forKey: key) ?? defaultValue == "1"
    }
}

private extension Configuration {
    func postUpdateQuickLinkButtonNotification() {
        let notification = Notification(name: .init("EZQuickLinkButtonUpdateNotification"), object: nil)
        NotificationCenter.default.post(notification)
    }

    func hideMenuBarIcon(hidden: Bool) {
        if hidden {
            EZMenuItemManager.shared().remove()
        } else {
            EZMenuItemManager.shared().setup()
        }
    }

    func updateLoginItemWithLaunchAtStartup(_ launchAtStartup: Bool) {
        let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleExecutable") as? String
        let appBundlePath = Bundle.main.bundlePath

        let script = """
            tell application "System Events" to get the name of every login item
            tell application "System Events"
                set loginItems to every login item
                repeat with aLoginItem in loginItems
                    if (aLoginItem's name is "\(appName ?? "")") then
                        delete aLoginItem
                    end if
                end repeat
                if \(launchAtStartup) then
                    make login item at end with properties {path:"\(appBundlePath)", hidden:false}
                end if
            end tell
        """

        let exeCommand = EZScriptExecutor()
        exeCommand.runAppleScript(script) { result, error in
            if error != nil {
                MMLogInfo("launchAtStartup error: error: \(error)")
            } else {
                print("launchAtStartup result:", result)
            }
        }
    }

    func logSettings(_ parameters: [String: Any]) {
        EZLog.logEvent(withName: "settings", parameters: parameters)
    }
}
