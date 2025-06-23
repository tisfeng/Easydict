//
//  AppleOCRTextMerger.swift
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
private let kShortPoetryCharacterCountOfLine = 12

// MARK: - VNRecognizedTextObservation Extension

extension VNRecognizedTextObservation {
    /// A computed property to get the top candidate string, returns empty string if not available.
    var text: String {
        topCandidates(1).first?.string ?? ""
    }

    open override var description: String {
        let boundRect = boundingBox
        return String(
            format: "Text: \"%@\", { x=%.3f, y=%.3f, width=%.3f, height=%.3f }",
            text,
            boundRect.origin.x,
            boundRect.origin.y,
            boundRect.size.width,
            boundRect.size.height
        )
    }
}

// MARK: - Array Extension for Better Printing

extension Array where Element == VNRecognizedTextObservation {
    /// Get a nicely formatted string representation of text observations
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

    /// Get just the recognized texts in a clean format
    var recognizedTexts: [String] {
        map { $0.text }
    }
}

// MARK: - Supporting Types

/// Contains text analysis properties for break type determination
private struct TextAnalysisContext {
    let isPrevEndPunctuation: Bool
    let isPrevLongText: Bool
    let hasIndentation: Bool
    let hasPrevIndentation: Bool
    let isBigLineSpacing: Bool
}

/// Contains text content for analysis
private struct TextContent {
    let currentText: String
    let previousText: String
}

// MARK: - AppleOCRTextMerger

/// Handles intelligent text merging logic for OCR results
/// This class directly corresponds to the joinedStringOfTextObservation method in EZAppleService.m
class AppleOCRTextMerger {
    // MARK: Lifecycle

    // MARK: - Initialization

    init(
        language: Language,
        isPoetry: Bool,
        minLineHeight: CGFloat,
        averageLineHeight: CGFloat,
        maxLongLineTextObservation: VNRecognizedTextObservation?,
        minXLineTextObservation: VNRecognizedTextObservation?,
        maxLineLength: CGFloat,
        charCountPerLine: CGFloat,
        ocrImage: NSImage,
        languageManager: EZLanguageManager
    ) {
        self.language = language
        self.isPoetry = isPoetry
        self.minLineHeight = minLineHeight
        self.averageLineHeight = averageLineHeight
        self.maxLongLineTextObservation = maxLongLineTextObservation
        self.minXLineTextObservation = minXLineTextObservation
        self.maxLineLength = maxLineLength
        self.charCountPerLine = charCountPerLine
        self.ocrImage = ocrImage
        self.languageManager = languageManager
    }

    // MARK: Private

    private let language: Language
    private let isPoetry: Bool
    private let minLineHeight: CGFloat
    private let averageLineHeight: CGFloat
    private let maxLongLineTextObservation: VNRecognizedTextObservation?
    private let minXLineTextObservation: VNRecognizedTextObservation?
    private let maxLineLength: CGFloat
    private let charCountPerLine: CGFloat
    private let ocrImage: NSImage
    private let languageManager: EZLanguageManager

    // MARK: - Private Methods

    private func analyzeLineRelationship(
        current: VNRecognizedTextObservation,
        previous: VNRecognizedTextObservation
    )
        -> (isNewLine: Bool, deltaY: CGFloat, deltaX: CGFloat) {
        let currentBoundingBox = current.boundingBox
        let previousBoundingBox = previous.boundingBox

        let deltaY =
            previousBoundingBox.origin.y
                - (currentBoundingBox.origin.y + currentBoundingBox.size.height)
        let deltaX =
            currentBoundingBox.origin.x
                - (previousBoundingBox.origin.x + previousBoundingBox.size.width)

        var isNewLine = false

        // Check Y coordinate for new line
        if deltaY > 0 {
            isNewLine = true
        } else if abs(deltaY) < minLineHeight / 2 {
            isNewLine = true
        }

        // Check X coordinate gap for line detection
        if deltaX > 0.07 {
            isNewLine = true
        }

        return (isNewLine, deltaY, deltaX)
    }

