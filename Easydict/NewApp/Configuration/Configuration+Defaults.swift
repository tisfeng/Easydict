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

// Setting
extension Defaults.Keys {
    // rename `from`
    static let queryFromLanguage = Key<Language>("EZConfiguration_kFromKey", default: .auto)
    // rename `to`
    static let queryToLanguage = Key<Language>("EZConfiguration_kToKey", default: .auto)

    static let firstLanguage = Key<Language>("EZConfiguration_kFirstLanguageKey", default: EZLanguageManager.shared().systemPreferredTwoLanguages[0])
    static let secondLanguage = Key<Language>("EZConfiguration_kSecondLanguageKey", default: EZLanguageManager.shared().systemPreferredTwoLanguages[1])

    static let autoSelectText = Key<Bool>("EZConfiguration_kAutoSelectTextKey", default: true)
    static let forceAutoGetSelectedText = Key<Bool>("EZConfiguration_kForceAutoGetSelectedText", default: false)

    static let disableEmptyCopyBeep = Key<Bool>("EZConfiguration_kDisableEmptyCopyBeepKey", default: true)
    static let clickQuery = Key<Bool>("EZConfiguration_kClickQueryKey", default: false)
    static let autoPlayAudio = Key<Bool>("EZConfiguration_kAutoPlayAudioKey", default: true)
    static let launchAtStartup = Key<Bool>("EZConfiguration_kLaunchAtStartupKey", default: false)
    static let hideMainWindow = Key<Bool>("EZConfiguration_kHideMainWindowKey", default: true)
    static let autoQueryOCRText = Key<Bool>("EZConfiguration_kAutoQueryOCTTextKey", default: true)
    static let autoQuerySelectedText = Key<Bool>("EZConfiguration_kAutoQuerySelectedTextKey", default: true)
    static let autoQueryPastedText = Key<Bool>("EZConfiguration_kAutoQueryPastedTextKey", default: false)
    static let autoCopyOCRText = Key<Bool>("EZConfiguration_kAutoCopyOCRTextKey", default: false)
    static let autoCopySelectedText = Key<Bool>("EZConfiguration_kAutoCopySelectedTextKey", default: false)
    static let autoCopyFirstTranslatedText = Key<Bool>("EZConfiguration_kAutoCopyFirstTranslatedTextKey", default: false)
    static let languageDetectOptimize = Key<LanguageDetectOptimize>("EZConfiguration_kLanguageDetectOptimizeTypeKey", default: LanguageDetectOptimize.none)
    static let defaultTTSServiceType = Key<TTSServiceType>("EZConfiguration_kDefaultTTSServiceTypeKey", default: TTSServiceType.youdao)
    static let showGoogleQuickLink = Key<Bool>("EZConfiguration_kShowGoogleLinkKey", default: true)
    static let showEudicQuickLink = Key<Bool>("EZConfiguration_kShowEudicLinkKey", default: true)
    static let showAppleDictionaryQuickLink = Key<Bool>("EZConfiguration_kShowAppleDictionaryLinkKey", default: true)
    static let hideMenuBarIcon = Key<Bool>("EZConfiguration_kHideMenuBarIconKey", default: false)
    static let fixedWindowPosition = Key<EZShowWindowPosition>("EZConfiguration_kShowFixedWindowPositionKey", default: .right)
    static let mouseSelectTranslateWindowType = Key<EZWindowType>("EZConfiguration_kMouseSelectTranslateWindowTypeKey", default: .mini)
    static let shortcutSelectTranslateWindowType = Key<EZWindowType>("EZConfiguration_kShortcutSelectTranslateWindowTypeKey", default: .fixed)
    static let adjustPopButtonOrigin = Key<Bool>("EZConfiguration_kAdjustPopButtomOriginKey", default: false)
    static let allowCrashLog = Key<Bool>("EZConfiguration_kAllowCrashLogKey", default: true)
    static let allowAnalytics = Key<Bool>("EZConfiguration_kAllowAnalyticsKey", default: true)
    static let clearInput = Key<Bool>("EZConfiguration_kClearInputKey", default: true)
    static let keepPrevResultWhenEmpty = Key<Bool>("EZConfiguration_kKeepPrevResultKey", default: true)
    static let selectQueryTextWhenWindowActivate = Key<Bool>("EZConfiguration_kSelectQueryTextWhenWindowActivate", default: false)
    static let enableBetaNewApp = Key<Bool>("EZConfiguration_kEnableBetaNewAppKey", default: false)

