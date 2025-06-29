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

    // MARK: Internal

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
        // Create comprehensive formatting data
        let lineContext = prepareLineContext(current: current, previous: previous)

        // Determine line break and paragraph decisions
        let (needLineBreak, isNewParagraph) = determineLineBreakAndParagraph(
            lineContext: lineContext
        )

        // Generate final joined string
        return generateJoinedString(
            needLineBreak: needLineBreak,
            isNewParagraph: isNewParagraph,
            previousText: previous.text
        )
    }

    // MARK: Private

    private let context: OCRContext
    private var languageManager = EZLanguageManager.shared()

    // Convenience computed properties for easier access
    private var language: Language { context.language }
    private var isPoetry: Bool { context.isPoetry }

    /// Check if current language is English
    private func isEnglishLanguage() -> Bool {
        languageManager.isEnglishLanguage(language)
    }

    /// Prepare comprehensive line context for text merging
    private func prepareLineContext(
        current: VNRecognizedTextObservation,
        previous: VNRecognizedTextObservation
    )
        -> OCRLineContext {
        OCRLineContext(
            current: current,
            previous: previous,
            context: context
        )
    }

    /// Determine if line break and paragraph break are needed
    private func determineLineBreakAndParagraph(
        lineContext: OCRLineContext
    )
        -> (needLineBreak: Bool, isNewParagraph: Bool) {
        var needLineBreak = false
        var isNewParagraph = false

        // Handle indented text
        if lineContext.hasIndentation {
            let result = handleIndentedText(lineContext: lineContext)
            needLineBreak = result.needLineBreak
            isNewParagraph = result.isNewParagraph
        } else {
            // Handle non-indented text
            let result = handleNonIndentedText(lineContext: lineContext)
            needLineBreak = result.needLineBreak
            isNewParagraph = result.isNewParagraph
        }

        // Apply additional formatting rules
        let finalResult = applyAdditionalFormattingRules(
            lineContext: lineContext,
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
            return OCRConstants.paragraphBreakText
        } else if needLineBreak {
            return OCRConstants.lineBreakText
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

    /// Apply additional formatting rules for special cases
    private func applyAdditionalFormattingRules(
        lineContext: OCRLineContext,
        needLineBreak: Bool,
        isNewParagraph: Bool
    )
        -> (needLineBreak: Bool, isNewParagraph: Bool) {
        var finalNeedLineBreak = needLineBreak
        var finalIsNewParagraph = isNewParagraph

        // Font size and spacing checks
        let isEqualFontSize = lineContext.isEqualFontSize
        let isFirstLetterUpperCase = lineContext.currentText.isFirstLetterUpperCase

        if !isEqualFontSize || lineContext.isBigLineSpacing {
            if !lineContext.isPrevLongText || (isEnglishLanguage() && isFirstLetterUpperCase) {
                finalIsNewParagraph = true
            }
        }

        if lineContext.isBigLineSpacing, isFirstLetterUpperCase {
            finalIsNewParagraph = true
        }

        // Chinese poetry handling
        let poetryResult = lineContext.handleChinesePoetry()
        if poetryResult.shouldWrap {
            finalNeedLineBreak = true
            if poetryResult.isNewParagraph {
                finalIsNewParagraph = true
            }
        }

        // List handling
        let listResult = lineContext.handleListFormatting()
        if listResult.needLineBreak {
            finalNeedLineBreak = true
        }
        if listResult.isNewParagraph {
            finalIsNewParagraph = true
        }

        return (finalNeedLineBreak, finalIsNewParagraph)
    }

    /// Handle text merging logic for indented text blocks
    private func handleIndentedText(
        lineContext: OCRLineContext
    )
        -> (needLineBreak: Bool, isNewParagraph: Bool) {
        var needLineBreak = false
        var isNewParagraph = false

        let isEqualX = isEqualXOfTextObservation(
            current: lineContext.current,
            previous: lineContext.previous
        )
        let lineX = lineContext.current.boundingBox.minX
        let prevLineX = lineContext.previous.boundingBox.minX
        let dx = lineX - prevLineX

        if lineContext.hasPrevIndentation {
            if lineContext.isBigLineSpacing,
               !lineContext.isPrevLongText,
               !lineContext.isPrevList,
               !lineContext.isList {
                isNewParagraph = true
            }

            // Check for short line conditions
            let isPrevLessHalfShortLine = lineContext.isPrevLessHalfShortLine(
                maxLineLength: context.maxLineLength
            )
            let isPrevShortLine = lineContext.isPrevShortLine(maxLineLength: context.maxLineLength)

            let lineMaxX = lineContext.current.boundingBox.maxX
            let prevLineMaxX = lineContext.previous.boundingBox.maxX
            let isEqualLineMaxX = isRatioGreaterThan(
                0.95, value1: lineMaxX, value2: prevLineMaxX
            )

            let isEqualInnerTwoLine = isEqualX && isEqualLineMaxX

            if isEqualInnerTwoLine {
                if isPrevLessHalfShortLine {
                    needLineBreak = true
                } else {
                    needLineBreak = lineContext.isEqualChineseText
                }
            } else {
                if lineContext.isPrevLongText {
                    if lineContext.hasPrevIndentation {
                        needLineBreak = true
                    } else {
                        if !isEqualX, dx < 0 {
                            isNewParagraph = true
                        } else {
                            needLineBreak = false
                        }
                    }
                } else {
                    if lineContext.hasPrevEndPunctuation {
                        if !isEqualX, !lineContext.isList {
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
            if lineContext.isPrevLongText {
                let isEqualFontSize = lineContext.isEqualFontSize
                if lineContext.hasPrevEndPunctuation || !isEqualFontSize {
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
        lineContext: OCRLineContext
    )
        -> (needLineBreak: Bool, isNewParagraph: Bool) {
        var needLineBreak = false
        var isNewParagraph = false

        let isFirstLetterUpperCase = lineContext.currentText.isFirstLetterUpperCase

        if lineContext.isBigLineSpacing {
            if lineContext.isPrevLongText {
                if isPoetry {
                    needLineBreak = true
                } else {
                    // Check for page turn scenarios
                    let isTurnedPage =
                        isEnglishLanguage() && lineContext.currentText.isLowercaseFirstChar
                            && !lineContext.hasPrevEndPunctuation
                    if !isTurnedPage {
                        needLineBreak = true
                    }
                }
            } else {
                if lineContext.hasPrevEndPunctuation || lineContext.hasPrevIndentation {
                    isNewParagraph = true
                } else {
                    needLineBreak = true
                }
            }
        } else {
            if lineContext.isPrevLongText {
                if !lineContext.hasPrevIndentation {
                    // Chinese poetry special case
                    if lineContext.hasPrevEndPunctuation,
                       lineContext.currentText.hasEndPunctuationSuffix {
                        needLineBreak = true

                        // If language is English and current line first letter is NOT uppercase, do not need line break
                        if isEnglishLanguage(), !isFirstLetterUpperCase {
                            needLineBreak = false
                        }
                    }
                }
            } else {
                needLineBreak = true
                if lineContext.hasPrevIndentation, !lineContext.hasPrevEndPunctuation {
                    isNewParagraph = true
                }
            }

            if isPoetry {
                needLineBreak = true
            }
        }

        /**
         If text is a letter format, like:
         ```
                                    Wednesday, 4 Octobre 1950
         My dearest Nelson,
         ```
         If `distance` > 0.45, means it may need line break, or treat as new paragraph.
         */
        if lineContext.isPrevLongText, lineContext.hasPrevIndentation {
            let dx = lineContext.previous.boundingBox.minX - lineContext.current.boundingBox.minX
            let distance = dx / context.maxLineLength
            if distance > 0.45 {
                isNewParagraph = true
            }
        }

        return (needLineBreak, isNewParagraph)
    }

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

    private func isRatioGreaterThan(_ ratio: Double, value1: Double, value2: Double) -> Bool {
        let minValue = min(value1, value2)
        let maxValue = max(value1, value2)
        return (minValue / maxValue) > ratio
    }
}
