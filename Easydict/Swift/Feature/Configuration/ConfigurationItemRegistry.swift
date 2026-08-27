//
//  ConfigurationItemRegistry.swift
//  Easydict
//
//  Created by Eric Pan on 2026/8/26.
//  Copyright © 2026 izual. All rights reserved.
//

import CoreFoundation
import Foundation

// MARK: - ConfigurationItemCategory

enum ConfigurationItemCategory: String, Codable {
    case portableSetting
    case serviceCredential
    case excludedContent
    case excludedRuntime
    case unsupported
}

// MARK: - ConfigurationValueKind

enum ConfigurationValueKind: String, Codable, Hashable {
    case string
    case boolean
    case integer
    case real
    case date
    case data
    case array
    case dictionary

    // MARK: Internal

    static func detect(_ value: Any) -> ConfigurationValueKind? {
        if let number = value as? NSNumber {
            if CFGetTypeID(number) == CFBooleanGetTypeID() {
                return .boolean
            }
            let integerEncodings = Set(["c", "i", "s", "l", "q", "C", "I", "S", "L", "Q"])
            return integerEncodings.contains(String(cString: number.objCType)) ? .integer : .real
        }
        return switch value {
        case is String: .string
        case is Date: .date
        case is Data: .data
        case is [Any]: .array
        case is [String: Any]: .dictionary
        default: nil
        }
    }
}

// MARK: - ConfigurationItemDescriptor

/// Stable semantic identity used inside encrypted backups instead of a raw defaults key.
struct ConfigurationItemDescriptor: Codable, Hashable {
    // MARK: Lifecycle

    init(name: String, qualifiers: [String: String] = [:]) {
        self.name = name
        self.qualifiers = qualifiers
    }

    // MARK: Internal

    let name: String
    let qualifiers: [String: String]
}

// MARK: - ConfigurationRegistryEntry

struct ConfigurationRegistryEntry {
    let descriptor: ConfigurationItemDescriptor
    let userDefaultsKey: String
    let category: ConfigurationItemCategory
    let allowedValueKinds: Set<ConfigurationValueKind>
    let isEndpoint: Bool
    let isSchemeAutomatable: Bool

    func accepts(_ value: Any) -> Bool {
        guard let kind = ConfigurationValueKind.detect(value) else { return false }
        return allowedValueKinds.contains(kind)
    }
}

// MARK: - ConfigurationItemRegistry

/// Central fail-closed inventory for configuration export, restore, and URL Scheme access.
enum ConfigurationItemRegistry {
    // MARK: Internal

    static func category(forUserDefaultsKey key: String) -> ConfigurationItemCategory {
        if let entry = entry(forUserDefaultsKey: key) {
            return entry.category
        }
        if excludedContentKeys.contains(key) || key.localizedCaseInsensitiveContains("history") ||
            key.localizedCaseInsensitiveContains("favorite") {
            return .excludedContent
        }
        if excludedRuntimePrefixes.contains(where: key.hasPrefix) ||
            excludedRuntimeKeys.contains(key) {
            return .excludedRuntime
        }
        return .unsupported
    }

    static func entry(forUserDefaultsKey key: String) -> ConfigurationRegistryEntry? {
        if let entry = staticEntriesByKey[key] {
            return entry
        }
        if let entry = serviceConfigurationEntry(forKey: key) {
            return entry
        }
        if let entry = queryConfigurationEntry(forKey: key) {
            return entry
        }
        if let entry = serviceStorageEntry(forKey: key) {
            return entry
        }
        return nil
    }

    static func entry(for descriptor: ConfigurationItemDescriptor) -> ConfigurationRegistryEntry? {
        if let entry = staticEntriesByDescriptor[descriptor] {
            return entry
        }
        switch descriptor.name {
        case Descriptor.serviceConfiguration:
            return serviceConfigurationEntry(for: descriptor)
        case Descriptor.intelligentQueryMode, Descriptor.serviceQueryType:
            return queryConfigurationEntry(for: descriptor)
        case Descriptor.serviceInstance, Descriptor.serviceOrder:
            return serviceStorageEntry(for: descriptor)
        default:
            return nil
        }
    }