    private func determineBreakType(
        current: VNRecognizedTextObservation,
        previous: VNRecognizedTextObservation,
        currentText: String,
        previousText: String
    )
        -> (isNewParagraph: Bool, needLineBreak: Bool, joinString: String) {
        // Check text properties (same as original)
        let analysisContext = TextAnalysisContext(
            isPrevEndPunctuation: hasEndPunctuationSuffix(previousText),
            isPrevLongText: isLongTextObservation(previous),
            hasIndentation: hasTextIndentation(current),
            hasPrevIndentation: hasTextIndentation(previous),
            isBigLineSpacing: isBigSpacing(current: current, previous: previous)
        )

        // Additional properties needed for complex logic
        let isEqualChineseText = isEqualChineseTextObservation(current: current, previous: previous)
        let isPrevList = isListTypeFirstWord(previousText)
        let isList = isListTypeFirstWord(currentText)
        let isEqualFontSize = checkEqualFontSize(current: current, previous: previous)
        let isFirstLetterUpperCase = isFirstLetterUppercase(currentText)

        var needLineBreak = false
        var isNewParagraph = false

        // Apply joining logic based on indentation
        if analysisContext.hasIndentation {
            let result = handleIndentedText(
                current: current,
                previous: previous,
                context: analysisContext,
                isEqualChineseText: isEqualChineseText,
                isPrevList: isPrevList,
                isList: isList
            )
            needLineBreak = result.needLineBreak
            isNewParagraph = result.isNewParagraph
        } else {
            let textContent = TextContent(currentText: currentText, previousText: previousText)
            let result = handleNonIndentedText(
                observations: (current: current, previous: previous),
                textContent: textContent,
                context: analysisContext
            )

            // Handle special return cases
            if let specialJoinString = result.specialJoinString {
                return (false, false, specialJoinString)
            }

            needLineBreak = result.needLineBreak
            isNewParagraph = result.isNewParagraph
        }

        // Apply font size and big spacing rules (from original line 1861-1867)
        if !isEqualFontSize || analysisContext.isBigLineSpacing {
            if !analysisContext.isPrevLongText || (isEnglishLanguage() && isFirstLetterUpperCase) {
                isNewParagraph = true
            }
        }

        // Apply additional big spacing and uppercase rules (from original line 1869-1871)
        if analysisContext.isBigLineSpacing, isFirstLetterUpperCase {
            isNewParagraph = true
        }

        // Apply Chinese poetry rules
        if isChinesePoetryPattern(current: currentText, previous: previousText) {
            needLineBreak = true
            if analysisContext.isBigLineSpacing {
                isNewParagraph = true
            }
        }

        // Apply list handling rules (from original line 1886-1896)
        if isPrevList {
            if isList {
                needLineBreak = true
                isNewParagraph = analysisContext.isBigLineSpacing
            } else {
                // Means list ends, next is new paragraph
                if analysisContext.isBigLineSpacing {
                    isNewParagraph = true
                }
            }
        }

        // Determine final join string
        let joinString = getFinalJoinString(
            isNewParagraph: isNewParagraph,
            needLineBreak: needLineBreak,
            previousText: previousText,
            currentText: currentText
        )

        return (isNewParagraph, needLineBreak, joinString)
    }

    private func handleIndentedText(
        current: VNRecognizedTextObservation,
        previous: VNRecognizedTextObservation,
        context: TextAnalysisContext,
        isEqualChineseText: Bool,
        isPrevList: Bool,
        isList: Bool
    )
        -> (needLineBreak: Bool, isNewParagraph: Bool) {
        var needLineBreak = false
        var isNewParagraph = false

        let isEqualX = isEqualXOfTextObservation(current: current, previous: previous)
        let lineX = current.boundingBox.minX
        let prevLineX = previous.boundingBox.minX
        let dx = lineX - prevLineX

        if context.hasPrevIndentation {
            if context.isBigLineSpacing, !context.isPrevLongText, !isPrevList, !isList {
                isNewParagraph = true
            }

            // Check for short line conditions
            let prevLineLength = previous.boundingBox.width
            let isPrevLessHalfShortLine = isShortLineLength(
                prevLineLength, maxLineLength: maxLineLength, lessRateOfMaxLength: 0.5
            )
            let isPrevShortLine = isShortLineLength(
                prevLineLength, maxLineLength: maxLineLength, lessRateOfMaxLength: 0.85
            )

            let lineMaxX = current.boundingBox.maxX
            let prevLineMaxX = previous.boundingBox.maxX
            let isEqualLineMaxX = isRatioGreaterThan(0.95, value1: lineMaxX, value2: prevLineMaxX)

            let isEqualInnerTwoLine = isEqualX && isEqualLineMaxX

            if isEqualInnerTwoLine {
                if isPrevLessHalfShortLine {
                    needLineBreak = true
                } else {
                    if isEqualChineseText {
                        needLineBreak = true
                    } else {
                        needLineBreak = false
                    }
                }
            } else {
                if context.isPrevLongText {
                    if context.isPrevEndPunctuation {
                        needLineBreak = true
                    } else {
                        if !isEqualX, dx < 0 {
                            isNewParagraph = true
                        } else {
                            needLineBreak = false
                        }
                    }
                } else {
                    if context.isPrevEndPunctuation {
                        if !isEqualX, !isList {
                            isNewParagraph = true
                        } else {
                            needLineBreak = true
                        }
                    } else {
                        if isPrevShortLine {
                            needLineBreak = true
                        } else {
                            needLineBreak = false
                        }
                    }
                }
            }
        } else {
            // Sometimes hasIndentation is a mistake, when prev line is long
            if context.isPrevLongText {
                let isEqualFontSize = checkEqualFontSize(current: current, previous: previous)
                if context.isPrevEndPunctuation || !isEqualFontSize {
                    isNewParagraph = true
                } else {
                    if !isEqualX, dx > 0 {
                        needLineBreak = false
                    } else {
                        needLineBreak = true
                    }
                }
            } else {
                isNewParagraph = true
            }
        }

        return (needLineBreak, isNewParagraph)
    }

