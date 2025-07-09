//
//  OCRLineAnalyzerTests.swift
//  EasydictSwiftTests
//
//  Created by tisfeng on 2025/7/8.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation
import Testing
import Vision

@testable import Easydict

// MARK: - OCRLineAnalyzerTests

/// Tests for OCRLineAnalyzer functionality
///
/// These tests validate the line analysis capabilities of OCRLineAnalyzer,
/// specifically focusing on the isBigLineSpacing function with real OCR data.
@Suite("OCR Line Analyzer Tests", .tags(.ocr, .unit))
struct OCRLineAnalyzerTests {
    var metrics = OCRMetrics()
    lazy var analyzer = OCRLineAnalyzer(metrics: metrics)

    @Test("Test ocr-en-text-1.png")
    mutating func testOcrEnText1() async throws {
        // Test specific image with expected big spacing text
        try await testBigLineSpacingWithImage(
            imageName: "ocr-en-text-1.png",
            language: .english,
            expectedBigSpacingTexts: [
                "If 4 cars take 2 hours to travel from",
            ],
        )
    }

    @Test("Test ocr-en-text-3.png")
    mutating func testOcrEnText3() async throws {
        // Test specific image with no expected big spacing texts
        try await testBigLineSpacingWithImage(
            imageName: "ocr-en-text-3.png",
            language: .english,
            expectedBigSpacingTexts: [],
        )
    }

    @Test("Test ocr-en-text-2.png")
    mutating func testOcrEnText2() async throws {
        // Test specific image with multiple expected big spacing texts
        try await testBigLineSpacingWithImage(
            imageName: "ocr-en-text-2.png",
            language: .english,
            expectedBigSpacingTexts: [
                "Today, Unity （the engine we use to make our games） announced that they'll soon",
                "Guess who has a somewhat highly anticipated game coming to Xbox Game Pass in 2024? That's",
                "That means Another Crab's Treasure will be free to install for the 25 million Game Pass",
                "And that's before we even think about sales on other platforms, or pirated installs of our game, or",
                "This decision puts us and countless other studios in a position where we might not be able to",
                "On behalf of the dev community, we're calling on Unity to reverse the latest in a string of",
                "I fucking hate it here.",
            ],
        )
    }

    @Test("Test ocr-en-text-bitcoin.png")
    mutating func testOcrEnTextBitcoin() async throws {
        // Test specific image with expected big spacing text
        try await testBigLineSpacingWithImage(
            imageName: "ocr-en-text-bitcoin.png",
            language: .english,
            expectedBigSpacingTexts: [
                "Satoshi Nakamoto",
                "Abstract. A purely peer-to-peer version of electronic cash would allow online",
                "1. Introduction",
                "Commerce on the Internet has come to rely almost exclusively on financial institutions serving as",
            ],
        )
    }

    @Test("Test Chinese Text OCR")
    mutating func testOcrChineseText() async throws {
        // Test Chinese text with specific language parameter
        try await testBigLineSpacingWithImage(
            imageName: "ocr-zh-text-1.png",
            language: .simplifiedChinese,
            expectedBigSpacingTexts: [
                "哈哈哈，特别有意思，没想到这种数学题真的在生活中遇到了",
                "儿子幼儿园要求用现金买东西，挑选-付钱-找钱过程，拍个视频上传",
                "正好路过楼下超市我寻思把这个东西做了，然后我就跟老板说，你借",
                "老板岁数挺大，五十多岁吧，说行，就给我拿出20块钱，我儿子挑了",
                "然后视频录完了，我就把11块还给了老板，同时扫码支付了9元，谢",
                "老板：诶，东西你别拿走啊",
                "我：啊？我付钱啦，扫码付的",
                "老板：你用我的钱买的啊，我还找你11块钱啊",
                "然后我就仔细给他解释了一下，他最后还是让我走了，但是他的眼神",
            ],
        )
    }

    @Test("Test Japanese Text OCR")
    mutating func testOcrJapaneseText() async throws {
        // Test Japanese text with specific language parameter
        try await testBigLineSpacingWithImage(
            imageName: "ocr-ja-text-1.png",
            language: .japanese,
            expectedBigSpacingTexts: [
                "この度相沢みなみはAV女優として",
                "引退に至るまでの経緯を正直にお話しさせて頂",
                "私はある方にスカウトをされ約7年前に",
                "相沢社長には夢がありました。",
            ],
        )
    }

