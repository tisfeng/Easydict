//
//  OCRAnalyzer.swift
//  Easydict
//
//  Created by tisfeng on 2025/6/26.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation
import Vision

// MARK: - OCRAnalyzer

/// Handles statistical analysis and calculations for OCR text observations
class OCRAnalyzer {
    var minLineHeight: Double = .greatestFiniteMagnitude
    var totalLineHeight: Double = 0
    var averageLineHeight: Double = 0

    var minLineSpacing: Double = .greatestFiniteMagnitude
    var minPositiveLineSpacing: Double = .greatestFiniteMagnitude
    var totalLineSpacing: Double = 0
    var averageLineSpacing: Double = 0

    var minX: Double = .greatestFiniteMagnitude
    var maxLineLength: Double = 0
    var minLineLength: Double = .greatestFiniteMagnitude

    var maxLongLineTextObservation: VNRecognizedTextObservation?
    var minXLineTextObservation: VNRecognizedTextObservation?
    var maxCharacterCountLineTextObservation: VNRecognizedTextObservation?

    var isPoetry: Bool = false
    var charCountPerLine: Double = 0
    var totalCharCount: Int = 0
    var punctuationMarkCount: Int = 0
    var singleAlphabetWidth: Double = 0.0

    /// Reset all analytical data to initial values
    func resetAnalysis() {
        minLineHeight = .greatestFiniteMagnitude
        totalLineHeight = 0
        averageLineHeight = 0

        minLineSpacing = .greatestFiniteMagnitude
        minPositiveLineSpacing = .greatestFiniteMagnitude
        totalLineSpacing = 0
        averageLineSpacing = 0

        minX = .greatestFiniteMagnitude
        maxLineLength = 0
        minLineLength = .greatestFiniteMagnitude

        maxLongLineTextObservation = nil
        minXLineTextObservation = nil
        maxCharacterCountLineTextObservation = nil

        isPoetry = false
        charCountPerLine = 0
        totalCharCount = 0
        punctuationMarkCount = 0
        singleAlphabetWidth = 0.0
    }

    /// Analyze line spacing, height, and positioning characteristics
    func analyzeLineLayout(
        _ textObservation: VNRecognizedTextObservation,
        index: Int,
        observations: [VNRecognizedTextObservation],
        lineSpacingCount: inout Int
    ) {
        let boundingBox = textObservation.boundingBox
        let lineHeight = boundingBox.size.height
        totalLineHeight += lineHeight

        if lineHeight < minLineHeight {
            minLineHeight = lineHeight
        }

        // Calculate line spacing
        if index > 0 {
            let prevObservation = observations[index - 1]
            let prevBoundingBox = prevObservation.boundingBox

            let deltaY = prevBoundingBox.origin.y - (boundingBox.origin.y + boundingBox.size.height)

            if deltaY > 0, deltaY < averageLineHeight * OCRConstants.paragraphLineHeightRatio {
                totalLineSpacing += deltaY
                lineSpacingCount += 1
            }

            if deltaY < minLineSpacing {
                minLineSpacing = deltaY
            }

            if deltaY > 0, deltaY < minPositiveLineSpacing {
                minPositiveLineSpacing = deltaY
            }
        }

        // Track x coordinates and line lengths
        let x = boundingBox.origin.x
        if x < minX {
            minX = x
            minXLineTextObservation = textObservation
        }

        let lengthOfLine = boundingBox.size.width
        if lengthOfLine > maxLineLength {
            maxLineLength = lengthOfLine
            maxLongLineTextObservation = textObservation
        }

        // Track maximum character count line
        let currentCharCount = textObservation.text.count
        if let maxCharObservation = maxCharacterCountLineTextObservation {
            if currentCharCount > maxCharObservation.text.count {
                maxCharacterCountLineTextObservation = textObservation
            }
        } else {
            maxCharacterCountLineTextObservation = textObservation
        }

        if lengthOfLine < minLineLength {
            minLineLength = lengthOfLine
        }
    }

    /// Analyze single character width for text observation
    func analyzeCharacterWidth(
        _ textObservation: VNRecognizedTextObservation,
        ocrImage: NSImage
    )
        -> Double {
        let scaleFactor = NSScreen.main?.backingScaleFactor ?? 1.0
        let textWidth = textObservation.boundingBox.size.width * ocrImage.size.width / scaleFactor
        return textWidth / textObservation.text.count.double
    }
}
