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

/// Encapsulates a pair of adjacent text observations for contextual OCR processing
///
/// This fundamental data structure represents the relationship between consecutive text
/// observations in the OCR processing pipeline. It provides the essential context needed
/// for making intelligent text merging decisions by maintaining references to both
/// the current text observation and its immediate predecessor.
///
/// **Usage Patterns:**
/// - **Text Merging**: Analyzing spatial relationships between adjacent text lines
/// - **Line Analysis**: Determining if observations are on same line or different lines
/// - **Formatting Decisions**: Making context-aware choices about spacing and breaks
/// - **Pattern Recognition**: Identifying poetry, lists, and other structured content
///
/// **Key Properties:**
/// - `current`: The text observation currently being processed
/// - `previous`: The immediately preceding text observation for context
///
/// **Example Usage:**
/// ```swift
/// let pair = OCRTextObservationPair(current: currentObs, previous: prevObs)
/// let isNewLine = lineAnalyzer.isNewLine(pair: pair)
/// let joinString = textMerger.joinedString(for: pair)
/// ```
///
/// Essential for maintaining contextual awareness throughout the OCR text processing pipeline.
struct OCRTextObservationPair: CustomStringConvertible, CustomDebugStringConvertible {
    // MARK: Internal

    /// The current text observation being processed
    ///
    /// This observation represents the "active" text element that is currently being
    /// analyzed in the context of its relationship with the previous observation.
    let current: VNRecognizedTextObservation

    /// The immediately preceding text observation for contextual analysis
    ///
    /// This observation provides the necessary context for making intelligent decisions
    /// about how the current observation should be processed relative to its predecessor.
    let previous: VNRecognizedTextObservation

    /// Human-readable description showing both observations for debugging
    ///
    /// Provides a formatted view of both text observations, useful for debugging
    /// text processing pipelines and understanding spatial relationships.
    var description: String {
        """

        ┌───── OCR Text Pair ─────┐
        │ previous: \(previous)
        │ current : \(current)
        └──────────────────────────────────┘
        """
    }

    var debugDescription: String {
        description
    }

    /// Calculate vertical gap between two text observation lines
    ///
    /// Computes the vertical spacing between two consecutive text observations.
    /// This is a fundamental measurement used for determining paragraph breaks
    /// and text formatting decisions.
    ///
    /// **Coordinate System (Vision Framework):**
    /// - Origin is at bottom-left (0,0)
    /// - Y increases upward
    /// - boundingBox.origin.y represents the bottom edge of the text
    /// - boundingBox.origin.y + height represents the top edge
    ///
    /// **OCRTextObservationPair Context:**
    /// - previous: Earlier in reading order (visually above, higher Y value)
    /// - current: Later in reading order (visually below, lower Y value)
    ///
    /// **Gap Calculation:**
    /// - Previous line bottom = previous.y (bottom edge of upper line)
    /// - Current line top = current.y + current.height (top edge of lower line)
    /// - Vertical gap = previous.y - (current.y + current.height)
    /// - Positive gap = space between lines
    /// - Negative gap = overlap between lines
    ///
    /// - Returns: Vertical gap in normalized coordinates (0.0-1.0)
    var verticalGap: Double {
        let previousBoundingBox = previous.boundingBox
        let currentBoundingBox = current.boundingBox

        // Previous line is above (higher Y), current line is below (lower Y)
        let previousLineBottom = previousBoundingBox.origin.y
        let currentLineTop = currentBoundingBox.origin.y + currentBoundingBox.size.height

        // Vertical gap = distance from bottom of upper line to top of lower line
        return previousLineBottom - currentLineTop
    }

    /// Check if both text observations have equal character length and formatting
    ///
    /// Performs comprehensive text equality analysis including character count,
    /// punctuation patterns, and basic spatial alignment. This is particularly
    /// useful for detecting structured content like poetry or aligned text.
    ///
    /// **Analysis Criteria:**
    /// - Equal character count between current and previous text
    /// - Both texts end with punctuation marks (consistent formatting)
    /// - Basic horizontal alignment (uses relative maxX comparison)
    ///
    /// **Use Cases:**
    /// - Poetry line detection (equal-length verses)
    /// - Structured content identification
    /// - Consistent formatting validation
    /// - Table column alignment analysis
    ///
    /// - Returns: true if texts have equal length and consistent formatting
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

    /// Calculate horizontal displacement between text observations
    ///
    /// Computes the horizontal distance between the left edges of two text observations.
    /// Positive values indicate rightward displacement (indentation), while negative
    /// values indicate leftward displacement.
    ///
    /// **Coordinate System:**
    /// - Uses normalized coordinates (0.0-1.0)
    /// - Displacement = current.x - previous.x
    /// - Positive = current line is indented relative to previous
    /// - Negative = current line is outdented relative to previous
    ///
    /// - Returns: Horizontal displacement in normalized coordinates
    var horizontalDisplacement: Double {
        current.boundingBox.origin.x - previous.boundingBox.origin.x
    }

    /// Check if current line appears to be indented relative to previous line
    ///
    /// Simple indentation detection based on horizontal displacement.
    /// Uses a small threshold to account for OCR positioning inaccuracies.
    ///
    /// - Returns: true if current line is indented, false otherwise
    var hasIndentation: Bool {
        let threshold = 0.01 // 1% of normalized width
        return horizontalDisplacement > threshold
    }

    // MARK: Private

    // MARK: - Helper Methods

    /// Compare two values with a ratio threshold
    ///
    /// Determines if two values are similar within a specified ratio tolerance.
    /// This is more robust than absolute difference comparison for varying scales.
    ///
    /// - Parameters:
    ///   - ratio: Minimum similarity ratio (0.0-1.0)
    ///   - value1: First value to compare
    ///   - value2: Second value to compare
    /// - Returns: true if values are similar within ratio tolerance
    private func isRatioGreaterThan(_ ratio: Double, value1: Double, value2: Double) -> Bool {
        let minValue = min(value1, value2)
        let maxValue = max(value1, value2)
        return (minValue / maxValue) > ratio
    }
}