    private func handleNonIndentedText(
        observations: (current: VNRecognizedTextObservation, previous: VNRecognizedTextObservation),
        textContent: TextContent,
        context: TextAnalysisContext
    )
        -> (needLineBreak: Bool, isNewParagraph: Bool, specialJoinString: String?) {
        var needLineBreak = false
        var isNewParagraph = false

        if context.hasPrevIndentation {
            needLineBreak = true
        }

        if context.isBigLineSpacing {
            if context.isPrevLongText {
                if isPoetry {
                    needLineBreak = true
                } else {
                    // Check for page turn scenarios (翻页, Page turn scenes without line feeds)
                    let isTurnedPage =
                        isEnglishLanguage() && isEnglishLowercaseStart(textContent.currentText)
                            && !context.isPrevEndPunctuation
                    if isTurnedPage {
                        isNewParagraph = false
                        needLineBreak = false
                        return (needLineBreak, isNewParagraph, " ")
                    }
                }
            } else {
                if context.isPrevEndPunctuation || context.hasPrevIndentation {
                    isNewParagraph = true
                } else {
                    needLineBreak = true
                }
            }
        } else {
            if context.isPrevLongText {
                if context.hasPrevIndentation {
                    needLineBreak = false
                }

                /**
                 Chinese poetry special case

                 人绕湘皋月坠时。斜横花树小，浸愁漪。一春幽事有谁知。东风冷、香远茜裙归。
                 鸥去昔游非。遥怜花可可，梦依依。九疑云杳断魂啼。相思血，都沁绿筠枝。
                 */
                if context.isPrevEndPunctuation, hasEndPunctuationSuffix(textContent.currentText) {
                    needLineBreak = true
                }
            } else {
                needLineBreak = true
                if context.hasPrevIndentation, !context.isPrevEndPunctuation {
                    isNewParagraph = true
                }
            }

            if isPoetry {
                needLineBreak = true
            }
        }

        return (needLineBreak, isNewParagraph, nil)
    }

    private func getFinalJoinString(
        isNewParagraph: Bool,
        needLineBreak: Bool,
        previousText: String,
        currentText: String
    )
        -> String {
        if isNewParagraph {
            return kParagraphBreakText
        } else if needLineBreak {
            return kLineBreakText
        } else if isPunctuationCharacter(String(previousText.last ?? " ")) {
            return " " // Add space after punctuation
        } else {
            return getLanguageSpecificJoiner(currentText: currentText, previousText: previousText)
        }
    }

    private func getLanguageSpecificJoiner(currentText: String, previousText: String) -> String {
        switch language {
        case .simplifiedChinese, .traditionalChinese:
            return applyChineseRules(current: currentText, previous: previousText)
        case .english:
            return applyEnglishRules(current: currentText, previous: previousText)
        case .japanese:
            return applyJapaneseRules(current: currentText, previous: previousText)
        default:
            return applyGenericRules(current: currentText, previous: previousText)
        }
    }

    private func applyChineseRules(current: String, previous: String) -> String {
        let prevEndsWithPunctuation = hasEndPunctuationSuffix(previous)
        let currentStartsWithPunctuation =
            !current.isEmpty && isPunctuationCharacter(String(current.first!))

        if prevEndsWithPunctuation || currentStartsWithPunctuation {
            return ""
        }

        return ""
    }

    private func applyEnglishRules(current: String, previous: String) -> String {
        let currentStartsWithPunctuation =
            !current.isEmpty && isPunctuationCharacter(String(current.first!))

        if currentStartsWithPunctuation {
            return ""
        }

        if previous.hasSuffix("."), current.count <= 3,
           current.allSatisfy({ $0.isUppercase || $0 == "." }) {
            return " "
        }

        return " "
    }

    private func applyJapaneseRules(current: String, previous: String) -> String {
        let currentStartsWithPunctuation =
            !current.isEmpty && isPunctuationCharacter(String(current.first!))

        if hasEndPunctuationSuffix(previous) || currentStartsWithPunctuation {
            return ""
        }

        return ""
    }

