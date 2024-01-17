//
//  Configuration.swift
//  Easydict
//
//  Created by 戴藏龙 on 2024/1/12.
//  Copyright © 2024 izual. All rights reserved.
//

import Defaults
import Foundation

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
    static let languageDetectOptimize = Key<EZLanguageDetectOptimize>("EZConfiguration_kLanguageDetectOptimizeTypeKey", default: EZLanguageDetectOptimize.none)
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
    static let enableBetaNewApp = Key<Bool>("EZConfiguration_kEnableBetaNewAppKey", default: false)

    static let enableBetaFeature = Key<Bool>("EZBetaFeatureKey", default: false)

    static let appearanceType = Key<AppearenceType>("EZConfiguration_kApperanceKey", default: .followSystem)
    static let fontSizeOptionIndex = Key<UInt>("EZConfiguration_kTranslationControllerFontKey", default: 0)
}

// Service Configuration
extension Defaults.Keys {
    // OPENAI
    static let openAIAPIKey = Key<String?>("EZOpenAIAPIKey")
    static let openAITranslation = Key<String?>("EZOpenAITranslationKey")
    static let openAIDictionary = Key<String?>("EZOpenAIDictionaryKey")
    static let openAISentence = Key<String?>("EZOpenAISentenceKey")
    static let openAIServiceUsageStatus = Key<String?>("EZOpenAIServiceUsageStatusKey")
    static let openAIDomain = Key<String?>("EZOpenAIDomainKey")
    static let openAIEndPoint = Key<String?>("EZOpenAIEndPointKey")
    static let openAIModel = Key<String?>("EZOpenAIModelKey")

    // DEEPL
    static let deepLAuth = Key<String?>("EZDeepLAuthKey")
    static let deepLTranslateEndPointKey = Key<String?>("EZDeepLTranslateEndPointKey")

    // BING
    static let bingCookieKey = Key<String?>("EZBingCookieKey")

    // niu
    static let niuTransAPIKey = Key<String?>("EZNiuTransAPIKey")

    // Caiyun
    static let caiyunToken = Key<String?>("EZCaiyunToken")

    // tencent
    static let tencentSecretId = Key<String?>("EZTencentSecretId")
    static let tencentSecretKey = Key<String?>("EZTencentSecretKey")

    // ALI
    static let aliAccessKeyId = Key<String?>("EZAliAccessKeyId")
    static let aliAccessKeySecret = Key<String?>("EZAliAccessKeySecret")
}
