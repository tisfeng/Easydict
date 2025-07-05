//
//  AppleLanguageDetector.swift
//  Easydict
//
//  Created by tisfeng on 2025/6/22.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation
import NaturalLanguage

// MARK: - AppleLanguageDetector

/// Advanced language detection using Apple's NaturalLanguage framework with intelligent corrections
///
/// Addresses common issues with raw Apple detection, especially for short text and mixed content.
/// Features smart post-processing, Chinese type intelligence, and user preference integration.
///
/// **Key Features:**
/// - Weighted language hints with user preference boost
/// - Hierarchical post-processing: Chinese/English verification → Mixed content → Short text corrections
/// - Accurate Chinese simplified/traditional detection
/// - Mixed script analysis with recursive detection
/// - User preferred language fallback for ambiguous cases
///
/// **Usage:**
/// ```swift
/// let detector = AppleLanguageDetector()
///
/// // Basic detection
/// let language = detector.detectLanguage(text: "apple")  // Returns .english instead of .turkish
/// let chinese = detector.detectLanguage(text: "很棒")    // Returns .simplifiedChinese accurately
///
/// // Mixed content handling
/// let mixed1 = detector.detectLanguage(text: "Hello world with one 中文 word")  // Returns .english
/// let mixed2 = detector.detectLanguage(text: "apple苹果")  // Returns .simplifiedChinese
///
/// // With logging for debugging
/// let result = detector.detectLanguage(text: "Hello world")
/// ```
///
/// **Performance Characteristics:**
/// - Minimal overhead over raw Apple detection (~1-2ms additional processing)
/// - Simplified post-processing pipeline for better maintainability
/// - Optimized for both short and long text scenarios
@objc
public class AppleLanguageDetector: NSObject {
    // MARK: Public

    /// Detect the most likely language of the provided text
    ///
    /// Primary interface for language detection with intelligent corrections
    /// for common misdetection cases and user preference consideration.
    ///
    /// - Parameter text: Text to analyze for language detection
    /// - Returns: Most likely Language enum value (.auto for empty text)
    @objc
    public func detectLanguage(text: String) -> Language {
        // Handle empty or whitespace-only text
        if text.isEmpty || text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .auto
        }

        let languageProbabilityDict = detectLanguageDict(text: text)
        let mostConfidentLanguage = getMostConfidentLanguage(
            languageProbabilityDict,
            text: text
        )

