//
//  TencentTranslateType.swift
//  Easydict
//
//  Created by Jerry on 2023-11-25.
//  Copyright © 2023 izual. All rights reserved.
//

import Foundation

struct TencentTranslateType: Equatable {

    var sourceLanguage: String
    var targetLanguage: String

    static let unsupported = TencentTranslateType(sourceLanguage: "unsupported", targetLanguage: "unsupported")

    static let supportedTypes: [Language: [Language]] = [
        .simplifiedChinese: [.simplifiedChinese, .traditionalChinese, .english, .japanese, .korean, .french, .spanish, .italian, .german, .turkish, .russian, .portuguese, .vietnamese, .indonesian, .thai, .malay],
        .traditionalChinese: [.simplifiedChinese, .traditionalChinese, .english, .japanese, .korean, .french, .spanish, .italian, .german, .turkish, .russian, .portuguese, .vietnamese, .indonesian, .thai, .malay],
        .english: [.simplifiedChinese, .traditionalChinese, .english, .japanese, .korean, .french, .spanish, .italian, .german, .turkish, .russian, .portuguese, .vietnamese, .indonesian, .thai, .malay, .arabic, .hindi],
        .japanese: [.simplifiedChinese, .traditionalChinese, .english, .japanese, .korean],
        .korean: [.simplifiedChinese, .traditionalChinese, .english, .japanese, .korean],
        .french: [.simplifiedChinese, .traditionalChinese, .english, .french, .spanish, .italian, .german, .turkish, .russian, .portuguese],
        .spanish: [.simplifiedChinese, .traditionalChinese, .english, .french, .spanish, .italian, .german, .turkish, .russian, .portuguese],
        .italian: [.simplifiedChinese, .traditionalChinese, .english, .french, .spanish, .italian, .german, .turkish, .russian, .portuguese],
        .german: [.simplifiedChinese, .traditionalChinese, .english, .french, .spanish, .italian, .german, .turkish, .russian, .portuguese],
        .turkish: [.simplifiedChinese, .traditionalChinese, .english, .french, .spanish, .italian, .german, .turkish, .russian, .portuguese],
        .russian: [.simplifiedChinese, .traditionalChinese, .english, .french, .spanish, .italian, .german, .turkish, .russian, .portuguese],
        .portuguese: [.simplifiedChinese, .traditionalChinese, .english, .french, .spanish, .italian, .german, .turkish, .russian, .portuguese],
        .vietnamese: [.simplifiedChinese, .traditionalChinese, .english, .french, .spanish, .italian, .german, .turkish, .russian, .vietnamese],
        .indonesian: [.simplifiedChinese, .traditionalChinese, .english, .french, .spanish, .italian, .german, .turkish, .russian, .indonesian],
        .thai: [.simplifiedChinese, .traditionalChinese, .english, .french, .spanish, .italian, .german, .turkish, .russian, .thai],
        .malay: [.simplifiedChinese, .traditionalChinese, .english, .french, .spanish, .italian, .german, .turkish, .russian, .malay],
        .arabic: [.simplifiedChinese, .traditionalChinese, .english, .french, .spanish, .italian, .german, .turkish, .russian, .arabic],
        .hindi: [.simplifiedChinese, .traditionalChinese, .english, .french, .spanish, .italian, .german, .turkish, .russian, .hindi]
    ]

    static let supportLanguagesDictionary: [Language: String] = [
        .auto: "auto",
        .simplifiedChinese: "zh",
        .traditionalChinese: "zh-TW",
        .english: "en",
        .japanese: "ja",
        .korean: "ko",
        .french: "fr",
        .spanish: "es",
        .italian: "it",
        .german: "de",
        .turkish: "tr",
        .russian: "ru",
        .portuguese: "pt",
        .vietnamese: "vi",
        .indonesian: "id",
        .thai: "th",
        .malay: "ms",
        .arabic: "ar",
        .hindi: "hi"
    ]

    static func transType(from: Language, to: Language) -> TencentTranslateType {
        if supportedTypes[from]?.contains(to) == true {
            guard let from = supportLanguagesDictionary[from],
                  let to = supportLanguagesDictionary[to] else {
                return .unsupported
            }
            return TencentTranslateType(sourceLanguage: from, targetLanguage: to)
        } else {
            return .unsupported
        }
    }
}
