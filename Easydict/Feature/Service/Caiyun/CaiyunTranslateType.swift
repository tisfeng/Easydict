//
//  CaiyunTranslateType.swift
//  Easydict
//
//  Created by Kyle on 2023/11/24.
//  Copyright © 2023 izual. All rights reserved.
//

import Foundation

struct CaiyunTranslateType: RawRepresentable {
    var rawValue: String
    
    static let unsupported = CaiyunTranslateType(rawValue: "unsupported")
    
    // Align with the web interface https://fanyi.caiyunapp.com/#/
    static let supportedTypes: [Language: [Language]] = [
        .simplifiedChinese: [.english, .japanese, .korean, .spanish, .french, .russian],
        .english: [.simplifiedChinese, .spanish, .french, .russian],
        .japanese: [.simplifiedChinese],
        .korean: [.simplifiedChinese],
        .spanish: [.simplifiedChinese, .english, .french, .russian],
        .french: [.simplifiedChinese, .english, .spanish, .russian],
        .russian: [.simplifiedChinese, .english, .spanish, .french],
    ]
    
    static let supportLanguagesDictionary: [Language: String] = [
        .auto: "auto",
        .simplifiedChinese: "zh",
        .traditionalChinese: "zh",
        .english: "en",
        .japanese: "ja",
        .korean: "ko",
        .french: "fr",
        .spanish: "es",
        .russian: "ru",
    ]
    
    static func transType(from: Language, to: Language) -> CaiyunTranslateType {
        // We can auto convert to Traditional Chinese.
        if (supportedTypes[from] != nil && to == .traditionalChinese) ||
            (supportedTypes[from]?.contains(to) == true) {
            guard let from = supportLanguagesDictionary[from],
                  let to = supportLanguagesDictionary[to] else {
                return .unsupported
            }
            return CaiyunTranslateType(rawValue: "\(from)2\(to)")
        } else {
            return .unsupported
        }
    }
}
