//
//  OCRTextNormalizer.swift
//  Easydict
//
//  Created by tisfeng on 2025/7/2.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation
import RegexBuilder

// MARK: - OCRTextNormalizer

/// Handles comprehensive text normalization for OCR results
///
/// This class addresses common OCR recognition issues by applying systematic corrections:
/// - **Spacing**: Removes excessive spaces while preserving paragraph structure
/// - **Punctuation**: Ensures language-appropriate punctuation styles (Western vs Chinese)
/// - **Symbols**: Normalizes misrecognized special characters and mathematical symbols
/// - **Formatting**: Fixes line breaks, hyphenation, and text structure issues
///
/// The normalizer is language-aware and applies different rules based on the detected language:
/// - Chinese/Japanese: Uses full-width punctuation (，。；：？！)
/// - English/Korean/Others: Uses half-width punctuation (,.;:?!)
///
/// Example usage:
/// ```swift
/// let metrics = OCRMetrics(language: .english)
/// let normalizer = OCRTextNormalizer(metrics: metrics)
/// let cleanText = normalizer.normalizeTextSymbols(in: messyOCRText)
/// ```
public class OCRTextNormalizer {
    // MARK: Lifecycle

    /// Initialize with OCR metrics for language-specific processing
    init(metrics: OCRMetrics) {
        self.metrics = metrics
    }

    /// Convenience initializer for testing with just a language
    /// - Parameter language: The target language for text normalization
    convenience init(language: Language) {
        let metrics = OCRMetrics(language: language)
        self.init(metrics: metrics)
    }

    // MARK: Public

    /// Normalize and replace various text symbols for better readability and consistency
    /// This is the main entry point that orchestrates all text normalization steps in optimal order
    ///
    /// Processing pipeline:
    /// 1. Dot symbol normalization - unifies various bullet points and dots
    /// 2. Common OCR errors - fixes symbol misrecognitions
    /// 3. Punctuation normalization - ensures language-appropriate punctuation style
    /// 4. Formatting cleanup - fixes line breaks and excessive spacing
    /// 5. Spacing normalization - cleans up irregular spacing (done last to handle punctuation changes)
    ///
    /// Example transformation:
    /// Input:  "Hello   •   world，this is a test—with   bad spacing ．"
    /// Output: "Hello · world, this is a test-with bad spacing."
    public func normalizeText(_ string: String) -> String {
        var normalizedText = string
        print("Before normalization: \n\(normalizedText)")

        // 0. FIRST: Protect special content that should never be modified
        let (protectedText, protectionMap) = protectSpecialContent(normalizedText)
        normalizedText = protectedText

        // 1. Apply dot symbol normalization (• → ·)
        normalizedText = replaceSimilarDotSymbol(in: normalizedText)

        // 2. Normalize common OCR symbol errors (— → -, ´ → ', … → ...)
        normalizedText = normalizeCommonOCRErrors(in: normalizedText)

        // 3. Apply punctuation normalization based on language context (，→ , or , → ，)
        normalizedText = normalizePunctuation(in: normalizedText)

        // 4. Fix common formatting issues (line breaks, excessive spacing)
        normalizedText = normalizeFormatting(in: normalizedText)

        // 5. Normalize spacing issues (after punctuation changes to handle new spacing correctly)
        normalizedText = normalizeSpacing(in: normalizedText)

        // 6. FINALLY: Restore all protected content
        normalizedText = restoreProtectedContent(normalizedText, protectionMap)

        print("After normalization: \n\(normalizedText)")

        return normalizedText
    }

    // MARK: Internal

    let metrics: OCRMetrics

    var language: Language {
        get {
            metrics.language
        }
        set {
            // Update metrics language when set
            metrics.language = newValue
        }
    }

    // MARK: Private

    private let languageManager = EZLanguageManager.shared()

