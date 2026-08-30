//
//  InPlaceOCRBlock.swift
//  Easydict
//
//  Created by Eric Pan on 2026/8/30.
//  Copyright © 2026 izual. All rights reserved.
//

import CoreGraphics
import Foundation

// MARK: - InPlaceOCRQuadrilateral

/// A normalized top-left-origin quadrilateral retained for lightly rotated text.
struct InPlaceOCRQuadrilateral: Codable, Equatable, Sendable {
    let topLeft: CGPoint
    let topRight: CGPoint
    let bottomRight: CGPoint
    let bottomLeft: CGPoint
}

// MARK: - InPlaceOCRBlock

/// One section-level OCR unit positioned in normalized top-left coordinates.
/// Matching can carry its stable identity across successive OCR generations.
struct InPlaceOCRBlock: Identifiable, Equatable, Sendable {
    // MARK: Lifecycle

    init(
        id: UUID = UUID(),
        normalizedRect: CGRect,
        quadrilateral: InPlaceOCRQuadrilateral? = nil,
        sourceText: String,
        detectedLanguage: Language,
        confidence: Float,
        readingOrder: Int
    ) {
        self.id = id
        self.normalizedRect = normalizedRect
        self.quadrilateral = quadrilateral
        self.sourceText = sourceText
        self.detectedLanguage = detectedLanguage
        self.confidence = confidence
        self.readingOrder = readingOrder
    }

    // MARK: Internal

    let id: UUID
    let normalizedRect: CGRect
    let quadrilateral: InPlaceOCRQuadrilateral?
    let sourceText: String
    let detectedLanguage: Language
    let confidence: Float
    let readingOrder: Int

    var sourceFingerprint: String {
        InPlaceTextNormalization.normalize(sourceText)
    }

    func replacingID(_ id: UUID) -> InPlaceOCRBlock {
        InPlaceOCRBlock(
            id: id,
            normalizedRect: normalizedRect,
            quadrilateral: quadrilateral,
            sourceText: sourceText,
            detectedLanguage: detectedLanguage,
            confidence: confidence,
            readingOrder: readingOrder
        )
    }
}

// MARK: - InPlaceTextNormalization

/// Applies the cache-safe text normalization contract without changing case or punctuation.
enum InPlaceTextNormalization {
    static func normalize(_ text: String) -> String {
        text
            .precomposedStringWithCanonicalMapping
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }
}
