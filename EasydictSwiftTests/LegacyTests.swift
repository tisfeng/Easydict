//
//  Test.swift
//  Easydict
//
//  Created by tisfeng on 2024/10/9.
//  Copyright © 2024 izual. All rights reserved.
//

import SelectedTextKit
import Testing
import Translation

@testable import Easydict

@available(macOS 15.0, *)
@Test
func testLanguageAvailability() async {
    let apple = AppleService()
    await apple.prepareSupportedLanguages()
}

@MainActor
@available(macOS 15.0, *)
@Test
func appleOfflineTranslation() async throws {
    let translationService = TranslationService(
        configuration: .init(
            source: .init(languageCode: .english),
            target: .init(languageCode: .chinese)
        )
    )

    #expect(try await translationService.translate(text: "Hello, world!").targetText == "你好，世界！")
    #expect(try await translationService.translate(text: "good").targetText == "利益")

    let response = try await translationService.translate(
        text: "你好",
        sourceLanguage: .init(languageCode: .chinese),
        targetLanguage: .init(languageCode: .english)
    )
    print(response)
    #expect(response.targetText == "Hello")
}

@Test
func testAES() {
    let text = "123"
    let encryptedText = text.encryptAES()
    let decryptedText = encryptedText.decryptAES()
    #expect(decryptedText == text)
}

@Test
func testAlertVolume() async throws {
    let originalVolume = try await AppleScriptTask.alertVolume()
    print("Original volume: \(originalVolume)")

    let testVolume = 50
    try await AppleScriptTask.setAlertVolume(testVolume)

    let newVolume = try await AppleScriptTask.alertVolume()
    #expect(newVolume == testVolume)

    try await AppleScriptTask.setAlertVolume(originalVolume)
    #expect(true, "Alert volume test completed")
}

@Test
func testGetSelectedText() async throws {
    // Run thousands of times to test crash.
    for i in 0..<2000 {
        print("test index: \(i)")
        let selectedText = await (try? getSelectedText()) ?? ""
        print("\(i) selectedText: \(selectedText)")
    }
    #expect(true, "Test getSelectedText completed without crash")
}

@Test
func testConcurrentGetSelectedText() async throws {
    await withTaskGroup(of: Void.self) { group in
        for i in 0..<2000 {
            group.addTask {
                print("test index: \(i)")
                let selectedText = (try? await getSelectedText()) ?? ""
                print("\(i) selectedText: \(selectedText)")
            }
        }
    }
    #expect(true, "Concurrent test getSelectedText completed without crash")
}

@Test
func testFilterThinkTags() {
    let testCases: [(input: String, expected: String)] = [
        ("<think>hello", ""),
        ("<think></think>hello", "hello"),
        ("<think>hello</think>world", "world"),
        ("hello<think>world</think>", "hello<think>world</think>"),
        ("no tags here", "no tags here"),
        ("", ""),
    ]

    for (index, testCase) in testCases.enumerated() {
        let result = testCase.input.filterThinkTagContent()
        print("Test Case \(index + 1): \(result)")
        #expect(result == testCase.expected)
    }
}

// MARK: - OCR Text Processing Tests

@Test
func testOCRTextNormalizerSpacing() async {
    let metrics = OCRMetrics()
    metrics.language = .english
    let normalizer = OCRTextNormalizer(metrics: metrics)

    // Test multiple spaces (should be reduced to single space)
    let multiSpaceText = "Hello    world   test"
    let normalizedSpaces = normalizer.normalizeTextSymbols(in: multiSpaceText)
    #expect(normalizedSpaces == "Hello world test")

    // Test punctuation spacing for English
    let punctuationText = "Hello , world .Test ; again !"
    let normalizedPunctuation = normalizer.normalizeTextSymbols(in: punctuationText)
    #expect(normalizedPunctuation.contains("Hello, world. Test; again!"))

    // Test decimal numbers should not be affected
    let decimalText = "The price is 10 . 99 dollars"
    let normalizedDecimal = normalizer.normalizeTextSymbols(in: decimalText)
    #expect(normalizedDecimal.contains("10.99"))
}

@Test
func testOCRTextNormalizationQuotes() async {
    let metrics = OCRMetrics()
    metrics.language = .english
    let normalizer = OCRTextNormalizer(metrics: metrics)

    // Test quote normalization
    let quoteText = "This is a `test´ with \u{201C}quotes\u{201D} and \u{2018}apostrophes\u{2019}"
    let normalizedQuotes = normalizer.normalizeTextSymbols(in: quoteText)
    #expect(normalizedQuotes.contains("'test'"))
    #expect(normalizedQuotes.contains("\"quotes\""))
    #expect(normalizedQuotes.contains("'apostrophes'"))
}

@Test
func testOCRTextNormalizationDashes() async {
    let metrics = OCRMetrics()
    metrics.language = .english
    let normalizer = OCRTextNormalizer(metrics: metrics)

    // Test dash normalization
    let dashText = "This is a test—with different–dashes―here"
    let normalizedDashes = normalizer.normalizeTextSymbols(in: dashText)
    #expect(normalizedDashes.contains("test-with"))
    #expect(normalizedDashes.contains("different-dashes-here"))
}

@Test
func testOCRTextNormalizationSymbols() async {
    let metrics = OCRMetrics()
    metrics.language = .english
    let normalizer = OCRTextNormalizer(metrics: metrics)

    // Test symbol normalization
    let symbolText = "Temperature is 98° and 2×3÷2 equals 3"
    let normalizedSymbols = normalizer.normalizeTextSymbols(in: symbolText)
    #expect(normalizedSymbols.contains("98o"))
    #expect(normalizedSymbols.contains("2x3/2"))
}

