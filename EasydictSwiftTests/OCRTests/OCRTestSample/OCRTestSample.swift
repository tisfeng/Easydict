//
//  OCRTestSample.swift
//  EasydictSwiftTests
//
//  Created by tisfeng on 2025/7/10.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

/// Enum representing the OCR test samples.
/// This provides a type-safe way to access test data, including the image name and the expected OCR text result.
enum OCRTestSample: String, CaseIterable {
    // MARK: - English Text Cases

    case enText1 = "ocr-en-text-1.png"
    case enText2 = "ocr-en-text-2.png"
    case enText3 = "ocr-en-text-3.png"
    case enText4 = "ocr-en-text-4.png"

    case enTextBitcoin = "ocr-en-text-bitcoin.png"
    case enTextReddit = "ocr-en-text-reddit.png"

    /// Entire English page of paper with two culoumns.
    case enPaper0 = "ocr-en-paper-0.png"

    // ocr english paper 1-14
    case enPaper1 = "ocr-en-paper-1.png"
    case enPaper2 = "ocr-en-paper-2.png"
    case enPaper3 = "ocr-en-paper-3.png"
    case enPaper4 = "ocr-en-paper-4.png"
    case enPaper5 = "ocr-en-paper-5.png"
    case enPaper6 = "ocr-en-paper-6.png"
    case enPaper7 = "ocr-en-paper-7.png"
    case enPaper8 = "ocr-en-paper-8.png"
    case enPaper9 = "ocr-en-paper-9.png"
    case enPaper10 = "ocr-en-paper-10.png"
    case enPaper11 = "ocr-en-paper-11.png"
    case enPaper12 = "ocr-en-paper-12.png"
    case enPaper13 = "ocr-en-paper-13.png"
    case enPaper14 = "ocr-en-paper-14.png"

    case enTextList1 = "ocr-en-text-list-1.png"
    case enTextList2 = "ocr-en-text-list-2.png"
    case enTextList3 = "ocr-en-text-list-3.png"

    case enTextLetter338 = "ocr-en-text-letter-338.png"

    case enPoetry8 = "ocr-en-poetry-8.png" // Match zhPoetry8

    // MARK: - Chinese Text Cases

    // ocr chinese text
    case zhText1 = "ocr-zh-text-1.png"
    case zhText2 = "ocr-zh-text-2.png"
    case zhText3 = "ocr-zh-text-3.png"
    case zhText4 = "ocr-zh-text-4.png"

    case zhTextBitcoin = "ocr-zh-text-bitcoin.png"
    case zhTextList1 = "ocr-zh-text-list-1.png"
    case zhTextTwoColums1 = "ocr-zh-text-two-columns-1.png"

    // Chinese modern poetry
    case zhPoetry1 = "ocr-zh-poetry-1.png"
    case zhPoetry2 = "ocr-zh-poetry-2.png"
    case zhPoetry3 = "ocr-zh-poetry-3.png"
    case zhPoetry4 = "ocr-zh-poetry-4.png"
    case zhPoetry5 = "ocr-zh-poetry-5.png"
    case zhPoetry6 = "ocr-zh-poetry-6.png"
    case zhPoetry7 = "ocr-zh-poetry-7.png"
    case zhPoetry8 = "ocr-zh-poetry-8.png"
    case zhPoetry9 = "ocr-zh-poetry-9.png"
    case zhPoetry10 = "ocr-zh-poetry-10.png"
    case zhPoetry11 = "ocr-zh-poetry-11.png"
    case zhPoetry12 = "ocr-zh-poetry-12.png"
    case zhPoetry13 = "ocr-zh-poetry-13.png"

    // Classical Chinese poetry
    case zhClassicalPoetry1 = "ocr-zh-classical-poetry-1.png"
    case zhClassicalPoetry2 = "ocr-zh-classical-poetry-2.png"
    case zhClassicalPoetry3 = "ocr-zh-classical-poetry-3.png"

    // Classical Chinese lyrics
    case zhClassicalLyrics1 = "ocr-zh-classical-lyrics-1.png"
    case zhClassicalLyrics2 = "ocr-zh-classical-lyrics-2.png"
    case zhClassicalLyrics3 = "ocr-zh-classical-lyrics-3.png"
    case zhClassicalLyrics4 = "ocr-zh-classical-lyrics-4.png"
    case zhClassicalLyrics5 = "ocr-zh-classical-lyrics-5.png"
    case zhClassicalLyrics6 = "ocr-zh-classical-lyrics-6.png"
    case zhClassicalLyrics7 = "ocr-zh-classical-lyrics-7.png"
    case zhClassicalLyrics8 = "ocr-zh-classical-lyrics-8.png"
    case zhClassicalLyrics9 = "ocr-zh-classical-lyrics-9.png"
    case zhClassicalLyrics10 = "ocr-zh-classical-lyrics-10.png"
    case zhClassicalLyrics11 = "ocr-zh-classical-lyrics-11.png"

    // MARK: - Japanese Text Cases

    // ocr japanese text
    case jaText1 = "ocr-ja-text-1.png"
    case jaText2 = "ocr-ja-text-2.png"
    case jaText3 = "ocr-ja-text-3.png"
    case jaText4 = "ocr-ja-text-4.png"

    // MARK: - Other Language Cases

    case ruPoetry11 = "ocr-ru-poetry-11.png" // Russian poetry

    // MARK: Unsupported Languages

    // For unsupported languages, we use automatically detected language, so result is not guaranteed.
    case plUnsupportedText1 = "ocr-pl-unsupported-text-1.png"

    // MARK: Internal

    // MARK: - Expected Results

    /// A dictionary holding all the expected results from different language files.
    static let expectedResults: [OCRTestSample: String] = {
        var results = [OCRTestSample: String]()

        // Merge all language-specific expected results
        results.merge(englishExpectedResults) { _, new in new }
        results.merge(chineseExpectedResults) { _, new in new }
        results.merge(classicalChineseExpectedResults) { _, new in new }
        results.merge(japaneseExpectedResults) { _, new in new }
        results.merge(otherLanguageExpectedResults) { _, new in new }

        return results
    }()

    /// The name of the image file for the test case.
    var imageName: String {
        rawValue
    }

    /// The expected text content after OCR processing.
    var expectedText: String {
        Self.expectedResults[self] ?? ""
    }

    /// Get test cases by language
    static func cases(for language: String) -> [OCRTestSample] {
        switch language.lowercased() {
        case "en", "english":
            return englishCases
        case "chinese", "zh":
            return chineseCases
        case "ja", "japanese":
            return japaneseCases
        default:
            return otherLanguageCases
        }
    }
}
