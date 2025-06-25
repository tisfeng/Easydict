//
//  AppleOCRTextMerger.swift
//  Easydict
//
//  Created by tisfeng on 2025/6/22.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation
import Vision

// MARK: - VNRecognizedTextObservation Extension

extension VNRecognizedTextObservation {
    /// A computed property to get the top candidate string, returns empty string if not available.
    var text: String {
        topCandidates(1).first?.string ?? ""
    }

    /// Custom description providing text content and bounding box information
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
    /// Get a nicely formatted string representation of text observations with indexes
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

    /// Extract just the recognized text strings from observations
    var recognizedTexts: [String] {
        map { $0.text }
    }
}

// MARK: - Supporting Types

/// Encapsulates text analysis properties for break type determination
private struct TextAnalysisContext {
    let isPrevEndPunctuation: Bool
    let isPrevLongText: Bool
    let hasIndentation: Bool
    let hasPrevIndentation: Bool
    let isBigLineSpacing: Bool
}

/// Contains text content for analysis operations
private struct TextContent {
    let currentText: String
    let previousText: String
}

// MARK: - AppleOCRTextMerger

/// Handles intelligent text merging logic for OCR results
/// This class directly corresponds to the joinedStringOfTextObservation method in EZAppleService.m
class AppleOCRTextMerger {
    // MARK: Lifecycle

    /// Initialize text merger with OCR context and analysis parameters
    /// - Parameters:
    ///   - language: The detected or specified language for text processing
    ///   - isPoetry: Whether the text is identified as poetry format
    ///   - minLineHeight: Minimum line height found in the text
    ///   - averageLineHeight: Average line height for spacing calculations
    ///   - maxLongLineTextObservation: Reference observation with maximum line length
    ///   - minXLineTextObservation: Reference observation with minimum X coordinate
    ///   - maxCharacterCountLineTextObservation: Reference observation with maximum character count
    ///   - maxLineLength: Maximum line length for comparison
    ///   - charCountPerLine: Average character count per line
    ///   - ocrImage: Source image for coordinate calculations
    ///   - languageManager: Language utility manager
    init(
        language: Language,
        isPoetry: Bool,
        minLineHeight: Double,
        averageLineHeight: Double,
        maxLongLineTextObservation: VNRecognizedTextObservation?,
        minXLineTextObservation: VNRecognizedTextObservation?,
        maxCharacterCountLineTextObservation: VNRecognizedTextObservation?,
        maxLineLength: Double,
        charCountPerLine: Double,
        ocrImage: NSImage,
        languageManager: EZLanguageManager
    ) {
        self.language = language
        self.isPoetry = isPoetry
        self.minLineHeight = minLineHeight
        self.averageLineHeight = averageLineHeight
        self.maxLongLineTextObservation = maxLongLineTextObservation
        self.minXLineTextObservation = minXLineTextObservation
        self.maxCharacterCountLineTextObservation = maxCharacterCountLineTextObservation
        self.maxLineLength = maxLineLength
        self.charCountPerLine = charCountPerLine
        self.ocrImage = ocrImage
        self.languageManager = languageManager
    }

    // MARK: Private

    private let language: Language
    private let isPoetry: Bool
    private let minLineHeight: Double
    private let averageLineHeight: Double
    private let maxLongLineTextObservation: VNRecognizedTextObservation?
    private let minXLineTextObservation: VNRecognizedTextObservation?
    private let maxCharacterCountLineTextObservation: VNRecognizedTextObservation?
    private let maxLineLength: Double
    private let charCountPerLine: Double
    private let ocrImage: NSImage
    private let languageManager: EZLanguageManager

    // MARK: - Private Methods

