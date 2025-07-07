//
//  OCRImageTests.swift
//  EasydictSwiftTests
//
//  Created by tisfeng on 2025/7/7.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation
import Testing

@testable import Easydict

// MARK: - OCRImageTests

/// Tests for AppleOCREngine using real test images
///
/// These tests validate the OCR functionality against a comprehensive collection of
/// test images covering different languages, text types, and document formats.
/// The test images are located in the ocr-images directory and include:
/// - English text samples (papers, letters, lists)
/// - Chinese text samples (traditional and simplified)
/// - Japanese text samples
/// - Various document formats and layouts
@Suite("Apple OCR Engine Image Tests", .tags(.ocr, .integration))
struct OCRImageTests {
    // MARK: Internal

    /// OCR engine instance for testing
    let ocrEngine = AppleOCREngine()

    // MARK: - English Text Tests

    @Test("English Paper Documents", .tags(.ocr))
    func testEnglishPaperDocuments() async throws {
        let paperImages = [
            "ocr-en-paper-1.png",
            "ocr-en-paper-2.png",
            "ocr-en-paper-3.png",
            "ocr-en-paper-4.png",
            "ocr-en-paper-5.png",
            "ocr-en-paper-6.png",
            "ocr-en-paper-7.png",
            "ocr-en-paper-8.png",
            "ocr-en-paper-9.png",
            "ocr-en-paper-10.png",
            "ocr-en-paper-11.png",
            "ocr-en-paper-12.png",
            "ocr-en-paper-13.png",
            "ocr-en-paper-14.png",
        ]

        for imageName in paperImages {
            try await testOCRImage(
                named: imageName,
                expectedLanguage: .english,
                minTextLength: 20
            )
        }
    }

    @Test("English Text Samples", .tags(.ocr))
    func testEnglishTextSamples() async throws {
        try await testOCRImage(
            named: "ocr-en-text-1.png",
            expectedLanguage: .english,
            minTextLength: 15
        )

        try await testOCRImage(
            named: "ocr-en-text-2.png",
            expectedLanguage: .english,
            minTextLength: 15
        )

        try await testOCRImage(
            named: "ocr-en-text-bitcoin.png",
            expectedLanguage: .english,
            minTextLength: 20,
            shouldContain: "bitcoin"
        )

        try await testOCRImage(
            named: "ocr-en-text-reddit.png",
            expectedLanguage: .english,
            minTextLength: 15
        )
    }

    @Test("English List and Letter", .tags(.ocr))
    func testEnglishListAndLetter() async throws {
        try await testOCRImage(
            named: "ocr-en-list.png",
            expectedLanguage: .english,
            minTextLength: 20
        )

        try await testOCRImage(
            named: "ocr-en-letter-338.png",
            expectedLanguage: .english,
            minTextLength: 30
        )
    }

    // MARK: - Chinese Text Tests

    @Test("Chinese Text Samples", .tags(.ocr))
    func testChineseTextSamples() async throws {
        let chineseImages = [
            "ocr-zh-text-1.png",
            "ocr-zh-text-2.png",
        ]

        for imageName in chineseImages {
            try await testOCRImage(
                named: imageName,
                expectedLanguage: .simplifiedChinese,
                minTextLength: 10
            )
        }
    }

    @Test("Chinese Bitcoin Text", .tags(.ocr))
    func testChineseBitcoinText() async throws {
        try await testOCRImage(
            named: "ocr-zh-text-bitcoin.png",
            expectedLanguage: .simplifiedChinese,
            minTextLength: 15,
            shouldContain: "比特币"
        )
    }

    // MARK: - Japanese Text Tests

    @Test("Japanese Text Samples", .tags(.ocr))
    func testJapaneseTextSamples() async throws {
        let japaneseImages = [
            "ocr-ja-text-1.png",
            "ocr-ja-text-2.png",
        ]

        for imageName in japaneseImages {
            try await testOCRImage(
                named: imageName,
                expectedLanguage: .japanese,
                minTextLength: 8
            )
        }
    }

    // MARK: - Performance and Async Tests

