//
//  GeminiTranslateType.swift
//  Easydict
//
//  Created by Jerry on 2024-01-02.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation

struct GeminiTranslateType: RawRepresentable {
    var rawValue: String

    static let unsupported = GeminiTranslateType(rawValue: "unsupported")

    // https://ai.google.dev/available_regions
    static let supportedTypes: [Language: [Language]] = [
        .arabic: [.arabic, .bengali, .bulgarian, .simplifiedChinese, .traditionalChinese, .croatian, .czech, .danish, .dutch, .english, .estonian, .finnish, .french, .german, .greek, .hebrew, .hindi, .hungarian, .indonesian, .italian, .japanese, .korean, .latvian, .lithuanian, .norwegian, .polish, .portuguese, .romanian, .russian, .serbian, .slovak, .slovenian, .spanish, .swedish, .thai, .turkish, .ukrainian, .vietnamese],
        .bengali: [.arabic, .bengali, .bulgarian, .simplifiedChinese, .traditionalChinese, .croatian, .czech, .danish, .dutch, .english, .estonian, .finnish, .french, .german, .greek, .hebrew, .hindi, .hungarian, .indonesian, .italian, .japanese, .korean, .latvian, .lithuanian, .norwegian, .polish, .portuguese, .romanian, .russian, .serbian, .slovak, .slovenian, .spanish, .swedish, .thai, .turkish, .ukrainian, .vietnamese],
        .bulgarian: [.arabic, .bengali, .bulgarian, .simplifiedChinese, .traditionalChinese, .croatian, .czech, .danish, .dutch, .english, .estonian, .finnish, .french, .german, .greek, .hebrew, .hindi, .hungarian, .indonesian, .italian, .japanese, .korean, .latvian, .lithuanian, .norwegian, .polish, .portuguese, .romanian, .russian, .serbian, .slovak, .slovenian, .spanish, .swedish, .thai, .turkish, .ukrainian, .vietnamese],
        .simplifiedChinese: [.arabic, .bengali, .bulgarian, .simplifiedChinese, .traditionalChinese, .croatian, .czech, .danish, .dutch, .english, .estonian, .finnish, .french, .german, .greek, .hebrew, .hindi, .hungarian, .indonesian, .italian, .japanese, .korean, .latvian, .lithuanian, .norwegian, .polish, .portuguese, .romanian, .russian, .serbian, .slovak, .slovenian, .spanish, .swedish, .thai, .turkish, .ukrainian, .vietnamese],
        .traditionalChinese: [.arabic, .bengali, .bulgarian, .simplifiedChinese, .traditionalChinese, .croatian, .czech, .danish, .dutch, .english, .estonian, .finnish, .french, .german, .greek, .hebrew, .hindi, .hungarian, .indonesian, .italian, .japanese, .korean, .latvian, .lithuanian, .norwegian, .polish, .portuguese, .romanian, .russian, .serbian, .slovak, .slovenian, .spanish, .swedish, .thai, .turkish, .ukrainian, .vietnamese],
        .croatian: [.arabic, .bengali, .bulgarian, .simplifiedChinese, .traditionalChinese, .croatian, .czech, .danish, .dutch, .english, .estonian, .finnish, .french, .german, .greek, .hebrew, .hindi, .hungarian, .indonesian, .italian, .japanese, .korean, .latvian, .lithuanian, .norwegian, .polish, .portuguese, .romanian, .russian, .serbian, .slovak, .slovenian, .spanish, .swedish, .thai, .turkish, .ukrainian, .vietnamese],
        .czech: [.arabic, .bengali, .bulgarian, .simplifiedChinese, .traditionalChinese, .croatian, .czech, .danish, .dutch, .english, .estonian, .finnish, .french, .german, .greek, .hebrew, .hindi, .hungarian, .indonesian, .italian, .japanese, .korean, .latvian, .lithuanian, .norwegian, .polish, .portuguese, .romanian, .russian, .serbian, .slovak, .slovenian, .spanish, .swedish, .thai, .turkish, .ukrainian, .vietnamese],
        .danish: [.arabic, .bengali, .bulgarian, .simplifiedChinese, .traditionalChinese, .croatian, .czech, .danish, .dutch, .english, .estonian, .finnish, .french, .german, .greek, .hebrew, .hindi, .hungarian, .indonesian, .italian, .japanese, .korean, .latvian, .lithuanian, .norwegian, .polish, .portuguese, .romanian, .russian, .serbian, .slovak, .slovenian, .spanish, .swedish, .thai, .turkish, .ukrainian, .vietnamese],
        .dutch: [.arabic, .bengali, .bulgarian, .simplifiedChinese, .traditionalChinese, .croatian, .czech, .danish, .dutch, .english, .estonian, .finnish, .french, .german, .greek, .hebrew, .hindi, .hungarian, .indonesian, .italian, .japanese, .korean, .latvian, .lithuanian, .norwegian, .polish, .portuguese, .romanian, .russian, .serbian, .slovak, .slovenian, .spanish, .swedish, .thai, .turkish, .ukrainian, .vietnamese],
        .english: [.arabic, .bengali, .bulgarian, .simplifiedChinese, .traditionalChinese, .croatian, .czech, .danish, .dutch, .english, .estonian, .finnish, .french, .german, .greek, .hebrew, .hindi, .hungarian, .indonesian, .italian, .japanese, .korean, .latvian, .lithuanian, .norwegian, .polish, .portuguese, .romanian, .russian, .serbian, .slovak, .slovenian, .spanish, .swedish, .thai, .turkish, .ukrainian, .vietnamese],
        .estonian: [.arabic, .bengali, .bulgarian, .simplifiedChinese, .traditionalChinese, .croatian, .czech, .danish, .dutch, .english, .estonian, .finnish, .french, .german, .greek, .hebrew, .hindi, .hungarian, .indonesian, .italian, .japanese, .korean, .latvian, .lithuanian, .norwegian, .polish, .portuguese, .romanian, .russian, .serbian, .slovak, .slovenian, .spanish, .swedish, .thai, .turkish, .ukrainian, .vietnamese],
        .finnish: [.arabic, .bengali, .bulgarian, .simplifiedChinese, .traditionalChinese, .croatian, .czech, .danish, .dutch, .english, .estonian, .finnish, .french, .german, .greek, .hebrew, .hindi, .hungarian, .indonesian, .italian, .japanese, .korean, .latvian, .lithuanian, .norwegian, .polish, .portuguese, .romanian, .russian, .serbian, .slovak, .slovenian, .spanish, .swedish, .thai, .turkish, .ukrainian, .vietnamese],
        .french: [.arabic, .bengali, .bulgarian, .simplifiedChinese, .traditionalChinese, .croatian, .czech, .danish, .dutch, .english, .estonian, .finnish, .french, .german, .greek, .hebrew, .hindi, .hungarian, .indonesian, .italian, .japanese, .korean, .latvian, .lithuanian, .norwegian, .polish, .portuguese, .romanian, .russian, .serbian, .slovak, .slovenian, .spanish, .swedish, .thai, .turkish, .ukrainian, .vietnamese],
        .german: [.arabic, .bengali, .bulgarian, .simplifiedChinese, .traditionalChinese, .croatian, .czech, .danish, .dutch, .english, .estonian, .finnish, .french, .german, .greek, .hebrew, .hindi, .hungarian, .indonesian, .italian, .japanese, .korean, .latvian, .lithuanian, .norwegian, .polish, .portuguese, .romanian, .russian, .serbian, .slovak, .slovenian, .spanish, .swedish, .thai, .turkish, .ukrainian, .vietnamese],
        .greek: [.arabic, .bengali, .bulgarian, .simplifiedChinese, .traditionalChinese, .croatian, .czech, .danish, .dutch, .english, .estonian, .finnish, .french, .german, .greek, .hebrew, .hindi, .hungarian, .indonesian, .italian, .japanese, .korean, .latvian, .lithuanian, .norwegian, .polish, .portuguese, .romanian, .russian, .serbian, .slovak, .slovenian, .spanish, .swedish, .thai, .turkish, .ukrainian, .vietnamese],
        .hebrew: [.arabic, .bengali, .bulgarian, .simplifiedChinese, .traditionalChinese, .croatian, .czech, .danish, .dutch, .english, .estonian, .finnish, .french, .german, .greek, .hebrew, .hindi, .hungarian, .indonesian, .italian, .japanese, .korean, .latvian, .lithuanian, .norwegian, .polish, .portuguese, .romanian, .russian, .serbian, .slovak, .slovenian, .spanish, .swedish, .thai, .turkish, .ukrainian, .vietnamese],
        .hindi: [.arabic, .bengali, .bulgarian, .simplifiedChinese, .traditionalChinese, .croatian, .czech, .danish, .dutch, .english, .estonian, .finnish, .french, .german, .greek, .hebrew, .hindi, .hungarian, .indonesian, .italian, .japanese, .korean, .latvian, .lithuanian, .norwegian, .polish, .portuguese, .romanian, .russian, .serbian, .slovak, .slovenian, .spanish, .swedish, .thai, .turkish, .ukrainian, .vietnamese],
        .hungarian: [.arabic, .bengali, .bulgarian, .simplifiedChinese, .traditionalChinese, .croatian, .czech, .danish, .dutch, .english, .estonian, .finnish, .french, .german, .greek, .hebrew, .hindi, .hungarian, .indonesian, .italian, .japanese, .korean, .latvian, .lithuanian, .norwegian, .polish, .portuguese, .romanian, .russian, .serbian, .slovak, .slovenian, .spanish, .swedish, .thai, .turkish, .ukrainian, .vietnamese],
        .indonesian: [.arabic, .bengali, .bulgarian, .simplifiedChinese, .traditionalChinese, .croatian, .czech, .danish, .dutch, .english, .estonian, .finnish, .french, .german, .greek, .hebrew, .hindi, .hungarian, .indonesian, .italian, .japanese, .korean, .latvian, .lithuanian, .norwegian, .polish, .portuguese, .romanian, .russian, .serbian, .slovak, .slovenian, .spanish, .swedish, .thai, .turkish, .ukrainian, .vietnamese],
        .italian: [.arabic, .bengali, .bulgarian, .simplifiedChinese, .traditionalChinese, .croatian, .czech, .danish, .dutch, .english, .estonian, .finnish, .french, .german, .greek, .hebrew, .hindi, .hungarian, .indonesian, .italian, .japanese, .korean, .latvian, .lithuanian, .norwegian, .polish, .portuguese, .romanian, .russian, .serbian, .slovak, .slovenian, .spanish, .swedish, .thai, .turkish, .ukrainian, .vietnamese],
        .japanese: [.arabic, .bengali, .bulgarian, .simplifiedChinese, .traditionalChinese, .croatian, .czech, .danish, .dutch, .english, .estonian, .finnish, .french, .german, .greek, .hebrew, .hindi, .hungarian, .indonesian, .italian, .japanese, .korean, .latvian, .lithuanian, .norwegian, .polish, .portuguese, .romanian, .russian, .serbian, .slovak, .slovenian, .spanish, .swedish, .thai, .turkish, .ukrainian, .vietnamese],
        .korean: [.arabic, .bengali, .bulgarian, .simplifiedChinese, .traditionalChinese, .croatian, .czech, .danish, .dutch, .english, .estonian, .finnish, .french, .german, .greek, .hebrew, .hindi, .hungarian, .indonesian, .italian, .japanese, .korean, .latvian, .lithuanian, .norwegian, .polish, .portuguese, .romanian, .russian, .serbian, .slovak, .slovenian, .spanish, .swedish, .thai, .turkish, .ukrainian, .vietnamese],
        .latvian: [.arabic, .bengali, .bulgarian, .simplifiedChinese, .traditionalChinese, .croatian, .czech, .danish, .dutch, .english, .estonian, .finnish, .french, .german, .greek, .hebrew, .hindi, .hungarian, .indonesian, .italian, .japanese, .korean, .latvian, .lithuanian, .norwegian, .polish, .portuguese, .romanian, .russian, .serbian, .slovak, .slovenian, .spanish, .swedish, .thai, .turkish, .ukrainian, .vietnamese],
        .lithuanian: [.arabic, .bengali, .bulgarian, .simplifiedChinese, .traditionalChinese, .croatian, .czech, .danish, .dutch, .english, .estonian, .finnish, .french, .german, .greek, .hebrew, .hindi, .hungarian, .indonesian, .italian, .japanese, .korean, .latvian, .lithuanian, .norwegian, .polish, .portuguese, .romanian, .russian, .serbian, .slovak, .slovenian, .spanish, .swedish, .thai, .turkish, .ukrainian, .vietnamese],
        .norwegian: [.arabic, .bengali, .bulgarian, .simplifiedChinese, .traditionalChinese, .croatian, .czech, .danish, .dutch, .english, .estonian, .finnish, .french, .german, .greek, .hebrew, .hindi, .hungarian, .indonesian, .italian, .japanese, .korean, .latvian, .lithuanian, .norwegian, .polish, .portuguese, .romanian, .russian, .serbian, .slovak, .slovenian, .spanish, .swedish, .thai, .turkish, .ukrainian, .vietnamese],
        .polish: [.arabic, .bengali, .bulgarian, .simplifiedChinese, .traditionalChinese, .croatian, .czech, .danish, .dutch, .english, .estonian, .finnish, .french, .german, .greek, .hebrew, .hindi, .hungarian, .indonesian, .italian, .japanese, .korean, .latvian, .lithuanian, .norwegian, .polish, .portuguese, .romanian, .russian, .serbian, .slovak, .slovenian, .spanish, .swedish, .thai, .turkish, .ukrainian, .vietnamese],
        .portuguese: [.arabic, .bengali, .bulgarian, .simplifiedChinese, .traditionalChinese, .croatian, .czech, .danish, .dutch, .english, .estonian, .finnish, .french, .german, .greek, .hebrew, .hindi, .hungarian, .indonesian, .italian, .japanese, .korean, .latvian, .lithuanian, .norwegian, .polish, .portuguese, .romanian, .russian, .serbian, .slovak, .slovenian, .spanish, .swedish, .thai, .turkish, .ukrainian, .vietnamese],
        .romanian: [.arabic, .bengali, .bulgarian, .simplifiedChinese, .traditionalChinese, .croatian, .czech, .danish, .dutch, .english, .estonian, .finnish, .french, .german, .greek, .hebrew, .hindi, .hungarian, .indonesian, .italian, .japanese, .korean, .latvian, .lithuanian, .norwegian, .polish, .portuguese, .romanian, .russian, .serbian, .slovak, .slovenian, .spanish, .swedish, .thai, .turkish, .ukrainian, .vietnamese],
        .russian: [.arabic, .bengali, .bulgarian, .simplifiedChinese, .traditionalChinese, .croatian, .czech, .danish, .dutch, .english, .estonian, .finnish, .french, .german, .greek, .hebrew, .hindi, .hungarian, .indonesian, .italian, .japanese, .korean, .latvian, .lithuanian, .norwegian, .polish, .portuguese, .romanian, .russian, .serbian, .slovak, .slovenian, .spanish, .swedish, .thai, .turkish, .ukrainian, .vietnamese],
        .serbian: [.arabic, .bengali, .bulgarian, .simplifiedChinese, .traditionalChinese, .croatian, .czech, .danish, .dutch, .english, .estonian, .finnish, .french, .german, .greek, .hebrew, .hindi, .hungarian, .indonesian, .italian, .japanese, .korean, .latvian, .lithuanian, .norwegian, .polish, .portuguese, .romanian, .russian, .serbian, .slovak, .slovenian, .spanish, .swedish, .thai, .turkish, .ukrainian, .vietnamese],
        .slovak: [.arabic, .bengali, .bulgarian, .simplifiedChinese, .traditionalChinese, .croatian, .czech, .danish, .dutch, .english, .estonian, .finnish, .french, .german, .greek, .hebrew, .hindi, .hungarian, .indonesian, .italian, .japanese, .korean, .latvian, .lithuanian, .norwegian, .polish, .portuguese, .romanian, .russian, .serbian, .slovak, .slovenian, .spanish, .swedish, .thai, .turkish, .ukrainian, .vietnamese],
        .slovenian: [.arabic, .bengali, .bulgarian, .simplifiedChinese, .traditionalChinese, .croatian, .czech, .danish, .dutch, .english, .estonian, .finnish, .french, .german, .greek, .hebrew, .hindi, .hungarian, .indonesian, .italian, .japanese, .korean, .latvian, .lithuanian, .norwegian, .polish, .portuguese, .romanian, .russian, .serbian, .slovak, .slovenian, .spanish, .swedish, .thai, .turkish, .ukrainian, .vietnamese],
        .spanish: [.arabic, .bengali, .bulgarian, .simplifiedChinese, .traditionalChinese, .croatian, .czech, .danish, .dutch, .english, .estonian, .finnish, .french, .german, .greek, .hebrew, .hindi, .hungarian, .indonesian, .italian, .japanese, .korean, .latvian, .lithuanian, .norwegian, .polish, .portuguese, .romanian, .russian, .serbian, .slovak, .slovenian, .spanish, .swedish, .thai, .turkish, .ukrainian, .vietnamese],
//      .swahili/kiswahili: [.swahili/kiswahili], Swahili language: not supported by Easydict
        .swedish: [.arabic, .bengali, .bulgarian, .simplifiedChinese, .traditionalChinese, .croatian, .czech, .danish, .dutch, .english, .estonian, .finnish, .french, .german, .greek, .hebrew, .hindi, .hungarian, .indonesian, .italian, .japanese, .korean, .latvian, .lithuanian, .norwegian, .polish, .portuguese, .romanian, .russian, .serbian, .slovak, .slovenian, .spanish, .swedish, .thai, .turkish, .ukrainian, .vietnamese],
        .thai: [.arabic, .bengali, .bulgarian, .simplifiedChinese, .traditionalChinese, .croatian, .czech, .danish, .dutch, .english, .estonian, .finnish, .french, .german, .greek, .hebrew, .hindi, .hungarian, .indonesian, .italian, .japanese, .korean, .latvian, .lithuanian, .norwegian, .polish, .portuguese, .romanian, .russian, .serbian, .slovak, .slovenian, .spanish, .swedish, .thai, .turkish, .ukrainian, .vietnamese],
        .turkish: [.arabic, .bengali, .bulgarian, .simplifiedChinese, .traditionalChinese, .croatian, .czech, .danish, .dutch, .english, .estonian, .finnish, .french, .german, .greek, .hebrew, .hindi, .hungarian, .indonesian, .italian, .japanese, .korean, .latvian, .lithuanian, .norwegian, .polish, .portuguese, .romanian, .russian, .serbian, .slovak, .slovenian, .spanish, .swedish, .thai, .turkish, .ukrainian, .vietnamese],
        .ukrainian: [.arabic, .bengali, .bulgarian, .simplifiedChinese, .traditionalChinese, .croatian, .czech, .danish, .dutch, .english, .estonian, .finnish, .french, .german, .greek, .hebrew, .hindi, .hungarian, .indonesian, .italian, .japanese, .korean, .latvian, .lithuanian, .norwegian, .polish, .portuguese, .romanian, .russian, .serbian, .slovak, .slovenian, .spanish, .swedish, .thai, .turkish, .ukrainian, .vietnamese],
        .vietnamese: [.arabic, .bengali, .bulgarian, .simplifiedChinese, .traditionalChinese, .croatian, .czech, .danish, .dutch, .english, .estonian, .finnish, .french, .german, .greek, .hebrew, .hindi, .hungarian, .indonesian, .italian, .japanese, .korean, .latvian, .lithuanian, .norwegian, .polish, .portuguese, .romanian, .russian, .serbian, .slovak, .slovenian, .spanish, .swedish, .thai, .turkish, .ukrainian, .vietnamese],
    ]

