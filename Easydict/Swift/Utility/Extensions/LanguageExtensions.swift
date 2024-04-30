//
//  LanguageExtensions.swift
//  Easydict
//
//  Created by 戴藏龙 on 2024/1/13.
//  Copyright © 2024 izual. All rights reserved.
//

import Defaults
import Foundation

// MARK: - Language + Defaults.Serializable

extension Language: Defaults.Serializable {}

// MARK: - Language + CaseIterable

extension Language: CaseIterable {
    public static let allCases: [Language] = EZLanguageModel.allLanguagesDict().sortedKeys().map { rawValue in
        Language(rawValue: rawValue as String)
    }

    public static let allAvailableOptions: [Language] = allCases.filter { language in
        language != .auto && language != .classicalChinese
    }
}

extension Language {
    public var model: EZLanguageModel {
        EZLanguageModel.allLanguagesDict().object(forKey: rawValue as NSString)
    }

    public var chineseName: String {
        model.chineseName
    }

    public var englishName: String {
        model.englishName.rawValue
    }

    public var localName: String {
        model.localName
    }

    public var flagEmoji: String {
        model.flagEmoji
    }

    public var voiceName: String {
        model.voiceName
    }

    public var localeIdentifier: String {
        model.localeIdentifier
    }

    public var localizedName: String {
        if I18nHelper.shared.isSimplifiedChineseLocalize {
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