    static func isSensitiveKey(_ key: String) -> Bool {
        entry(forUserDefaultsKey: key)?.category == .serviceCredential
    }

    static func isEndpointKey(_ key: String) -> Bool {
        entry(forUserDefaultsKey: key)?.isEndpoint == true
    }

    static func isSchemeAutomatableKey(_ key: String) -> Bool {
        guard let entry = entry(forUserDefaultsKey: key) else { return false }
        return entry.category == .portableSetting && entry.isSchemeAutomatable
    }

    /// Converts an untrusted URL query string into the exact property-list type registered for
    /// that setting. Collection-valued settings stay unavailable because the scheme has no
    /// structured value format.
    static func schemeValue(forKey key: String, rawValue: String) -> Any? {
        guard let entry = entry(forUserDefaultsKey: key),
              entry.category == .portableSetting, entry.isSchemeAutomatable
        else { return nil }

        if entry.allowedValueKinds.contains(.string) {
            return rawValue
        }
        if entry.allowedValueKinds == [.boolean] {
            switch rawValue.lowercased() {
            case "1", "true", "yes":
                return NSNumber(value: true)
            case "0", "false", "no":
                return NSNumber(value: false)
            default:
                return nil
            }
        }
        if entry.allowedValueKinds.contains(.integer), let integer = Int64(rawValue) {
            return NSNumber(value: integer)
        }
        if entry.allowedValueKinds.contains(.real), let real = Double(rawValue), real.isFinite {
            return NSNumber(value: real)
        }
        return nil
    }

    // MARK: Private

    private enum Descriptor {
        static let serviceConfiguration = "service.configuration"
        static let intelligentQueryMode = "query.intelligent-mode"
        static let serviceQueryType = "query.service-text-type"
        static let serviceOrder = "service.order"
        static let serviceInstance = "service.instance"
    }

    private static let staticEntries: [ConfigurationRegistryEntry] = {
        var entries = [ConfigurationRegistryEntry]()

        func add(
            _ key: String,
            _ descriptor: String,
            _ kinds: Set<ConfigurationValueKind>,
            category: ConfigurationItemCategory = .portableSetting,
            endpoint: Bool = false,
            scheme: Bool = false
        ) {
            entries.append(
                ConfigurationRegistryEntry(
                    descriptor: .init(name: descriptor),
                    userDefaultsKey: key,
                    category: category,
                    allowedValueKinds: kinds,
                    isEndpoint: endpoint,
                    isSchemeAutomatable: scheme
                )
            )
        }

        let string: Set<ConfigurationValueKind> = [.string]
        let boolean: Set<ConfigurationValueKind> = [.boolean]
        let integer: Set<ConfigurationValueKind> = [.integer]

        for (key, descriptor) in credentialKeys {
            add(key, descriptor, string, category: .serviceCredential)
        }

        add("EZDeepLTranslateEndPointKey", "service.deepl.endpoint", string, endpoint: true)
        add("EZDeepLTranslationAPIKey", "service.deepl.priority", string, scheme: true)
        add("EZAliServiceApiTypeKey", "service.alibaba.api-type", string)
        add("EZBaiduServiceApiTypeKey", "service.baidu.api-type", string)
        add("EZDoubaoModelKey", "service.doubao.model", string)
        add("kAppModelTriggerListKey", "setting.disabled-apps", [.array])

        for (key, descriptor) in boolSettings {
            add(key, "setting.\(descriptor)", boolean, scheme: key == "EZBetaFeatureKey")
        }
        for (key, descriptor) in stringSettings {
            add(key, "setting.\(descriptor)", string)
        }
        for (key, descriptor) in integerSettings {
            add(key, "setting.\(descriptor)", integer)
        }
        for (key, descriptor) in shortcutSettings {
            add(key, "shortcut.\(descriptor)", [.data])
        }
        return entries
    }()

    private static let staticEntriesByKey = Dictionary(
        uniqueKeysWithValues: staticEntries.map { ($0.userDefaultsKey, $0) }
    )
    private static let staticEntriesByDescriptor = Dictionary(
        uniqueKeysWithValues: staticEntries.map { ($0.descriptor, $0) }
    )

