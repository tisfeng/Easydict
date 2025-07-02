//
//  OCRTextProcessingTests.swift
//  EasydictSwiftTests
//
//  Created by AI Assistant on 2025/7/3.
//  Copyright © 2024 izual. All rights reserved.
//

import Testing

@testable import Easydict

/// Tests for OCR text processing and normalization
@Suite("OCR Text Processing", .tags(.ocr, .unit))
struct OCRTextProcessingTests {

    @Test("OCR Text Normalizer Spacing", .tags(.ocr))
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

    @Test("OCR Text Normalization Quotes", .tags(.ocr))
    func testOCRTextNormalizationQuotes() async {
        let metrics = OCRMetrics()
        metrics.language = .english
        let normalizer = OCRTextNormalizer(metrics: metrics)

        // Test quote normalization
        let quoteText =
            "This is a `test´ with \u{201C}quotes\u{201D} and \u{2018}apostrophes\u{2019}"
        let normalizedQuotes = normalizer.normalizeTextSymbols(in: quoteText)
        #expect(normalizedQuotes.contains("'test'"))
        #expect(normalizedQuotes.contains("\"quotes\""))
        #expect(normalizedQuotes.contains("'apostrophes'"))
    }

    @Test("OCR Text Normalization Dashes", .tags(.ocr))
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

    @Test("OCR Text Normalization Symbols", .tags(.ocr))
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

    @Test("OCR Text Normalization Dots", .tags(.ocr))
    func testOCRTextNormalizationDots() async {
        let metrics = OCRMetrics()
        metrics.language = .english
        let normalizer = OCRTextNormalizer(metrics: metrics)

        // Test various dot symbols
        let dotText = "Item 1 • Item 2 ⋅ Item 3 ∙ Item 4"
        let normalizedDots = normalizer.normalizeTextSymbols(in: dotText)
        #expect(normalizedDots.contains("Item 1 · Item 2 · Item 3 · Item 4"))
    }

    @Test("OCR Text Normalization Ellipsis", .tags(.ocr))
    func testOCRTextNormalizationEllipsis() async {
        let metrics = OCRMetrics()
        metrics.language = .english
        let normalizer = OCRTextNormalizer(metrics: metrics)

        // Test ellipsis normalization
        let ellipsisText = "Wait… for it"
        let normalizedEllipsis = normalizer.normalizeTextSymbols(in: ellipsisText)
        #expect(normalizedEllipsis.contains("Wait... for it"))
    }

    @Test("OCR Complete Text Normalization", .tags(.ocr, .integration))
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

    @Test("OCR Paragraph Preservation", .tags(.ocr))
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
        let nonEmptyLines = lines.filter {
            !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        #expect(nonEmptyLines.count == 3)  // Should have exactly 3 paragraphs

        // Should have empty lines between paragraphs
        #expect(normalizedText.contains("spaces.\n\nSecond paragraph"))
        #expect(normalizedText.contains("spaces.\n\nThird paragraph"))
    }
}
