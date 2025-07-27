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
        .plUnsupportedText1,
    ]

    // MARK: - Other Language Expected Results

    /// Expected results for other language OCR test samples
    static let otherLanguageExpectedResults: [OCRTestSample: String] = [
        // For unsupported languages, we use automatically detected language, so result is not guaranteed.
        plUnsupportedText1: """
        Anseio por te ver, mas, por favor, lembra-te que não vou pedir para te ver.

        Não é por orgulho, sabes que não tenho orgulho diante de ti, mas porque, só quando também me quiseres ver, o nosso encontro será significativo.
        """,
    ]
}

// swiftlint:enable line_length
