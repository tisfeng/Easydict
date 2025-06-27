//
//  AppleOCRTextMerger.swift
//  Easydict
//
//  Created by tisfeng on 2025/6/22.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation
import Vision

// MARK: - AppleOCRTextMerger

/// Handles intelligent text merging logic for OCR results
/// This class directly corresponds to the joinedStringOfTextObservation method in EZAppleService.m
class AppleOCRTextMerger {
    // MARK: Lifecycle

    /// Initialize text merger with OCR context
    /// - Parameter context: OCR context containing all necessary data for text merging
    init(context: OCRContext) {
        self.context = context
    }

    // MARK: Private

    private let context: OCRContext

    private var languageManager = EZLanguageManager.shared()

    // Convenience computed properties for easier access
    private var language: Language { context.language }
    private var isPoetry: Bool { context.isPoetry }
    private var minLineHeight: Double { context.minLineHeight }
    private var averageLineHeight: Double { context.averageLineHeight }
    private var maxLongLineTextObservation: VNRecognizedTextObservation? {
        context.maxLongLineTextObservation
    }

    private var minXLineTextObservation: VNRecognizedTextObservation? {
        context.minXLineTextObservation
    }

    private var maxCharacterCountLineTextObservation: VNRecognizedTextObservation? {
        context.maxCharacterCountLineTextObservation
    }

    private var maxLineLength: Double { context.maxLineLength }
    private var charCountPerLine: Double { context.charCountPerLine }
    private var ocrImage: NSImage { context.ocrImage }
    private var singleAlphabetWidth: Double { context.singleAlphabetWidth }
}

// MARK: - Helper Methods Extension

extension AppleOCRTextMerger {
    /// Compare font sizes between two text observations
    /// - Parameters:
    ///   - current: Current text observation
    ///   - previous: Previous text observation
    /// - Returns: True if font sizes are approximately equal
    private func checkEqualFontSize(
        current: VNRecognizedTextObservation,
        previous: VNRecognizedTextObservation
    )
        -> Bool {
        let currentFontSize = fontSizeOfTextObservation(current)
        let prevFontSize = fontSizeOfTextObservation(previous)

        let differentFontSize = abs(currentFontSize - prevFontSize)
        let isEqualFontSize = differentFontSize <= differentFontSizeThreshold(language)
        if !isEqualFontSize {
            print(
                "Not equal font: diff = \(differentFontSize) (\(prevFontSize), \(currentFontSize))"
            )
        }
        return isEqualFontSize
    }

    /// Different font size by language
    /// - Parameter language: Language of the text
    /// - Returns: Font size threshold for the given language
    private func differentFontSizeThreshold(_ language: Language) -> Double {
        isChineseLanguage()
            ? AppleOCRConstants.chineseDifferenceFontThreshold
            : AppleOCRConstants.englishDifferenceFontThreshold
    }

    /// Check if current language is English
    /// - Returns: True if processing English text
    private func isEnglishLanguage() -> Bool {
        languageManager.isEnglishLanguage(language)
    }

    /// Check if current language is Chinese
    /// - Returns: True if processing Chinese text
    private func isChineseLanguage() -> Bool {
        languageManager.isChineseLanguage(language)
    }

    // MARK: - Public Methods

    /// Main method to get joined string between two text observations
    /// This directly corresponds to joinedStringOfTextObservation in Objective-C
    /// - Parameters:
    ///   - current: Current text observation
    ///   - previous: Previous text observation
    /// - Returns: Appropriate joining string between the two observations
    func joinedStringOfTextObservation(
        current: VNRecognizedTextObservation,
        previous: VNRecognizedTextObservation
    )
        -> String {
        // Prepare analysis context
        let analysisContext = prepareAnalysisContext(current: current, previous: previous)

        // Determine line break and paragraph decisions
        let (needLineBreak, isNewParagraph) = determineLineBreakAndParagraph(
            current: current,
            previous: previous,
            context: analysisContext
        )

        // Generate final joined string
        return generateJoinedString(
            needLineBreak: needLineBreak,
            isNewParagraph: isNewParagraph,
            previousText: previous.text
        )
    }

    // MARK: - Helper Methods for Text Analysis

