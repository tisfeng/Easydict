//
//  LanguageExtensions.swift
//  Easydict
//
//  Created by 戴藏龙 on 2024/1/13.
//  Copyright © 2024 izual. All rights reserved.
//

import Defaults
import Foundation

extension Language: Defaults.Serializable {}

extension Language: CaseIterable {
    public static let allCases: [Language] = EZLanguageModel.allLanguagesDict().sortedKeys().map { rawValue in
        Language(rawValue: rawValue as String)
    }

    public static let allAvailableOptions: [Language] = allCases.filter { language in
        language != .auto && language != .classicalChinese
    }
}

public extension Language {
    var model: EZLanguageModel {
        EZLanguageModel.allLanguagesDict().object(forKey: rawValue as NSString)
    }

    var chineseName: String {
        model.chineseName
    }

    var englishName: String {
        model.englishName.rawValue
    }

    var localName: String {
        model.localName
    }

    var flagEmoji: String {
        model.flagEmoji
    }

    var voiceName: String {
        model.voiceName
    }

    var localeIdentifier: String {
        model.localeIdentifier
    }

    var localizedName: String {
        if EZLanguageManager.shared().isSystemChineseFirstLanguage() {
            chineseName
        } else {
            if self == .auto {
                "Auto"
            } else {
                englishName
            }
        }
    }
}

extension [Language] {
    /// Contains Chinese language,
    func containsChinese() -> Bool {
        contains { $0.isKindOfChinese() }
    }
}

extension Language {
    /// Is kind of Chinese language, means it is simplifiedChinese or traditionalChinese.
    func isKindOfChinese() -> Bool {
        self == .simplifiedChinese || self == .traditionalChinese
    }
}
