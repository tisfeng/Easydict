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
        UserDefaults.standard.string(forKey: languagePreferenceLocalKey) ?? LanguageState.LanguageType
            .simplifiedChinese.rawValue
    }

    var languageType: LanguageState.LanguageType {
        LanguageState.LanguageType(rawValue: localizeCode) ?? .simplifiedChinese
    }

    var isSimplifiedChineseLocalize: Bool {
        localizeCode == LanguageState.LanguageType.simplifiedChinese.rawValue
    }
}
