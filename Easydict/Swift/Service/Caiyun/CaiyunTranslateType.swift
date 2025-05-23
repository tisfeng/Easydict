//
//  CaiyunTranslateType.swift
//  Easydict
//
//  Created by Kyle on 2023/11/24.
//  Copyright © 2023 izual. All rights reserved.
//

import Foundation

struct CaiyunTranslateType: RawRepresentable {
    static let unsupported = CaiyunTranslateType(rawValue: "unsupported")

    // Align with the web interface https://fanyi.caiyunapp.com/#/
    static let supportedTypes: [Language: [Language]] = [
        .simplifiedChinese: [.traditionalChinese, .english, .japanese, .korean, .german, .spanish, .french, .italian, .portuguese, .russian, .turkish, .vietnamese],
        .traditionalChinese: [.simplifiedChinese, .english, .japanese, .korean, .german, .spanish, .french, .italian, .portuguese, .russian, .turkish, .vietnamese],
        .english: [.simplifiedChinese, .traditionalChinese],
        .japanese: [.simplifiedChinese, .traditionalChinese],
        .korean: [.simplifiedChinese, .traditionalChinese],
        .german: [.simplifiedChinese, .traditionalChinese],
        .spanish: [.simplifiedChinese, .traditionalChinese],
        .french: [.simplifiedChinese, .traditionalChinese],
        .italian: [.simplifiedChinese, .traditionalChinese],
        .portuguese: [.simplifiedChinese, .traditionalChinese],
        .russian: [.simplifiedChinese, .traditionalChinese],
        .turkish: [.simplifiedChinese, .traditionalChinese],
        .vietnamese: [.simplifiedChinese, .traditionalChinese],
    ]

    static let supportLanguagesDictionary: [Language: String] = [
        .auto: "auto",
        .simplifiedChinese: "zh",
        .traditionalChinese: "zh-Hant",
        .english: "en",
        .japanese: "ja",
        .korean: "ko",
        .german: "de",
        .spanish: "es",
        .french: "fr",
        .italian: "it",
        .portuguese: "pt",
        .russian: "ru",
        .turkish: "tr",
        .vietnamese: "vi",
    ]

    var rawValue: String

    static func transType(from: Language, to: Language) -> CaiyunTranslateType {
        guard let targetLanguages = supportedTypes[from],
              targetLanguages.contains(to)
        else {
            return .unsupported
        }

        guard let from = supportLanguagesDictionary[from],
              let to = supportLanguagesDictionary[to]
        else {
            return .unsupported
        }

        return CaiyunTranslateType(rawValue: "\(from)2\(to)")
    }
}
