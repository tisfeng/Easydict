//
//  AppleOCRTextProcessor.swift
//  Easydict
//
//  Created by tisfeng on 2025/6/22.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation
import Vision

// MARK: - Constants

private let kLineBreakText = "\n"
private let kParagraphBreakText = "\n\n"
private let kIndentationText = ""
private let kParagraphLineHeightRatio: CGFloat = 1.5
private let kShortPoetryCharacterCountOfLine = 12

// MARK: - AppleOCRTextProcessor

/// Handles intelligent OCR text processing and merging
/// Ported from EZAppleService setupOCRResult method
@objc
public class AppleOCRTextProcessor: NSObject {
    // MARK: Public

    // MARK: - Public Methods

    /// Main method to process OCR observations into structured result
    @objc
    public func setupOCRResult(
        _ ocrResult: EZOCRResult,
        observations: [VNRecognizedTextObservation],
        ocrImage: NSImage?,
        intelligentJoined: Bool
    ) {
        self.ocrImage = ocrImage
        language = ocrResult.from

        // Reset statistics
        resetStatistics()

        let recognizedTexts = observations.compactMap { observation in
            observation.topCandidates(1).first?.string
        }

        print("\nTextObservations: \(observations.formattedDescription)")

        let lineCount = observations.count
        var lineSpacingCount = 0

        // Calculate line statistics
        for i in 0 ..< lineCount {
            let textObservation = observations[i]
            calculateLineStatistics(
                textObservation,
                index: i,
                observations: observations,
                lineSpacingCount: &lineSpacingCount
            )
        }

        // Store final calculated values
        averageLineHeight = totalLineHeight / CGFloat(lineCount)
        if lineSpacingCount > 0 {
            averageLineSpacing = totalLineSpacing / CGFloat(lineSpacingCount)
        }

        // Set basic OCR result properties
        ocrResult.texts = recognizedTexts
        ocrResult.mergedText = recognizedTexts.joined(separator: "\n")
        ocrResult.raw = recognizedTexts

        // Calculate confidence
        calculateConfidence(ocrResult, observations: observations)

        // If intelligent joining is not enabled, return simple result
        if !intelligentJoined {
            return
        }

        print("Original OCR strings (\(ocrResult.from)): \(recognizedTexts)")

        // Detect if text is poetry
        isPoetry = detectPoetry(observations: observations)
        print("isPoetry: \(isPoetry)")

        // Sort text observations for proper order
        let sortedObservations = sortTextObservations(observations)
        print(
            "Sorted OCR strings: \(sortedObservations.recognizedTexts)"
        )

        // Perform intelligent text merging
        let mergedText = performIntelligentTextMerging(sortedObservations)

        // Update OCR result with intelligently merged text
        ocrResult.mergedText = mergedText.trimmingCharacters(in: .whitespacesAndNewlines)
        ocrResult.texts = ocrResult.mergedText.components(separatedBy: kLineBreakText)

        let showMergedText = String(ocrResult.mergedText.prefix(100))
        print(
            "OCR text (\(ocrResult.from)(\(String(format: "%.2f", ocrResult.confidence))): \(showMergedText)"
        )
    }

    // MARK: Private

    private var ocrImage: NSImage?
    private var language: Language = .auto
    private var minLineHeight: CGFloat = .greatestFiniteMagnitude
    private var totalLineHeight: CGFloat = 0
    private var averageLineHeight: CGFloat = 0

    // OCR line spacing may be less than 0
    private var minLineSpacing: CGFloat = .greatestFiniteMagnitude
    private var minPositiveLineSpacing: CGFloat = .greatestFiniteMagnitude
    private var totalLineSpacing: CGFloat = 0
    private var averageLineSpacing: CGFloat = 0

    private var minX: CGFloat = .greatestFiniteMagnitude
    private var maxLineLength: CGFloat = 0
    private var minLineLength: CGFloat = .greatestFiniteMagnitude

    private var maxLongLineTextObservation: VNRecognizedTextObservation?
    private var minXLineTextObservation: VNRecognizedTextObservation?

