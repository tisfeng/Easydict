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
        // Currently Caiyun does not support translating to the same language
        guard from != to else {
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