    private func applyGenericRules(current: String, previous: String) -> String {
        let currentStartsWithPunctuation =
            !current.isEmpty && isPunctuationCharacter(String(current.first!))

        if currentStartsWithPunctuation {
            return ""
        }

        return " "
    }
}

// MARK: - Helper Methods Extension

extension AppleOCRTextMerger {
    private func isBigSpacing(
        current: VNRecognizedTextObservation, previous: VNRecognizedTextObservation
    )
        -> Bool {
        let currentBoundingBox = current.boundingBox
        let previousBoundingBox = previous.boundingBox
        let lineHeight = currentBoundingBox.size.height

        let deltaY = previousBoundingBox.origin.y - (currentBoundingBox.origin.y + lineHeight)
        let lineHeightRatio = deltaY / lineHeight
        let averageLineHeightRatio = deltaY / averageLineHeight

        // Check various spacing conditions
        if lineHeightRatio > 1.0 || averageLineHeightRatio > 1.0 {
            return true
        }

        if lineHeightRatio > 0.6 {
            let prevText = previous.text
            if !isLongTextObservation(previous) || hasEndPunctuationSuffix(prevText)
                || previous === maxLongLineTextObservation {
                return true
            }
        }

        // English specific rules
        let currentText = current.text
        if isEnglishLanguage(), isFirstLetterUppercase(currentText) {
            if lineHeightRatio > 0.85 {
                return true
            } else {
                let prevText = previous.text
                if lineHeightRatio > 0.6, hasEndPunctuationSuffix(prevText) {
                    return true
                }
            }
        }

        return false
    }

    private func hasTextIndentation(_ observation: VNRecognizedTextObservation) -> Bool {
        guard let minXObservation = minXLineTextObservation else { return false }

        let observationX = observation.boundingBox.origin.x
        let minXValue = minXObservation.boundingBox.origin.x

        // Simple threshold-based indentation detection
        let threshold: CGFloat = 0.02
        return abs(observationX - minXValue) > threshold
    }

    private func isEqualCharacterLength(
        current: VNRecognizedTextObservation, previous: VNRecognizedTextObservation
    )
        -> Bool {
        let currentText = current.text
        let previousText = previous.text

        let isEqualLength = currentText.count == previousText.count
        let bothHaveEndPunctuation =
            hasEndPunctuationSuffix(currentText) && hasEndPunctuationSuffix(previousText)

        // Additional geometric equality checks
        let currentWidth = current.boundingBox.width
        let previousWidth = previous.boundingBox.width
        let isEqualWidth = abs(currentWidth - previousWidth) < 0.05

        return isEqualLength && bothHaveEndPunctuation && isEqualWidth
    }

    private func isChinesePoetryPattern(current: String, previous: String) -> Bool {
        if isChineseLanguage(), charCountPerLine < CGFloat(kShortPoetryCharacterCountOfLine) {
            let currentShort = current.count < kShortPoetryCharacterCountOfLine
            let previousShort = previous.count < kShortPoetryCharacterCountOfLine
            return currentShort && previousShort
        }
        return false
    }

    private func isEnglishLowercaseStart(_ text: String) -> Bool {
        guard let firstChar = text.first else { return false }
        return isEnglishLanguage() && firstChar.isLowercase && firstChar.isLetter
    }

    private func checkEqualFontSize(
        current: VNRecognizedTextObservation, previous: VNRecognizedTextObservation
    )
        -> Bool {
        let currentFontSize = fontSizeOfTextObservation(current)
        let prevFontSize = fontSizeOfTextObservation(previous)

        let differenceFontSize = abs(currentFontSize - prevFontSize)
        // Note: English uppercase-lowercase font size is not precise, so threshold should a bit large.
        var differenceFontThreshold: CGFloat = 5
        // Chinese fonts seem to be more precise.
        if languageManager.isChineseLanguage(language) {
            differenceFontThreshold = 3
        }

        let isEqualFontSize = differenceFontSize <= differenceFontThreshold
        if !isEqualFontSize {
            print(
                "Not equal font size: difference = \(differenceFontSize) (\(prevFontSize), \(currentFontSize))"
            )
        }

        return isEqualFontSize
    }

    private func isFirstLetterUppercase(_ text: String) -> Bool {
        guard let firstChar = text.first else { return false }
        return firstChar.isUppercase && firstChar.isLetter
    }

    private func isEnglishLanguage() -> Bool {
        languageManager.isEnglishLanguage(language)
    }

    private func isChineseLanguage() -> Bool {
        languageManager.isChineseLanguage(language)
    }

    private func isPunctuationCharacter(_ char: String) -> Bool {
        guard char.count == 1, let scalar = char.unicodeScalars.first else { return false }
        return CharacterSet.punctuationCharacters.contains(scalar)
    }

