//
//  OCRTextProcessingChineseTests.swift
//  EasydictSwiftTests
//
//  Created by tisfeng on 2025/7/3.
//  Copyright © 2025 izual. All rights reserved.
//

import Testing

@testable import Easydict

// MARK: - OCRTextProcessingChineseTests

@Suite("OCR Processing Chinese Text", .tags(.ocr, .unit))
struct OCRTextProcessingChineseTests {
    let normalizer = OCRTextNormalizer(language: .simplifiedChinese)

    @Test("OCR Chinese Text Punctuation", .tags(.ocr))
    func testOCRChineseTextPunctuation() {
        // Test English punctuation to Chinese style
        let mixedText = "你好,世界. array.map() 这是一个测试;对吗?当然!价格是99.99元."
        let normalizedText = normalizer.normalizeText(mixedText)

        // Should convert to Chinese punctuation but preserve decimals
        #expect(normalizedText.contains("你好，世界。"))
        #expect(normalizedText.contains("array.map()")) // array.map() should remain unchanged
        #expect(normalizedText.contains("测试；对吗？"))
        #expect(normalizedText.contains("当然！"))
        #expect(normalizedText.contains("99.99")) // Decimal should be preserved
        #expect(normalizedText.contains("元。"))
    }

    @Test("OCR Chinese Text Spacing", .tags(.ocr))
    func testOCRChineseTextSpacing() {
        // Test multiple spaces in Chinese text
        let spacedText = "这是一个    测试文本，   包含多个    空格和   标点符号。"
        let normalizedText = normalizer.normalizeText(spacedText)

        // Spaces should be normalized
        #expect(normalizedText == "这是一个 测试文本， 包含多个 空格和 标点符号。")
        #expect(!normalizedText.contains("    ")) // No multiple spaces
    }

    @Test("OCR Chinese Mixed Script", .tags(.ocr))
    func testOCRChineseMixedScript() {
        // Test Chinese text with English and numbers, detected as `SimplifiedChinese` language
        let mixedText = """
        欢迎使用   Easydict翻译软件!
        这是一个强大的翻译工具，支持多种服务，包括Google翻译、DeepL翻译等。
        支持多种语言，包括English,   Japanese，Korean等。
        价格：免费版0.00元；专业版99.99元.
        访问网站：https://easydict.app 或 easydict.app  了解更多信息。
        """

        let normalizedText = normalizer.normalizeText(mixedText)

        // Check Chinese punctuation conversion
        #expect(normalizedText.contains("软件！"))
        #expect(normalizedText.contains("English， Japanese，Korean等。"))
        #expect(normalizedText.contains("0.00")) // Preserve decimals
        #expect(normalizedText.contains("元。"))
        #expect(normalizedText.contains("https://easydict.app")) // Preserve URLs

        // Check spacing normalization
        #expect(!normalizedText.contains("   ")) // No triple spaces
        #expect(normalizedText.contains("Easydict翻译")) // No extra space in mixed text
    }

    @Test("OCR Chinese Symbols", .tags(.ocr))
    func testOCRChineseSymbols() {
        // Test symbol normalization in Chinese context
        let symbolText = "包含各种符号•如点号⋅和省略号… 如：省略...以及中文日常省略号。。。"
        let normalizedText = normalizer.normalizeText(symbolText)

        // Check symbol normalization
        #expect(normalizedText.contains("符号 · 如"))
        #expect(normalizedText.contains("点号 · 和"))
        #expect(normalizedText.contains("省略号..."))
        #expect(normalizedText.contains("省略...以及"))
        #expect(normalizedText.contains("中文日常省略号。。。"))
    }
}