    static let enableBetaFeature = Key<Bool>("EZBetaFeatureKey", default: false)

    static let appearanceType = Key<AppearenceType>("EZConfiguration_kApperanceKey", default: .followSystem)
    static let fontSizeOptionIndex = Key<UInt>("EZConfiguration_kTranslationControllerFontKey", default: 0)
    static let selectedMenuBarIcon = Key<MenuBarIconType>("EZConfiguration_kSelectedMenuBarIconKey", default: .square)
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

extension EZQueryTextType: Defaults.Serializable {
    public static var bridge: Bridge = .init()

    public struct Bridge: Defaults.Bridge {
        public func serialize(_ value: EZQueryTextType?) -> String? {
            guard let value else { return "7" }
            return "\(value.rawValue)"
        }

        public func deserialize(_ object: String?) -> EZQueryTextType? {
            guard let object else { return nil }
            return EZQueryTextType(rawValue: UInt(object) ?? 7)
        }

        public typealias Value = EZQueryTextType

        public typealias Serializable = String
    }
}

extension CGRect: Defaults.Serializable {
    public static var bridge: Bridge = .init()

    public struct Bridge: Defaults.Bridge {
        public func serialize(_ value: CGRect?) -> String? {
            let value = value ?? .zero
            return NSStringFromRect(value)
        }

        public func deserialize(_ object: String?) -> CGRect? {
            guard let object else { return nil }
            return NSRectFromString(object)
        }

        public typealias Value = CGRect

        public typealias Serializable = String
    }
}

@propertyWrapper
class DefaultsWrapper<T: Defaults.Serializable> {
    var wrappedValue: T {
        get {
            Defaults[key]
        } set {
            Defaults[key] = newValue
        }
    }

    init(_ key: Defaults.Key<T>) {
        self.key = key
    }

    let key: Defaults.Key<T>
}

// Service Configuration
extension Defaults.Keys {
    // OpenAI
    static let openAIAPIKey = Key<String?>("EZOpenAIAPIKey")
    static let openAITranslation = Key<String>("EZOpenAITranslationKey", default: "1")
    static let openAIDictionary = Key<String>("EZOpenAIDictionaryKey", default: "1")
    static let openAISentence = Key<String>("EZOpenAISentenceKey", default: "1")
    static let openAIServiceUsageStatus = Key<OpenAIUsageStats>("EZOpenAIServiceUsageStatusKey", default: OpenAIUsageStats.default)
    static let openAIEndPoint = Key<String?>("EZOpenAIEndPointKey")
    static let openAIModel = Key<OpenAIModels>("EZOpenAIModelKey", default: OpenAIModels.gpt3_5_turbo_0125)

    // DeepL
    static let deepLAuth = Key<String?>("EZDeepLAuthKey")
    static let deepLTranslation = Key<DeepLAPIUsagePriority>("EZDeepLTranslationAPIKey", default: DeepLAPIUsagePriority.webFirst)
    static let deepLTranslateEndPointKey = Key<String?>("EZDeepLTranslateEndPointKey")

    // Bing
    static let bingCookieKey = Key<String?>("EZBingCookieKey")

    // niu
    static let niuTransAPIKey = Key<String?>("EZNiuTransAPIKey")

    // Caiyun
    static let caiyunToken = Key<String?>("EZCaiyunToken")

    // tencent
    static let tencentSecretId = Key<String?>("EZTencentSecretId")
    static let tencentSecretKey = Key<String?>("EZTencentSecretKey")