    /// Prepare analysis context for text observation comparison
    private func prepareAnalysisContext(
        current: VNRecognizedTextObservation,
        previous: VNRecognizedTextObservation
    )
        -> TextAnalysisContext {
        let prevText = previous.text

        return TextAnalysisContext(
            isPrevEndPunctuation: prevText.hasEndPunctuationSuffix,
            isPrevLongText: isLongTextObservation(previous, isStrict: false),
            hasIndentation: hasIndentationOfTextObservation(current),
            hasPrevIndentation: hasIndentationOfTextObservation(previous),
            isBigLineSpacing: isBigSpacingLineOfTextObservation(
                current: current,
                previous: previous,
                greaterThanLineHeightRatio: 1.0
            )
        )
    }

    /// Prepare comprehensive formatting data for text analysis
    private func prepareFormattingData(
        current: VNRecognizedTextObservation,
        previous: VNRecognizedTextObservation
    )
        -> FormattingData {
        let prevText = previous.text
        let isEqualChineseText = isEqualChineseTextObservation(current: current, previous: previous)

        return FormattingData(
            current: current,
            previous: previous,
            isPrevEndPunctuation: prevText.hasEndPunctuationSuffix,
            isPrevLongText: isLongTextObservation(previous, isStrict: false),
            hasIndentation: hasIndentationOfTextObservation(current),
            hasPrevIndentation: hasIndentationOfTextObservation(previous),
            isBigLineSpacing: isBigSpacingLineOfTextObservation(
                current: current,
                previous: previous,
                greaterThanLineHeightRatio: 1.0
            ),
            isEqualChineseText: isEqualChineseText,
            isPrevList: previous.text.isListTypeFirstWord,
            isList: current.text.isListTypeFirstWord
        )
    }

    /// Determine if line break and paragraph break are needed
    private func determineLineBreakAndParagraph(
        current: VNRecognizedTextObservation,
        previous: VNRecognizedTextObservation,
        context: TextAnalysisContext
    )
        -> (needLineBreak: Bool, isNewParagraph: Bool) {
        var needLineBreak = false
        var isNewParagraph = false

        // Create comprehensive formatting data
        let formattingData = prepareFormattingData(current: current, previous: previous)

        // Handle indented text
        if formattingData.hasIndentation {
            let result = handleIndentedText(formattingData: formattingData)
            needLineBreak = result.needLineBreak
            isNewParagraph = result.isNewParagraph
        } else {
            // Handle non-indented text
            let result = handleNonIndentedText(formattingData: formattingData)
            needLineBreak = result.needLineBreak
            isNewParagraph = result.isNewParagraph
        }

        // Apply additional formatting rules
        let finalResult = applyAdditionalFormattingRules(
            formattingData: formattingData,
            needLineBreak: needLineBreak,
            isNewParagraph: isNewParagraph
        )

        return (finalResult.needLineBreak, finalResult.isNewParagraph)
    }

    /// Generate the final joined string based on formatting decisions
    private func generateJoinedString(
        needLineBreak: Bool,
        isNewParagraph: Bool,
        previousText: String
    )
        -> String {
        if isNewParagraph {
            return AppleOCRConstants.paragraphBreakText
        } else if needLineBreak {
            return AppleOCRConstants.lineBreakText
        } else if previousText.hasPunctuationSuffix {
            // If last char is a punctuation mark, append a space
            return " "
        } else {
            // For languages that need spaces between words
            if languageManager.isLanguageWordsNeedSpace(language) {
                return " "
            }
            return ""
        }
    }

    // MARK: - Private Helper Methods