        return mostConfidentLanguage
    }

    /// Get detailed language detection probabilities for analysis and debugging
    ///
    /// Returns probability distribution from Apple's language detection system.
    /// Useful for debugging detection issues and analyzing confidence levels.
    ///
    /// - Parameter text: Text to analyze for language probabilities
    /// - Returns: Dictionary mapping BCP-47 language codes to probability values (0.0-1.0)
    @objc
    public func detectLanguageDict(text: String) -> [String: NSNumber] {
        let startTime = CFAbsoluteTimeGetCurrent()

        let recognizer = NLLanguageRecognizer()
        recognizer.languageConstraints = AppleLanguageMapper.shared.recognizedLanguages
        recognizer.languageHints = customLanguageHints
        recognizer.processString(text)

        let probabilities = recognizer.languageHypotheses(withMaximum: 10)
        let dominantLanguage = recognizer.dominantLanguage

        let endTime = CFAbsoluteTimeGetCurrent()

        print("Language probabilities: \(probabilities.prettyPrinted)\n")
        print("Dominant language: \(dominantLanguage?.rawValue ?? "nil")")
        print("Detection cost: \(String(format: "%.1f", (endTime - startTime) * 1000)) ms")

        // Convert to String keys for Objective-C compatibility
        var result: [String: NSNumber] = [:]
        for (key, value) in probabilities {
            result[key.rawValue] = NSNumber(value: value)
        }

        return result
    }

    // MARK: Private

    /// Shared language mapper for converting between Apple NLLanguage and Easydict Language enums
    private let languageMapper = AppleLanguageMapper.shared

    /// Custom language hints for improving detection accuracy
    ///
    /// Combines base probability weights with user preference boost.
    /// High weights for common/misdetected languages, lower for distinct patterns.
    /// User preferred languages get +1.0 boost for better UX.
    /// - Helps with "apple" → "en" instead of "tr" problem
    private var customLanguageHints: [NLLanguage: Double] {
        // Base language weights optimized for balanced accuracy
        var customHints: [NLLanguage: Double] = [
            // High priority languages (commonly misdetected or very frequent)
            .english: 2.0, // Reduced from 3.0: Still boosted but not overwhelming
            .simplifiedChinese: 1.5, // Reduced from 2.5: Still prioritized
            .traditionalChinese: 1.0, // Keep as reference point

            // Major Asian languages
            .japanese: 0.8, // 門 Reduced from 1.2: Should detect `Traditional Chinese` properly
            .korean: 0.7, // Increased from 0.6: Should detect Korean properly

            // Major European languages (often confused with each other)
            .french: 0.8, // Increased from 0.5: Better French detection
            .spanish: 0.8, // Increased from 0.5: Better Spanish detection
            .italian: 0.7, // Increased from 0.4: Better Italian detection
            .portuguese: 0.7, // Increased from 0.4: Better Portuguese detection
            .german: 0.6, // Increased from 0.3: Better German detection
            .dutch: 0.4, // Increased from 0.25: Better Dutch detection

            // Other European languages
            .russian: 0.8, // Increased from 0.4: Cyrillic script
            .polish: 0.4, // Increased from 0.2: Latin script but distinct
            .czech: 0.3, // Increased from 0.15: Latin script but distinct
            .turkish: 0.08, // Further reduced from 0.2: Often causes false positives
            .catalan: 0.1, // Reduced from 0.15: Often confused with Spanish/French

            // Middle Eastern and others
            .arabic: 0.3, // Distinct script
            .persian: 0.2, // Similar to Arabic but less common
            .thai: 0.3, // Distinct script
            .vietnamese: 0.25, // Latin script with diacritics
            .hindi: 0.2, // Devanagari script

            // Nordic languages
            .swedish: 0.15,
            .danish: 0.15,
            .norwegian: 0.15,
            .finnish: 0.1, // Different language family

            // Less common but supported
            .ukrainian: 0.3, // Cyrillic, similar to Russian
            .bulgarian: 0.15, // Cyrillic
            .romanian: 0.2, // Romance language
            .hungarian: 0.05, // Reduced: Unique language family but often causes false positives
            .greek: 0.2, // Distinct script
            .slovak: 0.05, // Reduced: Similar to Czech, often causes false positives
            .croatian: 0.1, // Reduced: Latin script, can cause confusion
            .indonesian: 0.1, // Reduced: Latin script, can be confused with English
            .malay: 0.08, // Reduced: Similar to Indonesian
        ]

        // Get user preferred languages and boost their weights
        let preferredLanguages = EZLanguageManager.shared().preferredLanguages
        let preferredNLLanguages = preferredLanguages.compactMap { language in
            languageMapper.appleLanguagesDictionary[language]
        }

        // Boost preferred languages
        for preferredLanguage in preferredNLLanguages {
            if let currentWeight = customHints[preferredLanguage] {
                // Add boost based on current weight tier
                let boost: Double = currentWeight >= 2.0 ? 1.5 : 1.0
                customHints[preferredLanguage] = currentWeight + boost
            } else {
                // New preferred language not in base hints
                customHints[preferredLanguage] = 1.0
            }
        }

        // Set default weight for any remaining supported languages
        let supportedLanguages = languageMapper.recognizedLanguages
        for language in supportedLanguages where !customHints.keys.contains(language) {
            customHints[language] = 0.05 // Lower default to avoid false positives
        }

        return customHints
    }

    /// Get the most confident language with intelligent post-processing
    ///
    /// Combines ML probability scores, user preference weighting, and post-processing
    /// corrections for common misdetection cases.
    ///
    /// - Parameters:
    ///   - languageProbabilities: Raw probabilities from NL framework
    ///   - text: Original text for pattern analysis
    /// - Returns: Final detected language after all corrections
    private func getMostConfidentLanguage(
        _ languageProbabilities: [String: NSNumber],
        text: String
    )
        -> Language {
        // Handle empty results (e.g., numeric-only text like "729")
        guard !languageProbabilities.isEmpty else {
            return detectFallbackLanguage(for: text)
        }

        // Apply user preferred language weight correction
        let adjustedProbabilities = applyUserPreferredLanguageWeights(
            to: languageProbabilities
        )

        // Find the language with highest probability after user preference adjustment
        let sortedLanguages = adjustedProbabilities.sorted {
            $0.value.doubleValue > $1.value.doubleValue
        }

        guard let mostConfident = sortedLanguages.first else {
            return detectFallbackLanguage(for: text)
        }

        let topConfidence = mostConfident.value.doubleValue
        let nlLanguage = NLLanguage(rawValue: mostConfident.key)
        var detectedLanguage = languageMapper.languageEnum(from: nlLanguage)

        // Apply post-processing corrections for common misdetection cases
        detectedLanguage = applyPostProcessingCorrections(
            detectedLanguage: detectedLanguage,
            confidence: topConfidence,
            text: text,
            allProbabilities: adjustedProbabilities
        )

        print("Final detected text: \(text)")
        print(
            "Detected language: \(detectedLanguage) (\(String(format: "%.3f", topConfidence)))"
        )

        return detectedLanguage
    }

    /// Internal language detection method with recursion depth control
    ///
    /// Used by mixed-script analysis for recursive detection of non-English portions.
    /// Prevents infinite recursion with depth limit.
    ///
    /// - Parameters:
    ///   - text: Text to analyze for language detection
    ///   - recursionDepth: Current recursion depth (max 2)
    /// - Returns: Detected language or .auto for empty text
    private func detectLanguageInternal(
        text: String,
        recursionDepth: Int
    )
        -> Language {
        // Handle empty or whitespace-only text
        if text.isEmpty || text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .auto
        }

        let languageProbabilityDict = detectLanguageDict(text: text)
        let mostConfidentLanguage = getMostConfidentLanguageInternal(
            languageProbabilityDict,
            text: text,
            recursionDepth: recursionDepth
        )

        return mostConfidentLanguage
    }

    /// Internal method for getting most confident language with recursion depth control
    ///
    /// Similar to getMostConfidentLanguage but includes recursion depth tracking
    /// for mixed-script analysis scenarios.
    ///
    /// - Parameters:
    ///   - languageProbabilities: Raw probabilities from NL framework
    ///   - text: Original text for pattern analysis
    ///   - recursionDepth: Current recursion depth
    /// - Returns: Final detected language after corrections
    private func getMostConfidentLanguageInternal(
        _ languageProbabilities: [String: NSNumber],
        text: String,
        recursionDepth: Int
    )
        -> Language {
        // Handle empty results (e.g., numeric-only text like "729")
        guard !languageProbabilities.isEmpty else {
            return detectFallbackLanguage(for: text)
        }

        // Apply user preferred language weight correction
        let adjustedProbabilities = applyUserPreferredLanguageWeights(
            to: languageProbabilities
        )

        // Find the language with highest probability after user preference adjustment
        let sortedLanguages = adjustedProbabilities.sorted {
            $0.value.doubleValue > $1.value.doubleValue
        }

        guard let mostConfident = sortedLanguages.first else {
            return detectFallbackLanguage(for: text)
        }

        let topConfidence = mostConfident.value.doubleValue
        let nlLanguage = NLLanguage(rawValue: mostConfident.key)
        var detectedLanguage = languageMapper.languageEnum(from: nlLanguage)

        // Apply post-processing corrections for common misdetection cases
        detectedLanguage = applyPostProcessingCorrectionsInternal(
            detectedLanguage: detectedLanguage,
            confidence: topConfidence,
            text: text,
            allProbabilities: adjustedProbabilities,
            recursionDepth: recursionDepth
        )

        print(
            "Final detected language: \(detectedLanguage) (confidence: \(String(format: "%.3f", topConfidence)))"
        )

        return detectedLanguage
    }

    /// Apply user preferred language weight correction to detected probabilities
    ///
    /// Only affects languages that appear in detection results, preventing artificial
    /// promotion of undetected languages. Preferred languages get +0.1 to +0.4 boost.
    ///
    /// - Parameter languageProbabilities: Original detection probabilities from Apple NL
    /// - Returns: Adjusted probabilities with user preference weights applied
    private func applyUserPreferredLanguageWeights(
        to languageProbabilities: [String: NSNumber]
    )
        -> [String: NSNumber] {
        var adjustedProbabilities = languageProbabilities
        let preferredLanguages = EZLanguageManager.shared().preferredLanguages

        print("Original probabilities: \(languageProbabilities.prettyPrinted)")

        // Apply user preferred language weights
        for (index, preferredLanguage) in preferredLanguages.enumerated() {
            // Convert to Apple NLLanguage
            guard let nlLanguage = languageMapper.appleLanguagesDictionary[preferredLanguage],
                  let originalProbability = languageProbabilities[nlLanguage.rawValue]
            else {
                continue // Only boost languages that were actually detected
            }

            // Calculate weight boost based on preference position
            let maxWeight = 0.4
            let step = 0.1
            var weightBoost = maxWeight - Double(index) * step
            if weightBoost < 0.1 {
                weightBoost = 0.1
            }

            // Additional boost for English based on user's first language
            if preferredLanguage == .english {
                let isChineseFirst = EZLanguageManager.shared().isUserChineseFirstLanguage()
                weightBoost += isChineseFirst ? 0.1 : 0.2
            }

            // Apply the weight boost
            let newProbability = originalProbability.doubleValue + weightBoost
            adjustedProbabilities[nlLanguage.rawValue] = NSNumber(value: newProbability)
        }

        // Add English boost if not in user preferences (widely used language)
        if !preferredLanguages.contains(.english),
           let englishProbability = languageProbabilities[NLLanguage.english.rawValue] {
            let englishBoost = 0.2
            let newProbability = englishProbability.doubleValue + englishBoost
            adjustedProbabilities[NLLanguage.english.rawValue] = NSNumber(value: newProbability)
        }

        print("User preferred languages: \(preferredLanguages.prettyPrinted)")
        print("Adjusted probabilities: \(adjustedProbabilities.prettyPrinted)")

        return adjustedProbabilities
    }

    /// Apply intelligent post-processing corrections for common misdetection cases
    ///
    /// Public interface to post-processing pipeline. Delegates to internal method
    /// with recursion depth tracking.
    ///
    /// - Parameters:
    ///   - detectedLanguage: Language detected by ML system
    ///   - confidence: Detection confidence score (0.0-1.0)
    ///   - text: Original input text
    ///   - allProbabilities: All language probabilities from detection
    /// - Returns: Corrected language after post-processing
    private func applyPostProcessingCorrections(
        detectedLanguage: Language,
        confidence: Double,
        text: String,
        allProbabilities: [String: NSNumber]
    )
        -> Language {
        applyPostProcessingCorrectionsInternal(
            detectedLanguage: detectedLanguage,
            confidence: confidence,
            text: text,
            allProbabilities: allProbabilities,
            recursionDepth: 0
        )
    }

    /// Simplified post-processing with intelligent language-specific handling
    ///
    /// Three-tier priority system for corrections:
    /// 1. Chinese type verification (simplified vs traditional)
    /// 2. Mixed content detection and analysis
    /// 3. Short text and obvious misdetection corrections
    ///
    /// - Parameters:
    ///   - detectedLanguage: Language detected by ML system
    ///   - confidence: Detection confidence score (0.0-1.0)
    ///   - text: Original input text
    ///   - allProbabilities: All language probabilities from detection
    ///   - recursionDepth: Current recursion depth for mixed-script analysis
    /// - Returns: Corrected language after all post-processing steps
    private func applyPostProcessingCorrectionsInternal(
        detectedLanguage: Language,
        confidence: Double,
        text: String,
        allProbabilities: [String: NSNumber],
        recursionDepth: Int
    )
        -> Language {
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Early return for edge cases
        if cleanText.isEmpty {
            return .auto
        }

        // Priority 1: Handle detected Chinese with intelligent verification
        if detectedLanguage.isChinese {
            return determineChineseType(for: cleanText)
        }

        // Priority 2: Handle common misdetections with mixed content
        if let correctedLanguage = handleMixedContentDetection(
            detectedLanguage: detectedLanguage,
            text: cleanText,
            confidence: confidence,
            recursionDepth: recursionDepth
        ) {
            return correctedLanguage
        }

        // Priority 3: Handle obviously wrong detections for short text
        if let correctedLanguage = handleShortTextCorrections(
            detectedLanguage: detectedLanguage,
            text: cleanText,
            confidence: confidence,
            allProbabilities: allProbabilities
        ) {
            return correctedLanguage
        }

        // Default: trust the original detection
        return detectedLanguage
    }

    /// Detect fallback language for edge cases
    ///
    /// Handles scenarios where Apple's NL framework returns empty results,
    /// typically for numeric-only text or unrecognizable input.
    ///
    /// - Parameter text: Input text that failed normal detection
    /// - Returns: .english as safe fallback for most cases
    private func detectFallbackLanguage(for text: String) -> Language {
        // Check if numeric-only
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isNumericText {
            // For numeric text, default to English (simpler and more predictable)
            return .english
        }

        // For other edge cases, default to English
        return .english
    }

    /// Analyze mixed script text to determine dominant language
    ///
    /// Uses character ratio analysis and recursive detection for mixed English + other language scenarios.
    ///
    /// Examples: "apple苹果" → .simplifiedChinese, "Hello world 中文" → .english
    private func analyzeMixedScriptText(_ text: String, currentDetection: Language) -> Language {
        analyzeMixedScriptText(text, currentDetection: currentDetection, recursionDepth: 0)
    }

    /// Internal method with recursion depth control
    private func analyzeMixedScriptText(
        _ text: String, currentDetection: Language, recursionDepth: Int
    )
        -> Language {
        // Prevent infinite recursion
        guard recursionDepth < 2 else {
            return currentDetection
        }

        // If current detection is English but English is not dominant,
        // try to detect the non-English portion
        if currentDetection == .english {
            // Calculate English ratio to determine dominance
            let englishWordCount = text.englishWordCount

            let nonEnglishText = removeEnglishCharacters(from: text)
            let pureWordText = nonEnglishText.removingPunctuationCharacters()
                .removingWhitespaceAndNewlines()
            let nonEnglishWordCount = pureWordText.count

            // If English words are more than non-English, return English
            if englishWordCount > nonEnglishWordCount {
                return .english
            }

            let trimmedNonEnglish = nonEnglishText.trimmingCharacters(in: .whitespacesAndNewlines)

            if trimmedNonEnglish.count >= 2 {
                let nonEnglishLanguage = detectLanguageInternal(
                    text: trimmedNonEnglish, recursionDepth: recursionDepth + 1
                )

                if nonEnglishLanguage != .english, nonEnglishLanguage != .auto {
                    return nonEnglishLanguage
                }
            }
        }

        // For other cases, trust the original detection
        return currentDetection
    }

    /// Remove English alphabetic characters while preserving other languages
    ///
    /// Filters out ASCII English letters (a-z, A-Z) while keeping:
    /// - Non-Latin scripts (Chinese, Japanese, Korean, Arabic, Cyrillic, etc.)
    /// - Latin characters with diacritics (café, naïve, español)
    /// - Numbers, punctuation, and whitespace
    ///
    /// Used for mixed-script analysis to isolate non-English content for recursive detection.
    ///
    /// Examples: "apple苹果" → "苹果", "Hello 你好" → "你好"
    ///
    /// - Parameter text: Input text containing mixed languages
    /// - Returns: Text with English letters removed, trimmed of excess whitespace
    private func removeEnglishCharacters(from text: String) -> String {
        // Process character by character to properly filter English content
        var result = ""
        var previousWasSpace = false

        for char in text {
            let charString = String(char)

            // Keep non-English characters
            if !charString.isEnglishAlphabet {
                // Add character, but avoid duplicate spaces
                if char.isWhitespace {
                    if !previousWasSpace, !result.isEmpty {
                        result.append(char)
                        previousWasSpace = true
                    }
                } else {
                    result.append(char)
                    previousWasSpace = false
                }
            } else {
                // Skip English characters, but maintain spacing
                if !previousWasSpace, !result.isEmpty {
                    previousWasSpace = true
                }
            }
        }

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Determine Chinese type (simplified vs traditional) using character analysis
    ///
    /// Uses the `isSimplifiedChinese` extension for accurate detection, with fallback
    /// to simplified Chinese for ambiguous cases.
    ///
    /// Examples: "很棒" → .simplifiedChinese, "開門" → .traditionalChinese
    ///
    /// - Parameter text: Text containing Chinese characters
    /// - Returns: .simplifiedChinese or .traditionalChinese
    private func determineChineseType(for text: String) -> Language {
        // Extract only Chinese characters for analysis
        let chineseCharacters = text.filter { String($0).isChineseTextByRegex }
        let chineseText = String(chineseCharacters)

        // Handle edge cases
        guard !chineseText.isEmpty else {
            return .simplifiedChinese // Default fallback
        }

        // For very short Chinese text (1-2 characters), be conservative
        if chineseText.count <= 2 {
            // Use the intelligent detection method
            if chineseText.isSimplifiedChinese() {
                return .simplifiedChinese
            } else {
                // Could be traditional or ambiguous, check by conversion
                let simplified = chineseText.toSimplifiedChineseText()
                return simplified == chineseText ? .simplifiedChinese : .traditionalChinese
            }
        }

        // For longer text, use the robust isSimplifiedChinese method
        if chineseText.isSimplifiedChinese() {
            return .simplifiedChinese
        } else {
            return .traditionalChinese
        }
    }

    /// Handle mixed content detection and common misidentifications
    ///
    /// Corrects scenarios where mixed-script text is misdetected, particularly:
    /// - English + Chinese mixed content
    /// - Chinese content misdetected as other languages
    /// - Character ratio analysis for dominance determination
    ///
    /// - Parameters:
    ///   - detectedLanguage: Language detected by ML system
    ///   - text: Input text to analyze
    ///   - confidence: Detection confidence score
    ///   - recursionDepth: Current recursion depth
    /// - Returns: Corrected language if applicable, nil to continue processing
    private func handleMixedContentDetection(
        detectedLanguage: Language,
        text: String,
        confidence: Double,
        recursionDepth: Int
    )
        -> Language? {
        // Handle mixed scripts intelligently
        if text.hasMixedScripts, recursionDepth < 2 {
            return analyzeMixedScriptText(
                text, currentDetection: detectedLanguage, recursionDepth: recursionDepth
            )
        }

        // Handle obvious Chinese content misdetected as other languages
        if !detectedLanguage.isChinese, detectedLanguage != .japanese, detectedLanguage != .korean {
            let chineseCharCount = text.filter { String($0).isChineseTextByRegex }.count
            let englishCharCount = text.filter { String($0).isEnglishAlphabet }.count
            let totalChars = text.count

            if chineseCharCount > 0, totalChars > 0 {
                let chineseRatio = Double(chineseCharCount) / Double(totalChars)
                let englishRatio = Double(englishCharCount) / Double(totalChars)

                // If Chinese content is significant and English is not dominant
                if chineseRatio >= 0.25, englishRatio <= 0.6 {
                    return determineChineseType(for: text)
                }
            }
        }

        return nil
    }

    /// Handle corrections for short text and obvious misdetections
    ///
    /// Applies conservative corrections for edge cases:
    /// - Numeric-heavy text → English
    /// - Short low-confidence Latin text → English (if probability supports it)
    /// - Very short text → User preferred language or English fallback
    ///
    /// - Parameters:
    ///   - detectedLanguage: Language detected by ML system
    ///   - text: Input text to analyze
    ///   - confidence: Detection confidence score
    ///   - allProbabilities: All language probabilities for fallback analysis
    /// - Returns: Corrected language if applicable, nil to trust original detection
    private func handleShortTextCorrections(
        detectedLanguage: Language,
        text: String,
        confidence: Double,
        allProbabilities: [String: NSNumber]
    )
        -> Language? {
        // Handle numeric-heavy text
        if text.isNumericHeavy {
            return .english
        }

        // Handle short text with low confidence
        if confidence < 0.5, text.count <= 10, text.isLatinText {
            if let englishProb = allProbabilities[NLLanguage.english.rawValue],
               englishProb.doubleValue > 0.1 {
                return .english
            }
        }

        // Handle very short text conservatively
        if text.count <= 3 {
            let preferredLanguages = EZLanguageManager.shared().preferredLanguages
            if preferredLanguages.contains(detectedLanguage), confidence > 0.3 {
                return detectedLanguage
            }

            if text.isLatinText {
                return .english
            }
        }

        return nil
    }
}

extension [String: NSNumber] {
    /// Returns a sorted and pretty-printed string representation of the language probabilities
    var prettyPrinted: String {
        let sorttedString = sorted { $0.value.doubleValue > $1.value.doubleValue }
            .map { "\($0.key): \(String(format: "%.3f", $0.value.doubleValue))" }
            .joined(separator: "\n")
        return "\n" + sorttedString
    }
}

// MARK: - Pretty print for [NLLanguage: Double]

extension [NLLanguage: Double] {
    /// Returns a sorted and pretty-printed string representation of the language probabilities
    var prettyPrinted: String {
        let stringDict: [String: NSNumber] = reduce(into: [:]) { result, pair in
            result[pair.key.rawValue] = NSNumber(value: pair.value)
        }
        return stringDict.prettyPrinted
    }
}
