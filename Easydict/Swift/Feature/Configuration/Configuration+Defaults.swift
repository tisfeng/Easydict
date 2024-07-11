//
//  Configuration+Defaults.swift
//  Easydict
//
//  Created by 戴藏龙 on 2024/1/12.
//  Copyright © 2024 izual. All rights reserved.
//

import Defaults
import Foundation
import Magnet

/// Utils
extension Defaults.Keys {
    /// is first launch
    static let firstLaunch = Key<Bool>("EZConfiguration_kFirstLaunch", default: true)
}

// Setting
extension Defaults.Keys {
    // rename `from`
    static let queryFromLanguage = Key<Language>("EZConfiguration_kFromKey", default: .auto)
    // rename `to`
    static let queryToLanguage = Key<Language>("EZConfiguration_kToKey", default: .auto)

    static let firstLanguage = Key<Language>(
        "EZConfiguration_kFirstLanguageKey",
        default: EZLanguageManager.shared().systemPreferredTwoLanguages[0]
    )
    static let secondLanguage = Key<Language>(
        "EZConfiguration_kSecondLanguageKey",
        default: EZLanguageManager.shared().systemPreferredTwoLanguages[1]
    )

    static let autoSelectText = Key<Bool>("EZConfiguration_kAutoSelectTextKey", default: true)
    static let forceAutoGetSelectedText = Key<Bool>("EZConfiguration_kForceAutoGetSelectedText", default: false)

    static let clickQuery = Key<Bool>("EZConfiguration_kClickQueryKey", default: false)
    static let autoPlayAudio = Key<Bool>("EZConfiguration_kAutoPlayAudioKey", default: false)
    static let launchAtStartup = Key<Bool>("EZConfiguration_kLaunchAtStartupKey", default: false)
    static let hideMainWindow = Key<Bool>("EZConfiguration_kHideMainWindowKey", default: true)
    static let autoQueryOCRText = Key<Bool>("EZConfiguration_kAutoQueryOCTTextKey", default: true)
    static let autoQuerySelectedText = Key<Bool>("EZConfiguration_kAutoQuerySelectedTextKey", default: true)
    static let autoQueryPastedText = Key<Bool>("EZConfiguration_kAutoQueryPastedTextKey", default: false)
    static let autoCopyOCRText = Key<Bool>("EZConfiguration_kAutoCopyOCRTextKey", default: false)
    static let autoCopySelectedText = Key<Bool>("EZConfiguration_kAutoCopySelectedTextKey", default: false)
    static let autoCopyFirstTranslatedText = Key<Bool>(
        "EZConfiguration_kAutoCopyFirstTranslatedTextKey",
        default: false
    )
    static let languageDetectOptimize = Key<LanguageDetectOptimize>(
        "EZConfiguration_kLanguageDetectOptimizeTypeKey",
        default: LanguageDetectOptimize.none
    )
    static let defaultTTSServiceType = Key<TTSServiceType>(
        "EZConfiguration_kDefaultTTSServiceTypeKey",
        default: TTSServiceType.youdao
    )
    static let showGoogleQuickLink = Key<Bool>("EZConfiguration_kShowGoogleLinkKey", default: true)
    static let showEudicQuickLink = Key<Bool>("EZConfiguration_kShowEudicLinkKey", default: true)
    static let showAppleDictionaryQuickLink = Key<Bool>("EZConfiguration_kShowAppleDictionaryLinkKey", default: true)
    static let showQuickActionButton = Key<Bool>("EZConfiguration_kShowSettingQuickLink", default: true)
    static let hideMenuBarIcon = Key<Bool>("EZConfiguration_kHideMenuBarIconKey", default: false)
    static let fixedWindowPosition = Key<EZShowWindowPosition>(
        "EZConfiguration_kShowFixedWindowPositionKey",
        default: .right
    )
    static let mouseSelectTranslateWindowType = Key<EZWindowType>(
        "EZConfiguration_kMouseSelectTranslateWindowTypeKey",
        default: .mini
    )
    static let shortcutSelectTranslateWindowType = Key<EZWindowType>(
        "EZConfiguration_kShortcutSelectTranslateWindowTypeKey",
        default: .fixed
    )
    static let adjustPopButtonOrigin = Key<Bool>("EZConfiguration_kAdjustPopButtomOriginKey", default: false)
    static let allowCrashLog = Key<Bool>("EZConfiguration_kAllowCrashLogKey", default: true)
    static let allowAnalytics = Key<Bool>("EZConfiguration_kAllowAnalyticsKey", default: true)
    static let clearInput = Key<Bool>("EZConfiguration_kClearInputKey", default: true)
    static let keepPrevResultWhenEmpty = Key<Bool>("EZConfiguration_kKeepPrevResultKey", default: true)
    static let selectQueryTextWhenWindowActivate = Key<Bool>(
        "EZConfiguration_kSelectQueryTextWhenWindowActivate",
        default: false
    )