    // MARK: - Public Methods

    /// Main method to get joined string between two text observations
    /// This directly corresponds to joinedStringOfTextObservation in Objective-C
    func joinedStringOfTextObservation(
        current: VNRecognizedTextObservation,
        previous: VNRecognizedTextObservation
    )
        -> String {
        var joinedString = ""
        var needLineBreak = false
        var isNewParagraph = false

        let prevBoundingBox = previous.boundingBox
        let prevLineLength = prevBoundingBox.size.width
        let prevText = previous.text
        let prevLastChar = String(prevText.suffix(1))
        // Note: sometimes OCR is incorrect, so [.] may be recognized as [,]
        let isPrevEndPunctuationChar = hasEndPunctuationSuffix(prevText)

        let text = current.text
        let isEndPunctuationChar = hasEndPunctuationSuffix(text)

        let isBigLineSpacing = isBigSpacingLineOfTextObservation(
            current: current,
            previous: previous,
            greaterThanLineHeightRatio: 1.0
        )

        let hasPrevIndentation = hasIndentationOfTextObservation(previous)
        let hasIndentation = hasIndentationOfTextObservation(current)

        let isPrevLongText = isLongTextObservation(previous, isStrict: false)

        let isEqualChineseText = isEqualChineseTextObservation(current: current, previous: previous)

        let isPrevList = isListTypeFirstWord(prevText)
        let isList = isListTypeFirstWord(text)

        let textFontSize = fontSizeOfTextObservation(current)
        let prevTextFontSize = fontSizeOfTextObservation(previous)

        let differenceFontSize = abs(textFontSize - prevTextFontSize)
        // Note: English uppercase-lowercase font size is not precise, so threshold should a bit large.
        var differenceFontThreshold: CGFloat = 5
        // Chinese fonts seem to be more precise.
        if languageManager.isChineseLanguage(language) {
            differenceFontThreshold = 3
        }

        let isEqualFontSize = differenceFontSize <= differenceFontThreshold
        if !isEqualFontSize {
            print(
                "Not equal font size: difference = \(differenceFontSize) (\(prevTextFontSize), \(textFontSize))"
            )
        }

        /**
         Note: firstChar cannot be non-alphabet, such as '['

         the latter notifies the NFc upon the occurrence of the event
         [2].
         */
        let isFirstLetterUpperCase = text.first?.isUppercase == true && text.first?.isLetter == true

        // TODO: Maybe we need to refactor it, each indented paragraph is treated separately, instead of treating them together with the longest text line.

        if hasIndentation {
            let isEqualX = isEqualXOfTextObservation(current: current, previous: previous)

            let lineX = current.boundingBox.minX
            let prevLineX = previous.boundingBox.minX
            let dx = lineX - prevLineX

            if hasPrevIndentation {
                if isBigLineSpacing, !isPrevLongText, !isPrevList, !isList {
                    isNewParagraph = true
                }

                /**
                 Bitcoin: A Peer-to-Peer Electronic Cash System

                 Satoshi Nakamoto
                 satoshin@gmx.com
                 www.bitcoin.org

                 Abstract. A purely peer-to-peer version of electronic cash would allow online
                 payments to be sent directly from one party to another without going through a
                 */
                let isPrevLessHalfShortLine = isShortLineLength(
                    prevLineLength,
                    maxLineLength: maxLineLength,
                    lessRateOfMaxLength: 0.5
                )
                let isPrevShortLine = isShortLineLength(
                    prevLineLength,
                    maxLineLength: maxLineLength,
                    lessRateOfMaxLength: 0.85
                )

                let lineMaxX = current.boundingBox.maxX
                let prevLineMaxX = previous.boundingBox.maxX
                let isEqualLineMaxX = isRatioGreaterThan(
                    0.95, value1: lineMaxX, value2: prevLineMaxX
                )

                let isEqualInnerTwoLine = isEqualX && isEqualLineMaxX

                if isEqualInnerTwoLine {
                    if isPrevLessHalfShortLine {
                        needLineBreak = true
                    } else {
                        if isEqualChineseText {
                            needLineBreak = true
                        } else {
                            needLineBreak = false
                        }
                    }
                } else {
                    if isPrevLongText {
                        if isPrevEndPunctuationChar {
                            needLineBreak = true
                        } else {
                            /**
                             V. SECURITY CHALLENGES AND OPPORTUNITIES
                             In the following, we discuss existing security challenges
                             and shed light on possible security opportunities and research
                             */
                            if !isEqualX, dx < 0 {
                                isNewParagraph = true
                            } else {
                                needLineBreak = false
                            }
                        }
                    } else {
                        if isPrevEndPunctuationChar {
                            if !isEqualX, !isList {
                                isNewParagraph = true
                            } else {
                                needLineBreak = true
                            }
                        } else {
                            if isPrevShortLine {
                                needLineBreak = true
                            } else {
                                needLineBreak = false
                            }
                        }
                    }
                }
            } else {
                // Sometimes hasIndentation is a mistake, when prev line is long.
                /**
                 当您发现严重的崩溃问题后，通常推荐发布一个新的版本来修复该问题。这样做有以下几
                 个原因：

                 1. 保持版本控制：通过发布一个新版本，您可以清晰地记录修复了哪些问题。这对于用
                 户和开发团队来说都是透明和易于管理的。
                 2. 便于用户更新：通过发布新版本，您可以通知用户更新应用程序以修复问题。这样，
                 用户可以轻松地通过应用商店或更新机制获取到修复后的版本。

                 The problem with this solution is that the fate of  the  entire  money  system depends  on  the
                 company running the mint, with every transaction having to go through them, just like a bank.
                 We need a way for the payee to know that the previous owners  did  not  sign   any   earlier
                 transactions.
                 */

                if isPrevLongText {
                    if isPrevEndPunctuationChar || !isEqualFontSize {
                        isNewParagraph = true
                    } else {
                        if !isEqualX, dx > 0 {
                            needLineBreak = false
                        } else {
                            needLineBreak = true
                        }
                    }
                } else {
                    isNewParagraph = true
                }
            }
        } else {
            if hasPrevIndentation {
                needLineBreak = true
            }

            if isBigLineSpacing {
                if isPrevLongText {
                    if isPoetry {
                        needLineBreak = true
                    } else {
                        // 翻页, Page turn scenes without line feeds.
                        let isTurnedPage =
                            languageManager.isEnglishLanguage(language)
                                && isLowercaseFirstChar(text) && !isPrevEndPunctuationChar
                        if isTurnedPage {
                            isNewParagraph = false
                            needLineBreak = false
                        }
                    }
                } else {
                    if isPrevEndPunctuationChar || hasPrevIndentation {
                        isNewParagraph = true
                    } else {
                        needLineBreak = true
                    }
                }
            } else {
                if isPrevLongText {
                    if hasPrevIndentation {
                        needLineBreak = false
                    }

                    /**
                     人绕湘皋月坠时。斜横花树小，浸愁漪。一春幽事有谁知。东风冷、香远茜裙归。
                     鸥去昔游非。遥怜花可可，梦依依。九疑云杳断魂啼。相思血，都沁绿筠枝。
                     */
                    if isPrevEndPunctuationChar, isEndPunctuationChar {
                        needLineBreak = true
                    }
                } else {
                    needLineBreak = true
                    if hasPrevIndentation, !isPrevEndPunctuationChar {
                        isNewParagraph = true
                    }
                }

                if isPoetry {
                    needLineBreak = true
                }
            }
        }

        if !isEqualFontSize || isBigLineSpacing {
            if !isPrevLongText
                || (languageManager.isEnglishLanguage(language) && isFirstLetterUpperCase) {
                isNewParagraph = true
            }
        }

        if isBigLineSpacing && isFirstLetterUpperCase {
            isNewParagraph = true
        }

        /**
         https://so.gushiwen.cn/shiwenv_f83627ef2908.aspx

         绣袈裟衣缘
         长屋〔唐代〕

         山川异域，风月同天。
         寄诸佛子，共结来缘。
         */
        let isShortChinesePoetry = isShortChinesePoetryText(text)
        let isPrevShortChinesePoetry = isShortChinesePoetryText(prevText)

        /**
         Chinese poetry needs line break

         《鹧鸪天 · 正月十一日观灯》

         巷陌风光纵赏时，笼纱未出马先嘶。白头居士无呵殿，只有乘肩小女随。
         花满市，月侵衣，少年情事老来悲。沙河塘上春寒浅，看了游人缓缓归。

         —— 宋 · 姜夔
         */

        let isChinesePoetryLine =
            isEqualChineseText || (isShortChinesePoetry && isPrevShortChinesePoetry)
        let shouldWrap = isChinesePoetryLine

        if shouldWrap {
            needLineBreak = true
            if isBigLineSpacing {
                isNewParagraph = true
            }
        }

        if isPrevList {
            if isList {
                needLineBreak = true
                isNewParagraph = isBigLineSpacing
            } else {
                // Means list ends, next is new paragraph.
                if isBigLineSpacing {
                    isNewParagraph = true
                }
            }
        }

        if isNewParagraph {
            joinedString = kParagraphBreakText
        } else if needLineBreak {
            joinedString = kLineBreakText
        } else if isPunctuationChar(prevLastChar) {
            // if last char is a punctuation mark, then append a space, since ocr will remove white space.
            joinedString = " "
        } else {
            // Like Chinese text, don't need space between words if it is not a punctuation mark.
            if languageManager.isLanguageWordsNeedSpace(language) {
                joinedString = " "
            }
        }

        return joinedString
    }