    /// Protect special content that should never be modified during normalization
    /// Returns the protected text and a map for restoration
    private func protectSpecialContent(_ text: String) -> (String, [String: String]) {
        var result = text
        var protectionMap: [String: String] = [:]
        var protectionIndex = 0

        // Collect all ranges that need protection
        var ranges: [Range<String.Index>] = []

        // Protect URLs (http://, https://, ftp://, etc.)
        let urlRegex = /https?:\/\/[^\s\u4e00-\u9fff]+/
        for match in text.matches(of: urlRegex) {
            ranges.append(match.range)
        }

        // Protect domain names without protocol (e.g., easydict.app, google.com)
        let domainRegex = /[a-zA-Z0-9-]+\.[a-zA-Z]{2,}(?:\.[a-zA-Z]{2,})?/
        for match in text.matches(of: domainRegex) {
            ranges.append(match.range)
        }

        // Protect email addresses
        let emailRegex = /[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/
        for match in text.matches(of: emailRegex) {
            ranges.append(match.range)
        }

        // Protect file paths and extensions
        let filePathRegex = /[a-zA-Z]:[\\\/][^\s\u4e00-\u9fff]+/
        for match in text.matches(of: filePathRegex) {
            ranges.append(match.range)
        }

        // Protect programming code patterns (variable.method, object.property)
        let codeRegex = /[a-zA-Z_][a-zA-Z0-9_]*\.[a-zA-Z_][a-zA-Z0-9_]*/
        for match in text.matches(of: codeRegex) {
            ranges.append(match.range)
        }

        // Protect function call patterns (array.map(), obj.method(), etc.)
        let functionCallRegex = /[a-zA-Z_][a-zA-Z0-9_]*\.[a-zA-Z_][a-zA-Z0-9_]*\(\)/
        for match in text.matches(of: functionCallRegex) {
            ranges.append(match.range)
        }

        // Protect parentheses that are adjacent to alphanumeric characters (function calls, etc.)
        let adjacentParenRegex = /[a-zA-Z0-9]\([^)]*\)/
        for match in text.matches(of: adjacentParenRegex) {
            ranges.append(match.range)
        }

        // Protect decimal numbers (10.99, 3.14)
        let decimalRegex = /\d+\.\d+/
        for match in text.matches(of: decimalRegex) {
            ranges.append(match.range)
        }

        // Protect ellipsis (...)
        let ellipsisRegex = /\.\.\./
        for match in text.matches(of: ellipsisRegex) {
            ranges.append(match.range)
        }

        // Merge overlapping ranges and sort
        let mergedRanges = mergeOverlappingRanges(ranges)

        // Replace protected content with placeholders (in reverse order to maintain indices)
        for range in mergedRanges.reversed() {
            let placeholder = "〈PROTECTED_\(protectionIndex)〉"
            let originalContent = String(result[range])
            protectionMap[placeholder] = originalContent
            result.replaceSubrange(range, with: placeholder)
            protectionIndex += 1
        }

        return (result, protectionMap)
    }

    /// Restore all protected content from placeholders
    private func restoreProtectedContent(_ text: String, _ protectionMap: [String: String])
        -> String {
        var result = text

        // Restore all protected content
        for (placeholder, original) in protectionMap {
            result = result.replacingOccurrences(of: placeholder, with: original)
        }

        return result
    }

    /// Normalize spacing issues commonly found in OCR text
    /// OCR often produces irregular spacing that needs cleanup while preserving text structure
    private func normalizeSpacing(in string: String) -> String {
        var result = string

        // Remove multiple consecutive spaces and tabs (but preserve line breaks)
        // Example: "Hello    world   test" → "Hello world test"
        // Pattern: [ \t]{2,} matches 2 or more consecutive spaces/tabs
        result.replace(/[ \t]{2,}/, with: " ")

        // Fix spacing around punctuation for English-type languages
        if languageManager.isLanguageWordsNeedSpace(metrics.language) {
            // Fix decimal numbers FIRST before other punctuation processing
            // This handles all decimal spacing patterns: "10 . 99", "10. 99", "10 .99" -> "10.99"
            // Pattern: (\d)[ \t]*\.[ \t]*(\d) matches digit + optional spaces + dot + optional spaces + digit
            result.replace(/(\d)[ \t]*\.[ \t]*(\d)/) { match in
                "\(match.1).\(match.2)"
            }

            // Remove spaces before punctuation marks (but not line breaks)
            // Example: "Hello , world ." → "Hello, world."
            // Pattern: [ \t]+([,.;:!?)]) matches spaces/tabs before punctuation
            result.replace(/[ \t]+([,.;:!?])/) { match in
                "\(match.1)"
            }

            // Add space after punctuation marks if missing (except for decimals and ellipsis)
            // Example: "Hello,world.Test" → "Hello, world. Test"
            // We need to be careful not to add space after decimal points like "10.99" or ellipsis like "..."
            // Since Swift Regex doesn't support lookbehind, we use a protect-process-restore approach:
            // 1. Temporarily replace decimal points and ellipsis with placeholders
            // 2. Add spaces after punctuation
            // 3. Restore decimal points and ellipsis
            result.replace(/(\d)\.(\d)/) { match in
                "\(match.1)〈DECIMAL〉\(match.2)"
            }

            // Protect ellipsis (three consecutive dots)
            result.replace("...", with: "〈ELLIPSIS〉")

            // Now safely add spaces after punctuation
            // Pattern: ([,.;:!?)])([^\s]) matches punctuation followed by non-whitespace
            result.replace(/([,.;:!?])([^\s])/) { match in
                "\(match.1) \(match.2)"
            }

            // Restore decimal points and ellipsis from placeholders
            result.replace("〈DECIMAL〉", with: ".")
            result.replace("〈ELLIPSIS〉", with: "...")
        }

        return result
    }

