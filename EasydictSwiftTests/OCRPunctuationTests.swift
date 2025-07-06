//
//  OCRPunctuationTests.swift
//  EasydictSwiftTests
//
//  Created by AI Assistant on 2025/7/3.
//  Copyright © 2024 izual. All rights reserved.
//

import Testing

@testable import Easydict

/// Tests for OCR punctuation normalization across different languages
@Suite("OCR Punctuation", .tags(.ocr, .unit))
struct OCRPunctuationTests {
    // MARK: - Tests

    @Test("OCR Punctuation Normalization English", .tags(.ocr))
    func testOCRPunctuationNormalizationEnglish() {
        let normalizer = OCRTextNormalizer(language: .english)

        // Test Chinese punctuation to English
        let chineseText = "Hello，world。This is a test；right？Yes！"
        let normalizedText = normalizer.normalizeText(chineseText)
        #expect(normalizedText.contains("Hello,"))
        #expect(normalizedText.contains("world."))
        #expect(normalizedText.contains("test;"))
        #expect(normalizedText.contains("right?"))
        #expect(normalizedText.contains("Yes!"))
    }

    @Test("OCR Punctuation Normalization Chinese", .tags(.ocr))
    func testOCRPunctuationNormalizationChinese() {
        let normalizer = OCRTextNormalizer(language: .simplifiedChinese)

        // Test English punctuation to Chinese (but preserve decimals)
        let englishText = "你好,世界.这是测试;对吗?是的!价格是10.99元"
        let normalizedText = normalizer.normalizeText(englishText)
        #expect(normalizedText.contains("你好，"))
        #expect(normalizedText.contains("世界。"))
        #expect(normalizedText.contains("测试；"))
        #expect(normalizedText.contains("对吗？"))
        #expect(normalizedText.contains("是的！"))
        #expect(normalizedText.contains("10.99")) // Decimal should be preserved
    }

    @Test("OCR Chinese Punctuation with Protected Content", .tags(.ocr))
    func testOCRChinesePunctuationWithProtectedContent() {
        let normalizer = OCRTextNormalizer(language: .simplifiedChinese)

        // Test that special content is protected during Chinese punctuation conversion
        let textWithProtectedContent =
            "访问网站 https://easydict.app, 或者邮箱 test@example.com. 文件在 C:/Users/file.txt, 代码是 array.map()."
        let normalizedText = normalizer.normalizeText(textWithProtectedContent)

        // URLs should be preserved
        #expect(normalizedText.contains("https://easydict.app"))

        // Email should be preserved
        #expect(normalizedText.contains("test@example.com"))

        // File path should be preserved
        #expect(normalizedText.contains("C:/Users/file.txt"))

        // Function call should be preserved
        #expect(normalizedText.contains("array.map()"))

        // But surrounding punctuation should be converted to Chinese
        #expect(normalizedText.contains("，")) // Comma after website
        #expect(normalizedText.contains("。")) // Period at the end
    }

    @Test("OCR Punctuation Normalization Korean", .tags(.ocr))
    func testOCRPunctuationNormalizationKorean() {
        let normalizer = OCRTextNormalizer(language: .korean)

        // Korean should use Western punctuation, not Chinese
        let chineseText = "안녕하세요，세계。테스트입니다；맞나요？네！"
        let normalizedText = normalizer.normalizeText(chineseText)
        #expect(normalizedText.contains("안녕하세요,"))
        #expect(normalizedText.contains("세계."))
        #expect(normalizedText.contains("테스트입니다;"))
        #expect(normalizedText.contains("맞나요?"))
        #expect(normalizedText.contains("네!"))
    }

    @Test("OCR Punctuation Normalization Japanese", .tags(.ocr))
    func testOCRPunctuationNormalizationJapanese() {
        let normalizer = OCRTextNormalizer(language: .japanese)

        // Japanese should use Chinese-style punctuation
        let englishText = "こんにちは,世界.テストです;そうですか?はい!"
        let normalizedText = normalizer.normalizeText(englishText)
        #expect(normalizedText.contains("こんにちは，"))
        #expect(normalizedText.contains("世界。"))
        #expect(normalizedText.contains("テストです；"))
        #expect(normalizedText.contains("そうですか？"))
        #expect(normalizedText.contains("はい！"))
    }
}