    private static let credentialKeys = [
        ("EZDeepLAuthKey", "credential.deepl.auth"),
        ("EZBingCookieKey", "credential.bing.cookie"),
        ("EZNiuTransAPIKey", "credential.niutrans.api-key"),
        ("EZCaiyunToken", "credential.caiyun.token"),
        ("EZTencentSecretId", "credential.tencent.secret-id"),
        ("EZTencentSecretKey", "credential.tencent.secret-key"),
        ("EZGeminiAPIKey", "credential.gemini.api-key"),
        ("EZAliAccessKeyId", "credential.alibaba.access-key-id"),
        ("EZAliAccessKeySecret", "credential.alibaba.access-key-secret"),
        ("EZBaiduAppId", "credential.baidu.app-id"),
        ("EZBaiduSecretKey", "credential.baidu.secret-key"),
        ("EZVolcanoAccessKeyID", "credential.volcano.access-key-id"),
        ("EZVolcanoSecretAccessKey", "credential.volcano.secret-access-key"),
        ("EZDoubaoAPIKey", "credential.doubao.api-key"),
    ]

    private static let boolSettings = [
        ("EZBetaFeatureKey", "beta-features"),
        ("EZConfiguration_kAutoSelectTextKey", "auto-show-query-icon"),
        ("EZConfiguration_kClickQueryKey", "click-query"),
        ("EZConfiguration_kAutoPlayAudioKey", "auto-play-audio"),
        ("EZConfiguration_kHideMainWindowKey", "hide-main-window"),
        ("EZConfiguration_kAutoQueryOCTTextKey", "auto-query-ocr"),
        ("EZConfiguration_kAutoQuerySelectedTextKey", "auto-query-selection"),
        ("EZConfiguration_kAutoQueryPastedTextKey", "auto-query-paste"),
        ("EZConfiguration_kAutoQueryWhenTextChangedKey", "auto-query-input"),
        ("EZConfiguration_kAutoCopyOCRTextKey", "auto-copy-ocr"),
        ("EZConfiguration_kAutoCopySelectedTextKey", "auto-copy-selection"),
        ("EZConfiguration_kAutoCopyFirstTranslatedTextKey", "auto-copy-first-result"),
        ("EZConfiguration_kPreferYoudaoTTSForEnglishWordKey", "prefer-youdao-tts-for-english"),
        ("EZConfiguration_kShowGoogleLinkKey", "show-google-link"),
        ("EZConfiguration_kShowEudicLinkKey", "show-eudic-link"),
        ("EZConfiguration_kShowAppleDictionaryLinkKey", "show-apple-dictionary-link"),
        ("EZConfiguration_kShowSettingQuickLink", "show-quick-actions"),
        ("EZConfiguration_kHideMenuBarIconKey", "hide-menu-bar-icon"),
        ("EZConfiguration_kIncludeBetaUpdatesKey", "include-beta-updates"),
        ("EZConfiguration_kPinWindowWhenDisplayed", "pin-window"),
        ("EZConfiguration_kAllowCrashLogKey", "allow-crash-log"),
        ("EZConfiguration_kAllowAnalyticsKey", "allow-analytics"),
        ("EZConfiguration_kClearInputKey", "clear-input-before-query"),
        ("EZConfiguration_kKeepPrevResultKey", "keep-previous-result"),
        ("EZConfiguration_kSelectQueryTextWhenWindowActivate", "select-query-on-activate"),
        ("EZConfiguration_kAutomaticWordSegmentation", "automatic-word-segmentation"),
        ("EZConfiguration_kAutomaticallyRemoveCodeCommentSymbols", "remove-code-comment-symbols"),
        ("EZConfiguration_kReplaceNewlineWithSpace", "replace-newline-with-space"),
        ("disableTipsViewKey", "disable-tips"),
        ("enableYoudaoOCR", "enable-youdao-ocr"),
        ("replaceWithTranslationInCompatibilityMode", "compatibility-replace"),
        ("enableHTTPServer", "enable-http-server"),
        ("enableAppleOfflineTranslation", "enable-apple-offline-translation"),
        ("enableOCRTextNormalization", "enable-ocr-normalization"),
        ("showOCRMenuItems", "show-ocr-menu-items"),
        ("isScreenshotTipLayerHidden", "hide-screenshot-tip-layer"),
        ("EZConfiguration_kForceAutoGetSelectedText", "force-get-selected-text"),
        ("EZConfiguration_kEnableRemoveBooksExcerptInfo", "remove-books-excerpt-info"),
        ("EZConfiguration_kEnableMarkdownRendering", "enable-markdown-rendering"),
        ("EZConfiguration_kAutoSelectAllTextFieldText", "auto-select-input"),
        ("EZConfiguration_kPreferAppleScriptAPI", "prefer-applescript-api"),
    ]

