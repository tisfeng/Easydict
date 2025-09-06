//
//  OCRTestSampleOther.swift
//  EasydictSwiftTests
//
//  Created by tisfeng on 2025/7/27.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

// swiftlint:disable line_length

/// Other language OCR test samples
extension OCRTestSample {
    // MARK: - Other Language Cases

    static let otherLanguageCases: [OCRTestSample] = [
        .plText1,
        .ruPoetry11,
    ]

    // MARK: - Other Language Expected Results

    /// Expected results for other language OCR test samples
    static let otherLanguageExpectedResults: [OCRTestSample: String] = [
        plText1: """
        Anseio por te ver, mas, por favor, lembra-te que não vou pedir para te ver.

        Não é por orgulho, sabes que não tenho orgulho diante de ti, mas porque, só quando também me quiseres ver, o nosso encontro será significativo.
        """,

        ruPoetry11: """
        Парус

        Белеет парус одинокий
        В тумане моря голубом! ...
        Что ищет он в стране далекой?
        Что кинул он в краю родном? ...
        Играют волны - ветер свищет,
        И мачта гнется и скрыпит...
        Увы, - он счастия не ищет
        И не от счастия бежит!
        Под ним струя светлей лазури,
        Над ним луч солнца золотой...
        А он, мятежный, просит бури,
        Как будто в бурях есть покой!
        """,
    ]
}

// swiftlint:enable line_length
