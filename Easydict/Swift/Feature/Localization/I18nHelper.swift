//
//  I18nHelper.swift
//  Easydict
//
//  Created by choykarl on 2024/3/4.
//  Copyright © 2024 izual. All rights reserved.
//

import SwiftUI

// MARK: - I18nHelper

@objcMembers
@objc(EZI18nHelper)
class I18nHelper: NSObject {
    static let languagePreferenceChangedNotification = "LanguagePreferenceChangedNotification"
    static let shared = I18nHelper()

    var localizedBundle: Bundle {
        guard let path = Bundle.main.path(forResource: localizeCode, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return .main
        }
        return bundle
    }

    var localizeCode: String {
        guard let code = UserDefaults.standard.string(forKey: languagePreferenceLocalKey) else {
            guard let localLanguageType = LanguageState.LanguageType(rawValue: Locale.current.identifier) else {
                if Locale.current.identifier == "zh_CN" {
                    return LanguageState.LanguageType.simplifiedChinese.rawValue
                }
                return LanguageState.LanguageType.english.rawValue
            }
            return localLanguageType.rawValue
        }
        return code
    }

    var languageType: LanguageState.LanguageType {
        LanguageState.LanguageType(rawValue: localizeCode) ?? .english
    }

    var isSimplifiedChineseLocalize: Bool {
        localizeCode == LanguageState.LanguageType.simplifiedChinese.rawValue
    }
}