    private static let stringSettings = [
        ("EZConfiguration_kFromKey", "query-source-language"),
        ("EZConfiguration_kToKey", "query-target-language"),
        ("EZConfiguration_kFirstLanguageKey", "first-language"),
        ("EZConfiguration_kSecondLanguageKey", "second-language"),
        ("EZConfiguration_kAutoShowQueryIconExcludedLanguageKey", "auto-show-excluded-language"),
        ("EZConfiguration_kDefaultTTSServiceTypeKey", "default-tts-service"),
        ("EZConfiguration_kSelectedMenuBarIconKey", "menu-bar-icon"),
        ("translateAndReplaceServiceIdentifier", "translate-replace-service"),
        ("polishAndReplaceServiceIdentifier", "polish-replace-service"),
        ("translateAndReplaceAdditionalPrompt", "translate-replace-prompt"),
        ("polishAndReplaceAdditionalPrompt", "polish-replace-prompt"),
        ("httpPort", "http-server-port"),
        ("minClassicalChineseTextDetectLength", "classical-chinese-min-length"),
    ]

    private static let integerSettings = [
        ("EZConfiguration_kAutoShowQueryIconMinTextLengthKey", "auto-show-min-length"),
        ("EZConfiguration_kPronunciationKey", "pronunciation"),
        ("EZConfiguration_kLanguageDetectOptimizeTypeKey", "language-detect-optimization"),
        ("EZConfiguration_kShowFixedWindowPositionKey", "fixed-window-position"),
        ("EZConfiguration_kShowMiniWindowPositionKey", "mini-window-position"),
        ("EZConfiguration_kMouseSelectTranslateWindowTypeKey", "mouse-window-type"),
        ("EZConfiguration_kShortcutSelectTranslateWindowTypeKey", "shortcut-window-type"),
        ("EZConfiguration_kApperanceKey", "appearance"),
        ("EZConfiguration_kTranslationControllerFontKey", "font-size-option"),
        ("EZConfiguration_kForceGetSelectedTextTypeKey", "force-get-selection-strategy"),
        ("maxWindowHeightPercentage", "max-window-height-percentage"),
    ]

    private static let shortcutSettings = [
        ("EZSelectionShortcutKey_keyHolder", "selection"),
        ("EZToggleAutoSelectTextShortcutKey_keyHolder", "toggle-selection"),
        ("EZSnipShortcutKey_keyHolder", "screenshot"),
        ("EZInputShortcutKey_keyHolder", "input"),
        ("EZScreenshotOCRShortcutKey_keyHolder", "silent-screenshot-ocr"),
        ("EZShowMiniShortcutKey_keyHolder", "mini-window"),
        ("EZPasteboardTranslateShortcutKey_keyHolder", "pasteboard-translate"),
        ("EZTranslateAndReplaceShortcutKey_keyHolder", "translate-replace"),
        ("EZPolishAndReplaceShortcutKey_keyHolder", "polish-replace"),
        ("EZScreenshotOCRShortcutKey2_keyHolder", "screenshot-ocr"),
        ("EZPasteboardOCRShortcutKey_keyHolder", "pasteboard-ocr"),
        ("EZShowOCRWindowShortcutKey_keyHolder", "ocr-window"),
        ("EZClearInputShortcutKey_keyHolder", "clear-input"),
        ("EZClearAllShortcutKey_keyHolder", "clear-all"),
        ("EZCopyShortcutKey_keyHolder", "copy"),
        ("EZCopyFirstResultShortcutKey_keyHolder", "copy-first-result"),
        ("EZFocusShortcutKey_keyHolder", "focus"),
        ("EZPlayShortcutKey_keyHolder", "play"),
        ("EZRetryShortcutKey_keyHolder", "retry"),
        ("EZToggleShortcutKey_keyHolder", "toggle"),
        ("EZPinShortcutKey_keyHolder", "pin"),
        ("EZHideShortcutKey_keyHolder", "hide"),
        ("EZIncreaseFontSizeShortcutKey_keyHolder", "increase-font"),
        ("EZDecreaseFontSizeShortcutKey_keyHolder", "decrease-font"),
        ("EZGoogleShortcutKey_keyHolder", "google"),
        ("EZEudicShortcutKey_keyHolder", "eudic"),
        ("EZAppleDictionaryShortcutKey_keyHolder", "apple-dictionary"),
    ]