    /// Replace similar dot symbols with standardized middle dot character
    /// OCR often misidentifies various dot-like symbols, this unifies them for consistency
    /// Handles various dot-like symbols that OCR might recognize incorrectly
    private func replaceSimilarDotSymbol(in string: String) -> String {
        // Define the character set for various dot-like symbols that OCR commonly confuses
        // Examples of transformations:
        // "Item 1 • Item 2" → "Item 1 · Item 2" (bullet point)
        // "A ⋅ B ∙ C" → "A · B · C" (mathematical dots)
        // "List ○ First ● Second" → "List · First · Second" (circle symbols)
        let dotLikeCharacters = "⋅•‧∙⋄◦∘○●"
        let charSet = CharacterSet(charactersIn: dotLikeCharacters)
        let components = string.components(separatedBy: charSet)

        // Only proceed if we found dot-like symbols to replace
        if components.count > 1 {
            let trimmedComponents = components.compactMap { component in
                let trimmed = component.trimmingCharacters(in: .whitespaces)
                return trimmed.isEmpty ? nil : trimmed
            }

            // Use middle dot (·) as the standard separator for better readability
            let result = trimmedComponents.joined(separator: " · ")

            // Clean up any double spaces that might have been introduced (preserve line breaks)
            // Pattern: [ \t]{2,} matches 2 or more consecutive spaces/tabs
            return result.replacing(/[ \t]{2,}/, with: " ")
        }

        return string
    }

    /// Normalize common OCR recognition errors for symbols
    /// OCR systems frequently misidentify special characters and symbols
    /// Only applies essential corrections that are clearly OCR errors, not semantic replacements
    private func normalizeCommonOCRErrors(in string: String) -> String {
        var result = string

        // Only the most common and clearly erroneous OCR misrecognitions:
        let symbolMappings: [String: String] = [
            // Acute accent misread as apostrophe - this is clearly an OCR error
            "´": "'", // Acute accent → apostrophe: "don´t" → "don't"

            // Dash variations - OCR often can't distinguish these correctly
            "—": "-", // Em dash → hyphen: "hello—world" → "hello-world"
            "–": "-", // En dash → hyphen: "pages 1–10" → "pages 1-10"
            "―": "-", // Horizontal bar → hyphen: "test―case" → "test-case"

            "…": "...", // Ellipsis → three dots: "wait…" → "wait..."
        ]

        for (incorrect, correct) in symbolMappings {
            result.replace(incorrect, with: correct)
        }

        // Handle special cases that need regex patterns
        // Fix common lowercase 'l' misread as 'I' at word boundaries
        // Example: "l think" → "I think", "l am" → "I am"
        // Pattern: \bl(?=[ \t]|$|[.,:;!?]) matches 'l' at word start followed by space/punctuation/end
        result.replace(/\bl(?=[ \t]|$|[.,:;!?])/, with: "I")

        return result
    }

    /// Normalize punctuation marks based on language context to fix OCR recognition errors
    /// OCR often confuses punctuation styles between languages, this ensures consistency
    /// Examples:
    /// - English text: "Hello，world。" → "Hello, world."
    /// - Chinese text: "你好,世界." → "你好，世界。"
    /// - Korean text: "안녕，세계。" → "안녕, 세계." (uses Western punctuation)
    private func normalizePunctuation(in string: String) -> String {
        var normalizedText = string

        if usesChinesePunctuation(metrics.language) {
            // For Chinese and Japanese, normalize to Chinese/East Asian punctuation
            normalizedText = normalizeToChinesePunctuation(normalizedText)
        } else {
            // For English, Korean, and most other languages, normalize to Western punctuation
            normalizedText = normalizeToWesternPunctuation(normalizedText)
        }

        return normalizedText
    }

