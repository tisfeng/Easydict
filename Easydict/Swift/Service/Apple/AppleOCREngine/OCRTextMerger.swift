//
//  OCRTextMerger.swift
//  Easydict
//
//  Created by tisfeng on 2025/6/22.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation
import Vision

// MARK: - OCRTextMerger

/// Handles intelligent text merging logic for OCR results
/// This class directly corresponds to the joinedStringOfTextObservation method in EZAppleService.m
class OCRTextMerger {
    // MARK: Lifecycle

    /// Initialize text merger with OCR metrics
    /// - Parameter metrics: OCR metrics containing all necessary data for text merging
    init(metrics: OCRMetrics) {
        self.metrics = metrics
    }

    // MARK: Internal

    /// Main method to get joined string between two text observations
    /// This directly corresponds to joinedStringOfTextObservation in Objective-C
    /// - Parameter textObservationPair: Pair containing current and previous text observations
    /// - Returns: Appropriate joining string between the two observations
    func joinedString(for textObservationPair: OCRTextObservationPair) -> String {
        // If it's the same line, return a space
        if lineAnalyzer.isSameLine(textObservationPair) {
            return " "
        }

        // For new lines, apply the full merge decision logic
        // Create comprehensive line context
        let lineContext = prepareLineContext(textObservationPair)

        // Determine merge decision
        let mergeDecision = determineMergeDecision(lineContext: lineContext)

        // Generate final joined string
        return generateJoinedString(
            mergeDecision: mergeDecision,
            previousText: textObservationPair.previous.firstText
        )
    }

    // MARK: Private

    private let metrics: OCRMetrics
    private var languageManager = EZLanguageManager.shared()
    private lazy var lineAnalyzer = OCRLineAnalyzer(metrics: metrics)

    /// Check if current language is English
    private func isEnglishLanguage() -> Bool {
        languageManager.isEnglishLanguage(metrics.language)
    }

    /// Prepare comprehensive line context for text merging
    private func prepareLineContext(
        _ textObservationPair: OCRTextObservationPair
    )
        -> OCRLineContext {
        OCRLineContext(pair: textObservationPair, metrics: metrics)
    }

    /// Determine merge decision based on line context
    private func determineMergeDecision(
        lineContext: OCRLineContext
    )
        -> OCRMergeDecision {
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

        // Apply additional merge rules
        let finalResult = applyAdditionalMergeRules(
            lineContext: lineContext,
            needLineBreak: needLineBreak,
            isNewParagraph: isNewParagraph
        )

        return finalResult
    }

    /// Generate the final joined string based on merge decisions
    private func generateJoinedString(
        mergeDecision: OCRMergeDecision,
        previousText: String
    )
        -> String {
        if mergeDecision.isNewParagraph {
            return OCRConstants.paragraphBreakText
        } else if mergeDecision.needLineBreak {
            return OCRConstants.lineBreakText
        } else if previousText.hasPunctuationSuffix {
            // If last char is a punctuation mark, append a space
            return " "
        } else {
            // For languages that need spaces between words
            if languageManager.isLanguageWordsNeedSpace(metrics.language) {
                return " "
            }
            return ""
        }
    }

    /// Apply additional merge rules for special cases
    private func applyAdditionalMergeRules(
        lineContext: OCRLineContext,
        needLineBreak: Bool,
        isNewParagraph: Bool
    )
        -> OCRMergeDecision {
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
        let poetryResult = lineContext.determineChinesePoetryMerge()
        if poetryResult.needLineBreak {
            finalNeedLineBreak = true
            if poetryResult.isNewParagraph {
                finalIsNewParagraph = true
            }
        }

        // List handling
        let listResult = lineContext.determineListMerge()
        if listResult.needLineBreak {
            finalNeedLineBreak = true
        }
        if listResult.isNewParagraph {
            finalIsNewParagraph = true
        }

        return OCRMergeDecision.from(
            needLineBreak: finalNeedLineBreak,
            isNewParagraph: finalIsNewParagraph
        )
    }

    /// Handle text merging logic for indented text blocks
    private func handleIndentedText(lineContext: OCRLineContext) -> OCRMergeDecision {
        var needLineBreak = false
        var isNewParagraph = false

        let isEqualX = isEqualX(lineContext.pair)
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
                maxLineLength: metrics.maxLineLength
            )
            let isPrevShortLine = lineContext.isPrevShortLine(maxLineLength: metrics.maxLineLength)

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

        return OCRMergeDecision.from(
            needLineBreak: needLineBreak,
            isNewParagraph: isNewParagraph
        )
    }

    /// Handle text merging logic for non-indented text blocks
    private func handleNonIndentedText(lineContext: OCRLineContext) -> OCRMergeDecision {
        var needLineBreak = false
        var isNewParagraph = false

        let isFirstLetterUpperCase = lineContext.currentText.isFirstLetterUpperCase

        if lineContext.isBigLineSpacing {
            if lineContext.isPrevLongText {
                if metrics.isPoetry {
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

            if metrics.isPoetry {
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
            let distance = dx / metrics.maxLineLength
            if distance > 0.45 {
                isNewParagraph = true
            }
        }

        return OCRMergeDecision.from(
            needLineBreak: needLineBreak,
            isNewParagraph: isNewParagraph
        )
    }

    // MARK: - Helper Methods

    private func isEqualX(_ textObservationPair: OCRTextObservationPair) -> Bool {
        // Calculate threshold based on average character width and indentation constant
        let threshold = metrics.averageCharacterWidth * OCRConstants.indentationCharacterCount

        let lineX = textObservationPair.current.boundingBox.origin.x
        let prevLineX = textObservationPair.previous.boundingBox.origin.x
        let dx = lineX - prevLineX

        let scaleFactor = NSScreen.main?.backingScaleFactor ?? 1.0
        let maxLength = metrics.ocrImage.size.width * metrics.maxLineLength / scaleFactor
        let difference = maxLength * dx

        // dx > 0, means current line may has indentation.
        if (dx > 0 && difference < threshold) || abs(difference) < (threshold / 2) {
            return true
        }

        print("Not equalX text: \(textObservationPair.current)")
        print("difference: \(difference), threshold: \(threshold)")

        return false
    }

    private func isRatioGreaterThan(_ ratio: Double, value1: Double, value2: Double) -> Bool {
        let minValue = min(value1, value2)
        let maxValue = max(value1, value2)
        return (minValue / maxValue) > ratio
    }
}
