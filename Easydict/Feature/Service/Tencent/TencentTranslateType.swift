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

    // Docs: https://cloud.tencent.com/document/api/551/15619
    static let supportedTypes: [Language: [Language]] = [
        .simplifiedChinese: [.english, .japanese, .korean, .french, .spanish, .italian, .german, .turkish, .russian, .portuguese, .vietnamese, .indonesian, .thai, .malay],
        .traditionalChinese: [.english, .japanese, .korean, .french, .spanish, .italian, .german, .turkish, .russian, .portuguese, .vietnamese, .indonesian, .thai, .malay],
        .english: [.simplifiedChinese, .japanese, .korean, .french, .spanish, .italian, .german, .turkish, .russian, .portuguese, .vietnamese, .indonesian, .thai, .malay, .arabic, .hindi],
        .japanese: [.simplifiedChinese, .english, .korean],
        .korean: [.simplifiedChinese, .english, .japanese],
        .french: [.simplifiedChinese, .english, .spanish, .italian, .german, .turkish, .russian, .portuguese],
        .spanish: [.simplifiedChinese, .english, .french, .italian, .german, .turkish, .russian, .portuguese],
        .italian: [.simplifiedChinese, .english, .french, .spanish, .german, .turkish, .russian, .portuguese],
        .german: [.simplifiedChinese, .english, .french, .spanish, .italian, .turkish, .russian, .portuguese],
        .turkish: [.simplifiedChinese, .english, .french, .spanish, .italian, .german, .russian, .portuguese],
        .russian: [.simplifiedChinese, .english, .french, .spanish, .italian, .german, .turkish, .portuguese],
        .portuguese: [.simplifiedChinese, .english, .french, .spanish, .italian, .german, .turkish, .russian],
        .vietnamese: [.simplifiedChinese, .english],
        .indonesian: [.simplifiedChinese, .english],
        .thai: [.simplifiedChinese, .english],
        .malay: [.simplifiedChinese, .english],
        .arabic: [.english],
        .hindi: [.english]
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
        if (supportedTypes[from] != nil && to == .traditionalChinese) ||
            (supportedTypes[from]?.contains(to) == true) {
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
