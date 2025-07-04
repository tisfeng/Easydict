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

/// Intelligent text merging engine for OCR results with context-aware formatting decisions
///
/// This sophisticated text merging system serves as the core decision-making engine for combining
/// adjacent OCR text observations into coherent, well-formatted text output. It applies advanced
/// algorithms to analyze spatial relationships, content patterns, and formatting cues to make
/// intelligent decisions about how text should be joined together.
///
/// **Core Responsibilities:**
/// - **Spatial Analysis**: Analyzes positioning, alignment, and spacing between text observations
/// - **Context-Aware Merging**: Makes intelligent decisions based on text content and layout patterns
/// - **Format Preservation**: Maintains original document structure (poetry, lists, paragraphs)
/// - **Language Adaptation**: Applies language-specific rules for optimal text reconstruction
/// - **Typography Intelligence**: Handles punctuation, capitalization, and special formatting
///
/// **Key Algorithms:**
/// - **Same-Line Detection**: Identifies text that belongs on the same horizontal line
/// - **Indentation Analysis**: Handles indented text blocks with appropriate formatting
/// - **Poetry Recognition**: Preserves poetic structure and intentional line breaks
/// - **List Processing**: Maintains list formatting and hierarchical structures
/// - **Paragraph Detection**: Identifies paragraph boundaries and major content divisions
///
/// **Decision Matrix:**
/// The merger evaluates multiple factors to determine the optimal joining strategy:
/// - Line spacing and positioning relationships
/// - Text indentation patterns and alignment
/// - Font size variations and typography changes
/// - Punctuation patterns and sentence boundaries
/// - Language-specific formatting requirements
/// - Content type recognition (prose, poetry, lists, etc.)
///
/// **Output Strategies:**
/// - **Space Join**: Normal word separation for continuous text
/// - **Line Break**: Single line break for intentional text structure
/// - **Paragraph Break**: Double line break for major content divisions
/// - **No Separation**: Direct concatenation for character-based languages
///
/// **Example Transformations:**
/// ```
/// Input:  ["Hello", "world", "today"]  →  Output: "Hello world today"
/// Input:  ["Roses are red", "Violets blue"]  →  Output: "Roses are red\nViolets blue"
/// Input:  ["Chapter 1", "", "Once upon"]  →  Output: "Chapter 1\n\nOnce upon"
/// ```
///
/// Originally corresponds to the joinedStringOfTextObservation method in EZAppleService.m
/// but significantly enhanced with modern Swift architecture and advanced decision algorithms.
class OCRTextMerger {
    // MARK: Lifecycle

    /// Initialize intelligent text merger with comprehensive OCR metrics
    ///
    /// Creates a new text merger instance equipped with document-wide statistical data
    /// and analysis capabilities. The provided metrics serve as the foundation for all
    /// spatial calculations, threshold determinations, and formatting decisions.
    ///
    /// - Parameter metrics: Complete OCR metrics containing document analysis data,
    ///   including line measurements, character statistics, spatial relationships,
    ///   and language-specific processing parameters
    init(metrics: OCRMetrics) {
        self.metrics = metrics
    }

    // MARK: Internal

    /// Generate optimal joining string for adjacent text observations
    ///
    /// This is the primary entry point for text merging operations, orchestrating a sophisticated
    /// analysis pipeline to determine the most appropriate way to join two adjacent text observations.
    /// The method applies intelligent decision-making based on spatial relationships, content analysis,
    /// and document structure recognition.
    ///
    /// **Analysis Pipeline:**
    /// 1. **Same-Line Detection**: Quick check for horizontal text alignment
    /// 2. **Context Preparation**: Comprehensive analysis of spatial and content relationships
    /// 3. **Decision Making**: Advanced algorithms evaluate multiple formatting factors
    /// 4. **String Generation**: Produces appropriate joining string based on decision
    ///
    /// **Decision Factors Evaluated:**
    /// - Spatial positioning and alignment patterns
    /// - Line spacing and indentation characteristics
    /// - Text content patterns and punctuation
    /// - Font size variations and typography changes
    /// - Language-specific formatting requirements
    /// - Document structure recognition (poetry, lists, paragraphs)
    ///
    /// **Output Types:**
    /// - `" "`: Space separation for normal text continuation
    /// - `"\n"`: Single line break for structured text (poetry, lists)
    /// - `"\n\n"`: Paragraph break for major content divisions
    /// - `""`: No separation for character-based languages
    ///
    /// **Performance Optimization:**
    /// - Fast-path for same-line detection (most common case)
    /// - Lazy initialization of analysis components
    /// - Cached calculations for repeated operations
    ///
    /// - Parameter textObservationPair: Adjacent text observation pair for analysis
    /// - Returns: Optimal joining string for the text pair based on comprehensive analysis
    ///
    /// - Note: This method directly corresponds to joinedStringOfTextObservation in Objective-C
    ///   but provides significantly enhanced decision-making capabilities
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

