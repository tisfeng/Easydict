//
//  OCRTextProcessingTests.swift
//  EasydictSwiftTests
//
//  Created by AI Assistant on 2025/7/3.
//  Copyright © 2024 izual. All rights reserved.
//

import Testing

@testable import Easydict

// MARK: - OCRTextProcessingTests

/// Tests for OCR text processing and normalization
@Suite("OCR Processing English Text", .tags(.ocr, .unit))
struct OCRTextProcessingTests {
    // MARK: - Tests

    let normalizer = OCRTextNormalizer(language: .english)

    @Test("OCR Text Normalizer Single", .tags(.ocr))
    func testSingle() {
        // Test basic normalization of simple text
        let messyText = "Full Changelog: 2.13.0...2.14.1"
        let normalizedText = normalizer.normalizeText(messyText)

        #expect(normalizedText.contains("2.13.0...2.14.1")) // Ensure text is unchanged
    }

    @Test("OCR Text Normalizer Spacing", .tags(.ocr))
    func testOCRTextNormalizerSpacing() {
        // Combine multiple test cases into one multiline string
        let testCases = """
        Hello    world   test
        Hello , world .Test ; again !
        The price is 10.99 dollars
        """

        let normalizedText = normalizer.normalizeText(testCases)

        // Check all expected results in the normalized text
        #expect(normalizedText.contains("Hello world test")) // Multiple spaces reduced
        #expect(normalizedText.contains("Hello, world. Test; again!")) // Punctuation spacing fixed
        #expect(normalizedText.contains("10.99")) // Decimal numbers preserved
        #expect(!normalizedText.contains("    ")) // No multiple spaces anywhere
    }

    @Test("Essential OCR symbol corrections")
    func testEssentialSymbolCorrections() {
        // Combine all essential symbol corrections into one test
        let testCases = """
        don´t work properly
        hello—world connection
        pages 1–10 range
        test―case scenario
        wait… for response
        Item 1 • Item 2 ⋅ Item 3 ∙ Item 4
        """

        let normalizedText = normalizer.normalizeText(testCases)

        // Check all expected corrections
        #expect(normalizedText.contains("don't work")) // Acute accent correction
        #expect(normalizedText.contains("hello-world")) // Em dash
        #expect(normalizedText.contains("pages 1-10")) // En dash
        #expect(normalizedText.contains("test-case")) // Horizontal bar
        #expect(normalizedText.contains("wait... for")) // Ellipsis normalization
        #expect(normalizedText.contains("Item 1 · Item 2 · Item 3 · Item 4")) // Dots unified
    }

    @Test("OCR Complete Text Normalization", .tags(.ocr))
    func testOCRCompleteTextNormalization() {
        // Comprehensive test with various OCR issues in one multiline string
        let messyText = """
        This is a   test´ with   multiple   spaces—and dashes…
        It has wrong    punctuation；and various•symbols⋅that need∙fixing。

        First paragraph with    multiple    spaces.


        Third paragraph   with   lots   of   spaces.
        Temperature: 98°F and calculation 2×3=6÷2 result.
        Code example: `array.map()` and "quoted text" with 'apostrophes'.
        """

        let cleanText = normalizer.normalizeText(messyText)

        // Check symbol corrections
        #expect(cleanText.contains("test'")) // Acute accent fixed
        #expect(cleanText.contains("spaces-and")) // Dashes normalized
        #expect(cleanText.contains("dashes...")) // Ellipsis normalized
        #expect(cleanText.contains("punctuation;")) // Western punctuation for English
        #expect(cleanText.contains("symbols · that")) // Dots unified

        // Check spacing normalization
        #expect(!cleanText.contains("    ")) // No multiple spaces
        #expect(cleanText.contains("First paragraph with multiple spaces."))
        #expect(cleanText.contains("Third paragraph with lots of spaces."))

        // Check preserved symbols
        #expect(cleanText.contains("98°F")) // Degree symbol preserved
        #expect(cleanText.contains("2×3=6÷2")) // Math symbols preserved
        #expect(cleanText.contains("`array.map()`")) // Backticks preserved
        #expect(cleanText.contains("\"quoted text\"")) // Quotes preserved
        #expect(cleanText.contains("'apostrophes'")) // Apostrophes preserved

        // Check paragraph structure preservation
        #expect(cleanText.contains("spaces.\n\nThird paragraph")) // Paragraph separation maintained
    }
}
