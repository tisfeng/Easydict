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
        case simplifiedChinese = "zh-Hans"
        case traditionalChinese = "zh-Hant"
        case slovak = "sk"

        // MARK: Internal

        var name: String {
            switch self {
            case .english:
                "English"
            case .simplifiedChinese:
                "简体中文"
            case .traditionalChinese:
                "繁體中文"
            case .slovak:
                "Slovak"
            }
        }
    }

    @AppStorage(languagePreferenceLocalKey) var language: LanguageType =
        (.init(
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
        // Bundle resource format: zh-Hans.lproj, zh-Hant.lproj, en.lproj, en-CA.lproj

        let languageCode = language.languageCode?.identifier // zh, en, ja
        let script = language.script?.identifier // Hans, Hant,
        let region = language.region?.identifier // CN, TW,

        let languageCodeScriptRegion = [languageCode, script, region].compactMap { $0 }
            .joined(separator: "-") // zh-Hans-CN
        let languageCodeScript = [languageCode, script].compactMap { $0 }.joined(separator: "-") // zh-Hans
        let languageCodeRegion = [languageCode, region].compactMap { $0 }.joined(separator: "-") // zh-CN

        if let languageCode, let type = LanguageState.LanguageType(rawValue: languageCode) { // en
            return type
        }
        if let type = LanguageState.LanguageType(rawValue: languageCodeScriptRegion) { // zh-Hans-CN
            return type
        }
        if let type = LanguageState.LanguageType(rawValue: languageCodeScript) { // zh-Hans
            return type
        }
        if let type = LanguageState.LanguageType(rawValue: languageCodeRegion) { // zh-CN
            return type
        }

        return nil
    }
}