    private static let excludedContentKeys = Set([
        "EZConfiguration_kFavorites",
        "EZConfiguration_kQueryHistory",
    ])
    private static let excludedRuntimeKeys = Set([
        "EZConfiguration_kFirstLaunch",
        "EZConfiguration_kScreenVisibleFrameKey",
        "EZConfiguration_kFormerMiniScreenVisibleFrameKey",
    ])
    private static let excludedRuntimePrefixes = [
        "MASPreferences", "NSWindow Frame", "NSStatusItem", "SU", "SKPurchase",
        "easydict.screenshot.", "kQueryCountKey", "kQueryCharacterCountKey",
        "kQueryServiceRecordKey", "kBingConfigKey",
    ]

    private static var serviceTypeIDs: [String] {
        QueryServiceFactory.shared.allServiceTypeIDs.sorted { $0.count > $1.count }
    }

    private static func serviceConfigurationEntry(forKey key: String) -> ConfigurationRegistryEntry? {
        guard key.hasPrefix("EZ"), key.hasSuffix("Key") else { return nil }

        for service in serviceTypeIDs {
            let prefix = "EZ\(service)"
            guard key.hasPrefix(prefix) else { continue }
            let body = String(key.dropFirst(prefix.count).dropLast(3))
            for field in ServiceConfigurationKey.allCases.sorted(by: { $0.storageStem.count > $1.storageStem.count }) {
                guard let uuid = field.uuid(inStorageBody: body) else { continue }
                return makeServiceConfigurationEntry(service: service, field: field, uuid: uuid)
            }
        }
        return nil
    }

    private static func serviceConfigurationEntry(
        for descriptor: ConfigurationItemDescriptor
    )
        -> ConfigurationRegistryEntry? {
        guard descriptor.name == Descriptor.serviceConfiguration,
              let service = descriptor.qualifiers["service"], serviceTypeIDs.contains(service),
              let fieldName = descriptor.qualifiers["field"],
              let field = ServiceConfigurationKey(rawValue: fieldName)
        else { return nil }

        let uuid = descriptor.qualifiers["uuid"] ?? ""
        let expectedKeys = uuid.isEmpty ? Set(["service", "field"]) : Set(["service", "field", "uuid"])
        guard Set(descriptor.qualifiers.keys) == expectedKeys,
              uuid.isEmpty || UUID(uuidString: uuid) != nil
        else { return nil }
        return makeServiceConfigurationEntry(service: service, field: field, uuid: uuid)
    }

    private static func makeServiceConfigurationEntry(
        service: String,
        field: ServiceConfigurationKey,
        uuid: String
    )
        -> ConfigurationRegistryEntry {
        var qualifiers = ["service": service, "field": field.rawValue]
        if !uuid.isEmpty { qualifiers["uuid"] = uuid }
        let category: ConfigurationItemCategory = field == .apiKey ? .serviceCredential : .portableSetting
        return ConfigurationRegistryEntry(
            descriptor: .init(name: Descriptor.serviceConfiguration, qualifiers: qualifiers),
            userDefaultsKey: "EZ\(service)\(field.storageStem)\(uuid.isEmpty ? "" : "_\(uuid)_")Key",
            category: category,
            allowedValueKinds: field.allowedValueKinds,
            isEndpoint: field == .endpoint,
            isSchemeAutomatable: field.isSchemeAutomatable
        )
    }

