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
/// let isOnSameLine = lineAnalyzer.isSameLine(pair)
/// let joinString = textMerger.joinedString(for: pair)
/// ```
///
/// Essential for maintaining contextual awareness throughout the OCR text processing pipeline.
struct OCRTextObservationPair: CustomStringConvertible {
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
            previous: \(previous)
            current: \(current)
        """
    }
}
