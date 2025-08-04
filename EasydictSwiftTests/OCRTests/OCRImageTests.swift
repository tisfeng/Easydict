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

    // MARK: - Just one test

    @Test("One Test", .tags(.ocr))
    func test() async throws {
        await testOCR(sample: .enPaper1, language: .auto) // Cost 2.7s
    }

    // MARK: - Performance Tests

    // Test one ocr performance test
    @Test("OCR Performance Test One", .tags(.ocr, .performance))
    func testOCRPerformanceOne() async throws {
        // One time cost: 2.17s
//        await measureOCRPerformance(sample: .enPaper1, language: .auto, expectedCost: 6.0)

        // One time cost: 1.30s
        await measureOCRPerformance(sample: .zhClassicalPoetry1, language: .auto, expectedCost: 4.0)
    }

    @Test(
        "OCR Performance Test",
        .tags(.ocr, .performance),
        .disabled("OCR performance test should run independently, since it may fail due to other tests interference.")
    )
    func testOCRPerformance() async throws {
        // Average 3 time cost: 2.26s
        await measureOCRPerformance(sample: .enPaper1, language: .auto, expectedCost: 2.5)

        // Average 3 time cost: 1.28s
        await measureOCRPerformance(sample: .enPaper1, language: .english, expectedCost: 1.5)

        // Average 3 time cost: 3.83s
        await measureOCRPerformance(sample: .enPaper0, language: .auto, expectedCost: 4.0)

        // Average 3 time cost: 2.28s
        await measureOCRPerformance(sample: .enPaper0, language: .english, expectedCost: 2.5)
    }

    // MARK: - English Text Tests

    @Test("English OCR Test", .tags(.ocr))
    func testEnglishOCR() async throws {
        for sample in OCRTestSample.englishCases {
            await testOCR(sample: sample, language: .english)
        }
    }

    // MARK: - Chinese Text Tests

    @Test("Chinese OCR Test", .tags(.ocr))
    func testChineseOCR() async throws {
        for sample in OCRTestSample.chineseCases {
            await testOCR(sample: sample, language: .simplifiedChinese)
        }
    }

    // MARK: - Classical Chinese Text Tests

    @Test("Classical Chinese OCR Test", .tags(.ocr))
    func testClassicalChineseOCR() async throws {
        for sample in OCRTestSample.classicalChineseCases {
            await testOCR(sample: sample, language: .classicalChinese)
        }
    }

    // MARK: - Japanese Text Tests

    @Test("Japanese OCR Test", .tags(.ocr))
    func testJapaneseOCR() async throws {
        for sample in OCRTestSample.japaneseCases {
            await testOCR(sample: sample, language: .japanese)
        }
    }

    // MARK: - Other Language Tests

    @Test("Other Language OCR Test", .tags(.ocr))
    func testOtherLanguageOCR() async throws {
        for sample in OCRTestSample.otherLanguageCases {
            await testOCR(sample: sample, language: .auto)
        }
    }

    // MARK: - All OCR Tests

    @Test(
        "All OCR Tests",
        .tags(.ocr),
        .disabled("This test runs all OCR images, which can take a long time to complete. ")
    )
    func testAllOCRImages() async throws {
        for sample in OCRTestSample.allCases {
            await testOCR(sample: sample)
        }
    }

    // MARK: Private

    // MARK: - Helper Functions

    /// Measure OCR performance for a given image with detailed timing information
    ///
    /// - Parameters:
    ///   - sample: The test sample image to process
    ///   - language: The target language for OCR recognition
    ///   - iterations: Number of iterations to run for averaging (default: 3)
    ///   - expectedCost: Expected average time for recognition in seconds
    private func measureOCRPerformance(
        sample: OCRTestSample,
        language: Language = .auto,
        iterations: Int = 3,
        expectedCost: TimeInterval
    ) async {
        let imageName = sample.imageName

        // Load test image
        guard let image = NSImage.loadTestImage(named: imageName) else {
            Issue.record("Failed to load test image: \(imageName)")
            return
        }

        var totalTime: TimeInterval = 0
        var results: [String] = []

        log("\n🚀 OCR Performance Test")
        log("📷 Image: \(imageName)")
        log("🌐 Language: \(language)")
        log("🔄 Iterations: \(iterations)")
        log("─────────────────────────────────")

        for i in 1 ... iterations {
            let startTime = CFAbsoluteTimeGetCurrent()

            do {
                let result = try await ocrEngine.recognizeTextAsync(
                    image: image,
                    language: language
                )
                let endTime = CFAbsoluteTimeGetCurrent()
                let executionTime = endTime - startTime

                totalTime += executionTime
                results.append(result.mergedText)

                log("📊 Iteration \(i): \(String(format: "%.3f", executionTime))s")

            } catch {
                Issue.record(
                    "OCR recognition failed in iteration \(i): \(error.localizedDescription)"
                )
                return
            }
        }

        let averageTime = totalTime / Double(iterations)
        #expect(
            averageTime < expectedCost,
            "Average time \(averageTime.string3f)s exceeds expected \(expectedCost)s"
        )

        log("─────────────────────────────────")
        log("⏱️  Total Time: \(String(format: "%.3f", totalTime))s")
        log("📈 Average Time: \(averageTime.string3f) < \(expectedCost)s")

        log("📝 Result Preview: \(results.first?.prefix(100) ?? "No result")...")
        log("─────────────────────────────────\n")
    }

    /// Helper function to run OCR on a given image and compare with expected result.
    ///
    /// - Parameter named: The name of the image file in the test bundle.
    private func testOCR(sample: OCRTestSample, language: Language = .auto) async {
        let imageName = sample.imageName
        // Load test image
        guard let image = NSImage.loadTestImage(named: imageName) else {
            Issue.record("Failed to load test image: \(imageName)")
            return
        }

        do {
            // Perform OCR
            let result = try await ocrEngine.recognizeTextAsync(image: image, language: language)
            log("Testing OCR for image: \(imageName)")
            log("Merged text: \(result.mergedText)")

            let ocrText = result.mergedText
            let expectedText = sample.expectedText
            #expect(
                ocrText == expectedText,
                "Does not match expected image: \(imageName)"
            )
        } catch {
            Issue.record(
                "OCR recognition failed for \(sample.imageName): \(error.localizedDescription)"
            )
        }
    }
}