    // MARK: - Private Helper Methods

    private func hasEndPunctuationSuffix(_ text: String) -> Bool {
        let endPunctuationMarks = CharacterSet(charactersIn: "。！？.,!?;:")
        guard let lastChar = text.last else { return false }
        return String(lastChar).unicodeScalars.allSatisfy { endPunctuationMarks.contains($0) }
    }

    private func isBigSpacingLineOfTextObservation(
        current: VNRecognizedTextObservation,
        previous: VNRecognizedTextObservation,
        greaterThanLineHeightRatio: CGFloat
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

        // Since line spacing sometimes is too small and imprecise, we do not use it.
        if lineHeightRatio > 1.0 || averageLineHeightRatio > greaterThanLineHeightRatio {
            return true
        }

        if lineHeightRatio > 0.6,
           !isLongTextObservation(previous, isStrict: true)
           || hasEndPunctuationSuffix(prevText) || previous === maxLongLineTextObservation {
            return true
        }

        let isFirstLetterUpperCase = text.first?.isUppercase == true && text.first?.isLetter == true

        // For English text
        if languageManager.isEnglishLanguage(language), isFirstLetterUpperCase {
            if lineHeightRatio > 0.85 {
                return true
            } else {
                if lineHeightRatio > 0.6, hasEndPunctuationSuffix(prevText) {
                    return true
                }
            }
        }

        return false
    }

