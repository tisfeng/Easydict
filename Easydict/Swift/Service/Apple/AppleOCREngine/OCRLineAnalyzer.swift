//
//  OCRLineAnalyzer.swift
//  Easydict
//
//  Created by tisfeng on 2025/6/26.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation
import Vision

// MARK: - OCRConfidenceLevel

/// Confidence level for OCR analysis thresholds
///
/// Different confidence levels adjust detection thresholds to provide more or less
/// strict analysis depending on the reliability of the OCR data and specific use cases.
///
/// **Threshold Multipliers:**
/// - `.high`: More strict thresholds (1.5x) - requires stronger evidence for detection
/// - `.medium`: Standard thresholds (1.0x) - balanced detection sensitivity
/// - `.low`: More lenient thresholds (0.7x) - easier detection with lower confidence data
/// - `.custom(Double)`: Custom threshold multiplier for precise control
enum OCRConfidenceLevel {
    case high
    case medium
    case low
    case custom(Double)

    // MARK: Lifecycle

    /// Initialize confidence level from a numeric multiplier value
    ///
    /// Creates a custom confidence level with the exact multiplier value provided.
    /// This allows for precise threshold control beyond the predefined levels.
    ///
    /// **Usage Examples:**
    /// ```swift
    /// let customLow = OCRConfidenceLevel(multiplier: 0.5)      // .custom(0.5)
    /// let customHigh = OCRConfidenceLevel(multiplier: 3.0)     // .custom(3.0)
    /// let standard = OCRConfidenceLevel(multiplier: 1.0)       // .custom(1.0)
    /// ```
    ///
    /// - Parameter multiplier: The exact threshold multiplier value to use
    init(multiplier: Double) {
        self = .custom(multiplier)
    }

    // MARK: Internal

    /// Threshold multiplier for the confidence level
    var thresholdMultiplier: Double {
        switch self {
        case .high: return 1.5
        case .medium: return 1.0
        case .low: return 0.7
        case let .custom(multiplier): return multiplier
        }
    }
}

// MARK: - OCRLineAnalyzer

/// Handles line-level text analysis operations for OCR processing
///
/// This specialized analyzer provides sophisticated methods for analyzing relationships
/// between text lines and making intelligent formatting decisions. It serves as the
/// analytical brain for determining how text observations should be joined together.
///
/// **Core Capabilities:**
/// - **Line Relationship Analysis**: Determines if text observations are on same line or different lines
/// - **Indentation Detection**: Identifies text indentation patterns for proper formatting
/// - **Spacing Analysis**: Calculates appropriate spacing between text elements
/// - **Font Comparison**: Analyzes font size variations for formatting decisions
/// - **Poetry Recognition**: Detects poetic text patterns requiring special handling
/// - **List Processing**: Identifies and handles numbered/bulleted list structures
/// - **Language-aware Processing**: Applies language-specific analysis rules
///
/// **Key Algorithms:**
/// - Spatial relationship analysis using bounding box mathematics
/// - Dynamic threshold calculation based on text metrics
/// - Context-aware decision making for text merging
/// - Confidence-based threshold adjustment for varying detection strictness
///
/// **Confidence Level Support:**
/// Many analysis functions support configurable confidence levels:
/// - `.high`: More strict thresholds (2.0x) - requires stronger evidence
/// - `.medium`: Standard thresholds (1.0x) - balanced detection (default)
/// - `.low`: More lenient thresholds (0.7x) - easier detection
///
/// **Usage Examples:**
/// ```swift
/// let analyzer = OCRLineAnalyzer(metrics: metrics)
///
/// // Standard detection (medium confidence)
/// let isBig = analyzer.isBigLineSpacing(pair: pair)
///
/// // High confidence (strict detection)
/// let isBigStrict = analyzer.isBigLineSpacing(pair: pair, confidenceLevel: .high)
///
/// // Low confidence (lenient detection)
/// let isBigLenient = analyzer.isBigLineSpacing(pair: pair, confidenceLevel: .low)
/// ```
///
/// Used extensively by OCRTextMerger for making intelligent text joining decisions.
class OCRLineAnalyzer {
    // MARK: Lifecycle

    init(metrics: OCRMetrics) {
        self.metrics = metrics
        self.lineMeasurer = OCRLineMeasurer(metrics: metrics)
    }

