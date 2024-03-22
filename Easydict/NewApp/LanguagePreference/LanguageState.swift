//
//  LanguageState.swift
//  Easydict
//
//  Created by choykarl on 2024/3/3.
//  Copyright © 2024 izual. All rights reserved.
//

import SwiftUI

// MARK: - LanguageState

let kEZLanguagePreferenceLocalKey = "kEZLanguagePreferenceLocalKey"

// MARK: - LanguageState

class LanguageState: ObservableObject {
    enum LanguageType: String, CaseIterable {
        case english = "en"
        case simplifiedChinese = "zh-Hans"

        // MARK: Internal

        var name: String {
            switch self {
            case .english:
                "English"
            case .simplifiedChinese:
                "简体中文"
            }
        }
    }

    @AppStorage(kEZLanguagePreferenceLocalKey) var language: LanguageType = (.init(
        rawValue: Locale.current.identifier
    ) ?? .simplifiedChinese) {
        didSet {
            NotificationCenter.default.post(
                name: NSNotification.Name(rawValue: EZI18nHelper.languagePreferenceChangedNotification),
                object: nil
            )
        }
    }
}
