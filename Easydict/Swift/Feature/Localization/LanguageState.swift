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
        let languageCode = Locale.current.language.languageCode?.identifier
        let script = Locale.current.language.script?.identifier

        var type: LanguageState.LanguageType?
        switch languageCode {
        case "zh":
            type = .simplifiedChinese
        case "en":
            type = .english
        default:
            break
        }

        if let languageCode, let script,
           let tmpType = LanguageState.LanguageType(rawValue: "\(languageCode)-\(script)") {
            type = tmpType
        }

        return type
    }
}
