//
//  AppleOCRLayoutResult.swift
//  Easydict
//
//  Created by Eric Pan on 2026/8/30.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation

// MARK: - AppleOCRLayoutObservation

/// An immutable, value-semantic OCR observation safe to pass between the
/// Vision pipeline and layout-aware product features.
struct AppleOCRLayoutObservation: Codable, Equatable, Sendable {
    // MARK: Lifecycle

    init(
        id: UUID,
        text: String,
        confidence: Float,
        topLeft: CGPoint,
        topRight: CGPoint,
        bottomRight: CGPoint,
        bottomLeft: CGPoint
    ) {
        self.id = id
        self.text = text
        self.confidence = confidence
        self.topLeft = topLeft
        self.topRight = topRight
        self.bottomRight = bottomRight
        self.bottomLeft = bottomLeft
    }

    init(_ observation: EZRecognizedTextObservation) {
        self.init(
            id: observation.uuid,
            text: observation.firstText,
            confidence: observation.confidence,
            topLeft: observation.topLeft,
            topRight: observation.topRight,
            bottomRight: observation.bottomRight,
            bottomLeft: observation.bottomLeft
        )
    }

    // MARK: Internal

    let id: UUID
    let text: String
    let confidence: Float
    let topLeft: CGPoint
    let topRight: CGPoint
    let bottomRight: CGPoint
    let bottomLeft: CGPoint

    /// The normalized observation bounds in Vision's bottom-left coordinate space.
    var visionNormalizedRect: CGRect {
        let minX = min(topLeft.x, bottomLeft.x)
        let maxX = max(topRight.x, bottomRight.x)
        let minY = min(bottomLeft.y, bottomRight.y)
        let maxY = max(topLeft.y, topRight.y)
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
}

// MARK: - AppleOCRLayoutResult

/// A complete immutable result from one in-memory Apple Vision OCR request.
/// It intentionally excludes the source image and mutable processor state.
struct AppleOCRLayoutResult: Sendable {
    let mergedText: String
    let detectedLanguage: Language
    let confidence: Float
    let observations: [AppleOCRLayoutObservation]
}
