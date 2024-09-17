//
//  LanguageState.swift
//  Easydict
//
//  Created by choykarl on 2024/3/3.
//  Copyright © 2024 izual. All rights reserved.
//

import SwiftUI

// MARK: - LanguageState

let languagePreferenceLocalKey = "LanguagePreferenceLocalKey"

// MARK: - LanguageState

class LanguageState: ObservableObject {
    enum LanguageType: String, CaseIterable {
        case english = "en"
        case canadianEnglish = "en-CA"
        case simplifiedChinese = "zh-Hans"
        case traditionalChinese = "zh-Hant"
        case slovak = "sk"

        // MARK: Internal

        var name: String {
            switch self {
            case .english:
                "English"
            case .canadianEnglish:
                "English (Canada)"
            case .simplifiedChinese:
                "简体中文"
            case .traditionalChinese:
                "繁體中文"
            case .slovak:
                "Slovak"
            }
        }
    }

    @AppStorage(languagePreferenceLocalKey) var language: LanguageType = (.init(
        rawValue: I18nHelper.shared.localizeCode
    ) ?? .simplifiedChinese) {
        didSet {
            NotificationCenter.default.post(name: .languagePreferenceChanged, object: nil)
        }
    }
}

// https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPInternational/LanguageandLocaleIDs/LanguageandLocaleIDs.html
extension Locale {
    var languageType: LanguageState.LanguageType? {
        let languageCode = language.languageCode?.identifier
        let script = language.script?.identifier
        let region = language.region?.identifier

        let languageCodeScriptRegion = [languageCode, script, region].compactMap { $0 }.joined(separator: "-")
        let languageCodeScript = [languageCode, script].compactMap { $0 }.joined(separator: "-")
        let languageCodeRegion = [languageCode, region].compactMap { $0 }.joined(separator: "-")

        if let languageCode, let type = LanguageState.LanguageType(rawValue: languageCode) {
            return type
        }
        if let type = LanguageState.LanguageType(rawValue: languageCodeScriptRegion) {
            return type
        }
        if let type = LanguageState.LanguageType(rawValue: languageCodeScript) {
            return type
        }
        if let type = LanguageState.LanguageType(rawValue: languageCodeRegion) {
            return type
        }

        return nil
    }
}