    // MARK: Internal

    /// Check if text observation has indentation relative to the reference observation
    ///
    /// Analyzes whether a text observation is indented by comparing its X position
    /// against a reference observation (typically the leftmost or previous observation).
    /// Uses precise character-based calculation for accurate indentation detection.
    ///
    /// **Indentation Criteria:**
    /// - Current observation must be positioned to the right of the reference
    /// - Horizontal offset must be less than the indentation character threshold
    /// - Uses character-based measurement for consistent detection across different text sizes
    ///
    /// **Use Cases:**
    /// - Paragraph indentation detection
    /// - List item structure analysis
    /// - Block quote identification
    /// - Code block formatting preservation
    ///
    /// **Confidence Level Impact:**
    /// - `.high`: 2.0x threshold (more strict, requires larger indentation)
    /// - `.medium`: 1.0x threshold (standard detection)
    /// - `.low`: 0.7x threshold (more lenient, detects smaller indentation)
    ///
    /// - Parameters:
    ///   - observation: The text observation to analyze for indentation
    ///   - comparedObservation: The reference observation to compare against (optional, defaults to metrics.minXLineTextObservation)
    ///   - confidenceLevel: Detection confidence level affecting threshold strictness (default: .medium)
    /// - Returns: true if the observation is indented, false if aligned with left margin
    func hasIndentation(
        observation: VNRecognizedTextObservation,
        comparedObservation: VNRecognizedTextObservation? = nil,
        confidenceLevel: OCRConfidenceLevel = .medium
    )
        -> Bool {
        // Use provided comparedObservation or fall back to metrics default
        let referenceObservation = comparedObservation ?? metrics.minXLineTextObservation
        guard let referenceObservation = referenceObservation else { return false }

        let textObservationPair = OCRTextObservationPair(
            current: observation,
            previous: referenceObservation
        )

        let characterDifference = characterDifferenceInXPosition(pair: textObservationPair)
        let baseThreshold = OCRConstants.indentationCharacterCount
        let finalThreshold = baseThreshold * confidenceLevel.thresholdMultiplier
        let isIndented = characterDifference > finalThreshold

        if isIndented {
            let refText = referenceObservation.firstText.prefix20
            print(
                "\nIndentation detected (confidence: \(confidenceLevel)): \(characterDifference.oneDecimalString) > \(finalThreshold.oneDecimalString) (base: \(baseThreshold) × \(confidenceLevel.thresholdMultiplier)) characters"
            )
            print("Current observation: \(observation)")
            print("Compared against: '\(refText)...'\n")
        }

        return isIndented
    }

    /// Determine if text observation represents a long line of text
    ///
    /// **Confidence Level Impact:**
    /// - `.high`: 2.0x threshold (more strict, requires more space to be "long")
    /// - `.medium`: 1.0x threshold (standard detection)
    /// - `.low`: 0.7x threshold (more lenient, easier to detect as "long")
    ///
    /// - Parameters:
    ///   - observation: Text observation to analyze for line length characteristics
    ///   - nextObservation: Next text observation for enhanced context analysis (optional)
    ///   - comparedObservation: The reference observation to compare against (optional)
    ///   - confidenceLevel: Detection confidence level affecting threshold strictness (default: .medium)
    /// - Returns: true if line is considered "long", false if "short"
    func isLongText(
        observation: VNRecognizedTextObservation,
        nextObservation: VNRecognizedTextObservation? = nil,
        comparedObservation: VNRecognizedTextObservation? = nil,
        confidenceLevel: OCRConfidenceLevel = .medium
    )
        -> Bool {
        lineMeasurer.isLongLine(
            observation: observation,
            nextObservation: nextObservation,
            comparedObservation: comparedObservation,
            confidenceLevel: confidenceLevel
        )
    }