    /// Analyze spatial relationship between current and previous text observations
    /// - Parameters:
    ///   - current: Current text observation
    ///   - previous: Previous text observation
    /// - Returns: Tuple containing line relationship analysis (isNewLine, deltaY, deltaX)
    private func analyzeLineRelationship(
        current: VNRecognizedTextObservation,
        previous: VNRecognizedTextObservation
    )
        -> (isNewLine: Bool, deltaY: Double, deltaX: Double) {
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

    /// Handle text merging logic for indented text blocks
    /// - Parameters:
    ///   - current: Current text observation
    ///   - previous: Previous text observation
    ///   - context: Text analysis context
    ///   - isEqualChineseText: Whether texts are equal-length Chinese
    ///   - isPrevList: Whether previous text is a list item
    ///   - isList: Whether current text is a list item
    /// - Returns: Tuple indicating line break and paragraph decisions
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

    /// Handle text merging logic for non-indented text blocks
    /// - Parameters:
    ///   - observations: Tuple containing current and previous observations
    ///   - textContent: Text content structure
    ///   - context: Text analysis context
    /// - Returns: Tuple with break decisions and optional special join string
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
                        isEnglishLanguage() && textContent.currentText.isLowercaseFirstChar()
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
                if context.isPrevEndPunctuation, textContent.currentText.hasEndPunctuationSuffix {
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
}

// MARK: - Helper Methods Extension

extension AppleOCRTextMerger {
    /// Check if text observation has indentation relative to base line
    /// - Parameter observation: Text observation to check
    /// - Returns: True if text appears to be indented
    private func hasTextIndentation(_ observation: VNRecognizedTextObservation) -> Bool {
        guard let minXObservation = minXLineTextObservation else { return false }

        let observationX = observation.boundingBox.origin.x
        let minXValue = minXObservation.boundingBox.origin.x

        // Simple threshold-based indentation detection
        let threshold = 0.02
        return abs(observationX - minXValue) > threshold
    }

    /// Check if two observations have equal character length and punctuation patterns
    /// - Parameters:
    ///   - current: Current text observation
    ///   - previous: Previous text observation
    /// - Returns: True if character patterns match
    private func isEqualCharacterLength(
        current: VNRecognizedTextObservation,
        previous: VNRecognizedTextObservation
    )
        -> Bool {
        let currentText = current.text
        let previousText = previous.text
        let isCurrentEndPunctuationChar = currentText.hasEndPunctuationSuffix
        let isPreviousEndPunctuationChar = previousText.hasEndPunctuationSuffix

        let isEqualLength = currentText.count == previousText.count
        let bothHaveEndPunctuation = isCurrentEndPunctuationChar && isPreviousEndPunctuationChar

        // Additional geometric equality checks
        let currentWidth = current.boundingBox.width
        let previousWidth = previous.boundingBox.width
        let isEqualWidth = abs(currentWidth - previousWidth) < 0.05

        return isEqualLength && bothHaveEndPunctuation && isEqualWidth
    }

    /// Detect Chinese poetry pattern based on text characteristics
    /// - Parameters:
    ///   - current: Current line text
    ///   - previous: Previous line text
    /// - Returns: True if texts match Chinese poetry patterns
    private func isChinesePoetryPattern(current: String, previous: String) -> Bool {
        if isChineseLanguage(),
           charCountPerLine < Double(AppleOCRConstants.shortPoetryCharacterCountOfLine) {
            let currentShort = current.count < AppleOCRConstants.shortPoetryCharacterCountOfLine
            let previousShort = previous.count < AppleOCRConstants.shortPoetryCharacterCountOfLine
            return currentShort && previousShort
        }
        return false
    }

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

        let differenceFontSize = abs(currentFontSize - prevFontSize)
        // Note: English uppercase-lowercase font size is not precise, so threshold should a bit large.
        var differenceFontThreshold: Double = 5
        // Chinese fonts seem to be more precise.
        if languageManager.isChineseLanguage(language) {
            differenceFontThreshold = 3
        }

        let isEqualFontSize = differenceFontSize <= differenceFontThreshold
        if !isEqualFontSize {
            print(
                "Not equal font size: diff = \(differenceFontSize) (\(prevFontSize), \(currentFontSize))"
            )
        }

        return isEqualFontSize
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
        var joinedString = ""
        var needLineBreak = false
        var isNewParagraph = false

        let prevBoundingBox = previous.boundingBox
        let prevLineLength = prevBoundingBox.size.width
        let prevText = previous.text
        let prevLastChar = String(prevText.suffix(1))
        // Note: sometimes OCR is incorrect, so [.] may be recognized as [,]
        let isPrevEndPunctuationChar = prevText.hasEndPunctuationSuffix

        let text = current.text
        let isEndPunctuationChar = text.hasEndPunctuationSuffix

        let isBigLineSpacing = isBigSpacingLineOfTextObservation(
            current: current,
            previous: previous,
            greaterThanLineHeightRatio: 1.0
        )

        let hasPrevIndentation = hasIndentationOfTextObservation(previous)
        let hasIndentation = hasIndentationOfTextObservation(current)

        let isPrevLongText = isLongTextObservation(previous, isStrict: false)
        let isLongText = isLongTextObservation(current, isStrict: false)

        let isEqualChineseText = isEqualChineseTextObservation(current: current, previous: previous)

        let isPrevList = prevText.isListTypeFirstWord
        let isList = text.isListTypeFirstWord

        /**
         Note: firstChar cannot be non-alphabet, such as '['

         the latter notifies the NFc upon the occurrence of the event
         [2].
         */
        let isFirstLetterUpperCase = text.isFirstLetterUpperCase
        let isPrevFirstLetterUpperCase = prevText.isFirstLetterUpperCase

        let textFontSize = fontSizeOfTextObservation(current)
        let prevTextFontSize = fontSizeOfTextObservation(previous)

        let differenceFontSize = abs(textFontSize - prevTextFontSize)
        // Note: English uppercase-lowercase font size is not precise, so threshold should a bit large.
        var differenceFontThreshold: Double = 5
        // Chinese fonts seem to be more precise.
        if languageManager.isChineseLanguage(language) {
            differenceFontThreshold = 3
        }

        let isEqualFontSize = differenceFontSize <= differenceFontThreshold
        if !isEqualFontSize {
            print(
                "Not equal font size: diff = \(differenceFontSize) (\(prevTextFontSize), \(textFontSize))"
            )
        }

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
                            if isBigLineSpacing {
                                isNewParagraph = true
                            }
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

                            // If previous line first letter is NOT uppercase, but current line first letter is uppercase, then it is a new paragraph.
                            if isFirstLetterUpperCase, !isPrevFirstLetterUpperCase {
                                isNewParagraph = true
                            }

                            // If current line is a long text, then it is a new paragraph.
                            if isLongText {
                                isNewParagraph = true
                            }
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
                                && text.isLowercaseFirstChar && !isPrevEndPunctuationChar
                        if isTurnedPage {
                            isNewParagraph = false
                            needLineBreak = false
                        } else {
                            needLineBreak = true
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
            joinedString = AppleOCRConstants.paragraphBreakText
        } else if needLineBreak {
            joinedString = AppleOCRConstants.lineBreakText
        } else if prevLastChar.isPunctuationCharacter {
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

        let singleAlphabetWidth = singleAlphabetWidthOfTextObservation(observation)
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

    /// Calculate single character width for observation
    /// - Parameter textObservation: Text observation to analyze
    /// - Returns: Estimated width per character
    private func singleAlphabetWidthOfTextObservation(
        _ textObservation: VNRecognizedTextObservation
    )
        -> Double {
        let scaleFactor = NSScreen.main?.backingScaleFactor ?? 1.0
        let textWidth = textObservation.boundingBox.size.width * ocrImage.size.width / scaleFactor

        let textObservation = maxCharacterCountLineTextObservation ?? textObservation
        return textWidth / textObservation.text.count.double
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
        let alphabetCount = 1.5
        let threshold = getThresholdWithAlphabetCount(alphabetCount, textObservation: current)

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

    /// Calculate threshold based on alphabet count and observation context
    /// - Parameters:
    ///   - alphabetCount: Number of characters to base calculation on
    ///   - textObservation: Observation for context
    /// - Returns: Calculated threshold value
    private func getThresholdWithAlphabetCount(
        _ alphabetCount: Double,
        textObservation: VNRecognizedTextObservation
    )
        -> Double {
        let singleAlphabetWidth = singleAlphabetWidthOfTextObservation(textObservation)
        return alphabetCount * singleAlphabetWidth
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
}
