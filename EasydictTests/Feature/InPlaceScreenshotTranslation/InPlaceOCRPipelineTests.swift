//
//  InPlaceOCRPipelineTests.swift
//  EasydictTests
//
//  Created by Eric Pan on 2026/8/30.
//  Copyright © 2026 izual. All rights reserved.
//

import CoreGraphics
import Testing

@testable import Easydict

// MARK: - InPlaceOCRPipelineTests

/// Verifies local OCR language forwarding, immutable block output, and remote-request safety limits.
@Suite("In-place OCR Pipeline", .tags(.inPlaceTranslation, .ocr, .unit))
struct InPlaceOCRPipelineTests {
    // MARK: Internal

    @Test("Forwards the selected language and returns detected layout metadata")
    func returnsImmutableLayoutResult() async throws {
        let recognizer = TestLayoutRecognizer(
            result: layoutResult(
                language: .japanese,
                observations: [observation(text: "hello")]
            )
        )
        let pipeline = InPlaceOCRPipeline(recognizer: recognizer)
        let image = try #require(makeImage())

        let result = try await pipeline.recognize(image: image, language: .english)

        #expect(result.blocks.map(\.sourceText) == ["hello"])
        #expect(result.detectedLanguage == .japanese)
        #expect(result.characterCount == 5)
        #expect(await recognizer.requestedLanguages() == [.english])
    }

    @Test("Rejects layouts beyond the block limit before translation")
    func enforcesBlockLimit() async throws {
        let columnCount = 11
        let observations = (0 ... InPlaceTranslationConstants.maximumBlockCount).map { index in
            let row = index / columnCount
            let column = index % columnCount
            return observation(
                text: "line-\(index)",
                rect: CGRect(
                    x: 0.02 + 0.085 * CGFloat(column),
                    y: 0.02 + 0.07 * CGFloat(row),
                    width: 0.01,
                    height: 0.004
                )
            )
        }
        let recognizer = TestLayoutRecognizer(
            result: layoutResult(language: .english, observations: observations)
        )
        let pipeline = InPlaceOCRPipeline(recognizer: recognizer)
        let image = try #require(makeImage())

        await #expect(throws: InPlaceOCRPipelineError.tooManyBlocks(observations.count)) {
            try await pipeline.recognize(image: image, language: .auto)
        }
    }

    @Test("Rejects layouts beyond the character limit before translation")
    func enforcesCharacterLimit() async throws {
        let text = String(
            repeating: "x",
            count: InPlaceTranslationConstants.maximumCharacterCount + 1
        )
        let recognizer = TestLayoutRecognizer(
            result: layoutResult(
                language: .english,
                observations: [observation(text: text)]
            )
        )
        let pipeline = InPlaceOCRPipeline(recognizer: recognizer)
        let image = try #require(makeImage())

        await #expect(throws: InPlaceOCRPipelineError.tooManyCharacters(text.count)) {
            try await pipeline.recognize(image: image, language: .auto)
        }
    }

    // MARK: Private

    private func layoutResult(
        language: Language,
        observations: [AppleOCRLayoutObservation]
    )
        -> AppleOCRLayoutResult {
        AppleOCRLayoutResult(
            mergedText: observations.map(\.text).joined(separator: "\n"),
            detectedLanguage: language,
            confidence: 0.9,
            observations: observations
        )
    }

    private func observation(
        text: String,
        rect: CGRect = CGRect(x: 0.1, y: 0.1, width: 0.6, height: 0.1)
    )
        -> AppleOCRLayoutObservation {
        AppleOCRLayoutObservation(
            id: UUID(),
            text: text,
            confidence: 0.9,
            topLeft: CGPoint(x: rect.minX, y: 1 - rect.minY),
            topRight: CGPoint(x: rect.maxX, y: 1 - rect.minY),
            bottomRight: CGPoint(x: rect.maxX, y: 1 - rect.maxY),
            bottomLeft: CGPoint(x: rect.minX, y: 1 - rect.maxY)
        )
    }

    private func makeImage() -> CGImage? {
        guard let context = CGContext(
            data: nil,
            width: 2,
            height: 2,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }
        return context.makeImage()
    }
}

// MARK: - TestLayoutRecognizer

/// Returns one deterministic immutable layout and records source-language requests.
private actor TestLayoutRecognizer: OCRLayoutRecognizing {
    // MARK: Lifecycle

    init(result: AppleOCRLayoutResult) {
        self.result = result
    }

    // MARK: Internal

    func recognizeLayout(image _: CGImage, language: Language) async throws -> AppleOCRLayoutResult {
        languages.append(language)
        return result
    }

    func requestedLanguages() -> [Language] {
        languages
    }

    // MARK: Private

    private let result: AppleOCRLayoutResult
    private var languages: [Language] = []
}
