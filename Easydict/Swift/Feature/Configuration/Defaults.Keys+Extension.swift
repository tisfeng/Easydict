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
    static let clickQuery = Key<Bool>("EZConfiguration_kClickQueryKey", default: false)
    static let autoPlayAudio = Key<Bool>("EZConfiguration_kAutoPlayAudioKey", default: false)
    static let pronunciation = Key<EnglishPronunciation>(
        "EZConfiguration_kPronunciationKey",
        default: EnglishPronunciation.us
    )
    static let hideMainWindow = Key<Bool>("EZConfiguration_kHideMainWindowKey", default: true)
    static let autoQueryOCRText = Key<Bool>("EZConfiguration_kAutoQueryOCTTextKey", default: true)
    static let autoQuerySelectedText = Key<Bool>(
        "EZConfiguration_kAutoQuerySelectedTextKey", default: true
    )
    static let autoQueryPastedText = Key<Bool>(
        "EZConfiguration_kAutoQueryPastedTextKey", default: false
    )
    static let autoCopyOCRText = Key<Bool>("EZConfiguration_kAutoCopyOCRTextKey", default: false)
    static let autoCopySelectedText = Key<Bool>(
        "EZConfiguration_kAutoCopySelectedTextKey", default: false
    )
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
    static let showAppleDictionaryQuickLink = Key<Bool>(
        "EZConfiguration_kShowAppleDictionaryLinkKey", default: true
    )
    static let showQuickActionButton = Key<Bool>(
        "EZConfiguration_kShowSettingQuickLink", default: true
    )
    static let hideMenuBarIcon = Key<Bool>("EZConfiguration_kHideMenuBarIconKey", default: false)
    static let fixedWindowPosition = Key<EZShowWindowPosition>(
        "EZConfiguration_kShowFixedWindowPositionKey",
        default: .right
    )
    static let miniWindowPosition = Key<EZShowWindowPosition>(
        "EZConfiguration_kShowMiniWindowPositionKey",
        default: .mouse
    )
    static let mouseSelectTranslateWindowType = Key<EZWindowType>(
        "EZConfiguration_kMouseSelectTranslateWindowTypeKey",
        default: .fixed
    )
    static let shortcutSelectTranslateWindowType = Key<EZWindowType>(
        "EZConfiguration_kShortcutSelectTranslateWindowTypeKey",
        default: .fixed
    )
    static let pinWindowWhenDisplayed = Key<Bool>(
        "EZConfiguration_kPinWindowWhenDisplayed", default: false
    )

    static let adjustPopButtonOrigin = Key<Bool>(
        "EZConfiguration_kAdjustPopButtomOriginKey", default: false
    )
    static let allowCrashLog = Key<Bool>("EZConfiguration_kAllowCrashLogKey", default: true)
    static let allowAnalytics = Key<Bool>("EZConfiguration_kAllowAnalyticsKey", default: true)

    static let clearQueryWhenInputTranslate = Key<Bool>(
        "EZConfiguration_kClearInputKey", default: false
    )
    static let keepPrevResultWhenSelectTranslateTextIsEmpty = Key<Bool>(
        "EZConfiguration_kKeepPrevResultKey",
        default: true
    )
    static let selectQueryTextWhenWindowActivate = Key<Bool>(
        "EZConfiguration_kSelectQueryTextWhenWindowActivate",
        default: false
    )

    static let appearanceType = Key<AppearanceType>(
        "EZConfiguration_kApperanceKey", default: .followSystem
    )
    static let fontSizeOptionIndex = Key<UInt>(
        "EZConfiguration_kTranslationControllerFontKey", default: 0
    )
    static let selectedMenuBarIcon = Key<MenuBarIconType>(
        "EZConfiguration_kSelectedMenuBarIconKey", default: .square
    )

    static let automaticWordSegmentation = Key<Bool>(
        "EZConfiguration_kAutomaticWordSegmentation", default: true
    )
    static let automaticallyRemoveCodeCommentSymbols = Key<Bool>(
        "EZConfiguration_kAutomaticallyRemoveCodeCommentSymbols",
        default: true
    )
    static let replaceNewlineWithSpace = Key<Bool>(
        "EZConfiguration_kReplaceNewlineWithSpace", default: false
    )

    static let enableBetaFeature = Key<Bool>("EZBetaFeatureKey", default: false)
    static var disableTipsView = Key<Bool>("disableTipsViewKey", default: false)
    static var enableYoudaoOCR = Key<Bool>("enableYoudaoOCR", default: false)
    static var enableCompatibilityReplace = Key<Bool>(
        "replaceWithTranslationInCompatibilityMode",
        default: false
    )
    static var enableHTTPServer = Key<Bool>("enableHTTPServer", default: false)
    static var httpPort = Key<String>("httpPort", default: "8080")

    static var enableAppleOfflineTranslation = Key<Bool>(
        "enableAppleOfflineTranslation", default: false
    )
    static var enableOCRTextNormalization = Key<Bool>(
        "enableOCRTextNormalization", default: false
    )
    static var showOCRMenuItems = Key<Bool>(
        "showOCRMenuItems", default: false
    )
    /// Controls whether the screenshot tip layer is hidden during capture.
    static var isScreenshotTipLayerHidden = Key<Bool>(
        "isScreenshotTipLayerHidden", default: false
    )

    static var minClassicalChineseTextDetectLength = Key<String>(
        "minClassicalChineseTextDetectLength",
        default: "\(SharedConstants.minClassicalChineseLength)"
    )

    static let enableForceGetSelectedText = Key<Bool>(
        "EZConfiguration_kForceAutoGetSelectedText",
        default: true
    )
    static var forceGetSelectedTextType = Key<ForceGetSelectedTextType>(
        "EZConfiguration_kForceGetSelectedTextTypeKey",
        default: .menuBarActionCopy
    )

    static let autoSelectAllTextFieldText = Key<Bool>(
        "EZConfiguration_kAutoSelectAllTextFieldText",
        default: true
    )

    static let preferAppleScriptAPI = Key<Bool>(
        "EZConfiguration_kPreferAppleScriptAPI",
        default: true
    )

    /// Cannot use NSScreen, so we use CGRect to record the screen visible frame for EZShowWindowPositionFormer
    static var formerFixedScreenVisibleFrame = Key<CGRect>(
        "EZConfiguration_kScreenVisibleFrameKey", default: .zero
    )

    static var formerMiniScreenVisibleFrame = Key<CGRect>(
        "EZConfiguration_kFormerMiniScreenVisibleFrameKey",
        default: .zero
    )

    // MARK: - Window Height Limit

    // Key for storing the selected max window height percentage, default is 100%.
    // Storing as Int (e.g., 50, 80, 100).
    static let maxWindowHeightPercentage = Key<Int>("maxWindowHeightPercentage", default: 100)

    // MARK: - Favorites and History

    static let favorites = Key<[QueryRecord]>("EZConfiguration_kFavorites", default: [])
    static let queryHistory = Key<[QueryRecord]>("EZConfiguration_kQueryHistory", default: [])
}