    /// Analyze if there is significant line spacing between two text observations
    ///
    /// This method determines whether two consecutive text observations have enough
    /// vertical spacing to be considered as having big line spacing. It uses absolute
    /// height thresholds rather than ratios for more predictable and consistent behavior.
    ///
    /// - Parameters:
    ///   - pair: Text observation pair containing current and previous observations
    ///   - lineSpacingThreshold: Optional absolute height threshold; if nil, calculates adaptive threshold
    ///   - confidenceLevel: Detection confidence level affecting threshold strictness (default: .medium)
    /// - Returns: true if vertical gap exceeds the threshold, false otherwise
    func isBigLineSpacing(
        pair: OCRTextObservationPair,
        lineSpacingThreshold: Double? = nil,
        confidenceLevel: OCRConfidenceLevel = .medium
    )
        -> Bool {
        // Use provided threshold or fall back to metrics default big line spacing threshold
        let baseThreshold = lineSpacingThreshold ?? metrics.bigLineSpacingThreshold
        let finalThreshold = baseThreshold * confidenceLevel.thresholdMultiplier
        let isBigSpacing = pair.verticalGap > finalThreshold

        if isBigSpacing {
            print(
                "\nBig line spacing detected (confidence: \(confidenceLevel)), verticalGap: \(pair.verticalGap.threeDecimalString) > \(finalThreshold.threeDecimalString) (base: \(baseThreshold.threeDecimalString) × \(confidenceLevel.thresholdMultiplier))"
            )
            print("Current: \(pair.current)\n")
        }

        return isBigSpacing
    }

    /// Calculate font size difference between two text observations
    ///
    /// - Parameter pair: Text observation pair containing current and previous observations
    /// - Returns: Absolute difference between the font sizes of the two observations
    func fontSizeDifference(pair: OCRTextObservationPair) -> Double {
        let currentFontSize = fontSize(pair.current)
        let prevFontSize = fontSize(pair.previous)
        return abs(currentFontSize - prevFontSize)
    }

    /// Analyze and compare font sizes between two text observations
    ///
    /// **Confidence Level Impact:**
    /// - `.high`: 2.0x threshold (more strict, requires larger font differences)
    /// - `.medium`: 1.0x threshold (standard detection)
    /// - `.low`: 0.7x threshold (more lenient, detects smaller font differences)
    ///
    /// - Parameters:
    ///   - pair: Text observation pair containing current and previous observations
    ///   - fontSizeThreshold: Optional font size difference threshold; if nil, uses language-specific default
    ///   - confidenceLevel: Detection confidence level affecting threshold strictness (default: .medium)
    /// - Returns: true if font sizes are considered different beyond the threshold, false if they are similar
    func isDifferentFontSize(
        pair: OCRTextObservationPair,
        fontSizeThreshold: Double? = nil,
        confidenceLevel: OCRConfidenceLevel = .medium
    )
        -> Bool {
        let differentFontSize = fontSizeDifference(pair: pair)
        let baseThreshold = fontSizeThreshold ?? self.fontSizeThreshold(metrics.language)
        let finalThreshold = baseThreshold * confidenceLevel.thresholdMultiplier
        let isDifferent = differentFontSize >= finalThreshold

        if isDifferent {
            print(
                "\nDifferent font detected (confidence: \(confidenceLevel)): diff = \(differentFontSize), threshold = \(finalThreshold) (base: \(baseThreshold) × \(confidenceLevel.thresholdMultiplier))"
            )
            print("Pair: \(pair)\n")
        }
        return isDifferent
    }

    func fontSizeThreshold(_ language: Language) -> Double {
        languageManager.isChineseLanguage(language)
            ? OCRConstants.chineseDifferenceFontThreshold
            : OCRConstants.englishDifferenceFontThreshold
    }

    /// Check if two observations contain equal-length Chinese text
    ///
    /// Analyzes whether two text observations represent Chinese text with equal
    /// character lengths and consistent formatting. This is particularly useful
    /// for detecting Chinese poetry patterns and structured content.
    ///
    /// **Analysis Criteria:**
    /// - Current document language is Chinese (Simplified or Traditional)
    /// - Both observations have equal character count and formatting
    /// - Consistent punctuation patterns (both end with punctuation or neither do)
    /// - Basic horizontal alignment validation
    ///
    /// **Use Cases:**
    /// - Chinese poetry detection (classical poems often have equal line lengths)
    /// - Structured Chinese text identification
    /// - Traditional document format validation
    /// - Parallel text analysis
    ///
    /// - Parameter pair: Text observation pair to analyze
    /// - Returns: true if observations contain equal-length Chinese text
    func isEqualChineseText(pair: OCRTextObservationPair) -> Bool {
        let isEqualLength = pair.hasEqualCharacterLength
        let isEqualChinese = isEqualLength && languageManager.isChineseLanguage(metrics.language)

        if isEqualLength {
            print("Pair is considered equal Chinese text: \(pair)")
        }

        return isEqualChinese
    }

