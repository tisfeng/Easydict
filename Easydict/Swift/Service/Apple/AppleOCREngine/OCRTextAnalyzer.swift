//
//  OCRTextAnalyzer.swift
//  Easydict
//
//  Created by tisfeng on 2025/6/26.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation
import Vision

// MARK: - OCRTextAnalyzer

/// Handles text analysis operations for OCR processing
/// This class contains all the analytical methods for determining text properties and relationships
class OCRTextAnalyzer {
    // MARK: Lifecycle

    init(context: OCRContext) {
        self.context = context
    }

    // MARK: Internal

    /// Check if observation has indentation
    func hasIndentationOfTextObservation(_ observation: VNRecognizedTextObservation) -> Bool {
        guard let minXObservation = context.minXLineTextObservation else { return false }
        let isEqualX = isEqualXOfTextObservation(current: observation, previous: minXObservation)
        return !isEqualX
    }

    /// Determine if text observation represents a long line
    func isLongTextObservation(
        _ observation: VNRecognizedTextObservation,
        isStrict: Bool = false
    )
        -> Bool {
        let threshold = longTextAlphabetCountThreshold(observation, isStrict: isStrict)
        return isLongTextObservation(observation, threshold: threshold)
    }

    /// Check if observations contain equal-length Chinese text
    func isEqualChineseTextObservation(
        current: VNRecognizedTextObservation,
        previous: VNRecognizedTextObservation
    )
        -> Bool {
        let isEqualLength = isEqualCharacterLengthTextObservation(
            current: current, previous: previous
        )
        return isEqualLength && languageManager.isChineseLanguage(context.language)
    }

    /// Determine if there is big line spacing between observations
    func isBigSpacingLineOfTextObservation(
        current: VNRecognizedTextObservation,
        previous: VNRecognizedTextObservation,
        greaterThanLineHeightRatio: Double
    )
        -> Bool {
        let prevBoundingBox = previous.boundingBox
        let boundingBox = current.boundingBox
        let lineHeight = boundingBox.size.height

        // !!!: deltaY may be < 0
        let deltaY = prevBoundingBox.origin.y - (boundingBox.origin.y + lineHeight)
        let lineHeightRatio = deltaY / lineHeight
        let averageLineHeightRatio = deltaY / context.averageLineHeight

        let text = current.text
        let prevText = previous.text
        let isPrevEndPunctuationChar = prevText.hasEndPunctuationSuffix

        // Since line spacing sometimes is too small and imprecise, we do not use it.
        if lineHeightRatio > 1.0 || averageLineHeightRatio > greaterThanLineHeightRatio {
            return true
        }

        if lineHeightRatio > 0.6,
           !isLongTextObservation(previous, isStrict: true)
           || isPrevEndPunctuationChar || previous === context.maxLongLineTextObservation {
            return true
        }

        let isFirstLetterUpperCase = text.first?.isUppercase == true && text.first?.isLetter == true

        // For English text
        if languageManager.isEnglishLanguage(context.language), isFirstLetterUpperCase {
            if lineHeightRatio > 0.85 {
                return true
            } else {
                if lineHeightRatio > 0.6, isPrevEndPunctuationChar {
                    return true
                }
            }
        }

        return false
    }

    /// Compare font sizes between two text observations
    func checkEqualFontSize(
        current: VNRecognizedTextObservation,
        previous: VNRecognizedTextObservation
    )
        -> Bool {
        let currentFontSize = fontSizeOfTextObservation(current)
        let prevFontSize = fontSizeOfTextObservation(previous)

        let differentFontSize = abs(currentFontSize - prevFontSize)
        let isEqualFontSize = differentFontSize <= differentFontSizeThreshold(context.language)
        if !isEqualFontSize {
            print(
                "Not equal font: diff = \(differentFontSize) (\(prevFontSize), \(currentFontSize))"
            )
        }
        return isEqualFontSize
    }

    /// Check if text represents short Chinese poetry
    func isShortChinesePoetryText(_ text: String) -> Bool {
        languageManager.isChineseLanguage(context.language)
            && context.charCountPerLine < Double(OCRConstants.shortPoetryCharacterCountOfLine)
            && text.count < OCRConstants.shortPoetryCharacterCountOfLine
    }

    /// Check if line length is considered short
    func isShortLineLength(
        _ lineLength: Double,
        maxLineLength: Double,
        lessRateOfMaxLength: Double
    )
        -> Bool {
        lineLength < maxLineLength * lessRateOfMaxLength
    }

    /// Handle Chinese poetry formatting
    func handleChinesePoetry(
        currentText: String,
        previousText: String,
        isEqualChineseText: Bool,
        isBigLineSpacing: Bool
    )
        -> (shouldWrap: Bool, isNewParagraph: Bool) {
        let isShortChinesePoetry = isShortChinesePoetryText(currentText)
        let isPrevShortChinesePoetry = isShortChinesePoetryText(previousText)

        let isChinesePoetryLine =
            isEqualChineseText || (isShortChinesePoetry && isPrevShortChinesePoetry)
        let shouldWrap = isChinesePoetryLine
        let isNewParagraph = shouldWrap && isBigLineSpacing

        return (shouldWrap, isNewParagraph)
    }

    /// Handle list formatting
    func handleListFormatting(
        isPrevList: Bool,
        isList: Bool,
        isBigLineSpacing: Bool
    )
        -> (needLineBreak: Bool, isNewParagraph: Bool) {
        if isPrevList {
            if isList {
                return (needLineBreak: true, isNewParagraph: isBigLineSpacing)
            } else {
                // List ends, next is new paragraph if big spacing
                return (needLineBreak: false, isNewParagraph: isBigLineSpacing)
            }
        }
        if isList {
            // New list starts
            return (needLineBreak: true, isNewParagraph: isBigLineSpacing)
        }
        return (needLineBreak: false, isNewParagraph: false)
    }