    @Test("OCR Performance Test", .tags(.ocr, .performance))
    func testOCRPerformance() async throws {
        guard let image = loadTestImage(named: "ocr-en-text-1.png") else {
            Issue.record("Failed to load test image")
            return
        }

        let startTime = CFAbsoluteTimeGetCurrent()

        let result = try await ocrEngine.recognizeTextAsync(image: image, language: .auto)

        let duration = CFAbsoluteTimeGetCurrent() - startTime

        #expect(!result.mergedText.isEmpty, "OCR should return text")
        #expect(duration < 5.0, "OCR should complete within 5 seconds")

        print("OCR completed in \(String(format: "%.2f", duration)) seconds")
    }

    @Test("Async OCR API Test", .tags(.ocr))
    func testAsyncOCRAPI() async throws {
        guard let image = loadTestImage(named: "ocr-en-text-1.png") else {
            Issue.record("Failed to load test image")
            return
        }

        guard let cgImage = image.toCGImage() else {
            Issue.record("Failed to convert NSImage to CGImage")
            return
        }

        // Test async text observations API (raw Vision observations)
        let observations = try await ocrEngine.recognizeTextAsync(cgImage: cgImage, language: .auto)
        #expect(!observations.isEmpty, "Should return text observations")

        // Test async string API (simple text string)
        let text = try await ocrEngine.recognizeTextAsString(cgImage: cgImage, language: .auto)
        #expect(!text.isEmpty, "Should return recognized text")
        #expect(text.contains("\n") || !text.isEmpty, "Should contain text content")

        // Test async complete OCR result API (full EZOCRResult)
        let ocrResult = try await ocrEngine.recognizeTextAsync(image: image, language: .auto)
        #expect(!ocrResult.mergedText.isEmpty, "Should return merged text")
        #expect(!ocrResult.texts.isEmpty, "Should return text array")

        print("Async API test completed successfully")
        print("Observations count: \(observations.count)")
        print("Text length: \(text.count)")
        print("OCR result text length: \(ocrResult.mergedText.count)")
    }

    @Test("OCR Error Handling", .tags(.ocr))
    func testOCRErrorHandling() async throws {
        // Test with invalid image (1x1 transparent image)
        let emptyImage = NSImage(size: NSSize(width: 1, height: 1))

        do {
            let result = try await ocrEngine.recognizeTextAsync(image: emptyImage, language: .auto)
            // Should return empty result for invalid image
            #expect(result.mergedText.isEmpty, "Should return empty text for invalid image")
        } catch {
            // Should return QueryError for invalid input
            #expect(error is QueryError, "Should return QueryError for invalid input")
        }

        print("Error handling test completed")
    }

    // MARK: - Language Detection Tests