    static let supportLanguagesDictionary: [Language: String] = [
        .arabic: "ar",
        .bengali: "bn",
        .bulgarian: "bg",
        .simplifiedChinese: "zh",
        .traditionalChinese: "zh",
        .croatian: "hr",
        .czech: "cs",
        .danish: "da",
        .dutch: "nl",
        .english: "en",
        .estonian: "et",
        .finnish: "fi",
        .french: "fr",
        .german: "de",
        .greek: "el",
        .hebrew: "iw",
        .hindi: "hi",
        .hungarian: "hu",
        .indonesian: "id",
        .italian: "it",
        .japanese: "ja",
        .korean: "ko",
        .latvian: "lv",
        .lithuanian: "lt",
        .norwegian: "no",
        .polish: "pl",
        .portuguese: "pt",
        .romanian: "ro",
        .russian: "ru",
        .serbian: "sr",
        .slovak: "sk",
        .slovenian: "sl",
        .spanish: "es",
//      .swahili/kiswahili: "sw",
        .swedish: "sv",
        .thai: "th",
        .turkish: "tr",
        .ukrainian: "uk",
        .vietnamese: "vi",
    ]

    static func transType(from: Language, to: Language) -> GeminiTranslateType {
        // Treat traditional Chinese as simplified Chinese.
        if from == .traditionalChinese {
            return transType(from: .simplifiedChinese, to: to)
        }

        // We can auto convert to Traditional Chinese.
        guard let targetLanguages = supportedTypes[from],
              targetLanguages.contains(to) || to == .traditionalChinese
        else {
            return .unsupported
        }

        guard let from = supportLanguagesDictionary[from],
              let to = supportLanguagesDictionary[to]
        else {
            return .unsupported
        }

        return GeminiTranslateType(rawValue: "\(from)2\(to)")
    }
}