    private static func queryConfigurationEntry(forKey key: String) -> ConfigurationRegistryEntry? {
        if key.hasPrefix("IntelligentQueryMode-window"),
           let window = key.split(separator: "-").last?.replacingOccurrences(of: "window", with: ""),
           ["0", "1", "2"].contains(window) {
            return queryModeEntry(window: window)
        }
        for service in serviceTypeIDs {
            for field in ["IntelligentQueryTextType", "QueryTextType"]
                where key == "\(service)-\(field)" {
                return serviceQueryTypeEntry(service: service, field: field)
            }
        }
        return nil
    }

    private static func queryConfigurationEntry(
        for descriptor: ConfigurationItemDescriptor
    )
        -> ConfigurationRegistryEntry? {
        if descriptor.name == Descriptor.intelligentQueryMode,
           Set(descriptor.qualifiers.keys) == ["window"],
           let window = descriptor.qualifiers["window"], ["0", "1", "2"].contains(window) {
            return queryModeEntry(window: window)
        }
        guard descriptor.name == Descriptor.serviceQueryType,
              Set(descriptor.qualifiers.keys) == ["service", "field"],
              let service = descriptor.qualifiers["service"], serviceTypeIDs.contains(service),
              let field = descriptor.qualifiers["field"],
              ["IntelligentQueryTextType", "QueryTextType"].contains(field)
        else { return nil }
        return serviceQueryTypeEntry(service: service, field: field)
    }

    private static func queryModeEntry(window: String) -> ConfigurationRegistryEntry {
        ConfigurationRegistryEntry(
            descriptor: .init(name: Descriptor.intelligentQueryMode, qualifiers: ["window": window]),
            userDefaultsKey: "IntelligentQueryMode-window\(window)",
            category: .portableSetting,
            allowedValueKinds: [.string, .boolean],
            isEndpoint: false,
            isSchemeAutomatable: true
        )
    }

    private static func serviceQueryTypeEntry(service: String, field: String) -> ConfigurationRegistryEntry {
        ConfigurationRegistryEntry(
            descriptor: .init(
                name: Descriptor.serviceQueryType,
                qualifiers: ["service": service, "field": field]
            ),
            userDefaultsKey: "\(service)-\(field)",
            category: .portableSetting,
            allowedValueKinds: [.string, .integer],
            isEndpoint: false,
            isSchemeAutomatable: true
        )
    }

    private static func serviceStorageEntry(forKey key: String) -> ConfigurationRegistryEntry? {
        if key.hasPrefix("kAllServiceTypesKey-"), let window = key.split(separator: "-").last.map(String.init),
           ["0", "1", "2"].contains(window) {
            return serviceOrderEntry(window: window)
        }
        guard key.hasPrefix("kServiceInfoStorageKey-") else { return nil }
        for service in serviceTypeIDs {
            let prefix = "kServiceInfoStorageKey-\(service)-"
            guard key.hasPrefix(prefix) else { continue }
            let tail = String(key.dropFirst(prefix.count))
            if ["0", "1", "2"].contains(tail) {
                return serviceInstanceEntry(service: service, uuid: "", window: tail)
            }
            guard let separator = tail.lastIndex(of: "-") else { continue }
            let window = String(tail[tail.index(after: separator)...])
            let uuid = String(tail[..<separator])
            guard ["0", "1", "2"].contains(window) else { continue }
            guard uuid.isEmpty || UUID(uuidString: uuid) != nil else { continue }
            return serviceInstanceEntry(service: service, uuid: uuid, window: window)
        }
        return nil
    }