extension Defaults.Keys {
    static func intelligentQueryTextType(for serviceType: ServiceType) -> Key<EZQueryTextType> {
        let key = EZConstKey.constkey("IntelligentQueryTextType", serviceType: serviceType)
        return .init(key, default: EZQueryTextType(rawValue: 7))
    }

    static func queryTextType(for serviceType: ServiceType) -> Key<EZQueryTextType> {
        let key = EZConstKey.constkey("QueryTextType", serviceType: serviceType)
        return .init(key, default: EZQueryTextType(rawValue: 1))
    }

    static func windowFrame(for windowType: EZWindowType) -> Key<CGRect> {
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
        }
        set {
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
            return keyCombo.keyEquivalentModifierMaskString
                + keyCombo.keyEquivalentModifierMaskString
        }
        return (keyCombo?.keyEquivalentModifierMaskString ?? "") + (keyCombo?.keyEquivalent ?? "")
    }
}

private let EZDeepLTranslationAPIKey = "EZDeepLTranslationAPIKey"

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
    static let aliServiceApiTypeKey = Key<ServiceAPIType>(
        EZAliServiceApiTypeKey, default: .secretKey
    )

    // baidu
    static let baiduAppId = Key<String>(EZBaiduAppId, default: "")
    static let baiduSecretKey = Key<String>(EZBaiduSecretKey, default: "")
    static let baiduServiceApiTypeKey = Key<ServiceAPIType>(
        EZBaiduServiceApiTypeKey, default: .secretKey
    )

    // Volcano
    static let volcanoAccessKeyID = Key<String>(EZVolcanoAccessKeyID, default: "")
    static let volcanoSecretAccessKey = Key<String>(EZVolcanoSecretAccessKey, default: "")

    // Doubao
    static let doubaoAPIKey = Key<String>(EZDoubaoAPIKey, default: "")
    static let doubaoModel = Key<String>(EZDoubaoModelKey, default: DoubaoService.defaultModelIdentifier)
}

/// shortcut
extension Defaults.Keys {
    // Global
    static let selectionShortcut = Key<KeyCombo?>("EZSelectionShortcutKey_keyHolder")
    static let snipShortcut = Key<KeyCombo?>("EZSnipShortcutKey_keyHolder")
    static let inputShortcut = Key<KeyCombo?>("EZInputShortcutKey_keyHolder")
    // Note: This key value is not suitable for renaming, because it is used in old versions.
    static let silentScreenshotOCRShortcut = Key<KeyCombo?>("EZScreenshotOCRShortcutKey_keyHolder")
    static let showMiniWindowShortcut = Key<KeyCombo?>("EZShowMiniShortcutKey_keyHolder")
    static let pasteboardTranslateShortcut = Key<KeyCombo?>(
        "EZPasteboardTranslateShortcutKey_keyHolder"
    )
    static let translateAndReplaceShortcut = Key<KeyCombo?>(
        "EZTranslateAndReplaceShortcutKey_keyHolder"
    )
    static let polishAndReplaceShortcut = Key<KeyCombo?>(
        "EZPolishAndReplaceShortcutKey_keyHolder"
    )

    static let screenshotOCRShortcut = Key<KeyCombo?>("EZScreenshotOCRShortcutKey2_keyHolder")
    static let pasteboardOCRShortcut = Key<KeyCombo?>("EZPasteboardOCRShortcutKey_keyHolder")
    static let showOCRWindowShortcut = Key<KeyCombo?>("EZShowOCRWindowShortcutKey_keyHolder")

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
