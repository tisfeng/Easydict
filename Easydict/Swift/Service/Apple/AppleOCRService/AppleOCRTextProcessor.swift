//
//  AppleOCRTextProcessor.swift
//  Easydict
//
//  Created by tisfeng on 2025/6/22.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation
import Vision

// MARK: - AppleOCRTextProcessor

/// Handles intelligent OCR text processing and merging
/// Ported from EZAppleService setupOCRResult method
@objc
public class AppleOCRTextProcessor: NSObject {
    // MARK: Public

    // MARK: - Public Methods

    /// Process OCR observations into structured result with intelligent text merging
    /// - Parameters:
    ///   - ocrResult: The OCR result object to populate
    ///   - observations: Array of Vision text observations
    ///   - ocrImage: Source image for OCR processing
    ///   - intelligentJoined: Whether to apply intelligent text joining algorithms
    @objc
    public func setupOCRResult(
        _ ocrResult: EZOCRResult,
        observations: [VNRecognizedTextObservation],
        ocrImage: NSImage,
        intelligentJoined: Bool
    ) {
        self.ocrImage = ocrImage
        language = ocrResult.from

        // Reset statistics
        resetStatistics()

        print("\nTextObservations: \(observations.formattedDescription)")

        let recognizedTexts = observations.compactMap { observation in
            observation.text
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

        // Update single alphabet width
        if let textObservation = maxCharacterCountLineTextObservation {
            singleAlphabetWidth = singleAlphabetWidthOfTextObservation(textObservation)
        }
        // Store final calculated values
        averageLineHeight = totalLineHeight / lineCount.double
        if lineSpacingCount > 0 {
            averageLineSpacing = totalLineSpacing / lineSpacingCount.double
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
        ocrResult.texts = ocrResult.mergedText.components(
            separatedBy: OCRConstants.lineBreakText
        )

        let showMergedText = String(ocrResult.mergedText.prefix(100))
        print(
            "OCR text (\(ocrResult.from)(\(String(format: "%.2f", ocrResult.confidence))): \(showMergedText)"
        )
    }

    // MARK: Private

    private var ocrImage = NSImage()
    private var language: Language = .auto
    private var minLineHeight: Double = .greatestFiniteMagnitude
    private var totalLineHeight: Double = 0
    private var averageLineHeight: Double = 0

    // OCR line spacing may be less than 0
    private var minLineSpacing: Double = .greatestFiniteMagnitude
    private var minPositiveLineSpacing: Double = .greatestFiniteMagnitude
    private var totalLineSpacing: Double = 0
    private var averageLineSpacing: Double = 0

    // Width of a single alphabet character, maxCharacterCountLineText length / text.count
    private var singleAlphabetWidth: Double = 0.0

    private var minX: Double = .greatestFiniteMagnitude
    private var maxLineLength: Double = 0
    private var minLineLength: Double = .greatestFiniteMagnitude

    private var textObservations: [VNRecognizedTextObservation] = []
    private var maxLongLineTextObservation: VNRecognizedTextObservation?
    private var minXLineTextObservation: VNRecognizedTextObservation?
    private var maxCharacterCountLineTextObservation: VNRecognizedTextObservation?

    private var isPoetry: Bool = false
    private var charCountPerLine: Double = 0
    private var totalCharCount: Int = 0
    private var punctuationMarkCount: Int = 0

    private var languageManager = EZLanguageManager.shared()

    /// Create OCR context for text merging operations
    private func createOCRContext() -> OCRContext {
        OCRContext(
            ocrImage: ocrImage,
            language: language,
            isPoetry: isPoetry,
            singleAlphabetWidth: singleAlphabetWidth,
            charCountPerLine: charCountPerLine,
            minLineHeight: minLineHeight,
            averageLineHeight: averageLineHeight,
            maxLineLength: maxLineLength,
            textObservations: textObservations,
            minXLineTextObservation: minXLineTextObservation,
            maxCharacterCountLineTextObservation: maxCharacterCountLineTextObservation,
            maxLongLineTextObservation: maxLongLineTextObservation
        )
    }

    // MARK: - Private Methods

    /// Reset all statistical variables to initial values
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
        maxCharacterCountLineTextObservation = nil

        isPoetry = false
        charCountPerLine = 0
        totalCharCount = 0
        punctuationMarkCount = 0
    }

    /// Calculate line spacing, height, and positioning statistics for a text observation
    /// - Parameters:
    ///   - textObservation: Current text observation to analyze
    ///   - index: Index of current observation in the array
    ///   - observations: Complete array of text observations
    ///   - lineSpacingCount: Inout parameter tracking valid line spacing measurements
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

    /// Calculate and set the overall confidence score for OCR result
    /// - Parameters:
    ///   - ocrResult: OCR result object to update
    ///   - observations: Array of text observations with individual confidence scores
    private func calculateConfidence(
        _ ocrResult: EZOCRResult, observations: [VNRecognizedTextObservation]
    ) {
        if !observations.isEmpty {
            let totalConfidence = observations.compactMap { observation in
                observation.topCandidates(1).first?.confidence
            }.reduce(0, +)
            ocrResult.confidence = CGFloat(totalConfidence / Float(observations.count))

        } else {
            ocrResult.confidence = 0.0
        }
    }

    /// Detect if the text layout represents poetry based on line characteristics
    /// - Parameter observations: Array of text observations to analyze
    /// - Returns: True if text appears to be poetry, false for prose
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
            let text = observation.text

            totalCharCount += text.count
            totalWordCount += text.wordCount

            // Check if line ends with punctuation
            let isEndPunctuationChar = text.hasEndPunctuationSuffix
            if isEndPunctuationChar {
                endWithTerminatorCharLineCount += 1

                // Check for prose patterns
                if i > 0 {
                    let prevObservation = observations[i - 1]
                    let prevText = prevObservation.text
                    if isLongTextObservation(prevObservation), !prevText.hasEndPunctuationSuffix {
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
            punctuationMarkCount += text.countPunctuationMarks()
        }

        let charCountPerLine = totalCharCount.double / lineCount.double
        let wordCountPerLine = totalWordCount.double / lineCount.double
        let numberOfPunctuationMarksPerLine = punctuationMarkCount.double / lineCount.double

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
        let tooManyLongLine = longLineCount.double / lineCount.double > 0.4
        if tooManyLongLine {
            return false
        }

        return true
    }

    /// Sort text observations by vertical position (top to bottom)
    /// - Parameter observations: Unsorted array of text observations
    /// - Returns: Array sorted by Y coordinate for proper reading order
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

    /// Perform intelligent text merging based on spatial relationships and context
    private func performIntelligentTextMerging(_ observations: [VNRecognizedTextObservation])
        -> String {
        let lineCount = observations.count
        var confidence: Float = 0
        let mergedText = NSMutableString()

        for i in 0 ..< lineCount {
            let textObservation = observations[i]
            let recognizedText = textObservation.topCandidates(1).first
            confidence += recognizedText?.confidence ?? 0

            let recognizedString = recognizedText?.string ?? ""

            print("\n\(textObservation)")

            if i > 0 {
                let prevTextObservation = observations[i - 1]

                // Determine if this is a new line
                let isNewLine = isNewLineRelativeToPrevious(
                    current: textObservation,
                    previous: prevTextObservation
                )

                var joinedString: String

                // Check if need to handle last dash of text
                let isNeedHandleLastDashOfText = checkNeedHandleLastDashOfText(
                    current: textObservation,
                    previous: prevTextObservation
                )

                if isNeedHandleLastDashOfText {
                    joinedString = ""

                    // Check if need to remove last dash
                    let isNeedRemoveLastDashOfText = checkNeedRemoveLastDashOfText(
                        current: textObservation,
                        previous: prevTextObservation
                    )
                    if isNeedRemoveLastDashOfText {
                        if mergedText.length > 0 {
                            mergedText.deleteCharacters(
                                in: NSRange(location: mergedText.length - 1, length: 1)
                            )
                        }
                    }
                } else if isNewLine {
                    // Create text merger with OCR context
                    let context = createOCRContext()
                    let textMerger = AppleOCRTextMerger(context: context)

                    joinedString = textMerger.joinedStringOfTextObservation(
                        current: textObservation,
                        previous: prevTextObservation
                    )
                } else {
                    joinedString = " " // if the same line, just join two texts
                }

                // Store joinedString in observation (mimic original behavior)
                setJoinedString(for: textObservation, joinedString: joinedString)

                // 1. append joined string
                mergedText.append(joinedString)
            }

            // 2. append line text
            mergedText.append(recognizedString)
        }

        // Apply final text processing
        return replaceSimilarDotSymbol(in: mergedText as String).trimmingCharacters(
            in: .whitespacesAndNewlines
        )
    }

    /// Replace similar dot symbols with standardized middle dot character
    /// - Parameter string: Input string with various dot symbols
    /// - Returns: String with normalized dot symbols
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

    /// Determine if a text observation represents a long line of text
    /// - Parameter observation: Text observation to evaluate
    /// - Returns: True if observation is considered a long line
    private func isLongTextObservation(_ observation: VNRecognizedTextObservation) -> Bool {
        guard let maxObservation = maxLongLineTextObservation else { return false }

        let observationWidth = observation.boundingBox.width
        let maxWidth = maxObservation.boundingBox.width

        // Consider a line "long" if it's more than 85% of the maximum width
        let isLongByWidth = observationWidth > maxWidth * 0.85

        // Also check by character count for better accuracy
        if let maxCharObservation = maxCharacterCountLineTextObservation {
            let currentCharCount = observation.text.count.double
            let maxCharCount = maxCharObservation.text.count.double

            // Consider a line "long" if it has more than 80% of the maximum character count
            let isLongByCharCount = currentCharCount >= maxCharCount * 0.8

            // Return true if either condition is met
            return isLongByWidth || isLongByCharCount
        }

        return isLongByWidth
    }

    // MARK: - Dash Handling Methods

    /// Check if hyphenated word continuation needs special handling
    /// - Parameters:
    ///   - current: Current text observation
    ///   - previous: Previous text observation
    /// - Returns: True if dash handling is needed
    private func checkNeedHandleLastDashOfText(
        current: VNRecognizedTextObservation,
        previous: VNRecognizedTextObservation
    )
        -> Bool {
        let text = current.text
        let prevText = previous.text

        let maxLineFrameX = previous.boundingBox.maxX
        let isPrevLongLine = isLongLineLength(maxLineFrameX)

        let isPrevLastDashChar = isLastJoinedDashCharacter(in: text, prevText: prevText)
        return isPrevLongLine && isPrevLastDashChar
    }

    /// Check if trailing dash should be removed to join hyphenated words
    /// - Parameters:
    ///   - current: Current text observation
    ///   - previous: Previous text observation
    /// - Returns: True if dash should be removed
    private func checkNeedRemoveLastDashOfText(
        current: VNRecognizedTextObservation,
        previous: VNRecognizedTextObservation
    )
        -> Bool {
        let text = current.text
        let prevText = previous.text

        guard !prevText.isEmpty else { return false }

        let removedPrevDashText = String(prevText.dropLast())
        let lastWord =
            removedPrevDashText.components(separatedBy: .whitespacesAndNewlines).last ?? ""
        let firstWord = text.components(separatedBy: .whitespacesAndNewlines).first ?? ""
        let newWord = lastWord + firstWord

        // Request-Response, Architec-ture
        let isLowercaseWord = firstWord.first?.isLowercase ?? false
        let isSpelledCorrectly = (newWord as NSString).isSpelledCorrectly()

        return isLowercaseWord && isSpelledCorrectly
    }

    /// Check if text contains a dash character used for word continuation
    /// - Parameters:
    ///   - text: Current line text
    ///   - prevText: Previous line text
    /// - Returns: True if dash is used for word joining
    private func isLastJoinedDashCharacter(in text: String, prevText: String) -> Bool {
        guard !prevText.isEmpty, !text.isEmpty else { return false }

        let prevLastChar = String(prevText.suffix(1))
        let dashCharacters = ["-", "–", "—"]

        guard dashCharacters.contains(prevLastChar) else { return false }

        let removedPrevDashText = String(prevText.dropLast())
        let lastWord =
            removedPrevDashText.components(separatedBy: .whitespacesAndNewlines).last ?? ""

        let isFirstCharAlphabet = text.first?.isLetter ?? false

        return !lastWord.isEmpty && isFirstCharAlphabet
    }

    /// Check if line length qualifies as "long" based on maximum line width
    /// - Parameter lineLength: Width of the line to check
    /// - Returns: True if line is considered long
    private func isLongLineLength(_ lineLength: Double) -> Bool {
        lineLength >= maxLineLength * 0.9
    }

    /// Store joined string in text observation using associated objects
    /// - Parameters:
    ///   - observation: Text observation to store data in
    ///   - joinedString: String to associate with observation
    private func setJoinedString(for observation: VNRecognizedTextObservation, joinedString: String) {
        // Store joined string using associated objects (mimicking original behavior)
        objc_setAssociatedObject(
            observation,
            "joinedString",
            joinedString,
            .OBJC_ASSOCIATION_COPY_NONATOMIC
        )
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
        return textWidth / textObservation.text.count.double
    }

    /// Determine if current observation represents a new line relative to previous observation
    /// - Parameters:
    ///   - current: Current text observation
    ///   - previous: Previous text observation
    /// - Returns: True if current observation is on a new line
    private func isNewLineRelativeToPrevious(
        current: VNRecognizedTextObservation,
        previous: VNRecognizedTextObservation
    )
        -> Bool {
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
            // Since OCR may have slight overlaps, consider it a new line if deltaY is small.
            isNewLine = true
        }

        // Check X coordinate gap for line detection
        if deltaX > 0.07 {
            isNewLine = true
        }

        return isNewLine
    }

    /// Determine if line break and paragraph break are needed
    private func determineLineBreakAndParagraph(
        current: VNRecognizedTextObservation,
        previous: VNRecognizedTextObservation
    )
        -> (needLineBreak: Bool, isNewParagraph: Bool) {
        // Create text merger with OCR context
        let context = createOCRContext()
        let textMerger = AppleOCRTextMerger(context: context)

        let joinedString = textMerger.joinedStringOfTextObservation(
            current: current,
            previous: previous
        )

        // Determine the type of break based on joined string
        if joinedString == OCRConstants.paragraphBreakText {
            return (needLineBreak: true, isNewParagraph: true)
        } else if joinedString == OCRConstants.lineBreakText {
            return (needLineBreak: true, isNewParagraph: false)
        } else {
            return (needLineBreak: false, isNewParagraph: false)
        }
    }

    /// Prepare comprehensive formatting data for text analysis
    private func prepareFormattingData(
        current: VNRecognizedTextObservation,
        previous: VNRecognizedTextObservation
    )
        -> OCRLineContext {
        let prevText = previous.text
        let isEqualChineseText = isEqualChineseTextObservation(current: current, previous: previous)

        return OCRLineContext(
            current: current,
            previous: previous,
            isPrevEndPunctuation: prevText.hasEndPunctuationSuffix,
            isPrevLongText: isLongTextObservation(previous),
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

    // MARK: - Helper Methods

    /// Check if current language is English
    private func isEnglishLanguage() -> Bool {
        languageManager.isEnglishLanguage(language)
    }

    /// Check if current language is Chinese
    private func isChineseLanguage() -> Bool {
        languageManager.isChineseLanguage(language)
    }

    /// Check if observation has indentation
    private func hasIndentationOfTextObservation(_ observation: VNRecognizedTextObservation) -> Bool {
        guard let minXObservation = minXLineTextObservation else { return false }
        let isEqualX = isEqualXOfTextObservation(current: observation, previous: minXObservation)
        return !isEqualX
    }

    /// Determine if there is big line spacing between observations
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
           !isLongTextObservation(previous)
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

    /// Check if observations contain equal-length Chinese text
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
    private func isEqualXOfTextObservation(
        current: VNRecognizedTextObservation,
        previous: VNRecognizedTextObservation
    )
        -> Bool {
        // Simplified implementation based on threshold calculation
        let threshold = singleAlphabetWidth * OCRConstants.indentationCharacterCount

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

    /// Check if ratio between two values exceeds threshold
    private func isRatioGreaterThan(_ ratio: Double, value1: Double, value2: Double) -> Bool {
        let minValue = min(value1, value2)
        let maxValue = max(value1, value2)
        return (minValue / maxValue) > ratio
    }
}