@Test
func testOCRTextNormalizationDots() async {
    let metrics = OCRMetrics()
    metrics.language = .english
    let normalizer = OCRTextNormalizer(metrics: metrics)

    // Test various dot symbols
    let dotText = "Item 1 • Item 2 ⋅ Item 3 ∙ Item 4"
    let normalizedDots = normalizer.normalizeTextSymbols(in: dotText)
    #expect(normalizedDots.contains("Item 1 · Item 2 · Item 3 · Item 4"))
}

@Test
func testOCRTextNormalizationEllipsis() async {
    let metrics = OCRMetrics()
    metrics.language = .english
    let normalizer = OCRTextNormalizer(metrics: metrics)

    // Test ellipsis normalization
    let ellipsisText = "Wait… for it"
    let normalizedEllipsis = normalizer.normalizeTextSymbols(in: ellipsisText)
    #expect(normalizedEllipsis.contains("Wait... for it"))
}

@Test
func testOCRPunctuationNormalizationEnglish() async {
    let metrics = OCRMetrics()
    metrics.language = .english
    let normalizer = OCRTextNormalizer(metrics: metrics)

    // Test Chinese punctuation to English
    let chineseText = "Hello，world。This is a test；right？Yes！"
    let normalizedText = normalizer.normalizeTextSymbols(in: chineseText)
    #expect(normalizedText.contains("Hello,"))
    #expect(normalizedText.contains("world."))
    #expect(normalizedText.contains("test;"))
    #expect(normalizedText.contains("right?"))
    #expect(normalizedText.contains("Yes!"))
}

@Test
func testOCRPunctuationNormalizationChinese() async {
    let metrics = OCRMetrics()
    metrics.language = .simplifiedChinese
    let normalizer = OCRTextNormalizer(metrics: metrics)

    // Test English punctuation to Chinese (but preserve decimals)
    let englishText = "你好,世界.这是测试;对吗?是的!价格是10.99元"
    let normalizedText = normalizer.normalizeTextSymbols(in: englishText)
    #expect(normalizedText.contains("你好，"))
    #expect(normalizedText.contains("世界。"))
    #expect(normalizedText.contains("测试；"))
    #expect(normalizedText.contains("对吗？"))
    #expect(normalizedText.contains("是的！"))
    #expect(normalizedText.contains("10.99"))  // Decimal should be preserved
}

@Test
func testOCRPunctuationNormalizationKorean() async {
    let metrics = OCRMetrics()
    metrics.language = .korean
    let normalizer = OCRTextNormalizer(metrics: metrics)

    // Korean should use Western punctuation, not Chinese
    let chineseText = "안녕하세요，세계。테스트입니다；맞나요？네！"
    let normalizedText = normalizer.normalizeTextSymbols(in: chineseText)
    #expect(normalizedText.contains("안녕하세요,"))
    #expect(normalizedText.contains("세계."))
    #expect(normalizedText.contains("테스트입니다;"))
    #expect(normalizedText.contains("맞나요?"))
    #expect(normalizedText.contains("네!"))
}

@Test
func testOCRPunctuationNormalizationJapanese() async {
    let metrics = OCRMetrics()
    metrics.language = .japanese
    let normalizer = OCRTextNormalizer(metrics: metrics)

    // Japanese should use Chinese-style punctuation
    let englishText = "こんにちは,世界.テストです;そうですか?はい!"
    let normalizedText = normalizer.normalizeTextSymbols(in: englishText)
    #expect(normalizedText.contains("こんにちは，"))
    #expect(normalizedText.contains("世界。"))
    #expect(normalizedText.contains("テストです；"))
    #expect(normalizedText.contains("そうですか？"))
    #expect(normalizedText.contains("はい！"))
}

@Test
func testOCRCompleteTextNormalization() async {
    let metrics = OCRMetrics()
    metrics.language = .english
    let normalizer = OCRTextNormalizer(metrics: metrics)

    // Test complete normalization pipeline
    let messyText = """
        This is a   `test´ with   \u{201C}bad quotes\u{201D}   and—dashes…
        It has multiple    spaces，wrong punctuation；and
        various•symbols⋅that need∙fixing。
        """

    let cleanText = normalizer.normalizeTextSymbols(in: messyText)

    // The text should be much cleaner now
    #expect(cleanText.contains("'test'"))
    #expect(cleanText.contains("\"bad quotes\""))
    #expect(cleanText.contains("and-dashes..."))
    #expect(cleanText.contains("spaces, wrong punctuation;"))
    #expect(cleanText.contains("symbols · that"))
    #expect(!cleanText.contains("    "))  // No multiple spaces
}

@Test
func testOCRParagraphPreservation() async {
    let metrics = OCRMetrics()
    metrics.language = .english
    let normalizer = OCRTextNormalizer(metrics: metrics)

    // Test that paragraph structure is preserved while fixing spacing
    let paragraphText = """
        First paragraph with    multiple    spaces.

        Second paragraph also    has   extra   spaces.


        Third paragraph   with   lots   of   spaces.
        """

    let normalizedText = normalizer.normalizeTextSymbols(in: paragraphText)

    // Spaces within lines should be normalized
    #expect(normalizedText.contains("First paragraph with multiple spaces."))
    #expect(normalizedText.contains("Second paragraph also has extra spaces."))
    #expect(normalizedText.contains("Third paragraph with lots of spaces."))

    // But paragraph separation should be preserved (single empty line between paragraphs)
    let lines = normalizedText.components(separatedBy: "\n")
    let nonEmptyLines = lines.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    #expect(nonEmptyLines.count == 3)  // Should have exactly 3 paragraphs

    // Should have empty lines between paragraphs
    #expect(normalizedText.contains("spaces.\n\nSecond paragraph"))
    #expect(normalizedText.contains("spaces.\n\nThird paragraph"))
}
