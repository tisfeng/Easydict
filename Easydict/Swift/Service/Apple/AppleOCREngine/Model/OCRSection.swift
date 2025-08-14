//
//  OCRSection.swift
//  Easydict
//
//  Created by tisfeng on 2025/8/14.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation
import Vision

// MARK: - OCRSection

/// Represents a section of OCR text with associated observations, merged text, and detected language
struct OCRSection {
    /// The text observations for this section
    let observations: [VNRecognizedTextObservation]

    /// The merged text for this section
    let mergedText: String

    /// The detected language for this section
    let language: Language
}