    static let enableBetaFeature = Key<Bool>("EZBetaFeatureKey", default: false)

    static let appearanceType = Key<AppearenceType>("EZConfiguration_kApperanceKey", default: .followSystem)
    static let fontSizeOptionIndex = Key<UInt>("EZConfiguration_kTranslationControllerFontKey", default: 0)
    static let selectedMenuBarIcon = Key<MenuBarIconType>("EZConfiguration_kSelectedMenuBarIconKey", default: .square)

    static let automaticWordSegmentation = Key<Bool>("EZConfiguration_kAutomaticWordSegmentation", default: true)
    static let automaticallyRemoveCodeCommentSymbols = Key<Bool>(
        "EZConfiguration_kAutomaticallyRemoveCodeCommentSymbols",
        default: true
    )

    static var disableTipsView = Key<Bool>("disableTipsViewKey", default: false)
    static var enableYoudaoOCR = Key<Bool>("enableYoudaoOCR", default: false)
}

extension Defaults.Keys {
    static func intelligentQueryTextType(for serviceType: ServiceType) -> Key<EZQueryTextType> {
        let key = EZConstKey.constkey("IntelligentQueryTextType", serviceType: serviceType)
        return .init(key, default: EZQueryTextType(rawValue: 7))
    }

    static func queryTextType(for serviceType: ServiceType) -> Key<EZQueryTextType> {
        let key = EZConstKey.constkey("QueryTextType", serviceType: serviceType)
        return .init(key, default: EZQueryTextType(rawValue: 0))
    }

    static func windorFrame(for windowType: EZWindowType) -> Key<CGRect> {
        let key = "EZConfiguration_kWindowFrameKey_\(windowType)"
        return .init(key, default: .zero)
    }
}

// MARK: - EZQueryTextType + Defaults.Serializable

extension EZQueryTextType: Defaults.Serializable {
    public static var bridge: Bridge = .init()

    public struct Bridge: Defaults.Bridge {
        public typealias Value = EZQueryTextType

        public typealias Serializable = String

        public func serialize(_ value: EZQueryTextType?) -> String? {
            guard let value else { return "7" }
            return "\(value.rawValue)"
        }

        public func deserialize(_ object: String?) -> EZQueryTextType? {
            guard let object else { return nil }
            return EZQueryTextType(rawValue: UInt(object) ?? 7)
        }
    }
}

// MARK: - CGRect + Defaults.Serializable

extension CGRect: Defaults.Serializable {
    public static var bridge: Bridge = .init()

    public struct Bridge: Defaults.Bridge {
        public typealias Value = CGRect

        public typealias Serializable = String

        public func serialize(_ value: CGRect?) -> String? {
            let value = value ?? .zero
            return NSStringFromRect(value)
        }

        public func deserialize(_ object: String?) -> CGRect? {
            guard let object else { return nil }
            return NSRectFromString(object)
        }
    }
}

// MARK: - DefaultsWrapper

@propertyWrapper
class DefaultsWrapper<T: Defaults.Serializable> {
    // MARK: Lifecycle

    init(_ key: Defaults.Key<T>) {
        self.key = key
    }

    // MARK: Internal

    let key: Defaults.Key<T>

    var wrappedValue: T {
        get {
            Defaults[key]
        } set {
            Defaults[key] = newValue
        }
    }
}

// MARK: - ShortcutWrapper

@propertyWrapper
class ShortcutWrapper<T: KeyCombo> {
    // MARK: Lifecycle

    init(_ key: Defaults.Key<T?>) {
        self.key = key
    }

    // MARK: Internal

    let key: Defaults.Key<T?>