    @Test("Language Detection Accuracy", .tags(.ocr))
    func testLanguageDetection() async throws {
        let testCases: [(imageName: String, expectedLanguage: Language)] = [
            ("ocr-en-text-1.png", .english),
            ("ocr-zh-text-1.png", .simplifiedChinese),
            ("ocr-ja-text-1.png", .japanese),
        ]

        for testCase in testCases {
            guard let image = loadTestImage(named: testCase.imageName) else {
                Issue.record("Failed to load test image: \(testCase.imageName)")
                continue
            }

            let result = try await ocrEngine.recognizeTextAsync(image: image, language: .auto)

            #expect(
                result.from == testCase.expectedLanguage,
                "Expected \(testCase.expectedLanguage) for \(testCase.imageName), got \(result.from)"
            )
        }
    }

    // MARK: - Comprehensive OCR Test

    @Test("Comprehensive OCR Test", .tags(.ocr), .disabled("Only run manually for full validation"))
    func testAllOCRImages() async throws {
        let allImages = [
            // English papers
            "ocr-en-paper-1.png", "ocr-en-paper-2.png",
            "ocr-en-paper-3.png", "ocr-en-paper-4.png", "ocr-en-paper-5.png",
            "ocr-en-paper-6.png", "ocr-en-paper-7.png", "ocr-en-paper-8.png",
            "ocr-en-paper-9.png", "ocr-en-paper-10.png", "ocr-en-paper-11.png",
            "ocr-en-paper-12.png", "ocr-en-paper-13.png", "ocr-en-paper-14.png",

            // English text samples
            "ocr-en-text-1.png", "ocr-en-text-2.png", "ocr-en-text-bitcoin.png",
            "ocr-en-text-reddit.png", "ocr-en-list.png", "ocr-en-letter-338.png",

            // Chinese text samples
            "ocr-zh-text-1.png", "ocr-zh-text-2.png", "ocr-zh-text-3.png",
            "ocr-zh-text-bitcoin.png",

            // Japanese text samples
            "ocr-ja-text-1.png", "ocr-ja-text-2.png",
        ]

        var successCount = 0
        var failureCount = 0

        for imageName in allImages {
            do {
                try await testOCRImage(named: imageName, minTextLength: 5)
                successCount += 1
            } catch {
                print("❌ Failed to process \(imageName): \(error)")
                failureCount += 1
            }
        }

        print("\n📊 OCR Test Summary:")
        print("✅ Successful: \(successCount)")
        print("❌ Failed: \(failureCount)")
        print(
            "📈 Success Rate: \(String(format: "%.1f", Double(successCount) / Double(allImages.count) * 100))%"
        )

        // Expect at least 80% success rate
        let successRate = Double(successCount) / Double(allImages.count)
        #expect(successRate >= 0.8, "OCR success rate should be at least 80%")
    }

    // MARK: Private

    /// Test images directory path
    ///
    /// `Bundle(for:)` requires a class (`AnyClass`) argument, but `OCRImageTests`
    /// is a `struct`.  We introduce a private dummy class `BundleLocator`
    /// solely to obtain the correct unit‑test bundle.
    private class BundleLocator {}

    private var testBundle = Bundle(for: BundleLocator.self)

    // MARK: - Helper Methods

    /// Load test image from bundle
    /// - Parameter imageName: Name of the image file in Resources directory
    /// - Returns: NSImage instance or nil if loading fails
    private func loadTestImage(named imageName: String) -> NSImage? {
        guard let imagePath = testBundle.path(
            forResource: imageName.components(separatedBy: ".").first,
            ofType: imageName.components(separatedBy: ".").last
        )
        else {
            print("❌ Could not find image path for: \(imageName)")
            return nil
        }

        guard let image = NSImage(contentsOfFile: imagePath) else {
            print("❌ Could not load image from path: \(imagePath)")
            return nil
        }

        print("✅ Loaded image: \(imageName) from \(imagePath)")
        return image
    }

    /// Helper method to test OCR on a single image
    /// - Parameters:
    ///   - imageName: Name of the test image
    ///   - expectedLanguage: Expected detected language (optional)
    ///   - minTextLength: Minimum expected text length (default: 10)
    ///   - shouldContain: Optional text that should be contained in result
    private func testOCRImage(
        named imageName: String,
        expectedLanguage: Language? = nil,
        minTextLength: Int = 10,
        shouldContain: String? = nil
    ) async throws {
        // Load test image
        guard let image = loadTestImage(named: imageName) else {
            Issue.record("Failed to load test image: \(imageName)")
            return
        }

        // Perform OCR
        let result = try await ocrEngine.recognizeTextAsync(image: image, language: .auto)

        // Validate result
        #expect(
            result.mergedText.count >= minTextLength,
            "OCR text should have minimum length of \(minTextLength) characters"
        )
        #expect(!result.texts.isEmpty, "OCR should return text array")

        // Check expected language if specified
        if let expectedLanguage {
            #expect(
                result.from == expectedLanguage,
                "Expected language \(expectedLanguage), got \(result.from)"
            )
        }

        // Check for expected content if specified
        if let shouldContain {
            #expect(
                result.mergedText.localizedCaseInsensitiveContains(shouldContain),
                "OCR result should contain '\(shouldContain)'"
            )
        }

        print(
            "✅ \(imageName): Detected \(result.texts.count) text segments, language: \(result.from)"
        )
        print("  First 100 chars: \(String(result.mergedText.prefix(100)))")
    }
}
