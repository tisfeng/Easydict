//
//  InPlaceOCRBlockBuilderTests.swift
//  EasydictTests
//
//  Created by Eric Pan on 2026/8/30.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation
import Testing

@testable import Easydict

/// Verifies section grouping, reading order, and column separation for immutable OCR layouts.
@Suite("In-place OCR Block Builder", .tags(.inPlaceTranslation, .ocr, .unit))
struct InPlaceOCRBlockBuilderTests {
    // MARK: Internal

    @Test("Empty and whitespace-only observations do not create translation blocks")
    func ignoresEmptyObservations() {
        let result = layoutResult(observations: [
            observation(text: " \n\t ", rect: CGRect(x: 0.1, y: 0.1, width: 0.4, height: 0.05)),
        ])

        #expect(InPlaceOCRBlockBuilder().buildBlocks(from: result).isEmpty)
    }

    @Test("A short line retains its geometry, identity, language, and confidence")
    func buildsSingleLineBlock() throws {
        let id = UUID()
        let rect = CGRect(x: 0.15, y: 0.2, width: 0.25, height: 0.08)
        let result = layoutResult(observations: [
            observation(id: id, text: "Short", confidence: 0.91, rect: rect),
        ])

        let block = try #require(InPlaceOCRBlockBuilder().buildBlocks(from: result).first)

        #expect(block.id == id)
        #expect(rectsAreApproximatelyEqual(block.normalizedRect, rect))
        #expect(block.sourceText == "Short")
        #expect(block.detectedLanguage == .english)
        #expect(block.confidence == 0.91)
        #expect(block.readingOrder == 0)
        #expect(block.quadrilateral != nil)
    }

    @Test("Nearby aligned lines merge into one section-level translation block")
    func mergesParagraphLines() throws {
        let result = layoutResult(observations: [
            observation(
                text: "Hello",
                confidence: 0.8,
                rect: CGRect(x: 0.1, y: 0.1, width: 0.4, height: 0.05)
            ),
            observation(
                text: "world",
                confidence: 1,
                rect: CGRect(x: 0.11, y: 0.17, width: 0.38, height: 0.05)
            ),
        ])

        let blocks = InPlaceOCRBlockBuilder().buildBlocks(from: result)
        let block = try #require(blocks.first)

        #expect(blocks.count == 1)
        #expect(block.sourceText == "Hello\nworld")
        #expect(
            rectsAreApproximatelyEqual(
                block.normalizedRect,
                CGRect(x: 0.1, y: 0.1, width: 0.4, height: 0.12)
            )
        )
        #expect(abs(block.confidence - 0.9) < 0.000_1)
        #expect(block.quadrilateral == nil)
    }

    @Test("Wide aligned paragraph lines still merge instead of becoming one request per line")
    func mergesWideParagraphLines() throws {
        let result = layoutResult(observations: [
            observation(
                text: "A wide paragraph starts on this line.",
                rect: CGRect(x: 0.1, y: 0.1, width: 0.72, height: 0.05)
            ),
            observation(
                text: "Its next line remains in the same column.",
                rect: CGRect(x: 0.1, y: 0.17, width: 0.7, height: 0.05)
            ),
        ])

        let blocks = InPlaceOCRBlockBuilder().buildBlocks(from: result)
        let block = try #require(blocks.first)

        #expect(blocks.count == 1)
        #expect(
            block.sourceText ==
                "A wide paragraph starts on this line.\nIts next line remains in the same column."
        )
    }

    @Test("Two columns remain independent and preserve left-to-right reading order")
    func keepsColumnsSeparate() {
        let result = layoutResult(observations: [
            observation(text: "Right 2", rect: CGRect(x: 0.6, y: 0.18, width: 0.3, height: 0.05)),
            observation(text: "Left 1", rect: CGRect(x: 0.1, y: 0.1, width: 0.3, height: 0.05)),
            observation(text: "Right 1", rect: CGRect(x: 0.6, y: 0.1, width: 0.3, height: 0.05)),
            observation(text: "Left 2", rect: CGRect(x: 0.1, y: 0.18, width: 0.3, height: 0.05)),
        ])

        let blocks = InPlaceOCRBlockBuilder().buildBlocks(from: result)

        #expect(blocks.map(\.sourceText) == ["Left 1\nLeft 2", "Right 1\nRight 2"])
        #expect(blocks.map(\.readingOrder) == [0, 1])
        #expect(blocks[0].normalizedRect.maxX < blocks[1].normalizedRect.minX)
    }

    @Test("Separated mixed-language sections detect a language per block")
    func detectsEachBlockLanguageIndependently() {
        let result = layoutResult(observations: [
            observation(
                text: "This complete English sentence is used for language detection.",
                rect: CGRect(x: 0.1, y: 0.1, width: 0.35, height: 0.06)
            ),
            observation(
                text: "これは日本語で書かれた文章です。言語検出の確認に使います。",
                rect: CGRect(x: 0.55, y: 0.1, width: 0.35, height: 0.06)
            ),
        ])

        let blocks = InPlaceOCRBlockBuilder().buildBlocks(from: result)

        #expect(blocks.count == 2)
        #expect(blocks.map(\.detectedLanguage) == [.english, .japanese])
    }

    // MARK: Private

    private func layoutResult(
        observations: [AppleOCRLayoutObservation]
    )
        -> AppleOCRLayoutResult {
        AppleOCRLayoutResult(
            mergedText: observations.map(\.text).joined(separator: "\n"),
            detectedLanguage: .english,
            confidence: 0.9,
            observations: observations
        )
    }

    private func observation(
        id: UUID = UUID(),
        text: String,
        confidence: Float = 0.9,
        rect: CGRect
    )
        -> AppleOCRLayoutObservation {
        AppleOCRLayoutObservation(
            id: id,
            text: text,
            confidence: confidence,
            topLeft: CGPoint(x: rect.minX, y: 1 - rect.minY),
            topRight: CGPoint(x: rect.maxX, y: 1 - rect.minY),
            bottomRight: CGPoint(x: rect.maxX, y: 1 - rect.maxY),
            bottomLeft: CGPoint(x: rect.minX, y: 1 - rect.maxY)
        )
    }

    private func rectsAreApproximatelyEqual(
        _ lhs: CGRect,
        _ rhs: CGRect,
        tolerance: CGFloat = 0.000_001
    )
        -> Bool {
        abs(lhs.minX - rhs.minX) <= tolerance
            && abs(lhs.minY - rhs.minY) <= tolerance
            && abs(lhs.width - rhs.width) <= tolerance
            && abs(lhs.height - rhs.height) <= tolerance
    }
}
