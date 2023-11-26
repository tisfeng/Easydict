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

    // Align with the web interface
    static func type(from: Language, to: Language) -> CaiyunTranslateType {
        // Auto convert Tradional Chinese
        if to == .traditionalChinese {
            return transType(from: from, to: to)
        }
        
        if from.isChinese {
            guard [Language.english, .japanese, .korean, .spanish, .french, .russian].contains(to) else {
                return .unsupported
            }
        } else if from == .english {
            guard [Language.simplifiedChinese, .spanish, .french, .russian].contains(to) else {
                return .unsupported
            }
        } else if from == .japanese {
            guard [Language.simplifiedChinese].contains(to) else {
                return .unsupported
            }
        } else if from == .korean {
            guard [Language.simplifiedChinese].contains(to) else {
                return .unsupported
            }
        } else if from == .spanish {
            guard [Language.simplifiedChinese, .english, .french, .russian].contains(to) else {
                return .unsupported
            }
        } else if from == .french {
            guard [Language.simplifiedChinese, .english, .spanish, .russian].contains(to) else {
                return .unsupported
            }
        } else if from == .french {
            guard [Language.simplifiedChinese, .english, .spanish, .french].contains(to) else {
                return .unsupported
            }
        } else if from == .auto {
            guard [Language.simplifiedChinese, .english, .japanese, .korean, .spanish, .french, .russian].contains(to) else {
                return .unsupported
            }
        }
        return transType(from: from, to: to)
    }
    
    static func transType(from: Language, to: Language) -> CaiyunTranslateType {
        return CaiyunTranslateType(rawValue: "\(from.caiyunValue)2\(to.caiyunValue)")
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
