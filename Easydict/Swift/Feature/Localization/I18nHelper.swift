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
        if let code = UserDefaults.standard.string(forKey: languagePreferenceLocalKey) {
          return code
        }
        
        if let localLanguageType = LanguageState.LanguageType(rawValue: Locale.current.identifier) {
            return localLanguageType.rawValue
        }
        
        if Locale.current.identifier == "zh_CN" {
            return LanguageState.LanguageType.simplifiedChinese.rawValue
        }
        
        return LanguageState.LanguageType.english.rawValue
    }

    var languageType: LanguageState.LanguageType {
        LanguageState.LanguageType(rawValue: localizeCode) ?? .english
    }

    var isSimplifiedChineseLocalize: Bool {
        localizeCode == LanguageState.LanguageType.simplifiedChinese.rawValue
    }
}
