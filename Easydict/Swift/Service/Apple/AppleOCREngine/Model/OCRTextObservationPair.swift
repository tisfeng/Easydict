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

/// Encapsulates a pair of text observations (current and previous) for OCR processing
/// This struct provides convenient access to both observations and their properties
struct OCRTextObservationPair {
    /// The current text observation
    let current: VNRecognizedTextObservation

    /// The previous text observation
    let previous: VNRecognizedTextObservation
}