    // MARK: - Analysis Helper Methods

    /// Check if current processing language is English for language-specific formatting rules
    ///
    /// Provides a convenient way to check for English language context, which requires
    /// specific formatting rules such as capitalization-based sentence detection,
    /// space-separated words, and punctuation handling patterns.
    ///
    /// - Returns: true if the current language is English, false otherwise
    private func isEnglishLanguage() -> Bool {
        languageManager.isEnglishLanguage(metrics.language)
    }

    /// Prepare comprehensive line context for text merging analysis
    ///
    /// Creates a complete analysis context containing all necessary data for making
    /// intelligent text merging decisions. This centralized preparation ensures
    /// consistent analysis across all merging operations.
    ///
    /// - Parameter textObservationPair: Pair of text observations to analyze
    /// - Returns: Complete line context with pre-calculated analysis results
    private func prepareLineContext(
        _ textObservationPair: OCRTextObservationPair
    )
        -> OCRLineContext {
        OCRLineContext(pair: textObservationPair, metrics: metrics)
    }

    /// Determine appropriate merge decision based on comprehensive line context analysis
    ///
    /// This is the core decision-making method that orchestrates the entire text merging
    /// analysis pipeline. It processes the line context through multiple specialized
    /// handlers to determine the optimal way to join text observations.
    ///
    /// **Decision Process:**
    /// 1. **Indentation Analysis**: Handle indented vs non-indented text differently
    /// 2. **Context-specific Processing**: Apply specialized rules based on text characteristics
    /// 3. **Additional Rule Application**: Apply final refinements and edge case handling
    /// 4. **Decision Synthesis**: Combine all analysis results into final merge decision
    ///
    /// **Decision Types:**
    /// - `.none`: Join with space (normal text continuation)
    /// - `.lineBreak`: Insert line break (preserve line structure)
    /// - `.newParagraph`: Insert paragraph break (major content division)
    ///
    /// - Parameter lineContext: Complete line analysis context
    /// - Returns: Optimal merge decision for the text pair
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

    /// Generate the final joined string based on merge decision and contextual analysis
    ///
    /// Translates the strategic merge decision into the actual string that will join the text
    /// observations. This method applies language-specific rules, punctuation handling,
    /// and formatting preferences to produce the optimal joining string.
    ///
    /// **String Generation Logic:**
    /// - **New Paragraph**: Returns paragraph break text (typically "\n\n")
    /// - **Line Break**: Returns single line break text (typically "\n")
    /// - **Punctuation Context**: Adds space after punctuation for readability
    /// - **Language Adaptation**: Applies space rules based on language characteristics
    /// - **Default Handling**: No separation for languages that don't require word spacing
    ///
    /// **Language-Specific Behavior:**
    /// - **Space-separated languages** (English, French, etc.): Add spaces between words
    /// - **Character-based languages** (Chinese, Japanese): No automatic spacing
    /// - **Mixed scripts**: Intelligent detection and appropriate handling
    ///
    /// - Parameters:
    ///   - mergeDecision: Strategic decision about how to merge the text observations
    ///   - previousText: Text content of the previous observation for context analysis
    /// - Returns: Appropriately formatted joining string for the specific context
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