    /// Generic test function for big line spacing detection with specified image and expectations
    ///
    /// This reusable test function loads a specified test image, performs OCR, and validates
    /// that only the expected texts have big line spacing while others have normal spacing.
    ///
    /// - Parameters:
    ///   - imageName: Name of the test image file to load
    ///   - expectedBigSpacingTexts: Array of text strings that should have big line spacing
    ///   - language: Language for OCR processing (defaults to .english)
    /// - Throws: Test error if validation fails or image cannot be loaded
    mutating func testBigLineSpacingWithImage(
        imageName: String,
        language: Language = .auto,
        expectedBigSpacingTexts: [String]
    ) async throws {
        print("🧪 Testing big line spacing with image: \(imageName)")
        print("   Language: \(language)")
        print("   Expected big spacing texts: \(expectedBigSpacingTexts)")

        // Load real OCR data
        guard let (image, observations) = await NSImage.loadTestImageWithOCR(
            named: imageName,
            language: language
        )
        else {
            Issue.record("Failed to load test image '\(imageName)' or perform OCR")
            return
        }

        #expect(
            observations.count >= 2, "Image '\(imageName)' should have at least 2 text observations"
        )

        // Setup metrics and analyzer
        metrics = OCRMetrics(
            ocrImage: image,
            language: language,
            textObservations: observations
        )
        analyzer = OCRLineAnalyzer(metrics: metrics)

        // Print all observations for debugging
        print("📝 OCR Results for '\(imageName)' (Language: \(language)):")
        for (index, observation) in observations.enumerated() {
            print("  [\(index)]: '\(observation.firstText)'")
        }

        // Validate big line spacing expectations
        try validateBigLineSpacing(
            expectedBigSpacingTexts: expectedBigSpacingTexts,
            observations: observations
        )