    // Ali
    static let aliAccessKeyId = Key<String?>("EZAliAccessKeyId")
    static let aliAccessKeySecret = Key<String?>("EZAliAccessKeySecret")

    // Gemni
    static let geminiAPIKey = Key<String?>("EZGeminiAPIKey")
}

/// shortcut
extension Defaults.Keys {
    // Global
    static let selectionShortcut = Key<KeyCombo?>("EZSelectionShortcutKey_keyHolder", default: KeyCombo(key: .d, cocoaModifiers: .option))
    static let snipShortcut = Key<KeyCombo?>("EZSnipShortcutKey_keyHolder", default: KeyCombo(key: .s, cocoaModifiers: .option))
    static let inputShortcut = Key<KeyCombo?>("EZInputShortcutKey_keyHolder", default: KeyCombo(key: .a, cocoaModifiers: .option))
    static let screenshotOCRShortcut = Key<KeyCombo?>("EZScreenshotOCRShortcutKey_keyHolder", default: KeyCombo(key: .f, cocoaModifiers: [.option, .shift]))
    static let showMiniWindowShortcut = Key<KeyCombo?>("EZShowMiniShortcutKey_keyHolder", default: KeyCombo(key: .s, cocoaModifiers: .option))

    // App
    static let clearInputShortcut = Key<KeyCombo?>("EZClearInputShortcutKey_keyHolder", default: KeyCombo(key: .k, cocoaModifiers: .command))
    static let clearAllShortcut = Key<KeyCombo?>("EZClearAllShortcutKey_keyHolder", default: KeyCombo(key: .k, cocoaModifiers: [.command, .shift]))
    static let copyShortcut = Key<KeyCombo?>("EZCopyShortcutKey_keyHolder", default: KeyCombo(key: .c, cocoaModifiers: [.command, .shift]))
    static let copyFirstResultShortcut = Key<KeyCombo?>("EZCopyFirstResultShortcutKey_keyHolder", default: KeyCombo(key: .j, cocoaModifiers: [.command, .shift]))
    static let focusShortcut = Key<KeyCombo?>("EZFocusShortcutKey_keyHolder", default: KeyCombo(key: .i, cocoaModifiers: .command))
    static let playShortcut = Key<KeyCombo?>("EZPlayShortcutKey_keyHolder", default: KeyCombo(key: .s, cocoaModifiers: .command))
    static let retryShortcut = Key<KeyCombo?>("EZRetryShortcutKey_keyHolder", default: KeyCombo(key: .r, cocoaModifiers: .command))
    static let toggleShortcut = Key<KeyCombo?>("EZToggleShortcutKey_keyHolder", default: KeyCombo(key: .t, cocoaModifiers: .command))
    static let pinShortcut = Key<KeyCombo?>("EZPinShortcutKey_keyHolder", default: KeyCombo(key: .p, cocoaModifiers: .command))
    static let hideShortcut = Key<KeyCombo?>("EZHideShortcutKey_keyHolder", default: KeyCombo(key: .y, cocoaModifiers: .command))
    static let increaseFontSize = Key<KeyCombo?>("EZIncreaseFontSizeShortcutKey_keyHolder", default: KeyCombo(key: .keypadPlus, cocoaModifiers: .command))
    static let decreaseFontSize = Key<KeyCombo?>("EZDecreaseFontSizeShortcutKey_keyHolder", default: KeyCombo(key: .keypadMinus, cocoaModifiers: .command))
    static let googleShortcut = Key<KeyCombo?>("EZGoogleShortcutKey_keyHolder", default: KeyCombo(key: .return, cocoaModifiers: .command))
    static let eudicShortcut = Key<KeyCombo?>("EZEudicShortcutKey_keyHolder", default: KeyCombo(key: .return, cocoaModifiers: [.command, .shift]))
    static let appleDictionaryShortcut = Key<KeyCombo?>("EZAppleDictionaryShortcutKey_keyHolder", default: KeyCombo(key: .d, cocoaModifiers: [.command, .shift]))
}