    private static func serviceStorageEntry(for descriptor: ConfigurationItemDescriptor)
        -> ConfigurationRegistryEntry? {
        if descriptor.name == Descriptor.serviceOrder,
           Set(descriptor.qualifiers.keys) == ["window"],
           let window = descriptor.qualifiers["window"], ["0", "1", "2"].contains(window) {
            return serviceOrderEntry(window: window)
        }
        guard descriptor.name == Descriptor.serviceInstance,
              let service = descriptor.qualifiers["service"], serviceTypeIDs.contains(service),
              let window = descriptor.qualifiers["window"], ["0", "1", "2"].contains(window)
        else { return nil }
        let uuid = descriptor.qualifiers["uuid"] ?? ""
        let expectedKeys = uuid.isEmpty ? Set(["service", "window"]) : Set(["service", "uuid", "window"])
        guard Set(descriptor.qualifiers.keys) == expectedKeys,
              uuid.isEmpty || UUID(uuidString: uuid) != nil
        else { return nil }
        return serviceInstanceEntry(service: service, uuid: uuid, window: window)
    }

    private static func serviceOrderEntry(window: String) -> ConfigurationRegistryEntry {
        ConfigurationRegistryEntry(
            descriptor: .init(name: Descriptor.serviceOrder, qualifiers: ["window": window]),
            userDefaultsKey: "kAllServiceTypesKey-\(window)", category: .portableSetting,
            allowedValueKinds: [.array], isEndpoint: false, isSchemeAutomatable: false
        )
    }

    private static func serviceInstanceEntry(
        service: String,
        uuid: String,
        window: String
    )
        -> ConfigurationRegistryEntry {
        var qualifiers = ["service": service, "window": window]
        if !uuid.isEmpty { qualifiers["uuid"] = uuid }
        let uuidPart = uuid.isEmpty ? "" : "-\(uuid)"
        return ConfigurationRegistryEntry(
            descriptor: .init(name: Descriptor.serviceInstance, qualifiers: qualifiers),
            userDefaultsKey: "kServiceInfoStorageKey-\(service)\(uuidPart)-\(window)",
            category: .portableSetting, allowedValueKinds: [.data],
            isEndpoint: false, isSchemeAutomatable: false
        )
    }
}

// MARK: - ServiceConfigurationKey + Registry

extension ServiceConfigurationKey {
    fileprivate var storageStem: String { rawValue.capitalizeFirstLetter() }

    fileprivate var allowedValueKinds: Set<ConfigurationValueKind> {
        switch self {
        case .validModels: [.array]
        case .enableCustomPrompt, .enableStreaming, .thinkTag: [.boolean]
        case .temperature: [.real, .integer]
        default: [.string]
        }
    }

    fileprivate var isSchemeAutomatable: Bool {
        ![.apiKey, .endpoint, .name, .systemPrompt, .userPrompt].contains(self)
    }

    fileprivate func uuid(inStorageBody body: String) -> String? {
        guard body.hasPrefix(storageStem) else { return nil }
        let remainder = String(body.dropFirst(storageStem.count))
        if remainder.isEmpty { return "" }
        guard remainder.hasPrefix("_"), remainder.hasSuffix("_"), remainder.count > 2 else { return nil }
        let candidate = String(remainder.dropFirst().dropLast())
        guard UUID(uuidString: candidate) != nil else { return nil }
        return candidate
    }
}

// MARK: - ConfigurationItemRegistryBridge

/// Objective-C bridge used by the URL Scheme parser.
@objc(EZConfigurationItemRegistry)
final class ConfigurationItemRegistryBridge: NSObject {
    @objc
    static func isSensitiveKey(_ key: String) -> Bool {
        ConfigurationItemRegistry.isSensitiveKey(key)
    }

    @objc
    static func isEndpointKey(_ key: String) -> Bool {
        ConfigurationItemRegistry.isEndpointKey(key)
    }

    @objc
    static func isSchemeAutomatableKey(_ key: String) -> Bool {
        ConfigurationItemRegistry.isSchemeAutomatableKey(key)
    }

    @objc(schemeValueForKey:rawValue:)
    static func schemeValue(forKey key: String, rawValue: String) -> Any? {
        ConfigurationItemRegistry.schemeValue(forKey: key, rawValue: rawValue)
    }
}