    /// Determine if there is big line spacing between observations
    /// - Parameters:
    ///   - current: Current observation
    ///   - previous: Previous observation
    ///   - greaterThanLineHeightRatio: Minimum ratio threshold
    /// - Returns: True if spacing is considered big
    private func isBigSpacingLineOfTextObservation(
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
        let averageLineHeightRatio = deltaY / averageLineHeight

        let text = current.text
        let prevText = previous.text
        let isPrevEndPunctuationChar = prevText.hasEndPunctuationSuffix

        // Since line spacing sometimes is too small and imprecise, we do not use it.
        if lineHeightRatio > 1.0 || averageLineHeightRatio > greaterThanLineHeightRatio {
            return true
        }

        if lineHeightRatio > 0.6,
           !isLongTextObservation(previous, isStrict: true)
           || isPrevEndPunctuationChar || previous === maxLongLineTextObservation {
            return true
        }

        let isFirstLetterUpperCase = text.first?.isUppercase == true && text.first?.isLetter == true

        // For English text
        if languageManager.isEnglishLanguage(language), isFirstLetterUpperCase {
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

    /// Check if observation has indentation
    /// - Parameter observation: Observation to check
    /// - Returns: True if observation appears indented
    private func hasIndentationOfTextObservation(_ observation: VNRecognizedTextObservation) -> Bool {
        guard let minXObservation = minXLineTextObservation else { return false }
        let isEqualX = isEqualXOfTextObservation(current: observation, previous: minXObservation)
        return !isEqualX
    }

    /// Determine if text observation represents a long line
    /// - Parameters:
    ///   - observation: Text observation to evaluate
    ///   - isStrict: Whether to use strict evaluation criteria
    /// - Returns: True if observation is considered a long line
    private func isLongTextObservation(
        _ observation: VNRecognizedTextObservation,
        isStrict: Bool = false
    )
        -> Bool {
        let threshold = longTextAlphabetCountThreshold(observation, isStrict: isStrict)
        return isLongTextObservation(observation, threshold: threshold)
    }

    /// Check if observation is long based on threshold
    /// - Parameters:
    ///   - observation: Observation to check
    ///   - threshold: Threshold value for comparison
    /// - Returns: True if observation exceeds threshold
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

    /// Calculate remaining alphabet count for line length evaluation
    /// - Parameter observation: Observation to analyze
    /// - Returns: Estimated remaining character count
    private func remainingAlphabetCountOfTextObservation(_ observation: VNRecognizedTextObservation)
        -> Double {
        guard let maxObservation = maxLongLineTextObservation else { return 0 }

        let scaleFactor = NSScreen.main?.backingScaleFactor ?? 1.0
        let dx = maxObservation.boundingBox.maxX - observation.boundingBox.maxX
        let maxLength = ocrImage.size.width * maxLineLength / scaleFactor
        let difference = maxLength * dx

        return difference / singleAlphabetWidth
    }

    /// Calculate threshold for long text determination
    /// - Parameters:
    ///   - observation: Text observation context
    ///   - isStrict: Whether to use strict criteria
    /// - Returns: Calculated threshold value
    private func longTextAlphabetCountThreshold(
        _ observation: VNRecognizedTextObservation,
        isStrict: Bool
    )
        -> Double {
        let isEnglishTypeLanguage = languageManager.isLanguageWordsNeedSpace(language)

        // For long text, there are up to 15 letters or 2 Chinese characters on the far right.
        // "implementation ," : @"你好"
        var alphabetCount: Double = isEnglishTypeLanguage ? 15 : 1.5

        let text = observation.text
        let isEndPunctuationChar = text.hasEndPunctuationSuffix

        if !isStrict, languageManager.isChineseLanguage(language) {
            if !isEndPunctuationChar {
                alphabetCount += 0.8
            }
        }

        return alphabetCount
    }

    /// Check if observations contain equal-length Chinese text
    /// - Parameters:
    ///   - current: Current observation
    ///   - previous: Previous observation
    /// - Returns: True if both are equal Chinese text
    private func isEqualChineseTextObservation(
        current: VNRecognizedTextObservation,
        previous: VNRecognizedTextObservation
    )
        -> Bool {
        let isEqualLength = isEqualCharacterLengthTextObservation(
            current: current, previous: previous
        )
        return isEqualLength && languageManager.isChineseLanguage(language)
    }

    /// Check if observations have equal character length patterns
    /// - Parameters:
    ///   - current: Current observation
    ///   - previous: Previous observation
    /// - Returns: True if character length patterns match
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

    /// Check if two observations are geometrically equal
    /// - Parameters:
    ///   - current: Current observation
    ///   - previous: Previous observation
    /// - Returns: True if observations are similar in position and size
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

    /// Check if observations have equal X coordinates
    /// - Parameters:
    ///   - current: Current observation
    ///   - previous: Previous observation
    /// - Returns: True if X coordinates are approximately equal
    private func isEqualXOfTextObservation(
        current: VNRecognizedTextObservation,
        previous: VNRecognizedTextObservation
    )
        -> Bool {
        // Simplified implementation based on threshold calculation
        let threshold = singleAlphabetWidth * AppleOCRConstants.indentationCharacterCount

        let lineX = current.boundingBox.origin.x
        let prevLineX = previous.boundingBox.origin.x
        let dx = lineX - prevLineX

        let scaleFactor = NSScreen.main?.backingScaleFactor ?? 1.0
        let maxLength = ocrImage.size.width * maxLineLength / scaleFactor
        let difference = maxLength * dx

        // dx > 0, means current line may has indentation.
        if (dx > 0 && difference < threshold) || abs(difference) < (threshold / 2) {
            return true
        }

        print("Not equalX text: \(current)")
        print("difference: \(difference), threshold: \(threshold)")

        return false
    }

    /// Calculate font size for text observation
    /// - Parameter observation: Observation to analyze
    /// - Returns: Estimated font size
    private func fontSizeOfTextObservation(_ observation: VNRecognizedTextObservation) -> Double {
        let scaleFactor = NSScreen.main?.backingScaleFactor ?? 1.0
        let textWidth = observation.boundingBox.size.width * ocrImage.size.width / scaleFactor
        return fontSizeOfText(observation.text, width: textWidth)
    }

    /// Calculate font size based on text content and width
    /// - Parameters:
    ///   - text: Text content
    ///   - textWidth: Width of the text
    /// - Returns: Estimated font size
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

    /// Check if line length is considered short
    /// - Parameters:
    ///   - lineLength: Length to check
    ///   - maxLineLength: Maximum line length reference
    ///   - lessRateOfMaxLength: Threshold ratio
    /// - Returns: True if line is considered short
    private func isShortLineLength(
        _ lineLength: Double,
        maxLineLength: Double,
        lessRateOfMaxLength: Double
    )
        -> Bool {
        lineLength < maxLineLength * lessRateOfMaxLength
    }

    /// Check if ratio between two values exceeds threshold
    /// - Parameters:
    ///   - ratio: Minimum ratio threshold
    ///   - value1: First value
    ///   - value2: Second value
    /// - Returns: True if ratio exceeds threshold
    private func isRatioGreaterThan(_ ratio: Double, value1: Double, value2: Double) -> Bool {
        let minValue = min(value1, value2)
        let maxValue = max(value1, value2)
        return (minValue / maxValue) > ratio
    }

    /// Check if text represents short Chinese poetry
    /// - Parameter text: Text to analyze
    /// - Returns: True if text matches short Chinese poetry patterns
    private func isShortChinesePoetryText(_ text: String) -> Bool {
        languageManager.isChineseLanguage(language)
            && charCountPerLine < Double(AppleOCRConstants.shortPoetryCharacterCountOfLine)
            && text.count < AppleOCRConstants.shortPoetryCharacterCountOfLine
    }

    /// Handle text merging logic for indented text blocks
    /// - Parameter formattingData: All formatting context data
    /// - Returns: Tuple indicating line break and paragraph decisions
    private func handleIndentedText(
        formattingData: FormattingData
    )
        -> (needLineBreak: Bool, isNewParagraph: Bool) {
        var needLineBreak = false
        var isNewParagraph = false

        let isEqualX = isEqualXOfTextObservation(
            current: formattingData.current,
            previous: formattingData.previous
        )
        let lineX = formattingData.current.boundingBox.minX
        let prevLineX = formattingData.previous.boundingBox.minX
        let dx = lineX - prevLineX

        if formattingData.hasPrevIndentation {
            if formattingData.isBigLineSpacing,
               !formattingData.isPrevLongText,
               !formattingData.isPrevList,
               !formattingData.isList {
                isNewParagraph = true
            }

            // Check for short line conditions
            let prevLineLength = formattingData.previous.boundingBox.width
            let isPrevLessHalfShortLine = isShortLineLength(
                prevLineLength, maxLineLength: maxLineLength, lessRateOfMaxLength: 0.5
            )
            let isPrevShortLine = isShortLineLength(
                prevLineLength, maxLineLength: maxLineLength, lessRateOfMaxLength: 0.85
            )

            let lineMaxX = formattingData.current.boundingBox.maxX
            let prevLineMaxX = formattingData.previous.boundingBox.maxX
            let isEqualLineMaxX = isRatioGreaterThan(
                0.95, value1: lineMaxX, value2: prevLineMaxX
            )

            let isEqualInnerTwoLine = isEqualX && isEqualLineMaxX

            if isEqualInnerTwoLine {
                if isPrevLessHalfShortLine {
                    needLineBreak = true
                } else {
                    needLineBreak = formattingData.isEqualChineseText
                }
            } else {
                if formattingData.isPrevLongText {
                    if formattingData.isPrevEndPunctuation {
                        needLineBreak = true
                    } else {
                        if !isEqualX, dx < 0 {
                            isNewParagraph = true
                        } else {
                            needLineBreak = false
                        }
                    }
                } else {
                    if formattingData.isPrevEndPunctuation {
                        if !isEqualX, !formattingData.isList {
                            isNewParagraph = true
                        } else {
                            needLineBreak = true
                        }
                    } else {
                        needLineBreak = isPrevShortLine
                    }
                }
            }
        } else {
            // Sometimes hasIndentation is a mistake, when prev line is long
            if formattingData.isPrevLongText {
                let isEqualFontSize = checkEqualFontSize(
                    current: formattingData.current,
                    previous: formattingData.previous
                )
                if formattingData.isPrevEndPunctuation || !isEqualFontSize {
                    isNewParagraph = true
                } else {
                    needLineBreak = !(dx > 0 && !isEqualX)
                }
            } else {
                isNewParagraph = true
            }
        }

        return (needLineBreak, isNewParagraph)
    }

    /// Handle text merging logic for non-indented text blocks
    private func handleNonIndentedText(
        formattingData: FormattingData
    )
        -> (needLineBreak: Bool, isNewParagraph: Bool) {
        var needLineBreak = false
        var isNewParagraph = false

        if formattingData.hasPrevIndentation {
            needLineBreak = true
        }

        if formattingData.isBigLineSpacing {
            if formattingData.isPrevLongText {
                if isPoetry {
                    needLineBreak = true
                } else {
                    // Check for page turn scenarios
                    let isTurnedPage = isEnglishLanguage() &&
                        formattingData.currentText.isLowercaseFirstChar &&
                        !formattingData.isPrevEndPunctuation
                    if !isTurnedPage {
                        needLineBreak = true
                    }
                }
            } else {
                if formattingData.isPrevEndPunctuation || formattingData.hasPrevIndentation {
                    isNewParagraph = true
                } else {
                    needLineBreak = true
                }
            }
        } else {
            if formattingData.isPrevLongText {
                if !formattingData.hasPrevIndentation {
                    // Chinese poetry special case
                    if formattingData.isPrevEndPunctuation, formattingData.currentText.hasEndPunctuationSuffix {
                        needLineBreak = true

                        // If language is English and current line first letter is NOT uppercase, do not need line break
                        if isEnglishLanguage(), !formattingData.currentText.isFirstLetterUpperCase {
                            needLineBreak = false
                        }
                    }
                }
            } else {
                needLineBreak = true
                if formattingData.hasPrevIndentation, !formattingData.isPrevEndPunctuation {
                    isNewParagraph = true
                }
            }

            if isPoetry {
                needLineBreak = true
            }
        }

        return (needLineBreak, isNewParagraph)
    }

    /// Apply additional formatting rules for special cases
    private func applyAdditionalFormattingRules(
        formattingData: FormattingData,
        needLineBreak: Bool,
        isNewParagraph: Bool
    )
        -> (needLineBreak: Bool, isNewParagraph: Bool) {
        var finalNeedLineBreak = needLineBreak
        var finalIsNewParagraph = isNewParagraph

        // Font size and spacing checks
        let isEqualFontSize = checkEqualFontSize(
            current: formattingData.current,
            previous: formattingData.previous
        )
        let isFirstLetterUpperCase = formattingData.currentText.isFirstLetterUpperCase

        if !isEqualFontSize || formattingData.isBigLineSpacing {
            if !formattingData.isPrevLongText || (isEnglishLanguage() && isFirstLetterUpperCase) {
                finalIsNewParagraph = true
            }
        }

        if formattingData.isBigLineSpacing, isFirstLetterUpperCase {
            finalIsNewParagraph = true
        }

        // Chinese poetry handling
        let poetryResult = handleChinesePoetry(
            currentText: formattingData.currentText,
            previousText: formattingData.previousText,
            isEqualChineseText: formattingData.isEqualChineseText,
            isBigLineSpacing: formattingData.isBigLineSpacing
        )
        if poetryResult.shouldWrap {
            finalNeedLineBreak = true
            if poetryResult.isNewParagraph {
                finalIsNewParagraph = true
            }
        }

        // List handling
        let listResult = handleListFormatting(
            isPrevList: formattingData.isPrevList,
            isList: formattingData.isList,
            isBigLineSpacing: formattingData.isBigLineSpacing
        )
        if listResult.needLineBreak {
            finalNeedLineBreak = true
        }
        if listResult.isNewParagraph {
            finalIsNewParagraph = true
        }

        return (finalNeedLineBreak, finalIsNewParagraph)
    }

    /// Handle Chinese poetry formatting
    private func handleChinesePoetry(
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
    private func handleListFormatting(
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
}