    /// Analyze if text represents short Chinese poetry format
    func isShortPoetry(_ text: String) -> Bool {
        languageManager.isChineseLanguage(metrics.language)
            && metrics.charCountPerLine < Double(OCRConstants.shortPoetryCharacterCountOfLine)
            && text.count < OCRConstants.shortPoetryCharacterCountOfLine
    }

    /// Check if text observation is a short line of text
    ///
    /// - Parameters:
    ///  - observation: Text observation to analyze for line length characteristics
    ///  - comparedObservation: Optional reference observation to compare against (defaults to metrics.maxLineLengthObservation)
    ///  - lessRateOfMaxLength: Optional rate of maximum line length to consider as "short" (default: 0.5)
    func isShortLineText(
        observation: VNRecognizedTextObservation,
        comparedObservation: VNRecognizedTextObservation? = nil,
        lessRateOfMaxLength: Double = 0.5
    )
        -> Bool {
        // Use provided comparedObservation or fall back to metrics default
        let referenceObservation = comparedObservation ?? metrics.maxLineLengthObservation
        guard let referenceObservation = referenceObservation else { return false }

        return isShortLine(
            lineLength: observation.lineWidth,
            maxLineLength: referenceObservation.lineWidth,
            lessRateOfMaxLength: lessRateOfMaxLength
        )
    }

    func isShortLine(
        lineLength: Double,
        maxLineLength: Double,
        lessRateOfMaxLength: Double
    )
        -> Bool {
        lineLength < maxLineLength * lessRateOfMaxLength
    }

    /// Analyze and determine Chinese poetry merge decision
    ///
    /// Applies specialized logic for handling Chinese poetry text that requires
    /// different formatting rules than regular prose. Chinese poetry often has
    /// distinctive characteristics that need preservation during text merging.
    ///
    /// - Parameters:
    ///   - pair: Text observation pair containing current and previous observations
    ///   - isEqualChineseText: Whether the texts have equal character counts (Chinese characteristic)
    ///   - isBigLineSpacing: Whether there is significant spacing between lines
    /// - Returns: Merge decision (none, lineBreak, or newParagraph)
    func determineChinesePoetryMerge(
        pair: OCRTextObservationPair,
        isEqualChineseText: Bool,
        isBigLineSpacing: Bool
    )
        -> OCRMergeDecision {
        let isShortChinesePoetry = isShortPoetry(pair.current.firstText)
        let isPrevShortChinesePoetry = isShortPoetry(pair.previous.firstText)

        let isChinesePoetryLine =
            isEqualChineseText || (isShortChinesePoetry && isPrevShortChinesePoetry)
        let shouldWrap = isChinesePoetryLine

        if shouldWrap, isBigLineSpacing {
            return .newParagraph
        } else if shouldWrap {
            return .lineBreak
        } else {
            return .none
        }
    }

