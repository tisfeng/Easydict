//
//  RecognizedTextObservation+Extension.swift
//  Easydict
//
//  Created by tisfeng on 2025/8/22.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation
import Vision

// MARK: - RecognizedTextObservation + CustomStringConvertible

@available(macOS 15.0, *)
extension RecognizedTextObservation: CustomStringConvertible {
    var firstText: String {
        // Return the first recognized text if available
        guard let first = topCandidates(1).first else {
            return ""
        }
        return first.string
    }

    var description: String {
        let boundRect = boundingBox.cgRect
        return String(
            format: "Text: \"%@\", BoundingBox: { x=%.3f, y=%.3f, width=%.3f, height=%.3f }, Confidence: %.2f",
            firstText,
            boundRect.origin.x,
            boundRect.origin.y,
            boundRect.size.width,
            boundRect.size.height,
            confidence
        )
    }
}

@available(macOS 15.0, *)
extension [RecognizedTextObservation] {
    var combinedText: String {
        map { $0.firstText }.joined(separator: "\n")
    }
}

// MARK: - Conversion to EZRecognizedTextObservation

@available(macOS 15.0, *)
extension RecognizedTextObservation {
    /// Converts this RecognizedTextObservation to unified EZRecognizedTextObservation format.
    ///
    /// This method provides a convenient way to convert modern Vision API observations
    /// to the unified format used throughout the application.
    ///
    /// - Returns: EZRecognizedTextObservation for consistent processing, or nil if no candidates
    func toEZRecognizedTextObservation() -> EZRecognizedTextObservation? {
        guard let topCandidate = topCandidates(1).first else {
            return nil
        }

        // Get bounding box coordinates - modern API uses NormalizedRect
        let normalizedRect = boundingBox
        let boundingBox = normalizedRect.cgRect

        // Convert to corner points (Vision coordinates are normalized)
        let topLeft = CGPoint(x: boundingBox.minX, y: boundingBox.maxY)
        let topRight = CGPoint(x: boundingBox.maxX, y: boundingBox.maxY)
        let bottomLeft = CGPoint(x: boundingBox.minX, y: boundingBox.minY)
        let bottomRight = CGPoint(x: boundingBox.maxX, y: boundingBox.minY)

        // Create EZRecognizedText candidates
        let ezCandidates = topCandidates(3).map { candidate in
            EZRecognizedText(
                string: candidate.string,
                confidence: candidate.confidence
            )
        }

        return EZRecognizedTextObservation(
            topLeft: topLeft,
            topRight: topRight,
            bottomRight: bottomRight,
            bottomLeft: bottomLeft,
            uuid: uuid,
            confidence: topCandidate.confidence,
            topCandidates: ezCandidates
        )
    }
}

@available(macOS 15.0, *)
extension [RecognizedTextObservation] {
    /// Converts array of RecognizedTextObservation to unified EZRecognizedTextObservation format.
    ///
    /// This method provides a convenient way to convert arrays of modern Vision API observations
    /// to the unified format used throughout the application.
    ///
    /// - Returns: Array of EZRecognizedTextObservation for consistent processing
    func toEZRecognizedTextObservations() -> [EZRecognizedTextObservation] {
        compactMap { $0.toEZRecognizedTextObservation() }
    }
}