    private func hasIndentationOfTextObservation(_ observation: VNRecognizedTextObservation) -> Bool {
        guard let minXObservation = minXLineTextObservation else { return false }
        let isEqualX = isEqualXOfTextObservation(current: observation, previous: minXObservation)
        return !isEqualX
    }

    private func isLongTextObservation(
        _ observation: VNRecognizedTextObservation, isStrict: Bool = false
    )
        -> Bool {
        let threshold = longTextAlphabetCountThreshold(observation, isStrict: isStrict)
        return isLongTextObservation(observation, threshold: threshold)
    }

    private func isLongTextObservation(
        _ observation: VNRecognizedTextObservation, threshold: CGFloat
    )
        -> Bool {
        let remainingAlphabetCount = remainingAlphabetCountOfTextObservation(observation)
        let isLongText = remainingAlphabetCount < threshold
        if !isLongText {
            print(
                "Not long text, remaining alphabet Count: \(remainingAlphabetCount) (threshold: \(threshold))"
            )
        }
        return isLongText
    }

    private func remainingAlphabetCountOfTextObservation(_ observation: VNRecognizedTextObservation)
        -> CGFloat {
        guard let maxObservation = maxLongLineTextObservation else { return 0 }

        let scaleFactor = NSScreen.main?.backingScaleFactor ?? 1.0
        let dx = maxObservation.boundingBox.maxX - observation.boundingBox.maxX
        let maxLength = ocrImage.size.width * maxLineLength / scaleFactor
        let difference = maxLength * dx

        let singleAlphabetWidth = singleAlphabetWidthOfTextObservation(observation)
        return difference / singleAlphabetWidth
    }

    private func longTextAlphabetCountThreshold(
        _ observation: VNRecognizedTextObservation, isStrict: Bool
    )
        -> CGFloat {
        let isEnglishTypeLanguage = languageManager.isLanguageWordsNeedSpace(language)

        // For long text, there are up to 15 letters or 2 Chinese characters on the far right.
        // "implementation ," : @"你好"
        var alphabetCount: CGFloat = isEnglishTypeLanguage ? 15 : 1.5

        let text = observation.text
        let isEndPunctuationChar = hasEndPunctuationSuffix(text)

        if !isStrict, languageManager.isChineseLanguage(language) {
            if !isEndPunctuationChar {
                alphabetCount += 3.5
            }
        }

        return alphabetCount
    }

    private func singleAlphabetWidthOfTextObservation(_ observation: VNRecognizedTextObservation)
        -> CGFloat {
        let scaleFactor = NSScreen.main?.backingScaleFactor ?? 1.0
        let textWidth = observation.boundingBox.size.width * ocrImage.size.width / scaleFactor
        return textWidth / CGFloat(observation.text.count)
    }

    private func isEqualChineseTextObservation(
        current: VNRecognizedTextObservation, previous: VNRecognizedTextObservation
    )
        -> Bool {
        let isEqualLength = isEqualCharacterLengthTextObservation(
            current: current, previous: previous
        )
        return isEqualLength && languageManager.isChineseLanguage(language)
    }