    /// Determine if two text observations represent a new line break
    ///
    /// Uses vertical gap analysis to determine if two text observations are positioned
    /// on different lines (new line) or the same horizontal line. This method employs
    /// adaptive thresholding for accurate line break detection across varying text sizes.
    ///
    /// **Algorithm:**
    /// - Uses the verticalGap property from OCRTextObservationPair for precise spacing analysis
    /// - Applies adaptive threshold based on actual text heights for dynamic adjustment
    /// - Uses the larger of adaptive threshold and minimum threshold for robust detection
    /// - Accounts for slight OCR positioning inaccuracies and text overlap scenarios
    ///
    /// **New Line Detection Criteria:**
    /// - Positive vertical gap (clear spacing between lines)
    /// - Negative gap magnitude exceeding the adaptive threshold (significant overlap)
    /// - Threshold is calculated as 40% of the larger between smaller text height and average line height
    ///
    /// **Threshold Calculation:**
    /// - `adaptiveThreshold = min(currentHeight, previousHeight)` - based on smaller text
    /// - `minimumThreshold = metrics.averageLineHeight` - document-wide baseline
    /// - `finalThreshold = max(adaptiveThreshold, minimumThreshold) * 0.4` - 40% safety factor
    ///
    /// - Parameter pair: Pair of text observations to analyze for line separation
    /// - Returns: true if observations represent a new line, false if on the same line
    func isNewLine(pair: OCRTextObservationPair) -> Bool {
        let verticalGap = pair.verticalGap

        // Calculate adaptive threshold based on actual text heights
        let currentHeight = pair.current.boundingBox.size.height
        let previousHeight = pair.previous.boundingBox.size.height
        let smallerHeight = min(currentHeight, previousHeight)

        // Use a fraction of the smaller text height as threshold
        // This is more adaptive than using global minimum line height
        let adaptiveThreshold = smallerHeight

        // Also consider a minimum threshold to avoid being too strict with very small text
        let minimumThreshold = metrics.averageLineHeight

        // Use the larger of the two thresholds for better accuracy
        let threshold = max(adaptiveThreshold, minimumThreshold) * 0.4

        // If vertical gap is positive (spacing) or very small negative (slight overlap),
        // consider it as a new line.
        let isNewLine = verticalGap > 0 || abs(verticalGap) <= threshold

        if !isNewLine {
            print(
                "\nVertical gap: \(verticalGap.threeDecimalString), Threshold: \(threshold.threeDecimalString)"
            )
            print("Same line detected: \(pair)")
        }

        return isNewLine
    }

    // MARK: - Helper Methods

    /// Calculate the horizontal difference between two text observations in character units
    ///
    /// This function converts the spatial X-coordinate difference between two text observations
    /// into an equivalent character count. This provides a more intuitive and consistent way
    /// to measure horizontal spacing and indentation across different text sizes and screen resolutions.
    ///
    /// **Calculation Method:**
    /// - Calculates the raw X-coordinate difference (dx)
    /// - Converts to screen coordinates using image dimensions and scaling
    /// - Divides by average character width to get character-equivalent distance
    ///
    /// **Return Values:**
    /// - Positive: current observation is to the right of previous (potential indentation)
    /// - Negative: current observation is to the left of previous (outdentation)
    /// - Zero: observations are aligned horizontally
    ///
    /// - Parameter pair: Pair of text observations to compare
    /// - Returns: Horizontal difference in character units (can be positive, negative, or zero)
    func characterDifferenceInXPosition(pair: OCRTextObservationPair) -> Double {
        guard let ocrImage = metrics.ocrImage else {
            return 0.0
        }

        let currentX = pair.current.boundingBox.origin.x
        let previousX = pair.previous.boundingBox.origin.x
        let dx = currentX - previousX

        // Vision framework provides normalized coordinates (0-1), multiply by image width to get logical distance
        let imageWidth = ocrImage.size.width
        let logicalDifference = imageWidth * dx

        // Convert logical difference to character units using average character width
        let characterDifference = logicalDifference / metrics.averageCharacterWidth

        return characterDifference
    }

    // Determine if two text observations have equivalent horizontal positioning (X coordinates)
    ///
    /// This precise spatial analysis method determines whether two text observations are aligned
    /// horizontally within acceptable tolerance thresholds. Uses the new character-based
    /// calculation for more accurate and consistent alignment detection.
    ///
    /// **Analysis Method:**
    /// - Uses character-based difference calculation for consistent measurement
    /// - Applies tolerance ranges for slight positioning variations
    /// - Considers both perfect alignment and small positioning differences as "equal"
    ///
    /// **Alignment Criteria:**
    /// - Absolute character difference is less than half the indentation threshold (1.0 characters)
    /// - This provides tolerance for slight OCR positioning inaccuracies
    /// - Uses character units for consistent behavior across different text sizes
    ///
    /// **Use Cases:**
    /// - Paragraph alignment detection
    /// - List item alignment analysis
    /// - Block structure identification
    /// - Column alignment recognition
    ///
    /// - Parameter pair: Pair of text observations to compare for X alignment
    /// - Returns: true if observations are horizontally aligned within tolerance, false otherwise
    func isEqualX(
        pair: OCRTextObservationPair,
        confidenceLevel: OCRConfidenceLevel = .medium
    )
        -> Bool {
        let characterDifference = characterDifferenceInXPosition(pair: pair)

        // Consider positions "equal" if difference is less than indentation threshold
        let baseTolerance = OCRConstants.indentationCharacterCount * 0.9
        let finalTolerance = baseTolerance / confidenceLevel.thresholdMultiplier
        let isEqual = abs(characterDifference) < finalTolerance

        if !isEqual {
            print(
                "\nNot equalX text (confidence: \(confidenceLevel)): difference = \(characterDifference.oneDecimalString) >= tolerance \(finalTolerance.oneDecimalString) (base: \(baseTolerance.oneDecimalString) × \(confidenceLevel.thresholdMultiplier))"
            )
            print("Current: \(pair.current)\n")
        }

        return isEqual
    }

