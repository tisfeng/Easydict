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
        Language(rawValue: rawValue as! String)
    }

    public static let allAvailableOptions: [Language] = allCases.filter { language in
        language != .auto && language != .classicalChinese
    }

    /// // Get language from code.
    /// - Parameter code: BCP-47 code, such as en, zh-Hans, zh-Hant
    /// - Returns: Language
    public static func language(fromCode code: String) -> Language {
        allCases.first { $0.model.code == code } ?? .auto
    }
}

// MARK: - Language + CustomStringConvertible

extension Language: CustomStringConvertible {
    public var description: String {
        "\(localizedName)(\(code))"
    }
}

extension Language {
    public var model: EZLanguageModel {
        EZLanguageModel.allLanguagesDict().object(forKey: rawValue as NSString) as! EZLanguageModel
    }

    public var chineseName: String {
        model.chineseName
    }

    public var englishName: String {
        model.englishName.rawValue
    }

    public var nativeName: String {
        model.nativeName
    }

    public var flagEmoji: String {
        model.flagEmoji
    }

    public var voiceLocaleIdentifier: String {
        model.voiceLocaleIdentifier
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

    /// BCP-47 language code: en, zh-Hans, zh-Hans, equal to Apple's NLLanguage.
    public var code: String {
        model.code
    }

    public var localeLanguage: Locale.Language {
        .init(identifier: code)
    }

    /// Is kind of Chinese language, means it is simplifiedChinese, traditionalChinese or classicalChinese.
    var isChinese: Bool {
        [.simplifiedChinese, .traditionalChinese, .classicalChinese].contains(self)
    }

    var isEnglish: Bool {
        self == .english
    }

    var requiresWordSpacing: Bool {
        EZLanguageManager.shared().isLanguageWordsNeedSpace(self)
    }
}

// MARK: - Language + MMOrderedDictionary

extension [Language: String] {
    /// Convert Language dict to MMOrderedDictionary
    func toMMOrderedDictionary() -> MMOrderedDictionary {
        let orderedDict = MMOrderedDictionary()
        for (key, value) in self {
            orderedDict.setObject(value as NSString, forKey: key.rawValue as NSString)
        }
        return orderedDict
    }
}

extension [Language] {
    /// Contains Chinese language,
    func containsChinese() -> Bool {
        contains { $0.isChinese }
    }

    /// Convert Language array to MMOrderedDictionary, dict value is the same as key
    func toMMOrderedDictionary() -> MMOrderedDictionary {
        let orderedDict = MMOrderedDictionary()
        for language in self {
            orderedDict.setObject(language.rawValue as NSString, forKey: language.rawValue as NSString)
        }
        return orderedDict
    }

    var formattedDescription: String {
        map { $0.localizedName }.joined(separator: ", ")
    }
}