    /// Apply comprehensive additional merge rules for edge cases and special formatting
    ///
    /// This advanced rule application system handles complex scenarios that require
    /// additional analysis beyond the basic indentation and spacing logic. It serves
    /// as the final decision refinement layer, ensuring optimal text formatting for
    /// specialized content types and edge cases.
    ///
    /// **Advanced Rule Categories:**
    ///
    /// **1. Typography and Font Analysis:**
    /// - Font size variation detection and handling
    /// - Capitalization pattern analysis for sentence boundaries
    /// - Mixed typography formatting preservation
    ///
    /// **2. Spacing and Layout Refinement:**
    /// - Big line spacing analysis for paragraph detection
    /// - Long text line pattern recognition
    /// - Visual spacing correlation with content structure
    ///
    /// **3. Specialized Content Handling:**
    /// - Chinese poetry structure preservation
    /// - List formatting and hierarchy maintenance
    /// - Special document structure recognition
    ///
    /// **4. Language-Specific Enhancements:**
    /// - English capitalization rules for sentence boundaries
    /// - Character-based language formatting preferences
    /// - Mixed-language document handling
    ///
    /// **Rule Priority System:**
    /// - Content-specific rules (poetry, lists) take precedence
    /// - Typography rules override basic spacing decisions
    /// - Language rules provide final formatting adjustments
    /// - Default rules ensure consistent fallback behavior
    ///
    /// - Parameters:
    ///   - lineContext: Complete line analysis context with pre-calculated properties
    ///   - needLineBreak: Initial line break decision from basic analysis
    ///   - isNewParagraph: Initial paragraph break decision from basic analysis
    /// - Returns: Final merge decision with all advanced rules applied
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

    /// Handle specialized text merging logic for indented text blocks and structured content
    ///
    /// This sophisticated handler manages the complex formatting requirements of indented text,
    /// which often represents structured content such as paragraphs, block quotes, code blocks,
    /// list items, or nested document elements. The analysis considers both current and previous
    /// line indentation patterns to make contextually appropriate formatting decisions.
    ///
    /// **Indentation Analysis Categories:**
    ///
    /// **1. Mutual Indentation Scenarios:**
    /// - Both lines indented: Analyze consistency and spacing patterns
    /// - Uniform indentation: Preserve structure while managing line breaks
    /// - Variable indentation: Detect hierarchy changes and structure shifts
    ///
    /// **2. Single Line Indentation:**
    /// - Current line indented, previous normal: New block detection
    /// - Previous line indented, current normal: Block termination handling
    /// - Indentation level changes: Hierarchy structure preservation
    ///
    /// **3. Content-Specific Rules:**
    /// - Long line continuation: Smart wrapping within indented blocks
    /// - Short line handling: Preserve intentional structure breaks
    /// - Punctuation context: Sentence boundaries within blocks
    /// - Equal line lengths: Detect structured content (tables, poetry)
    ///
    /// **4. Special Case Handling:**
    /// - Letter format detection: Handle specific indentation patterns
    /// - List item continuation: Maintain list structure integrity
    /// - Code block preservation: Respect technical content formatting
    /// - Quote block handling: Preserve quotation structure
    ///
    /// **Decision Logic:**
    /// - Analyzes horizontal positioning deltas for structure understanding
    /// - Considers line length ratios for content type detection
    /// - Evaluates punctuation patterns for boundary identification
    /// - Applies language-specific indentation conventions
    ///
    /// - Parameter lineContext: Complete line analysis context with indentation data
    /// - Returns: Optimal merge decision for indented text structure preservation
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