    func isRatioGreaterThan(_ ratio: Double, value1: Double, value2: Double) -> Bool {
        let minValue = min(value1, value2)
        let maxValue = max(value1, value2)
        return (minValue / maxValue) > ratio
    }

    /// Determine if two text observations have equal alignment (both X position and line width)
    ///
    /// This method combines horizontal positioning analysis with line width comparison
    /// to determine if two text observations represent aligned text blocks. It considers
    /// both the starting position (X coordinate) and ending position (maxX) for comprehensive
    /// alignment detection.
    ///
    /// **Analysis Components:**
    /// - X-coordinate alignment using character-based tolerance
    /// - Maximum X-coordinate similarity using ratio-based comparison
    /// - Combined assessment for overall text alignment
    ///
    /// **Use Cases:**
    /// - Paragraph boundary detection
    /// - Text block alignment analysis
    /// - Structured document processing
    /// - Layout consistency verification
    ///
    /// - Parameter pair: Text observation pair to analyze for alignment
    /// - Returns: true if observations are aligned in both position and width, false otherwise
    func isEqualAlignment(pair: OCRTextObservationPair) -> Bool {
        let isEqualX = isEqualX(pair: pair)
        let isEqualLineMaxX = isEqualMaxX(pair: pair)

        return isEqualX && isEqualLineMaxX
    }

    /// Check if two text observations have similar maximum X coordinates (line endings)
    ///
    /// Analyzes whether two text observations end at approximately the same horizontal
    /// position by comparing their maximum X coordinates. This is useful for detecting
    /// text blocks with similar line lengths or right-aligned content.
    ///
    /// **Comparison Method:**
    /// - Uses ratio-based comparison for relative similarity assessment
    /// - Default threshold of 95% similarity for robust detection
    /// - Considers the ratio between smaller and larger maxX values
    ///
    /// **Use Cases:**
    /// - Right margin alignment detection
    /// - Similar line length identification
    /// - Text block boundary analysis
    /// - Justified text recognition
    ///
    /// - Parameters:
    ///   - pair: Text observation pair to analyze
    ///   - ratio: Similarity threshold ratio (default: 0.95)
    /// - Returns: true if maxX coordinates are similar within the ratio threshold
    func isEqualMaxX(pair: OCRTextObservationPair, ratio: Double = 0.95) -> Bool {
        let lineMaxX = pair.current.boundingBox.maxX
        let prevLineMaxX = pair.previous.boundingBox.maxX

        return isRatioGreaterThan(ratio, value1: lineMaxX, value2: prevLineMaxX)
    }

    // MARK: Private

    private let metrics: OCRMetrics
    private let lineMeasurer: OCRLineMeasurer
    private var languageManager = EZLanguageManager.shared()

    private func fontSize(_ observation: VNRecognizedTextObservation) -> Double {
        guard let ocrImage = metrics.ocrImage else {
            return NSFont.systemFontSize
        }

        // Vision framework provides normalized coordinates, multiply by image size to get logical width
        let textWidth = observation.boundingBox.size.width * ocrImage.size.width
        return fontSize(observation.firstText, width: textWidth)
    }

    private func fontSize(_ text: String, width textWidth: Double) -> Double {
        let systemFontSize = NSFont.systemFontSize
        let font = NSFont.boldSystemFont(ofSize: systemFontSize)

        let width = text.size(withAttributes: [.font: font]).width

        /**
         systemFontSize / width = fontSize / textWidth
         fontSize = textWidth * (systemFontSize / width)
         */
        let fontSize = textWidth * (systemFontSize / width)

        return fontSize
    }
}
