//
//  InPlaceOCRBlockTests.swift
//  EasydictTests
//
//  Created by Eric Pan on 2026/8/30.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation
import Testing

@testable import Easydict

/// Verifies stable OCR block identity and cache-safe source fingerprint normalization.
@Suite("In-place OCR Block", .tags(.inPlaceTranslation, .ocr, .unit))
struct InPlaceOCRBlockTests {
    @Test("Fingerprint collapses whitespace and canonical Unicode forms")
    func normalizesCacheFingerprint() {
        let decomposed = "  Cafe\u{301}\n\tREADY!  "

        #expect(InPlaceTextNormalization.normalize(decomposed) == "Café READY!")
        #expect(InPlaceTextNormalization.normalize("Case, punctuation.") == "Case, punctuation.")
        #expect(InPlaceTextNormalization.normalize("case, punctuation.") != "Case, punctuation.")
    }

    @Test("Replacing identity preserves OCR content and geometry")
    func replacesOnlyBlockIdentity() {
        let originalID = UUID()
        let replacementID = UUID()
        let quadrilateral = InPlaceOCRQuadrilateral(
            topLeft: CGPoint(x: 0.1, y: 0.2),
            topRight: CGPoint(x: 0.5, y: 0.2),
            bottomRight: CGPoint(x: 0.5, y: 0.4),
            bottomLeft: CGPoint(x: 0.1, y: 0.4)
        )
        let block = InPlaceOCRBlock(
            id: originalID,
            normalizedRect: CGRect(x: 0.1, y: 0.2, width: 0.4, height: 0.2),
            quadrilateral: quadrilateral,
            sourceText: "  hello\nworld  ",
            detectedLanguage: .english,
            confidence: 0.96,
            readingOrder: 3
        )

        let replaced = block.replacingID(replacementID)

        #expect(replaced.id == replacementID)
        #expect(replaced.normalizedRect == block.normalizedRect)
        #expect(replaced.quadrilateral == quadrilateral)
        #expect(replaced.sourceText == block.sourceText)
        #expect(replaced.detectedLanguage == block.detectedLanguage)
        #expect(replaced.confidence == block.confidence)
        #expect(replaced.readingOrder == block.readingOrder)
        #expect(replaced.sourceFingerprint == "hello world")
    }
}