    /// Handle text merging logic for non-indented text blocks and standard document flow
    ///
    /// This handler manages the formatting requirements for regular document text that follows
    /// standard layout patterns without special indentation. It focuses on maintaining natural
    /// text flow while detecting and preserving important structural elements such as paragraph
    /// boundaries, sentence breaks, and content transitions.
    ///
    /// **Primary Analysis Areas:**
    ///
    /// **1. Line Spacing Analysis:**
    /// - **Big Spacing Detection**: Identifies significant vertical gaps indicating structure breaks
    /// - **Standard Spacing**: Handles normal line-to-line text continuation
    /// - **Tight Spacing**: Manages closely spaced text while preserving readability
    ///
    /// **2. Content Flow Management:**
    /// - **Long Line Continuation**: Smart handling of text that flows naturally to next line
    /// - **Short Line Processing**: Detects intentional breaks vs. formatting artifacts
    /// - **Page Turn Detection**: Identifies text continuation across page boundaries
    ///
    /// **3. Document Structure Recognition:**
    /// - **Paragraph Boundaries**: Detects natural paragraph divisions
    /// - **Poetry Handling**: Preserves poetic structure in non-indented verse
    /// - **Letter Format**: Handles correspondence and formal document structures
    ///
    /// **4. Language-Specific Processing:**
    /// - **English Rules**: Capitalization-based sentence boundary detection
    /// - **Punctuation Analysis**: Uses punctuation patterns for structure identification
    /// - **Character-based Languages**: Applies appropriate spacing and flow rules
    ///
    /// **5. Special Cases:**
    /// - **Mixed Content**: Handles transitions between different content types
    /// - **Typography Changes**: Responds to font and style variations
    /// - **Spacing Anomalies**: Manages unusual spacing patterns intelligently
    ///
    /// **Decision Framework:**
    /// - Prioritizes natural reading flow for standard text
    /// - Preserves intentional structure breaks
    /// - Maintains paragraph integrity
    /// - Adapts to language-specific formatting conventions
    ///
    /// - Parameter lineContext: Complete line analysis context for non-indented text
    /// - Returns: Optimal merge decision for natural document flow preservation
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

    // MARK: - Spatial Analysis Helper Methods

    /// Determine if two text observations have equivalent horizontal positioning (X coordinates)
    ///
    /// This precise spatial analysis method determines whether two text observations are aligned
    /// horizontally within acceptable tolerance thresholds. The analysis is crucial for detecting
    /// indentation patterns, paragraph boundaries, and structured content formatting.
    ///
    /// **Analysis Method:**
    /// - Calculates dynamic threshold based on average character width and indentation constants
    /// - Accounts for screen scaling factors for accurate measurements
    /// - Applies tolerance ranges for slight positioning variations
    /// - Uses relative positioning analysis for robust detection
    ///
    /// **Threshold Calculation:**
    /// - Based on `averageCharacterWidth * OCRConstants.indentationCharacterCount`
    /// - Incorporates screen scaling factor for high-resolution displays
    /// - Provides half-threshold tolerance for boundary cases
    /// - Adapts to document-specific character sizing
    ///
    /// **Use Cases:**
    /// - Paragraph indentation detection
    /// - List item alignment analysis
    /// - Block quote structure identification
    /// - Table column alignment recognition
    ///
    /// - Parameter textObservationPair: Pair of text observations to compare for X alignment
    /// - Returns: true if observations are horizontally aligned within tolerance, false otherwise
    ///
    /// - Note: Includes debug output for alignment analysis during development
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

    /// Calculate if the ratio between two values exceeds a specified threshold
    ///
    /// This utility method provides robust ratio comparison for spatial and measurement
    /// analysis throughout the text merging process. It ensures consistent comparison
    /// logic by always using the smaller value as numerator and larger as denominator.
    ///
    /// **Mathematical Approach:**
    /// - Always calculates `min(value1, value2) / max(value1, value2)`
    /// - Ensures ratio is always between 0.0 and 1.0
    /// - Provides symmetric comparison regardless of parameter order
    /// - Handles edge cases with zero or negative values safely
    ///
    /// **Common Use Cases:**
    /// - Line length similarity analysis (`isEqualLineMaxX`)
    /// - Font size comparison for typography consistency
    /// - Spacing ratio analysis for layout decisions
    /// - Proportional measurement validation
    ///
    /// **Example Usage:**
    /// ```swift
    /// let isSimilar = isRatioGreaterThan(0.95, value1: line1.width, value2: line2.width)
    /// // Returns true if lines are within 5% of each other's width
    /// ```
    ///
    /// - Parameters:
    ///   - ratio: Minimum ratio threshold (0.0 to 1.0) for comparison
    ///   - value1: First value for ratio calculation
    ///   - value2: Second value for ratio calculation
    /// - Returns: true if the ratio of smaller/larger values exceeds the threshold
    private func isRatioGreaterThan(_ ratio: Double, value1: Double, value2: Double) -> Bool {
        let minValue = min(value1, value2)
        let maxValue = max(value1, value2)
        return (minValue / maxValue) > ratio
    }
}
