//
//  VNRecognizedTextObservation.swift
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

    /// Enhanced description providing comprehensive observation details
    ///
    /// Overrides the default description to provide human-readable information about
    /// both the recognized text content and its spatial positioning. Useful for
    /// debugging OCR results and understanding text layout.
    ///
    /// **Format**: `Text: "content", { x=0.123, y=0.456, width=0.789, height=0.012 }`
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

/// Associated object storage for temporary processing data
///
/// This extension provides a mechanism to temporarily store processing-related data
/// with VNRecognizedTextObservation instances during OCR text processing pipeline.
/// Uses Objective-C associated objects for dynamic property addition.
///
/// - Warning: This is intended for temporary storage during processing and should
///   not be relied upon for long-term data persistence.
extension VNRecognizedTextObservation {
    /// Storage key for joined string associated object
    private static var joinedStringKey: UInt8 = 0

    /// Storage key for merge strategy associated object
    private static var mergeStrategyKey: UInt8 = 0

    /// Temporary storage for processed joining string during text merging
    ///
    /// This property allows storing intermediate processing results during the
    /// OCR text merging pipeline. The value represents how this observation
    /// should be joined with adjacent text.
    ///
    /// - Note: Uses OBJC_ASSOCIATION_COPY_NONATOMIC for thread-safe string copying
    var joinedString: String? {
        get { objc_getAssociatedObject(self, &Self.joinedStringKey) as? String }
        set {
            objc_setAssociatedObject(
                self, &Self.joinedStringKey, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC
            )
        }
    }

    var mergeStrategy: OCRMergeStrategy? {
        get { objc_getAssociatedObject(self, &Self.mergeStrategyKey) as? OCRMergeStrategy }
        set {
            objc_setAssociatedObject(
                self, &Self.mergeStrategyKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }
}

// MARK: - Array Extension for Enhanced Debugging

/// Debugging utilities for arrays of VNRecognizedTextObservation
extension Array where Element == VNRecognizedTextObservation {
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

    /// Extract just the recognized text strings from observations
    var recognizedTexts: [String] {
        map { $0.firstText }
    }

    /// Merges all recognized text strings into a single string, just joining with "\n"
    var mergedText: String {
        recognizedTexts.joined(separator: "\n")
    }
}