        print("✅ Test completed successfully for image: \(imageName)")
    }

    /// Check if text observation identified by its text content has big line spacing
    ///
    /// This method searches for a text observation by its content and checks if it
    /// has big line spacing compared to the previous observation.
    ///
    /// - Parameters:
    ///   - text: The text content to search for
    ///   - observations: Array of text observations to search in
    /// - Returns: true if the observation has big line spacing, false otherwise
    /// - Throws: Test error if text is not found or index is invalid
    mutating func isBigLineSpacing(text: String, observations: [VNRecognizedTextObservation]) throws
        -> Bool {
        // Find the observation with matching text
        guard let currentIndex = observations.firstIndex(where: { $0.firstText == text }) else {
            Issue.record("Text '\(text)' not found in observations")
            return false
        }

        // Ensure we can form a pair (current observation is not the first)
        guard currentIndex > 0 else {
            Issue.record(
                "Text '\(text)' is the first observation, cannot check spacing with previous"
            )
            return false
        }

        let pair = OCRTextObservationPair(
            current: observations[currentIndex],
            previous: observations[currentIndex - 1]
        )

        return analyzer.isBigLineSpacing(pair: pair)
    }

    /// Validate that specific texts have big line spacing while others don't
    ///
    /// This comprehensive validation method checks that only the specified texts
    /// have big line spacing, while all other text observations should have normal spacing.
    ///
    /// - Parameters:
    ///   - expectedBigSpacingTexts: Array of text strings that should have big spacing
    ///   - observations: Array of all text observations
    /// - Throws: Test error if validation fails
    mutating func validateBigLineSpacing(
        expectedBigSpacingTexts: [String],
        observations: [VNRecognizedTextObservation]
    ) throws {
        print("🧪 Validating big line spacing expectations...")
        print("  Expected big spacing texts: \(expectedBigSpacingTexts)")

        var actualBigSpacingTexts: [String] = []
        var normalSpacingTexts: [String] = []

        // Check all observations (starting from index 1 since we need a previous observation)
        for index in 1 ..< observations.count {
            let currentText = observations[index].firstText
            let hasBigSpacing = try isBigLineSpacing(text: currentText, observations: observations)

            if hasBigSpacing {
                actualBigSpacingTexts.append(currentText)
            } else {
                normalSpacingTexts.append(currentText)
            }
        }

        print("📊 Validation Results:")
        print("  Actual big spacing texts: \(actualBigSpacingTexts)")

        // Validate that all expected texts have big spacing
        for expectedText in expectedBigSpacingTexts {
            #expect(
                actualBigSpacingTexts.contains(expectedText),
                "Expected text '\(expectedText)' should have big line spacing"
            )
        }

        // Validate that no unexpected texts have big spacing
        for actualText in actualBigSpacingTexts {
            #expect(
                expectedBigSpacingTexts.contains(actualText),
                "Text '\(actualText)' has big spacing but was not expected to"
            )
        }

        print("✅ Big line spacing validation completed successfully")
    }

    /// Find text observation by partial text content match
    ///
    /// Searches for text observations that contain the specified text substring.
    /// Useful when you know part of the text content but not the exact match.
    ///
    /// - Parameters:
    ///   - partialText: Substring to search for in text observations
    ///   - observations: Array of text observations to search
    /// - Returns: Array of matching observations with their indices
    func findObservations(
        containing partialText: String,
        in observations: [VNRecognizedTextObservation]
    )
        -> [(index: Int, observation: VNRecognizedTextObservation)] {
        observations.enumerated().compactMap { index, observation in
            if observation.firstText.localizedCaseInsensitiveContains(partialText) {
                return (index: index, observation: observation)
            }
            return nil
        }
    }

    /// Check big line spacing for text containing specific substring
    ///
    /// Similar to the exact text match version, but searches for observations
    /// containing the specified substring.
    ///
    /// - Parameters:
    ///   - partialText: Substring to search for
    ///   - observations: Array of text observations
    /// - Returns: Array of results for all matching observations
    mutating func checkBigLineSpacing(
        forTextContaining partialText: String,
        observations: [VNRecognizedTextObservation]
    )
        -> [(text: String, hasBigSpacing: Bool)] {
        let matches = findObservations(containing: partialText, in: observations)

        return matches.compactMap { indexAndObservation in
            let index = indexAndObservation.index
            let observation = indexAndObservation.observation

            // Skip first observation as it cannot have spacing with previous
            guard index > 0 else { return nil }

            let pair = OCRTextObservationPair(
                current: observation,
                previous: observations[index - 1]
            )

            let hasBigSpacing = analyzer.isBigLineSpacing(pair: pair)
            return (text: observation.firstText, hasBigSpacing: hasBigSpacing)
        }
    }

    /// Analyze big line spacing with language parameter
    ///
    /// Enhanced version of the analysis function that supports different languages.
    ///
    /// - Parameters:
    ///   - imageName: Name of the test image file to analyze
    ///   - language: Language for OCR processing (defaults to .english)
    /// - Returns: Array of tuples containing text and whether it has big spacing
    mutating func analyzeBigLineSpacing(
        imageName: String,
        language: Language = .english
    ) async throws
        -> [(text: String, hasBigSpacing: Bool, gap: Double)] {
        print("🔍 Analyzing big line spacing for image: \(imageName) (Language: \(language))")

        // Load OCR data
        guard let (image, observations) = await NSImage.loadTestImageWithOCR(
            named: imageName,
            language: language
        )
        else {
            Issue.record("Failed to load test image '\(imageName)' or perform OCR")
            return []
        }

        guard observations.count >= 2 else {
            print("⚠️  Image '\(imageName)' has fewer than 2 text observations")
            return []
        }

        // Setup metrics and analyzer
        metrics = OCRMetrics(
            ocrImage: image,
            language: language,
            textObservations: observations
        )
        analyzer = OCRLineAnalyzer(metrics: metrics)

        // Analyze all observations
        var results: [(text: String, hasBigSpacing: Bool, gap: Double)] = []

        print("📝 Spacing Analysis Results for \(language):")
        for index in 1 ..< observations.count {
            let current = observations[index]
            let previous = observations[index - 1]
            let pair = OCRTextObservationPair(current: current, previous: previous)

            let text = current.firstText
            let gap = pair.verticalGap
            let hasBigSpacing = analyzer.isBigLineSpacing(pair: pair)

            results.append((text: text, hasBigSpacing: hasBigSpacing, gap: gap))

            let spacingIndicator = hasBigSpacing ? "🔸" : "🔹"
            print("  \(spacingIndicator) '\(text)' - gap: \(String(format: "%.3f", gap))")
        }

        let bigSpacingCount = results.filter { $0.hasBigSpacing }.count
        print("📊 Summary: \(bigSpacingCount)/\(results.count) texts have big spacing")

        return results
    }
}
