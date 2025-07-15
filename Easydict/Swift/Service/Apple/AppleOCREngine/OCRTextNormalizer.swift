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
/// let normalizer = OCRTextNormalizer(language: .english)
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
    /// 1. Protection - safeguard special content (URLs, decimals, code patterns)
    /// 2. Dot symbol normalization - unifies various bullet points and dots
    /// 3. Punctuation normalization - ensures language-appropriate punctuation style
    /// 4. Formatting cleanup - fixes line breaks and excessive spacing
    /// 5. OCR symbol errors - fixes symbol misrecognitions (after punctuation to avoid conflicts)
    /// 6. Spacing normalization - cleans up irregular spacing (done last to handle all changes)
    /// 7. Restoration - restore all protected content
    ///
    /// Example transformation:
    /// Input:  "Hello   •   world，this is a test—with   bad spacing…"
    /// Output: "Hello · world, this is a test-with bad spacing..."
    public func normalizeText(_ string: String) -> String {
        var normalizedText = string
        print("Before normalization: \n\(normalizedText)")

        // 0. FIRST: Protect special content that should never be modified
        let (protectedText, protectionMap) = protectSpecialContent(normalizedText)
        normalizedText = protectedText

        // 1. Apply dot symbol normalization (• → ·)
        normalizedText = replaceSimilarDotSymbol(in: normalizedText)

        // 2. Apply punctuation normalization based on language context (，→ , or , → ，)
        normalizedText = normalizePunctuation(in: normalizedText)

        // 3. Fix common formatting issues (line breaks, excessive spacing)
        normalizedText = normalizeFormatting(in: normalizedText)

        // 4. Normalize common OCR symbol errors (— → -, ´ → ', … → ...)
        // This step comes AFTER punctuation normalization to avoid conflicts
        // For example: "…" → "..." should not be converted to "。。。" in Chinese mode
        normalizedText = normalizeCommonOCRErrors(in: normalizedText)

        // 5. Normalize spacing issues (after all content changes to handle spacing correctly)
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
    ///
    /// This function identifies and temporarily replaces special content with placeholders to prevent
    /// unwanted modifications during text normalization steps. It uses sophisticated regex patterns
    /// to detect various types of content that should remain unchanged.
    ///
    /// **Protected Content Types:**
    /// - **URLs**: `https://example.com` → `〈PROTECTED_0〉`
    /// - **Domain names**: `google.com` → `〈PROTECTED_1〉`
    /// - **Email addresses**: `user@domain.com` → `〈PROTECTED_2〉`
    /// - **File paths**: `C:/Users/file.txt` → `〈PROTECTED_3〉`
    /// - **Code patterns**: `array.map()` → `〈PROTECTED_4〉`
    /// - **Number patterns**: `10.99`, `1.2.3`, `192.168.1.1` → `〈PROTECTED_5〉`
    /// - **Ellipsis**: `...` → `〈PROTECTED_6〉`
    ///
    /// **Smart Punctuation Handling:**
    /// The regex patterns exclude trailing punctuation that might be sentence endings:
    /// - `"Visit https://easydict.app, it's great!"` → URL excludes the comma
    /// - `"Email me at test@example.com."` → Email excludes the period
    /// - `"Version 1.2.3, released today."` → Version excludes the comma
    ///
    /// **Example Input:**
    /// ```
    /// "访问 https://easydict.app, 邮箱 test@example.com. 版本 1.2.3, 价格 $10.99, 代码 array.map()."
    /// ```
    ///
    /// **Example Output:**
    /// ```
    /// protectedText: "访问 〈PROTECTED_0〉, 邮箱 〈PROTECTED_1〉. 版本 〈PROTECTED_2〉, 价格 $〈PROTECTED_3〉, 代码 〈PROTECTED_4〉."
    /// protectionMap: [
    ///   "〈PROTECTED_0〉": "https://easydict.app",
    ///   "〈PROTECTED_1〉": "test@example.com",
    ///   "〈PROTECTED_2〉": "1.2.3",
    ///   "〈PROTECTED_3〉": "10.99",
    ///   "〈PROTECTED_4〉": "array.map()"
    /// ```
    ///
    /// - Parameter text: The original text to scan for special content
    /// - Returns: A tuple containing the protected text with placeholders and a restoration map
    /// protectionMap: [
    ///   "〈PROTECTED_0〉": "https://easydict.app",
    ///   "〈PROTECTED_1〉": "test@example.com",
    ///   "〈PROTECTED_2〉": "10.99",
    ///   "〈PROTECTED_3〉": "array.map()"
    /// ]
    /// ```
    ///
    /// - Parameter text: The original text to scan for special content
    /// - Returns: A tuple containing the protected text with placeholders and a restoration map
    private func protectSpecialContent(_ text: String) -> (String, [String: String]) {
        var result = text
        var protectionMap: [String: String] = [:]
        var protectionIndex = 0

        // Collect all ranges that need protection using optimized regex patterns
        var ranges: [Range<String.Index>] = []

        // Use regex patterns from Regex+Common.swift for consistency and maintainability

        // Protect URLs (http://, https://, ftp://, etc.)
        for match in text.matches(of: Regex.url) {
            ranges.append(match.range)
        }

        // Protect domain names without protocol
        for match in text.matches(of: Regex.domain) {
            ranges.append(match.range)
        }

        // Protect email addresses
        for match in text.matches(of: Regex.email) {
            ranges.append(match.range)
        }

        // Protect file paths and extensions
        for match in text.matches(of: Regex.filePath) {
            ranges.append(match.range)
        }

        // Protect programming code patterns
        for match in text.matches(of: Regex.codePattern) {
            ranges.append(match.range)
        }

        // Protect function call patterns
        for match in text.matches(of: Regex.functionCall) {
            ranges.append(match.range)
        }

        // Protect parentheses that are adjacent to alphanumeric characters
        for match in text.matches(of: Regex.adjacentParentheses) {
            ranges.append(match.range)
        }

        // Protect decimal numbers and version numbers
        for match in text.matches(of: Regex.numberLikePattern) {
            ranges.append(match.range)
        }

        // Protect ellipsis
        for match in text.matches(of: Regex.ellipsis) {
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

    /// Restore all protected content from placeholders back to original text
    ///
    /// This function is the counterpart to `protectSpecialContent`, restoring all placeholder
    /// tokens back to their original protected content after normalization is complete.
    ///
    /// **Example Restoration:**
    /// ```
    /// Input text: "访问 〈PROTECTED_0〉，邮箱 〈PROTECTED_1〉。价格 $〈PROTECTED_2〉，代码 〈PROTECTED_3〉。"
    /// Protection map: [
    ///   "〈PROTECTED_0〉": "https://easydict.app",
    ///   "〈PROTECTED_1〉": "test@example.com",
    ///   "〈PROTECTED_2〉": "10.99",
    ///   "〈PROTECTED_3〉": "array.map()"
    /// ]
    ///
    /// Output: "访问 https://easydict.app，邮箱 test@example.com。价格 $10.99，代码 array.map()。"
    /// ```
    ///
    /// Note that the surrounding text may have been normalized (e.g., punctuation converted
    /// to Chinese style), but the protected content remains exactly as it was originally.
    ///
    /// - Parameters:
    ///   - text: Text containing placeholder tokens
    ///   - protectionMap: Map of placeholders to their original content
    /// - Returns: Text with all placeholders restored to original content
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
        result.replace(Regex.multipleHorizontalWhitespace, with: " ")

        // Fix spacing around punctuation for English-type languages
        if languageManager.isLanguageWordsNeedSpace(metrics.language) {
            // Fix number patterns FIRST before other punctuation processing
            // This handles spacing patterns in decimals, versions, IPs: "1 . 2 . 3", "10 . 99" -> "1.2.3", "10.99"
            result.replace(Regex.numberPatternWithSpacing) { match in
                // Remove all whitespace around dots in the matched number pattern
                String(match.output).replacingOccurrences(of: " ", with: "").replacingOccurrences(
                    of: "\t", with: "")
            }

            // Remove spaces before punctuation marks (but not line breaks)
            // Example: "Hello , world ." → "Hello, world."
            result.replace(Regex.whitespaceBeforePunctuation) { match in
                "\(match.1)"
            }

            // Add space after punctuation marks if missing (except for number patterns and ellipsis)
            // Example: "Hello,world.Test" → "Hello, world. Test"
            // We need to be careful not to add space after decimal points like "10.99", version numbers like "1.2.3", or ellipsis like "..."
            // Since Swift Regex doesn't support lookbehind, we use a protect-process-restore approach:
            // 1. Temporarily replace dots in number patterns and ellipsis with placeholders
            // 2. Add spaces after punctuation
            // 3. Restore dots in number patterns and ellipsis
            result.replace(Regex.numberLikePattern) { match in
                String(match.output).replacingOccurrences(of: ".", with: "〈NUMBERDOT〉")
            }

            // Protect ellipsis (three consecutive dots)
            result.replace("...", with: "〈ELLIPSIS〉")

            // Now safely add spaces after punctuation
            result.replace(Regex.punctuationWithoutSpace) { match in
                "\(match.1) \(match.2)"
            }

            // Restore dots in number patterns and ellipsis from placeholders
            result.replace("〈NUMBERDOT〉", with: ".")
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
            return result.replacing(Regex.multipleHorizontalWhitespace, with: " ")
        }

        return string
    }

    /// Normalize common OCR recognition errors for symbols
    /// OCR systems frequently misidentify special characters and symbols
    ///
    /// This step is performed AFTER punctuation normalization to avoid conflicts:
    /// - Example: "…" → "..." should not become "。。。" in Chinese mode
    /// - Ensures dash normalization doesn't interfere with punctuation style choices
    ///
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
        result.replace(Regex.lowercaseLAsI, with: "I")

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
            "［": "[", // Chinese left square bracket → Western: "【重要】" → "[重要]"
            "】": "]", // Chinese right bracket → Western: "【重要】" → "[重要]"
            "］": "]", // Chinese right square bracket → Western: "【重要】" → "[重要]"
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
    /// Special content is already protected by the main normalization pipeline
    /// Examples of transformations:
    /// - "你好, 世界." → "你好，世界。"
    /// - "Test; right? Yes!" → "Test；right？Yes！"
    /// - "(括号)" → "（括号）"
    /// - Protected content like URLs, decimals remain unchanged
    private func normalizeToChinesePunctuation(_ text: String) -> String {
        var result = text

        // Western punctuation → Chinese punctuation mappings
        // Special content is already protected in the main pipeline, so we can safely transform
        let punctuationMappings: [String: String] = [
            ",": "，", // Western comma → Chinese comma: "你好, 世界" → "你好，世界"
            ".": "。", // Western period → Chinese period: "结束." → "结束。"
            ";": "；", // Western semicolon → Chinese semicolon: "第一; 第二" → "第一；第二"
            ":": "：", // Western colon → Chinese colon: "注意: 重要" → "注意：重要"
            "?": "？", // Western question mark → Chinese question mark: "什么?" → "什么？"
            "!": "！", // Western exclamation → Chinese exclamation: "太好了!" → "太好了！"
            "(": "（", // Western left parenthesis → Chinese: "(说明)" → "（说明）"
            ")": "）", // Western right parenthesis → Chinese: "(说明)" → "（说明）"
        ]

        // Apply punctuation transformations
        // Protected content (URLs, decimals, code patterns, etc.) is already replaced with placeholders
        for (western, chinese) in punctuationMappings {
            result.replace(western, with: chinese)
        }

        return result
    }

    /// Merge overlapping ranges to prevent nested placeholders and ensure clean protection
    ///
    /// When multiple regex patterns match overlapping text segments, this function consolidates
    /// them into non-overlapping ranges to avoid conflicts during placeholder replacement.
    ///
    /// **Problem it solves:**
    /// - `array.map()` matches both code pattern regex and function call regex
    /// - `test@example.com` might overlap with domain pattern if not handled carefully
    /// - Without merging, we could get nested placeholders like `〈PROTECTED_1〉PROTECTED_2〉`
    ///
    /// **Example:**
    /// ```
    /// Input ranges for "Visit test@example.com for array.map() info":
    /// [
    ///   6..<21  (test@example.com - email pattern)
    ///   12..<21 (example.com - domain pattern)
    ///   26..<37 (array.map() - code pattern)
    ///   26..<39 (array.map() - function call pattern)
    /// ]
    ///
    /// After merging:
    /// [
    ///   6..<21  (test@example.com - merged email/domain)
    ///   26..<39 (array.map() - merged code/function)
    /// ]
    /// ```
    ///
    /// **Algorithm:**
    /// 1. Sort ranges by start position
    /// 2. Iterate and merge ranges that overlap or touch
    /// 3. Return consolidated non-overlapping ranges
    ///
    /// - Parameter ranges: Array of potentially overlapping string ranges
    /// - Returns: Array of merged, non-overlapping ranges sorted by position
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
        result.replace(Regex.excessiveNewlines, with: "\n\n")

        // Normalize different line ending styles to Unix format
        // Example: "Line1\r\nLine2\rLine3" → "Line1\nLine2\nLine3"
        result.replace("\r\n", with: "\n") // Windows line endings → Unix
        result.replace("\r", with: "\n") // Classic Mac line endings → Unix

        // Clean up excessive whitespace at line boundaries
        // Example: "Line1   \n   Line2" → "Line1\nLine2"
        result.replace(Regex.whitespaceAfterNewline, with: "\n") // Remove spaces/tabs after newlines
        result.replace(Regex.whitespaceBeforeNewline, with: "\n") // Remove spaces/tabs before newlines

        return result
    }
}