    var wrappedValue: String {
        let keyCombo = Defaults[key]
        if let keyCombo, keyCombo.doubledModifiers {
            return keyCombo.keyEquivalentModifierMaskString + keyCombo.keyEquivalentModifierMaskString
        }
        return (keyCombo?.keyEquivalentModifierMaskString ?? "") + (keyCombo?.keyEquivalent ?? "")
    }
}

func defaultsKey<T>(_ key: StoredKey, serviceType: ServiceType) -> Defaults.Key<T?> {
    defaultsKey(key, serviceType: serviceType, defaultValue: nil)
}

func defaultsKey<T: _DefaultsSerializable>(_ key: StoredKey, serviceType: ServiceType, defaultValue: T) -> Defaults
    .Key<T> {
    Defaults.Key<T>(
        storedKey(key, serviceType: serviceType),
        default: defaultValue
    )
}

// Service Configuration
extension Defaults.Keys {
    // DeepL
    static let deepLAuth = Key<String>(EZDeepLAuthKey, default: "")
    static let deepLTranslation = Key<DeepLAPIUsagePriority>(
        EZDeepLTranslationAPIKey,
        default: DeepLAPIUsagePriority.webFirst
    )
    static let deepLTranslateEndPointKey = Key<String>(EZDeepLTranslateEndPointKey, default: "")

    // Bing
    static let bingCookieKey = Key<String>(EZBingCookieKey, default: "")

    // niu
    static let niuTransAPIKey = Key<String>(EZNiuTransAPIKey, default: "")

    // Caiyun
    static let caiyunToken = Key<String>(EZCaiyunToken, default: "")

    // tencent
    static let tencentSecretId = Key<String>(EZTencentSecretId, default: "")
    static let tencentSecretKey = Key<String>(EZTencentSecretKey, default: "")

    // Ali
    static let aliAccessKeyId = Key<String>(EZAliAccessKeyId, default: "")
    static let aliAccessKeySecret = Key<String>(EZAliAccessKeySecret, default: "")
}

/// shortcut
extension Defaults.Keys {
    // Global
    static let selectionShortcut = Key<KeyCombo?>("EZSelectionShortcutKey_keyHolder")
    static let snipShortcut = Key<KeyCombo?>("EZSnipShortcutKey_keyHolder")
    static let inputShortcut = Key<KeyCombo?>("EZInputShortcutKey_keyHolder")
    static let screenshotOCRShortcut = Key<KeyCombo?>("EZScreenshotOCRShortcutKey_keyHolder")
    static let showMiniWindowShortcut = Key<KeyCombo?>("EZShowMiniShortcutKey_keyHolder")

    // App
    static let clearInputShortcut = Key<KeyCombo?>("EZClearInputShortcutKey_keyHolder")
    static let clearAllShortcut = Key<KeyCombo?>("EZClearAllShortcutKey_keyHolder")
    static let copyShortcut = Key<KeyCombo?>("EZCopyShortcutKey_keyHolder")
    static let copyFirstResultShortcut = Key<KeyCombo?>("EZCopyFirstResultShortcutKey_keyHolder")
    static let focusShortcut = Key<KeyCombo?>("EZFocusShortcutKey_keyHolder")
    static let playShortcut = Key<KeyCombo?>("EZPlayShortcutKey_keyHolder")
    static let retryShortcut = Key<KeyCombo?>("EZRetryShortcutKey_keyHolder")
    static let toggleShortcut = Key<KeyCombo?>("EZToggleShortcutKey_keyHolder")
    static let pinShortcut = Key<KeyCombo?>("EZPinShortcutKey_keyHolder")
    static let hideShortcut = Key<KeyCombo?>("EZHideShortcutKey_keyHolder")
    static let increaseFontSize = Key<KeyCombo?>("EZIncreaseFontSizeShortcutKey_keyHolder")
    static let decreaseFontSize = Key<KeyCombo?>("EZDecreaseFontSizeShortcutKey_keyHolder")
    static let googleShortcut = Key<KeyCombo?>("EZGoogleShortcutKey_keyHolder")
    static let eudicShortcut = Key<KeyCombo?>("EZEudicShortcutKey_keyHolder")
    static let appleDictionaryShortcut = Key<KeyCombo?>("EZAppleDictionaryShortcutKey_keyHolder")
}
