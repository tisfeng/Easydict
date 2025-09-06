//
//  OCRTextObservationPair.swift
//  Easydict
//
//  Created by tisfeng on 2025/6/26.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation
import Vision

// MARK: - OCRTextObservationPair

/// A structure that encapsulates a pair of consecutive `VNRecognizedTextObservation` objects for analysis.
///
/// This struct simplifies the process of comparing two adjacent text observations by providing
/// convenient access to the `current` and `previous` observations, along with computed
/// properties for their spatial relationships.
struct OCRObservationPair: CustomStringConvertible, CustomDebugStringConvertible {
    // MARK: Internal

    /// The current text observation being analyzed.
    let current: VNRecognizedTextObservation

    /// The text observation that immediately precedes the `current` one.
    let previous: VNRecognizedTextObservation

    /// A debug-friendly description of the text observation pair.
    var description: String {
        """

        ┌───── OCR Text Pair ─────┐
        │ previous: \(previous)
        │ current : \(current)
        └─────────────────────────┘
        """
    }

    var debugDescription: String {
        description
    }

    /// The vertical distance between the bounding boxes of the two observations.
    /// A positive value indicates space between the lines, while a negative value indicates an overlap.
    var verticalGap: Double {
        let previousBoundingBox = previous.boundingBox
        let currentBoundingBox = current.boundingBox

        // Previous line is above (higher Y), current line is below (lower Y)
        let previousLineBottom = previousBoundingBox.origin.y
        let currentLineTop = currentBoundingBox.origin.y + currentBoundingBox.size.height

        // Vertical gap = distance from bottom of upper line to top of lower line
        return previousLineBottom - currentLineTop
    }

    /// Checks if both text observations have a similar character length and formatting.
    ///
    /// This is useful for detecting structured content like poetry or aligned text columns.
    var hasEqualCharacterLength: Bool {
        let currentText = current.firstText
        let previousText = previous.firstText

        let isCurrentEndPunctuationChar = currentText.hasEndPunctuationSuffix
        let isPreviousEndPunctuationChar = previousText.hasEndPunctuationSuffix

        let isEqualLength = currentText.count == previousText.count
        let isEqualEndSuffix = isCurrentEndPunctuationChar && isPreviousEndPunctuationChar

        // Check basic horizontal alignment using maxX comparison
        let lineMaxX = current.boundingBox.maxX
        let prevLineMaxX = previous.boundingBox.maxX
        let ratio = 0.95
        let isEqualLineMaxX = isRatioGreaterThan(ratio, value1: lineMaxX, value2: prevLineMaxX)

        return isEqualLength && isEqualEndSuffix && isEqualLineMaxX
    }

    // MARK: Private

    /// Determines if two values are similar within a specified ratio.
    private func isRatioGreaterThan(_ ratio: Double, value1: Double, value2: Double) -> Bool {
        let minValue = min(value1, value2)
        let maxValue = max(value1, value2)
        return (minValue / maxValue) > ratio
    }
}
