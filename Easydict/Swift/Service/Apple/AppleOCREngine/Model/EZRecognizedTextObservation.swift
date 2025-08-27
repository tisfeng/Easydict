//
//  EZRecognizedTextObservation.swift
//  Easydict
//
//  Created by tisfeng on 2025/8/22.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

// MARK: - EZRecognizedTextObservation

/// EZRecognizedTextObservation is a compatible version of RecognizedTextObservation and VNRecognizedTextObservation
/// that provides a unified interface for both modern and legacy Vision APIs.
struct EZRecognizedTextObservation: Codable, Equatable, CustomStringConvertible {
    let topLeft: CGPoint
    let topRight: CGPoint
    let bottomRight: CGPoint
    let bottomLeft: CGPoint

    let uuid: UUID
    let confidence: Float
    let topCandidates: [EZRecognizedText]

    // MARK: - CustomStringConvertible

    var description: String {
        let boundRect = boundingBox
        return String(
            format: "Text: \"%@\", { x=%.3f, y=%.3f, width=%.3f, height=%.3f }, confidence: %.2f",
            firstText,
            boundRect.origin.x,
            boundRect.origin.y,
            boundRect.size.width,
            boundRect.size.height,
            confidence
        )
    }

    var boundingBox: CGRect {
        CGRect(
            x: bottomLeft.x,
            y: bottomRight.y,
            width: topRight.x - topLeft.x,
            height: topRight.y - bottomRight.y
        )
    }

    var firstText: String {
        topCandidates.first?.string ?? ""
    }

    /// Gets the first 20 characters of the recognized text
    var prefix20: String {
        firstText.prefixChars(20)
    }

    var prefix30: String {
        firstText.prefixChars(30)
    }

    var lineHeight: Double {
        boundingBox.size.height
    }

    var lineWidth: Double {
        boundingBox.size.width
    }

    // MARK: - Equatable

    static func == (lhs: EZRecognizedTextObservation, rhs: EZRecognizedTextObservation) -> Bool {
        lhs.uuid == rhs.uuid
    }
}

extension EZRecognizedTextObservation {
    /// Storage key for merge strategy associated object
    private static var mergeStrategyKey: UInt8 = 0

    /// Merge strategy associated with this observation, e.g. "\n", "\n\n", " ", etc.
    ///
    /// This property allows associating a specific merge strategy with the observation,
    /// which can be used later during the text merging process to determine how this
    /// observation should be combined with others.
    ///
    /// - Note: The first index observation don't have a merge strategy.
    var mergeStrategy: OCRMergeStrategy? {
        get { objc_getAssociatedObject(self, &Self.mergeStrategyKey) as? OCRMergeStrategy }
        set {
            objc_setAssociatedObject(
                self, &Self.mergeStrategyKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }
}

// MARK: - EZRecognizedText

/// EZRecognizedText is a compatible version of RecognizedText and VNRecognizedText
/// that provides a unified interface for text candidates.
struct EZRecognizedText: Codable {
    let string: String
    let confidence: Float
}

// MARK: - Array Extensions

/// Array extensions for EZRecognizedTextObservation to maintain compatibility with existing code
extension [EZRecognizedTextObservation] {
    /// Merges all recognized text strings into a single string, simply joining with "\n"
    var simpleMergedText: String {
        recognizedTexts.joined(separator: "\n")
    }

    /// Extract all the recognized text strings from observations
    var recognizedTexts: [String] {
        map { $0.firstText }
    }

    /// Calculate the bounding box that contains all text observations in the array
    ///
    /// This method computes the minimum bounding rectangle that encompasses all the
    /// individual text observation bounding boxes. Useful for grouping observations
    /// into sections and understanding the overall layout structure.
    ///
    /// - Returns: CGRect in Vision coordinate system (0,0 at bottom-left, normalized coordinates)
    ///           Returns CGRect.zero if the array is empty
    func calculateSectionBoundingBox() -> CGRect {
        guard let firstObservation = first else {
            return CGRect.zero
        }

        var minX = firstObservation.boundingBox.minX
        var maxX = firstObservation.boundingBox.maxX
        var minY = firstObservation.boundingBox.minY
        var maxY = firstObservation.boundingBox.maxY

        for observation in dropFirst() {
            let box = observation.boundingBox
            minX = Swift.min(minX, box.minX)
            maxX = Swift.max(maxX, box.maxX)
            minY = Swift.min(minY, box.minY)
            maxY = Swift.max(maxY, box.maxY)
        }

        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    /// Get maxX coordinate of all text observations in the array
    var maxX: Double {
        guard let firstObservation = first else { return 0.0 }
        return reduce(firstObservation.boundingBox.minX) { Swift.max($0, $1.boundingBox.maxX) }
    }

    /// Get minX coordinate of all text observations in the array
    var minX: Double {
        guard let firstObservation = first else { return 0.0 }
        return reduce(firstObservation.boundingBox.maxX) { Swift.min($0, $1.boundingBox.minX) }
    }

    /// Calculate the average height of all text observations in the array
    var averageHeight: Double {
        guard !isEmpty else { return 0.0 }
        let totalHeight = reduce(0) { $0 + $1.boundingBox.height }
        return totalHeight / Double(count)
    }

    /// Generate a comprehensive formatted description of all text observations
    ///
    /// Creates a well-formatted, indexed list of all text observations in the array,
    /// showing both the recognized text content and spatial positioning information.
    /// Invaluable for debugging OCR results and understanding text layout patterns.
    ///
    /// **Output Format:**
    /// ```
    /// [
    ///   [0] Text: "Hello", { x=0.031, y=0.795, width=0.106, height=0.103 },
    ///   [1] Text: "World", { x=0.185, y=0.789, width=0.244, height=0.116 },
    ///   ...
    /// ]
    /// ```
    ///
    /// - Returns: Multi-line formatted string with indexed observation details
    var formattedDescription: String {
        if isEmpty {
            return "[]"
        }

        var result = "[\n"
        for (index, observation) in enumerated() {
            let boundRect = observation.boundingBox
            let description = String(
                format:
                "Text: \"%@\", { x=%.3f, y=%.3f, width=%.3f, height=%.3f }, confidence: %.2f",
                observation.firstText,
                boundRect.origin.x,
                boundRect.origin.y,
                boundRect.size.width,
                boundRect.size.height,
                observation.confidence
            )
            result += "  [\(index)] \(description)"
            if index < count - 1 {
                result += ",\n"
            } else {
                result += "\n"
            }
        }
        result += "]"
        return result
    }
}
