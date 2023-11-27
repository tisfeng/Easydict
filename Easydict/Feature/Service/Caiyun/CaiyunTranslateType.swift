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
    
    // Align with the web interface, https://fanyi.caiyunapp.com/#/
    static let supportedTypes: [Language: [Language]] = [
        .simplifiedChinese: [.english, .japanese, .korean, .spanish, .french, .russian],
        .english: [.simplifiedChinese, .spanish, .french, .russian],
        .japanese: [.simplifiedChinese],
        .korean: [.simplifiedChinese],
        .spanish: [.simplifiedChinese, .english, .french, .russian],
        .french: [.simplifiedChinese, .english, .spanish, .russian],
        .russian: [.simplifiedChinese, .english, .spanish, .french],
    ]
    
    static func transType(from: Language, to: Language) -> CaiyunTranslateType {
        // We can auto convert to Traditional Chinese.
        if (supportedTypes[from] != nil && to == .traditionalChinese) ||
            (supportedTypes[from]?.contains(to) == true) {
            return CaiyunTranslateType(rawValue: "\(from.caiyunValue)2\(to.caiyunValue)")
        } else {
            return .unsupported
        }
    }
}

extension Language {
    var isChinese: Bool {
        [Language.classicalChinese, .simplifiedChinese, .traditionalChinese].contains(self)
    }

    var caiyunValue: String {
        switch self {
        case .classicalChinese, .simplifiedChinese, .traditionalChinese: return "zh"
        case .english: return "en"
        case .japanese: return "ja"
        case .korean: return "ko"
        case .spanish: return "es"
        case .french: return "fr"
        case .russian: return "ru"
        case .auto: return "auto"
        default: return ""
        }
    }
}