    private var isPoetry: Bool = false
    private var charCountPerLine: CGFloat = 0
    private var totalCharCount: Int = 0
    private var punctuationMarkCount: Int = 0

    // MARK: - Private Methods

    private func resetStatistics() {
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

        isPoetry = false
        charCountPerLine = 0
        totalCharCount = 0
        punctuationMarkCount = 0
    }

    private func calculateLineStatistics(
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

            // deltaY may be < 0, means the OCR line frame is overlapped
            let deltaY = prevBoundingBox.origin.y - (boundingBox.origin.y + boundingBox.size.height)

            // If deltaY too big, it may be paragraph, do not add it
            if deltaY > 0, deltaY < averageLineHeight * kParagraphLineHeightRatio {
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

        if lengthOfLine < minLineLength {
            minLineLength = lengthOfLine
        }

        // Update running averages
        averageLineHeight = totalLineHeight / CGFloat(index + 1)
    }

    private func calculateConfidence(
        _ ocrResult: EZOCRResult, observations: [VNRecognizedTextObservation]
    ) {
        if !observations.isEmpty {
            let totalConfidence = observations.compactMap { observation in
                observation.topCandidates(1).first?.confidence
            }.reduce(0, +)

            ocrResult.confidence = CGFloat(Float(totalConfidence) / Float(observations.count))
        } else {
            ocrResult.confidence = 0.0
        }
    }

    private func detectPoetry(observations: [VNRecognizedTextObservation]) -> Bool {
        let lineCount = observations.count
        var longLineCount = 0
        var continuousLongLineCount = 0
        var maxContinuousLongLineCount = 0

        var totalCharCount = 0
        var totalWordCount = 0
        var punctuationMarkCount = 0
        var endWithTerminatorCharLineCount = 0

        for i in 0 ..< lineCount {
            let observation = observations[i]
            let text = observation.topCandidates(1).first?.string ?? ""

            totalCharCount += text.count
            totalWordCount += countWords(in: text)

            // Check if line ends with punctuation
            let isEndPunctuationChar = hasEndPunctuationSuffix(text)
            if isEndPunctuationChar {
                endWithTerminatorCharLineCount += 1

                // Check for prose patterns
                if i > 0 {
                    let prevObservation = observations[i - 1]
                    let prevText = prevObservation.topCandidates(1).first?.string ?? ""
                    if isLongTextObservation(prevObservation), !hasEndPunctuationSuffix(prevText) {
                        return false
                    }
                }
            }

            // Check for long lines
            let isLongLine = isLongTextObservation(observation)
            if isLongLine {
                longLineCount += 1

                if !isEndPunctuationChar {
                    continuousLongLineCount += 1
                    if continuousLongLineCount > maxContinuousLongLineCount {
                        maxContinuousLongLineCount = continuousLongLineCount
                    }
                } else {
                    continuousLongLineCount = 0
                }
            } else {
                continuousLongLineCount = 0
            }

            // Count punctuation marks
            punctuationMarkCount += countPunctuationMarks(in: text)
        }

        let charCountPerLine = CGFloat(totalCharCount) / CGFloat(lineCount)
        let wordCountPerLine = totalWordCount / lineCount
        let numberOfPunctuationMarksPerLine = CGFloat(punctuationMarkCount) / CGFloat(lineCount)

        self.charCountPerLine = charCountPerLine
        self.totalCharCount = totalCharCount
        self.punctuationMarkCount = punctuationMarkCount

        // Poetry detection rules

        // Single character per line (like vertical poetry)
        if charCountPerLine < 2 {
            return false
        }

        // Too many punctuation marks per line
        if numberOfPunctuationMarksPerLine > 2 {
            return false
        }

        // No punctuation but many words per line
        if punctuationMarkCount == 0, wordCountPerLine >= 5 {
            return true
        }

        // All lines end with punctuation
        if endWithTerminatorCharLineCount == lineCount {
            return true
        }

        // Continuous long lines with some punctuation (prose pattern)
        if maxContinuousLongLineCount >= 2, endWithTerminatorCharLineCount > 0 {
            return false
        }

        // English poetry pattern
        if endWithTerminatorCharLineCount == 0, lineCount >= 6,
           numberOfPunctuationMarksPerLine <= 1.5 {
            return true
        }

        // Too many long lines (prose pattern)
        let tooManyLongLine = CGFloat(longLineCount) / CGFloat(lineCount) > 0.4
        if tooManyLongLine {
            return false
        }

        return true
    }

    private func sortTextObservations(_ observations: [VNRecognizedTextObservation])
        -> [VNRecognizedTextObservation] {
        // Sort text observations by Y coordinate (top to bottom)
        observations.sorted { obj1, obj2 in
            let boundingBox1 = obj1.boundingBox
            let boundingBox2 = obj2.boundingBox

            let y1 = boundingBox1.origin.y
            let y2 = boundingBox2.origin.y

            if y2 - y1 > minLineHeight * 0.8 {
                return false // obj2 > obj1
            } else {
                return true
            }
        }
    }

    private func performIntelligentTextMerging(_ observations: [VNRecognizedTextObservation])
        -> String {
        let lineCount = observations.count
        var confidence: Float = 0
        var mergedText = ""

        for i in 0 ..< lineCount {
            let textObservation = observations[i]
            let recognizedText = textObservation.topCandidates(1).first
            confidence += recognizedText?.confidence ?? 0

            let recognizedString = recognizedText?.string ?? ""

            if i > 0 {
                let prevTextObservation = observations[i - 1]

                // Create text merger with current statistics
                let textMerger = AppleOCRTextMerger(
                    language: language,
                    isPoetry: isPoetry,
                    minLineHeight: minLineHeight,
                    averageLineHeight: averageLineHeight,
                    maxLongLineTextObservation: maxLongLineTextObservation,
                    minXLineTextObservation: minXLineTextObservation,
                    maxLineLength: maxLineLength,
                    charCountPerLine: charCountPerLine,
                    ocrImage: ocrImage ?? NSImage(),
                    languageManager: EZLanguageManager.shared()
                )

                let joinString = textMerger.joinedStringOfTextObservation(
                    current: textObservation, previous: prevTextObservation
                )

                mergedText += joinString
            }

            mergedText += recognizedString
        }

        // Apply final text processing
        return replaceSimilarDotSymbol(in: mergedText)
    }

    private func replaceSimilarDotSymbol(in string: String) -> String {
        // Replace similar dot symbols with standard middle dot
        let charSet = CharacterSet(charactersIn: "⋅•⋅‧∙")
        let components = string.components(separatedBy: charSet)

        if components.count > 1 {
            let trimmedComponents = components.compactMap { component in
                let trimmed = component.trimmingCharacters(in: .whitespaces)
                return trimmed.isEmpty ? nil : trimmed
            }
            return trimmedComponents.joined(separator: " · ")
        }

        return string
    }

    // MARK: - Basic Helper Methods

    private func countWords(in text: String) -> Int {
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        return words.filter { !$0.isEmpty }.count
    }

    private func hasEndPunctuationSuffix(_ text: String) -> Bool {
        let endPunctuationMarks = CharacterSet(charactersIn: "。！？.,!?;:")
        guard let lastChar = text.last else { return false }
        return String(lastChar).unicodeScalars.allSatisfy { endPunctuationMarks.contains($0) }
    }

    private func countPunctuationMarks(in text: String) -> Int {
        let allowedCharacters = ["《", "》", "〔", "〕"] // Poetry-specific characters
        var count = 0

        for char in text {
            let charString = String(char)
            if !allowedCharacters.contains(charString), isPunctuationCharacter(charString) {
                count += 1
            }
        }

        return count
    }

    private func isPunctuationCharacter(_ char: String) -> Bool {
        guard char.count == 1, let scalar = char.unicodeScalars.first else { return false }
        return CharacterSet.punctuationCharacters.contains(scalar)
    }

    private func isLongTextObservation(_ observation: VNRecognizedTextObservation) -> Bool {
        guard let maxObservation = maxLongLineTextObservation else { return false }

        let observationWidth = observation.boundingBox.width
        let maxWidth = maxObservation.boundingBox.width

        // Consider a line "long" if it's more than 85% of the maximum width
        return observationWidth > maxWidth * 0.85
    }
}
