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

    // Align with the web interface
    static func type(from: Language, to: Language) -> TencentTranslateType {
        if from == .simplifiedChinese {
            guard [Language.traditionalChinese, .english, .japanese, .korean, .french, .spanish, .italian, .german, .turkish, .russian, .portuguese, .vietnamese, .indonesian, .thai, .malay].contains(to) else {
                return .unsupported
            }
        } else if from == .traditionalChinese {
            guard [Language.simplifiedChinese, .english, .japanese, .korean, .french, .spanish, .italian, .german, .turkish, .russian, .portuguese, .vietnamese, .indonesian, .thai, .malay].contains(to) else {
                return .unsupported
            }
        } else if from == .english {
            guard [Language.simplifiedChinese, .traditionalChinese, .japanese, .korean, .french, .spanish, .italian, .german, .turkish, .russian, .portuguese, .vietnamese, .indonesian, .thai, .malay, .arabic, .hindi].contains(to) else {
                return .unsupported
            }
        } else if from == .japanese {
            guard [Language.simplifiedChinese, .traditionalChinese, .english, .korean].contains(to) else {
                return .unsupported
            }
        } else if from == .korean {
            guard [Language.simplifiedChinese, .traditionalChinese, .english, .japanese].contains(to) else {
                return .unsupported
            }
        } else if from == .french{
            guard [Language.simplifiedChinese, .traditionalChinese, .english, .spanish, .italian, .german, .turkish, .russian, .portuguese].contains(to) else {
                return .unsupported
            }
        } else if from == .spanish {
            guard [Language.simplifiedChinese, .traditionalChinese, .english, .french, .italian, .german, .turkish, .russian, .portuguese].contains(to) else {
                return .unsupported
            }
        } else if from == .italian {
            guard [Language.simplifiedChinese, .traditionalChinese, .english, .french, .spanish, .german, .turkish, .russian, .portuguese].contains(to) else {
                return .unsupported
            }
        } else if from == .german {
            guard [Language.simplifiedChinese, .traditionalChinese, .english, .french, .spanish, .italian, .turkish, .russian, .portuguese].contains(to) else {
                return .unsupported
            }
        } else if from == .turkish {
            guard [Language.simplifiedChinese, .traditionalChinese, .english, .french, .spanish, .italian, .german, .russian, .portuguese].contains(to) else {
                return .unsupported
            }
        } else if from == .russian {
            guard [Language.simplifiedChinese, .traditionalChinese, .english, .french, .spanish, .italian, .german, .turkish, .portuguese].contains(to) else {
                return .unsupported
            }
        } else if from == .portuguese {
            guard [Language.simplifiedChinese, .traditionalChinese, .english, .french, .spanish, .italian, .german, .turkish, .russian].contains(to) else {
                return .unsupported
            }
        } else if from == .vietnamese {
            guard [Language.simplifiedChinese, .traditionalChinese, .english].contains(to) else {
                return .unsupported
            }
        } else if from == .indonesian {
            guard [Language.simplifiedChinese, .traditionalChinese, .english].contains(to) else {
                return .unsupported
            }
        } else if from == .thai {
            guard [Language.simplifiedChinese, .traditionalChinese, .english].contains(to) else {
                return .unsupported
            }
        } else if from == .malay {
            guard [Language.simplifiedChinese, .traditionalChinese, .english].contains(to) else {
                return .unsupported
            }
        } else if from == .arabic {
            guard [Language.english].contains(to) else {
                return .unsupported
            }
        } else if from == .hindi {
            guard [Language.english].contains(to) else {
                return .unsupported
            }
        } else if from == .auto {
            guard [Language.simplifiedChinese, .traditionalChinese, .english, .japanese, .korean, .french, .spanish, .italian, .german, .turkish, .russian, .portuguese, .vietnamese, .indonesian, .thai, .malay, .arabic, .hindi].contains(to) else {
                return .unsupported
            }
        }
        return TencentTranslateType(sourceLanguage: from.tencentValue, targetLanguage: to.tencentValue)
    }
}

extension Language {

    var tencentValue: String {
        switch self {
        case .auto: return "auto"
        case .simplifiedChinese: return "zh"
        case .traditionalChinese: return "zh-TW"
        case .english: return "en"
        case .japanese: return "ja"
        case .korean: return "ko"
        case .french: return "fr"
        case .spanish: return "es"
        case .italian: return "it"
        case .german: return "de"
        case .turkish: return "tr"
        case .russian: return "ru"
        case .portuguese: return "pt"
        case .vietnamese: return "vi"
        case .indonesian: return "id"
        case .thai: return "th"
        case .malay: return "ms"
        case .arabic: return "ar"
        case .hindi: return "hi"
        default: return ""
        }
    }
}
