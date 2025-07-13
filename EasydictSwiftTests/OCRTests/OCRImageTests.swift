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

    @Test("Test", .tags(.ocr))
    func test() async throws {
//        await testOCR(sample: .enText2, language: .auto)
    }

    // MARK: - All OCR Tests

    @Test("All OCR Tests", .tags(.ocr))
    func testAllOCRImages() async throws {
        for sample in OCRTestSample.allCases {
            await testOCR(sample: sample)
        }
    }

    // MARK: Private

    // MARK: - Helper Functions

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
            print("Testing OCR for image: \(imageName)")
            print("Merged text: \(result.mergedText)")

            let ocrText = result.mergedText
            let expectedText = sample.expectedText
            #expect(ocrText == expectedText)
        } catch {
            Issue.record(
                "OCR recognition failed for \(sample.imageName): \(error.localizedDescription)"
            )
        }
    }
}