    /// Determine if a language uses Chinese-style punctuation
    /// Languages that use full-width punctuation marks in their writing systems
    /// - Chinese (Simplified/Traditional/Classical): 你好，世界。
    /// - Japanese: こんにちは，世界。
    /// - Other languages (English, Korean, etc.): Hello, world.
    private func usesChinesePunctuation(_ language: Language) -> Bool {
        switch language {
        case .classicalChinese, .japanese, .simplifiedChinese, .traditionalChinese:
            return true
        default:
            return false
        }
    }

    /// Normalize punctuation to Western style (used by English, Korean, and most languages)
    /// Converts full-width Chinese punctuation to half-width Western equivalents
    /// Examples of transformations:
    /// - "Hello，world。" → "Hello, world."
    /// - "Test；right？Yes！" → "Test; right? Yes!"
    /// - "（括号）【方括号】" → "(brackets) [square brackets]"
    private func normalizeToWesternPunctuation(_ text: String) -> String {
        var result = text

        // Chinese punctuation → Western punctuation mappings with examples
        let punctuationMappings: [String: String] = [
            "，": ",", // Chinese comma → Western comma: "你好，世界" → "你好, 世界"
            "。": ".", // Chinese period → Western period: "结束。" → "结束."
            "；": ";", // Chinese semicolon → Western semicolon: "第一；第二" → "第一; 第二"
            "：": ":", // Chinese colon → Western colon: "注意：重要" → "注意: 重要"
            "？": "?", // Chinese question mark → Western question mark: "什么？" → "什么?"
            "！": "!", // Chinese exclamation → Western exclamation: "太好了！" → "太好了!"
            "（": "(", // Chinese left parenthesis → Western: "（说明）" → "(说明)"
            "）": ")", // Chinese right parenthesis → Western: "（说明）" → "(说明)"
            "【": "[", // Chinese left bracket → Western: "【重要】" → "[重要]"
            "】": "]", // Chinese right bracket → Western: "【重要】" → "[重要]"
        ]

        for (chinese, western) in punctuationMappings {
            result.replace(chinese, with: western)
        }

        // Note: Quote normalization has been removed to preserve original formatting
        // Users may prefer to keep various quote styles as-is

        return result
    }

    /// Normalize punctuation to Chinese style (used by Chinese and Japanese)
    /// Converts half-width Western punctuation to full-width Chinese equivalents
    /// Carefully preserves decimal numbers to avoid breaking numeric values
    /// Examples of transformations:
    /// - "你好, 世界." → "你好，世界。"
    /// - "Test; right? Yes!" → "Test；right？Yes！"
    /// - "(括号)" → "（括号）"
    /// - "Price: 10.99" → "Price：10.99" (decimal preserved)
    private func normalizeToChinesePunctuation(_ text: String) -> String {
        var result = text

        // First, protect English contexts that should not be converted
        let protectedRanges = findProtectedRanges(in: result)

        // Replace protected content with placeholders (in reverse order to maintain indices)
        var placeholders: [String: String] = [:]
        for (index, range) in protectedRanges.enumerated().reversed() {
            let placeholder = "〈PROTECTED_\(index)〉"
            let originalContent = String(result[range.1])
            placeholders[placeholder] = originalContent
            result.replaceSubrange(range.1, with: placeholder)
        }

        // Western punctuation → Chinese punctuation mappings with examples
        let punctuationMappings: [String: String] = [
            ",": "，", // Western comma → Chinese comma: "你好, 世界" → "你好，世界"
            ".": "。", // Western period → Chinese period: "结束." → "结束。" (but preserve decimals)
            ";": "；", // Western semicolon → Chinese semicolon: "第一; 第二" → "第一；第二"
            ":": "：", // Western colon → Chinese colon: "注意: 重要" → "注意：重要"
            "?": "？", // Western question mark → Chinese question mark: "什么?" → "什么？"
            "!": "！", // Western exclamation → Chinese exclamation: "太好了!" → "太好了！"
            "(": "（", // Western left parenthesis → Chinese: "(说明)" → "（说明）"
            ")": "）", // Western right parenthesis → Chinese: "(说明)" → "（说明）"
        ]

        for (western, chinese) in punctuationMappings {
            // Be more careful with period - don't replace if it's part of a decimal number or ellipsis
            if western == "." {
                // Protect decimal numbers first, then replace periods, then restore
                // Example: "End." → "End。" but "10.99" remains "10.99"
                result.replace(/(\d)\.(\d)/) { match in
                    "\(match.1)〈DECIMAL〉\(match.2)"
                }

                // Protect code patterns: array.map, file.txt, 3.14
                result.replace(/([a-zA-Z0-9_])\.([a-zA-Z0-9_])/) { match in
                    "\(match.1)〈DOT〉\(match.2)"
                }

                // Protect ellipsis (three consecutive dots) - this must be done BEFORE converting periods
                // Example: "wait..." → "wait〈ELLIPSIS〉" to prevent "wait。。。"
                result.replace("...", with: "〈ELLIPSIS〉")

                // Now safely replace standalone periods
                result.replace(".", with: chinese)

                // Restore all protected patterns from placeholders
                result.replace("〈DECIMAL〉", with: ".")
                result.replace("〈DOT〉", with: ".")
                result.replace("〈ELLIPSIS〉", with: "...")
            } else {
                result.replace(western, with: chinese)
            }
        }

        // Restore protected content
        for (placeholder, original) in placeholders {
            result.replace(placeholder, with: original)
        }

        return result
    }