    // MARK: Private

    private let context: OCRContext
    private var languageManager = EZLanguageManager.shared()

    // MARK: - Helper Methods

    private func isEqualXOfTextObservation(
        current: VNRecognizedTextObservation,
        previous: VNRecognizedTextObservation
    )
        -> Bool {
        // Simplified implementation based on threshold calculation
        let threshold = context.singleAlphabetWidth * OCRConstants.indentationCharacterCount

        let lineX = current.boundingBox.origin.x
        let prevLineX = previous.boundingBox.origin.x
        let dx = lineX - prevLineX

        let scaleFactor = NSScreen.main?.backingScaleFactor ?? 1.0
        let maxLength = context.ocrImage.size.width * context.maxLineLength / scaleFactor
        let difference = maxLength * dx

        // dx > 0, means current line may has indentation.
        if (dx > 0 && difference < threshold) || abs(difference) < (threshold / 2) {
            return true
        }

        print("Not equalX text: \(current)")
        print("difference: \(difference), threshold: \(threshold)")

        return false
    }

    private func isLongTextObservation(
        _ observation: VNRecognizedTextObservation,
        threshold: Double
    )
        -> Bool {
        let remainingAlphabetCount = remainingAlphabetCountOfTextObservation(observation)
        let isLongText = remainingAlphabetCount < threshold
        if !isLongText {
            print("Not long text: \(observation)")
            print("Remaining alphabet count: \(remainingAlphabetCount), threshold: \(threshold)")
        }
        return isLongText
    }

    private func remainingAlphabetCountOfTextObservation(_ observation: VNRecognizedTextObservation)
        -> Double {
        guard let maxObservation = context.maxLongLineTextObservation else { return 0 }

        let scaleFactor = NSScreen.main?.backingScaleFactor ?? 1.0
        let dx = maxObservation.boundingBox.maxX - observation.boundingBox.maxX
        let maxLength = context.ocrImage.size.width * context.maxLineLength / scaleFactor
        let difference = maxLength * dx

        return difference / context.singleAlphabetWidth
    }

    private func longTextAlphabetCountThreshold(
        _ observation: VNRecognizedTextObservation,
        isStrict: Bool
    )
        -> Double {
        let isEnglishTypeLanguage = languageManager.isLanguageWordsNeedSpace(context.language)

        // For long text, there are up to 15 letters or 2 Chinese characters on the far right.
        // "implementation ," : @"你好"
        var alphabetCount: Double = isEnglishTypeLanguage ? 15 : 1.5

        let text = observation.text
        let isEndPunctuationChar = text.hasEndPunctuationSuffix

        if !isStrict, languageManager.isChineseLanguage(context.language) {
            if !isEndPunctuationChar {
                alphabetCount += 0.8
            }
        }

        return alphabetCount
    }

    private func isEqualCharacterLengthTextObservation(
        current: VNRecognizedTextObservation,
        previous: VNRecognizedTextObservation
    )
        -> Bool {
        let isEqual = isEqualTextObservation(current: current, previous: previous)

        let currentText = current.text
        let previousText = previous.text

        let isCurrentEndPunctuationChar = currentText.hasEndPunctuationSuffix
        let isPreviousEndPunctuationChar = previousText.hasEndPunctuationSuffix

        let isEqualLength = currentText.count == previousText.count
        let isEqualEndSuffix = isCurrentEndPunctuationChar && isPreviousEndPunctuationChar

        return isEqual && isEqualLength && isEqualEndSuffix
    }

    private func isEqualTextObservation(
        current: VNRecognizedTextObservation,
        previous: VNRecognizedTextObservation
    )
        -> Bool {
        let isEqualX = isEqualXOfTextObservation(current: current, previous: previous)

        let lineMaxX = current.boundingBox.maxX
        let prevLineMaxX = previous.boundingBox.maxX

        let ratio = 0.95
        let isEqualLineMaxX = isRatioGreaterThan(ratio, value1: lineMaxX, value2: prevLineMaxX)

        return isEqualX && isEqualLineMaxX
    }

    private func isRatioGreaterThan(_ ratio: Double, value1: Double, value2: Double) -> Bool {
        let minValue = min(value1, value2)
        let maxValue = max(value1, value2)
        return (minValue / maxValue) > ratio
    }

    private func fontSizeOfTextObservation(_ observation: VNRecognizedTextObservation) -> Double {
        let scaleFactor = NSScreen.main?.backingScaleFactor ?? 1.0
        let textWidth =
            observation.boundingBox.size.width * context.ocrImage.size.width / scaleFactor
        return fontSizeOfText(observation.text, width: textWidth)
    }

    private func fontSizeOfText(_ text: String, width textWidth: Double) -> Double {
        let systemFontSize = NSFont.systemFontSize
        let font = NSFont.boldSystemFont(ofSize: systemFontSize)

        let width = text.size(withAttributes: [.font: font]).width

        /**
         systemFontSize / width = x / textWidth
         x = textWidth * (systemFontSize / width)
         */
        let fontSize = textWidth * (systemFontSize / width)

        return fontSize
    }

    private func differentFontSizeThreshold(_ language: Language) -> Double {
        languageManager.isChineseLanguage(language)
            ? OCRConstants.chineseDifferenceFontThreshold
            : OCRConstants.englishDifferenceFontThreshold
    }
}