    private func isEqualCharacterLengthTextObservation(
        current: VNRecognizedTextObservation, previous: VNRecognizedTextObservation
    )
        -> Bool {
        let isEqual = isEqualTextObservation(current: current, previous: previous)

        let currentText = current.text
        let previousText = previous.text
        let isEqualLength = currentText.count == previousText.count
        let isEqualEndSuffix =
            hasEndPunctuationSuffix(currentText) && hasEndPunctuationSuffix(previousText)

        return isEqual && isEqualLength && isEqualEndSuffix
    }

    private func isEqualTextObservation(
        current: VNRecognizedTextObservation, previous: VNRecognizedTextObservation
    )
        -> Bool {
        let isEqualX = isEqualXOfTextObservation(current: current, previous: previous)

        let lineMaxX = current.boundingBox.maxX
        let prevLineMaxX = previous.boundingBox.maxX

        let ratio: CGFloat = 0.95
        let isEqualLineMaxX = isRatioGreaterThan(ratio, value1: lineMaxX, value2: prevLineMaxX)

        return isEqualX && isEqualLineMaxX
    }

    private func isEqualXOfTextObservation(
        current: VNRecognizedTextObservation, previous: VNRecognizedTextObservation
    )
        -> Bool {
        // Simplified implementation based on threshold calculation
        let alphabetCount: CGFloat = 2
        let threshold = getThresholdWithAlphabetCount(alphabetCount, textObservation: current) * 0.9

        let lineX = current.boundingBox.origin.x
        let prevLineX = previous.boundingBox.origin.x
        let dx = lineX - prevLineX

        let scaleFactor = NSScreen.main?.backingScaleFactor ?? 1.0
        let maxLength = ocrImage.size.width * maxLineLength / scaleFactor
        let difference = maxLength * dx

        if (difference > 0 && difference < threshold) || abs(difference) < (threshold / 2) {
            return true
        }

        print(
            "Not equalX text: \(current.text)(difference: \(difference), threshold: \(threshold))"
        )
        return false
    }

    private func getThresholdWithAlphabetCount(
        _ alphabetCount: CGFloat, textObservation: VNRecognizedTextObservation
    )
        -> CGFloat {
        let singleAlphabetWidth = singleAlphabetWidthOfTextObservation(textObservation)
        return alphabetCount * singleAlphabetWidth
    }

    private func isListTypeFirstWord(_ text: String) -> Bool {
        let listPatterns = [
            "1.", "2.", "3.", "4.", "5.", "6.", "7.", "8.", "9.", "•", "-", "*", "a.", "b.", "c.",
        ]
        let trimmedText = text.trimmingCharacters(in: .whitespaces)

        for pattern in listPatterns where trimmedText.hasPrefix(pattern) {
            return true
        }

        return false
    }

    private func fontSizeOfTextObservation(_ observation: VNRecognizedTextObservation) -> CGFloat {
        let scaleFactor = NSScreen.main?.backingScaleFactor ?? 1.0
        let textWidth = observation.boundingBox.size.width * ocrImage.size.width / scaleFactor
        return fontSizeOfText(observation.text, width: textWidth)
    }

    private func fontSizeOfText(_ text: String, width textWidth: CGFloat) -> CGFloat {
        let systemFontSize = NSFont.systemFontSize
        let font = NSFont.boldSystemFont(ofSize: systemFontSize)

        let width = text.size(withAttributes: [.font: font]).width

        // systemFontSize / width = x / textWidth
        // x = textWidth * (systemFontSize / width)
        let fontSize = textWidth * (systemFontSize / width)

        return fontSize
    }

    private func isShortLineLength(
        _ lineLength: CGFloat, maxLineLength: CGFloat, lessRateOfMaxLength: CGFloat
    )
        -> Bool {
        lineLength < maxLineLength * lessRateOfMaxLength
    }

    private func isRatioGreaterThan(_ ratio: CGFloat, value1: CGFloat, value2: CGFloat) -> Bool {
        let minValue = min(value1, value2)
        let maxValue = max(value1, value2)
        return (minValue / maxValue) > ratio
    }

    private func isLowercaseFirstChar(_ text: String) -> Bool {
        guard let firstChar = text.first else { return false }
        return firstChar.isLowercase && firstChar.isLetter
    }

    private func isShortChinesePoetryText(_ text: String) -> Bool {
        languageManager.isChineseLanguage(language)
            && charCountPerLine < CGFloat(kShortPoetryCharacterCountOfLine)
            && text.count < kShortPoetryCharacterCountOfLine
    }

    private func isPunctuationChar(_ char: String) -> Bool {
        guard char.count == 1, let scalar = char.unicodeScalars.first else { return false }
        return CharacterSet.punctuationCharacters.contains(scalar)
    }
}
