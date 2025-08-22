//
//  VNRecognizedTextObservation+Extension.swift
//  Easydict
//
//  Created by tisfeng on 2025/6/26.
//  Copyright © 2025 izual. All rights reserved.
//

import Vision

// MARK: - VNRecognizedTextObservation Extension

/// Convenient extensions for VNRecognizedTextObservation to simplify OCR text processing
extension VNRecognizedTextObservation {
    /// Convenient access to the highest-confidence recognized text
    ///
    /// Returns the top candidate string from the recognition results, which represents
    /// the most likely text interpretation. Falls back to empty string if no candidates
    /// are available, ensuring safe usage without optional unwrapping.
    ///
    /// - Returns: The highest-confidence text string, or empty string if unavailable
    var firstText: String {
        topCandidates(1).first?.string ?? ""
    }

    /// Gets the first 20 characters of the recognized text
    var prefix20: String {
        firstText.prefixChars(20)
    }

    var prefix30: String {
        firstText.prefixChars(30)
    }

    /// Enhanced description providing comprehensive observation details
    ///
    /// Overrides the default description to provide human-readable information about
    /// both the recognized text content and its spatial positioning. Useful for
    /// debugging OCR results and understanding text layout.
    ///
    /// **Format**: `Text: "content", { x=0.123, y=0.456, width=0.789, height=0.012 }, confidence: 0.98`
    ///
    /// - Returns: Formatted string containing text and bounding box coordinates
    open override var description: String {
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

    var lineHeight: Double {
        boundingBox.size.height
    }

    var lineWidth: Double {
        boundingBox.size.width
    }
}

// MARK: - VNRecognizedTextObservation associated merge strategy

extension VNRecognizedTextObservation {
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

// MARK: - [VNRecognizedTextObservation] associated merged text

extension [VNRecognizedTextObservation] {
    /// Storage key for merged text associated object
    private static var mergedTextKey: UInt8 = 0

    /// Merged text associated with this array of observations
    ///
    /// This property allows associating a single merged text string with the entire
    /// array of observations, which can be used later to retrieve the combined text
    /// without needing to reprocess the observations.
    var mergedText: String? {
        get { objc_getAssociatedObject(self, &Self.mergedTextKey) as? String }
        set {
            objc_setAssociatedObject(
                self, &Self.mergedTextKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }
}

// MARK: - Array Extension for Enhanced Debugging

/// Debugging utilities for arrays of VNRecognizedTextObservation
extension [VNRecognizedTextObservation] {
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
            result += "  [\(index)] \(observation.description)"
            if index < count - 1 {
                result += ",\n"
            } else {
                result += "\n"
            }
        }
        result += "]"
        return result
    }

    /// Merges all recognized text strings into a single string, just simply joining with "\n"
    var simpleMergedText: String {
        recognizedTexts.joined(separator: "\n")
    }

    /// Extract all the recognized text strings from observations
    var recognizedTexts: [String] {
        map { $0.firstText }
    }
}

// MARK: - Conversion to EZRecognizedTextObservation

extension VNRecognizedTextObservation {
    /// Converts this VNRecognizedTextObservation to unified EZRecognizedTextObservation format.
    ///
    /// This method provides a convenient way to convert legacy Vision API observations
    /// to the unified format used throughout the application.
    ///
    /// - Returns: EZRecognizedTextObservation for consistent processing, or nil if no candidates
    func toEZRecognizedTextObservation() -> EZRecognizedTextObservation? {
        guard let topCandidate = topCandidates(1).first else {
            return nil
        }

        // Get bounding box coordinates
        let boundingBox = boundingBox

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
            uuid: UUID(),
            confidence: topCandidate.confidence,
            topCandidates: ezCandidates
        )
    }
}

extension [VNRecognizedTextObservation] {
    /// Converts array of VNRecognizedTextObservation to unified EZRecognizedTextObservation format.
    ///
    /// This method provides a convenient way to convert arrays of legacy Vision API observations
    /// to the unified format used throughout the application.
    ///
    /// - Returns: Array of EZRecognizedTextObservation for consistent processing
    func toEZRecognizedTextObservations() -> [EZRecognizedTextObservation] {
        compactMap { $0.toEZRecognizedTextObservation() }
    }
}
