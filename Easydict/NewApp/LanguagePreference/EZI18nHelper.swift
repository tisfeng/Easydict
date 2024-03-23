//
//  EZI18nHelper.swift
//  Easydict
//
//  Created by choykarl on 2024/3/4.
//  Copyright © 2024 izual. All rights reserved.
//

import SwiftUI

// MARK: - EZI18nHelper

@objcMembers
class EZI18nHelper: NSObject {
    static let languagePreferenceChangedNotification = "EZLanguagePreferenceChangedNotification"
    static let shared = EZI18nHelper()

    var localizedBundle: Bundle {
        let res = localizeCode
        let path = Bundle.main.path(forResource: res, ofType: "lproj")
        let bundle: Bundle
        if let path = path {
            bundle = Bundle(path: path) ?? .main
        } else {
            bundle = .main
        }
        return bundle
    }

    var localizeCode: String {
        UserDefaults.standard.string(forKey: kEZLanguagePreferenceLocalKey) ?? LanguageState.LanguageType
            .simplifiedChinese.rawValue
    }

    var languageType: LanguageState.LanguageType {
        LanguageState.LanguageType(rawValue: localizeCode) ?? .simplifiedChinese
    }

    var isSimplifiedChineseLocalize: Bool {
        localizeCode == LanguageState.LanguageType.simplifiedChinese.rawValue
    }
}