    /// Find ranges that should be protected from Chinese punctuation conversion
    /// These include URLs, email addresses, file paths, and other English-specific content
    private func findProtectedRanges(in text: String) -> [(Int, Range<String.Index>)] {
        var ranges: [Range<String.Index>] = []

        // Protect URLs (http://, https://, ftp://, etc.)
        let urlRegex = /https?:\/\/[^\s\u4e00-\u9fff]+/
        for match in text.matches(of: urlRegex) {
            ranges.append(match.range)
        }

        // Protect domain names without protocol (e.g., easydict.app, google.com)
        let domainRegex = /[a-zA-Z0-9-]+\.[a-zA-Z]{2,}(?:\.[a-zA-Z]{2,})?/
        for match in text.matches(of: domainRegex) {
            ranges.append(match.range)
        }

        // Protect email addresses
        let emailRegex = /[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/
        for match in text.matches(of: emailRegex) {
            ranges.append(match.range)
        }

        // Protect file paths and extensions
        let filePathRegex = /[a-zA-Z]:[\\\/][^\s\u4e00-\u9fff]+/
        for match in text.matches(of: filePathRegex) {
            ranges.append(match.range)
        }

        // Protect programming code patterns (variable.method, object.property)
        let codeRegex = /[a-zA-Z_][a-zA-Z0-9_]*\.[a-zA-Z_][a-zA-Z0-9_]*/
        for match in text.matches(of: codeRegex) {
            ranges.append(match.range)
        }

        // Merge overlapping ranges and sort
        let mergedRanges = mergeOverlappingRanges(ranges)

        // Return ranges with indices
        return mergedRanges.enumerated().map { index, range in
            (index, range)
        }
    }

    /// Merge overlapping ranges to prevent nested placeholders
    private func mergeOverlappingRanges(_ ranges: [Range<String.Index>]) -> [Range<String.Index>] {
        guard !ranges.isEmpty else { return [] }

        let sortedRanges = ranges.sorted { $0.lowerBound < $1.lowerBound }
        var mergedRanges: [Range<String.Index>] = []

        var currentRange = sortedRanges[0]

        for range in sortedRanges.dropFirst() {
            if range.lowerBound <= currentRange.upperBound {
                // Ranges overlap, merge them
                currentRange =
                    currentRange.lowerBound ..< max(currentRange.upperBound, range.upperBound)
            } else {
                // No overlap, add current range and start new one
                mergedRanges.append(currentRange)
                currentRange = range
            }
        }

        // Add the last range
        mergedRanges.append(currentRange)

        return mergedRanges
    }

    /// Fix common formatting issues in OCR text
    /// OCR often produces irregular line breaks and spacing artifacts
    /// This method cleans up these issues while preserving intentional structure
    private func normalizeFormatting(in string: String) -> String {
        var result = string

        // Fix excessive line breaks that OCR sometimes produces
        // Example: "Line1\n\n\n\nLine2" → "Line1\n\nLine2" (max 2 consecutive newlines)
        // Pattern: \n{3,} matches 3 or more consecutive newlines
        result.replace(/\n{3,}/, with: "\n\n")

        // Normalize different line ending styles to Unix format
        // Example: "Line1\r\nLine2\rLine3" → "Line1\nLine2\nLine3"
        result.replace("\r\n", with: "\n") // Windows line endings → Unix
        result.replace("\r", with: "\n") // Classic Mac line endings → Unix

        // Clean up excessive whitespace at line boundaries
        // Example: "Line1   \n   Line2" → "Line1\nLine2"
        result.replace(/\n[ \t]+/, with: "\n") // Remove spaces/tabs after newlines
        result.replace(/[ \t]+\n/, with: "\n") // Remove spaces/tabs before newlines

        return result
    }
}
