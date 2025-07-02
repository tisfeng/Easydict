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
/// let metrics = OCRMetrics()
/// metrics.language = .english
/// let normalizer = OCRTextNormalizer(metrics: metrics)
/// let cleanText = normalizer.normalizeTextSymbols(in: messyOCRText)
/// ```
public class OCRTextNormalizer {
    // MARK: Lifecycle

    /// Initialize with OCR metrics for language-specific processing
    init(metrics: OCRMetrics) {
        self.metrics = metrics
    }

    // MARK: Public

    /// Normalize and replace various text symbols for better readability and consistency
    /// This is the main entry point that orchestrates all text normalization steps in optimal order
    ///
    /// Processing pipeline:
    /// 1. Dot symbol normalization - unifies various bullet points and dots
    /// 2. Common OCR errors - fixes symbol misrecognitions
    /// 3. Punctuation normalization - ensures language-appropriate punctuation style
    /// 4. Formatting cleanup - fixes line breaks and hyphenation
    /// 5. Spacing normalization - cleans up irregular spacing (done last to handle punctuation changes)
    ///
    /// Example transformation:
    /// Input:  "Hello   •   world，this is a test—with   bad spacing ．"
    /// Output: "Hello · world, this is a test-with bad spacing."
    public func normalizeTextSymbols(in string: String) -> String {
        var normalizedText = string
        print("Before normalization: \(normalizedText)")

        // 1. Apply dot symbol normalization (• → ·)
        normalizedText = replaceSimilarDotSymbol(in: normalizedText)

        // 2. Normalize common OCR symbol errors (— → -, ° → o, etc.)
        normalizedText = normalizeCommonOCRErrors(in: normalizedText)

        // 3. Apply punctuation normalization based on language context (，→ , or , → ，)
        normalizedText = normalizePunctuation(in: normalizedText)

        // 4. Fix common formatting issues (line breaks, hyphenation)
        normalizedText = normalizeFormatting(in: normalizedText)

        // 5. Normalize spacing issues (after punctuation changes to handle new spacing correctly)
        normalizedText = normalizeSpacing(in: normalizedText)

        print("After normalization: \(normalizedText)")

        return normalizedText
    }

    // MARK: Internal

    let metrics: OCRMetrics

    // MARK: Private

    private let languageManager = EZLanguageManager.shared()

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
            // This handles all decimal spacing patterns: "10 . 99", "10. 99", "10 .99"
            // Pattern: (\d)[ \t]*\.[ \t]*(\d) matches digit + optional spaces + dot + optional spaces + digit
            result.replace(/(\d)[ \t]*\.[ \t]*(\d)/) { match in
                "\(match.1).\(match.2)"
            }

            // Remove spaces before punctuation marks (but not line breaks)
            // Example: "Hello , world ." → "Hello, world."
            // Pattern: [ \t]+([,.;:!?)]) matches spaces/tabs before punctuation
            result.replace(/[ \t]+([,.;:!?)])/) { match in
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
            result.replace(/([,.;:!?)])([^\s])/) { match in
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
    private func normalizeCommonOCRErrors(in string: String) -> String {
        var result = string

        // Common OCR misrecognitions with specific examples:
        let symbolMappings: [String: String] = [
            // Quote-like characters that are often misrecognized
            "`": "'", // Backtick → apostrophe: "`hello`" → "'hello'"
            "´": "'", // Acute accent → apostrophe: "don´t" → "don't"
            "\u{201C}": "\"", // Curved left quote → straight quote: ""hello"" → "\"hello\""
            "\u{201D}": "\"", // Curved right quote → straight quote: ""world"" → "\"world\""
            "\u{2018}": "'", // Curved left single quote → apostrophe: "'test'" → "'test'"
            "\u{2019}": "'", // Curved right single quote → apostrophe: "'word'" → "'word'"

            // Dash variations that OCR confuses
            "—": "-", // Em dash → hyphen: "hello—world" → "hello-world"
            "–": "-", // En dash → hyphen: "pages 1–10" → "pages 1-10"
            "―": "-", // Horizontal bar → hyphen: "test―case" → "test-case"

            // Mathematical and special symbols commonly misread
            "°": "o", // Degree symbol → letter o: "98°F" → "98oF"
            "×": "x", // Multiplication sign → letter x: "2×3" → "2x3"
            "÷": "/", // Division sign → slash: "6÷2" → "6/2"
            "…": "...", // Ellipsis → three dots: "wait…" → "wait..."

            // Currency and special symbols
            "￠": "¢", // Alternative cent symbol → standard cent
            "£": "£", // Keep pound sign as is but normalize encoding
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

        // Handle quotes separately using Unicode escape sequences
        // Examples: "引用" → "引用", '单引号' → 'single quotes'
        result.replace("\u{201C}", with: "\"") // Chinese left quote: " → "
        result.replace("\u{201D}", with: "\"") // Chinese right quote: " → "
        result.replace("\u{2018}", with: "'") // Chinese left single quote: ' → '
        result.replace("\u{2019}", with: "'") // Chinese right single quote: ' → '

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
            // Be more careful with period - don't replace if it's part of a decimal number
            if western == "." {
                // Protect decimal numbers first, then replace periods, then restore
                // Example: "End." → "End。" but "10.99" remains "10.99"
                result.replace(/(\d)\.(\d)/) { match in
                    "\(match.1)〈DECIMAL〉\(match.2)"
                }

                // Now safely replace standalone periods
                result.replace(".", with: chinese)

                // Restore decimal points
                result.replace("〈DECIMAL〉", with: ".")
            } else {
                result.replace(western, with: chinese)
            }
        }

        return result
    }

    /// Fix common formatting issues in OCR text
    /// OCR often produces irregular line breaks, spacing, and formatting artifacts
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

        // Fix hyphenated words split across lines (for English-type languages)
        if languageManager.isLanguageWordsNeedSpace(metrics.language) {
            // Remove hyphen at end of line followed by newline and lowercase letter
            // Example: "reconnect-\ning" → "reconnecting", "self-\ncontained" → "selfcontained"
            // Pattern: -\s*\n\s*([a-z]) matches hyphen + optional spaces + newline + optional spaces + lowercase
            result.replace(/-\s*\n\s*([a-z])/) { match in
                "\(match.1)"
            }
        }

        // Clean up excessive whitespace at line boundaries
        // Example: "Line1   \n   Line2" → "Line1\nLine2"
        result.replace(/\n[ \t]+/, with: "\n") // Remove spaces/tabs after newlines
        result.replace(/[ \t]+\n/, with: "\n") // Remove spaces/tabs before newlines

        return result
    }
}
