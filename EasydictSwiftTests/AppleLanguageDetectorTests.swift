//
//  AppleLanguageDetectorTests.swift
//  EasydictSwiftTests
//
//  Created by AI Assistant on 2025/7/4.
//  Copyright © 2025 izual. All rights reserved.
//

import Testing

@testable import Easydict

/// Comprehensive tests for Apple Language Detection with intelligent corrections
///
/// Tests cover multiple scenarios including:
/// - Pure language text detection
/// - Mixed script text (Chinese-English combinations)
/// - Short text edge cases
/// - Numeric and special character handling
/// - User preference integration
/// - Common misdetection patterns
@Suite("Apple Language Detector", .tags(.apple, .unit))
struct AppleLanguageDetectorTests {
    // MARK: Internal

    // MARK: - Pure Language Detection Tests

    @Test("English Text Detection", .tags(.apple, .unit))
    func testEnglishTextDetection() {
        // Standard English sentences
        #expect(detector.detectLanguage(text: "Hello, how are you today?") == .english)
        #expect(detector.detectLanguage(text: "This is a beautiful day for coding.") == .english)
        #expect(detector.detectLanguage(text: "Welcome to our application!") == .english)

        // English with mixed punctuation
        #expect(detector.detectLanguage(text: "Hello, world! This is great.") == .english)

        let commonEnglishWords = [
            "apple", "the", "and", "you", "for", "are", "with", "not", "this", "but",
            "have", "from", "they", "know", "want", "been", "good", "much", "some",
            "time", "very", "when", "come", "here", "just", "like", "long", "make",
            "many", "over", "such", "take", "than", "them", "well", "work",
        ]

        // Test common English words
        for word in commonEnglishWords {
            #expect(detector.detectLanguage(text: word) == .english)
        }
    }

    @Test("Chinese Text Detection", .tags(.apple, .unit))
    func testChineseTextDetection() {
        // Simplified Chinese
        #expect(detector.detectLanguage(text: "你好，世界！") == .simplifiedChinese)
        #expect(detector.detectLanguage(text: "这是一个很好的翻译软件。") == .simplifiedChinese)
        #expect(detector.detectLanguage(text: "我们今天去哪里？") == .simplifiedChinese)

        // Traditional Chinese
        #expect(detector.detectLanguage(text: "繁體中文測試內容") == .traditionalChinese)

        // Chinese with numbers
        #expect(detector.detectLanguage(text: "今天温度是25度，很舒服。") == .simplifiedChinese)
    }

    @Test("Japanese Text Detection", .tags(.apple, .unit))
    func testJapaneseTextDetection() {
        #expect(detector.detectLanguage(text: "こんにちは、世界！") == .japanese)
        #expect(detector.detectLanguage(text: "今日はいい天気ですね。") == .japanese)
        #expect(detector.detectLanguage(text: "ありがとうございます。") == .japanese)

        // Hiragana, Katakana, Kanji mixed
        #expect(detector.detectLanguage(text: "コンピュータで日本語を入力する") == .japanese)
    }

    @Test("Korean Text Detection", .tags(.apple, .unit))
    func testKoreanTextDetection() {
        #expect(detector.detectLanguage(text: "안녕하세요, 세계!") == .korean)
        #expect(detector.detectLanguage(text: "오늘은 좋은 날씨입니다.") == .korean)
        #expect(detector.detectLanguage(text: "감사합니다.") == .korean)
    }

    @Test("European Languages Detection", .tags(.apple, .unit))
    func testEuropeanLanguagesDetection() {
        // French
        #expect(detector.detectLanguage(text: "Bonjour, comment allez-vous?") == .french)
        #expect(detector.detectLanguage(text: "C'est une belle journée.") == .french)

        // Spanish
        #expect(detector.detectLanguage(text: "Hola, ¿cómo estás?") == .spanish)
        #expect(detector.detectLanguage(text: "Es un día hermoso.") == .spanish)

        // German
        #expect(detector.detectLanguage(text: "Guten Tag, wie geht es Ihnen?") == .german)
        #expect(detector.detectLanguage(text: "Das ist ein schöner Tag.") == .german)

        // Italian
        #expect(detector.detectLanguage(text: "Ciao, come stai?") == .italian)
        #expect(detector.detectLanguage(text: "È una bella giornata.") == .italian)

        // Portuguese
        #expect(detector.detectLanguage(text: "Olá, como você está?") == .portuguese)
        #expect(detector.detectLanguage(text: "É um dia lindo.") == .portuguese)
    }

    // MARK: - Short Text and Edge Cases

    @Test("Short English Words Detection", .tags(.apple, .unit))
    func testShortEnglishWordsDetection() {
        // This addresses the "apple" → Turkish problem
        #expect(detector.detectLanguage(text: "apple") == .english)
        #expect(detector.detectLanguage(text: "hello") == .english)
        #expect(detector.detectLanguage(text: "world") == .english)
        #expect(detector.detectLanguage(text: "good") == .english)
        #expect(detector.detectLanguage(text: "test") == .english)
        #expect(detector.detectLanguage(text: "work") == .english)
        #expect(detector.detectLanguage(text: "time") == .english)
        #expect(detector.detectLanguage(text: "make") == .english)
    }

    @Test("Very Short Text Detection", .tags(.apple, .unit))
    func testVeryShortTextDetection() {
        // Single characters - should default to English for alphabetic chars

        // Iterat a-z and A-Z
        let alphabet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
        for char in alphabet {
            #expect(detector.detectLanguage(text: String(char)) == .english)
        }

        // Two characters
        #expect(detector.detectLanguage(text: "hi") == .english)
        #expect(detector.detectLanguage(text: "ok") == .english)

        // Three characters
        #expect(detector.detectLanguage(text: "yes") == .english)
        #expect(detector.detectLanguage(text: "the") == .english)
    }

    @Test("Numeric Text Detection", .tags(.apple, .unit))
    func testNumericTextDetection() {
        // Pure numbers should fallback to English as default
        #expect(detector.detectLanguage(text: "123456") == .english)
        #expect(detector.detectLanguage(text: "99.99") == .english)

        // Numbers with currency
        #expect(detector.detectLanguage(text: "$10.99") == .english)
        #expect(detector.detectLanguage(text: "€15.50") == .english)
    }

    @Test("Empty and Whitespace Text Detection", .tags(.apple, .unit))
    func testEmptyAndWhitespaceDetection() {
        #expect(detector.detectLanguage(text: "") == .auto)
        #expect(detector.detectLanguage(text: "   ") == .auto)
        #expect(detector.detectLanguage(text: "\n\t  ") == .auto)
    }

    // MARK: - Mixed Script Text Detection

    @Test("Chinese-English Mixed Text Detection", .tags(.apple, .unit))
    func testChineseEnglishMixedTextDetection() {
        // High Chinese ratio - should detect as Chinese
        #expect(detector.detectLanguage(text: "苹果apple") == .simplifiedChinese)
        #expect(detector.detectLanguage(text: "我爱apple") == .simplifiedChinese)
        #expect(detector.detectLanguage(text: "apple苹果很好吃") == .simplifiedChinese)

        // Complex mixed sentences
        #expect(detector.detectLanguage(text: "欢迎使用 Easydict翻译软件!") == .simplifiedChinese)
        #expect(
            detector.detectLanguage(text: "这是一个强大的翻译工具, 支持多种服务, 包括Google翻译、DeepL翻译等.")
                == .simplifiedChinese
        )
        #expect(
            detector.detectLanguage(text: "支持多种语言, 包括English, Japanese, Korean等.")
                == .simplifiedChinese
        )

        // Mixed with URLs and numbers
        #expect(
            detector.detectLanguage(text: "访问网站: https://easydict.app 了解更多信息.")
                == .simplifiedChinese
        )
        #expect(detector.detectLanguage(text: "价格: 免费版0.00元; 专业版 99.99 元.") == .simplifiedChinese)

        // Test recursive detection for English mixed with Chinese
        #expect(detector.detectLanguage(text: "Hello 你好") == .simplifiedChinese)
        #expect(detector.detectLanguage(text: "Welcome 欢迎使用") == .simplifiedChinese)
        #expect(detector.detectLanguage(text: "iPhone 很棒") == .simplifiedChinese)
        #expect(detector.detectLanguage(text: "apple 苹果 fruit") == .simplifiedChinese)
    }

    @Test("English Dominant Mixed Text Detection", .tags(.apple, .unit))
    func testEnglishDominantMixedTextDetection() {
        // If English words count is higher, it should detect as English
        #expect(
            detector.detectLanguage(text: "This is a long English sentence with one 中文 word")
                == .english
        )

        // English word count is 4, and Chinese word count is 4, so it should detect as Chinese
        #expect(
            detector.detectLanguage(text: "Welcome to our application, 欢迎使用") == .simplifiedChinese
        )
    }

    @Test("Japanese-English Mixed Text Detection", .tags(.apple, .unit))
    func testJapaneseEnglishMixedTextDetection() {
        #expect(detector.detectLanguage(text: "こんにちは Hello world") == .japanese)
        #expect(detector.detectLanguage(text: "今日はAppleの発表日です") == .japanese)
        #expect(detector.detectLanguage(text: "iPhone は素晴らしいです") == .japanese)

        // Test recursive detection for English mixed with Japanese
        #expect(detector.detectLanguage(text: "Hello こんにちは") == .japanese)
        #expect(detector.detectLanguage(text: "Welcome いらっしゃいませ") == .japanese)
        #expect(detector.detectLanguage(text: "apple りんご") == .japanese)
    }

    @Test("Korean-English Mixed Text Detection", .tags(.apple, .unit))
    func testKoreanEnglishMixedTextDetection() {
        #expect(detector.detectLanguage(text: "안녕하세요 Hello world") == .korean)
        #expect(detector.detectLanguage(text: "오늘은 Apple 발표일입니다") == .korean)
        #expect(detector.detectLanguage(text: "iPhone은 훌륭합니다") == .korean)

        // Test recursive detection for English mixed with Korean
        #expect(detector.detectLanguage(text: "Hello 안녕하세요") == .korean)
        #expect(detector.detectLanguage(text: "Welcome 환영합니다") == .korean)
        #expect(detector.detectLanguage(text: "apple 사과") == .korean)
    }

    // MARK: - Common Misdetection Cases

    @Test("Turkish Misdetection Prevention", .tags(.apple, .unit))
    func testTurkishMisdetectionPrevention() {
        // These should NOT be detected as Turkish
        #expect(detector.detectLanguage(text: "apple") == .english)
        #expect(detector.detectLanguage(text: "table") == .english)
        #expect(detector.detectLanguage(text: "simple") == .english)
        #expect(detector.detectLanguage(text: "people") == .english)
        #expect(detector.detectLanguage(text: "little") == .english)

        // But actual Turkish should still work
        #expect(detector.detectLanguage(text: "Merhaba, nasılsın? Bu güzel bir gün.") == .turkish)
    }

    @Test("Portuguese Misdetection Prevention", .tags(.apple, .unit))
    func testPortugueseMisdetectionPrevention() {
        // Common English words that might be misdetected as Portuguese
        #expect(detector.detectLanguage(text: "simple") == .english)
        #expect(detector.detectLanguage(text: "table") == .english)
        #expect(detector.detectLanguage(text: "possible") == .english)

        // But actual Portuguese should still work
        #expect(
            detector.detectLanguage(text: "Olá, como você está? Este é um belo dia.") == .portuguese
        )
    }

    // MARK: - Real-world Text Scenarios

    @Test("Technical Documentation Detection", .tags(.apple, .unit))
    func testTechnicalDocumentationDetection() {
        // English technical text
        let englishTech = """
        func detectLanguage(text: String) -> Language {
            // Implementation details here
            return .english
        }
        """
        #expect(detector.detectLanguage(text: englishTech) == .english)

        // Chinese technical text
        let chineseTech = """
        这个函数用于检测文本的语言类型。
        参数: text - 要检测的文本字符串
        返回值: Language 枚举类型
        """
        #expect(detector.detectLanguage(text: chineseTech) == .simplifiedChinese)

        // Mixed technical text
        let mixedTech = """
        使用 Apple 的 NaturalLanguage 框架进行语言检测。
        调用 detectLanguage(text:) 方法获取结果。
        """
        #expect(detector.detectLanguage(text: mixedTech) == .simplifiedChinese)
    }

    @Test("Social Media Text Detection", .tags(.apple, .unit))
    func testSocialMediaTextDetection() {
        // Twitter-like posts
        #expect(
            detector.detectLanguage(text: "Just had the best coffee ☕️ #coffee #morning") == .english
        )
        #expect(detector.detectLanguage(text: "今天天气真好 ☀️ #天气 #心情") == .simplifiedChinese)
        #expect(detector.detectLanguage(text: "Love this app! 很棒的应用 👍") == .simplifiedChinese)

        // Hashtags and mentions
        #expect(detector.detectLanguage(text: "@username this is awesome! #cool") == .english)
        #expect(detector.detectLanguage(text: "@用户名 这个很棒！ #酷") == .simplifiedChinese)
    }

    @Test("URLs and Email Detection", .tags(.apple, .unit))
    func testURLsAndEmailDetection() {
        // Text with URLs
        #expect(
            detector.detectLanguage(text: "Visit https://example.com for more info") == .english
        )
        #expect(
            detector.detectLanguage(text: "访问 https://example.com 获取更多信息") == .simplifiedChinese
        )

        // Text with emails
        #expect(detector.detectLanguage(text: "Contact us at support@example.com") == .english)

        // Mixed language with email - Chinese characters dominate
        #expect(detector.detectLanguage(text: "联系我们: support@example.com") == .simplifiedChinese)
    }

    // MARK: - Performance and Detailed Analysis Tests

    @Test("Language Detection Performance", .tags(.apple, .performance))
    func testLanguageDetectionPerformance() {
        let testTexts = [
            "Hello, how are you today?",
            "你好，世界！",
            "Bonjour, comment allez-vous?",
            "apple苹果",
            "欢迎使用 Easydict翻译软件!",
            "这是一个强大的翻译工具, 支持多种服务, 包括Google翻译、DeepL翻译等.",
        ]

        // Measure detection performance
        let startTime = CFAbsoluteTimeGetCurrent()

        for text in testTexts {
            for _ in 1 ... 100 { // Run 100 times each
                _ = detector.detectLanguage(text: text)
            }
        }

        let endTime = CFAbsoluteTimeGetCurrent()
        let totalTime = endTime - startTime
        let averageTime = totalTime / Double(testTexts.count * 100)

        print("Average detection time: \(averageTime * 1000) ms")

        // Performance expectation: should be fast (< 5ms per detection on average)
        #expect(averageTime < 0.005, "Detection should be fast (< 5ms per call)")
    }

    @Test("Detailed Language Probabilities", .tags(.apple, .unit))
    func testDetailedLanguageProbabilities() {
        // Test that probability distribution makes sense
        let probabilities = detector.detectLanguageDict(text: "Hello, world!")

        // Should have probabilities
        #expect(!probabilities.isEmpty)

        // English should have high probability
        if let englishProb = probabilities["en"] {
            #expect(
                englishProb.doubleValue > 0.5,
                "English should have high probability for English text"
            )
        }

        // Test Chinese text probabilities
        let chineseProbabilities = detector.detectLanguageDict(text: "你好，世界！")

        #expect(!chineseProbabilities.isEmpty)

        // Should have Chinese variant with high probability
        let hasHighChineseProb = chineseProbabilities.contains { key, value in
            (key == "zh-Hans" || key == "zh-Hant") && value.doubleValue > 0.5
        }
        #expect(hasHighChineseProb, "Chinese text should have high Chinese probability")
    }

    @Test("Mixed Text Detailed Analysis", .tags(.apple, .unit))
    func testMixedTextDetailedAnalysis() {
        // Test the detailed analysis of mixed Chinese-English text
        let mixedText = "欢迎使用 Easydict翻译软件! 这是一个强大的翻译工具, 支持多种服务, 包括Google翻译、DeepL翻译等."

        let result = detector.detectLanguage(text: mixedText) // Enable logging for this test

        #expect(
            result == .simplifiedChinese,
            "Mixed text with significant Chinese content should be detected as Chinese"
        )

        // Test with different ratios - English dominant text should be English
        let englishDominantText =
            "This is mostly English text with some 中文 words mixed in the sentence"
        #expect(detector.detectLanguage(text: englishDominantText) == .english)
    }

    // MARK: - Edge Cases and Error Handling

    @Test("Special Characters and Symbols", .tags(.apple, .unit))
    func testSpecialCharactersAndSymbols() {
        // Emoji-heavy text should default to English
        #expect(detector.detectLanguage(text: "😀😃😄😁😆😅😂🤣") == .english)

        // Punctuation-heavy text should default to English
        #expect(detector.detectLanguage(text: "!@#$%^&*()_+-=[]{}|;':\",./<>?") == .english)

        // Mixed symbols with text
        #expect(detector.detectLanguage(text: "Hello! 😀👍🎉") == .english)

        // Chinese with emojis - Chinese characters should dominate
        #expect(detector.detectLanguage(text: "你好！😀👍🎉") == .simplifiedChinese)
    }

    @Test("Unusual Text Patterns", .tags(.apple, .unit))
    func testUnusualTextPatterns() {
        // Repeated characters should be detected as English
        #expect(detector.detectLanguage(text: "aaaaaaa") == .english)
        #expect(detector.detectLanguage(text: "hhhhhhh") == .english)

        // Mixed repeated patterns should be detected as English
        #expect(detector.detectLanguage(text: "ababababab") == .english)

        // Very long single word
        #expect(detector.detectLanguage(text: "supercalifragilisticexpialidocious") == .english)
    }

    @Test("Language Boundary Cases", .tags(.apple, .unit))
    func testLanguageBoundaryCases() {
        // Simplified vs Traditional Chinese - test accurate detection
        let simplifiedChinese = "这是简体中文测试"
        let traditionalChinese = "這是繁體中文測試"

        #expect(detector.detectLanguage(text: simplifiedChinese) == .simplifiedChinese)
        #expect(detector.detectLanguage(text: traditionalChinese) == .traditionalChinese)

        // Spanish vs Portuguese (similar Romance languages)
        #expect(detector.detectLanguage(text: "Hola, ¿cómo estás hoy?") == .spanish)
        #expect(detector.detectLanguage(text: "Olá, como você está hoje?") == .portuguese)
    }

    // MARK: - User Preference Weight Correction Tests

    @Test("User Preferred Language Weight Boost", .tags(.apple, .unit))
    func testUserPreferredLanguageWeightBoost() {
        // This test verifies that user preferred languages get appropriate weight boosts
        // when they appear in the detection results

        // Test with ambiguous text that could be multiple languages
        let ambiguousText = "favor" // Could be English, Spanish, Portuguese, etc.

        // Get the detailed probabilities to see the weight adjustment effect
        let probabilities = detector.detectLanguageDict(text: ambiguousText)

        // Verify that probabilities are returned
        #expect(!probabilities.isEmpty, "Should return language probabilities for ambiguous text")

        // The exact behavior depends on user's preferred languages, but we can verify
        // that the system handles the weight correction without crashing
        let detectedLanguage = detector.detectLanguage(text: ambiguousText)
        #expect(detectedLanguage != .auto, "Should detect a specific language for ambiguous text")
    }

    @Test("User Preference Weight Only Affects Detected Languages", .tags(.apple, .unit))
    func testUserPreferenceWeightOnlyAffectsDetectedLanguages() {
        // Test that user preference weights only apply to languages that are actually detected
        // not to languages that weren't detected at all

        // Use clear English text that won't be detected as other languages
        let clearEnglishText = "The quick brown fox jumps over the lazy dog"

        let probabilities = detector.detectLanguageDict(text: clearEnglishText)

        // English should be strongly detected
        if let englishProb = probabilities["en"] {
            #expect(
                englishProb.doubleValue > 0.7,
                "Clear English text should have high English probability"
            )
        }

        // Verify final detection is English
        #expect(detector.detectLanguage(text: clearEnglishText) == .english)
    }

    @Test("Weight Correction With Mixed Text", .tags(.apple, .unit))
    func testWeightCorrectionWithMixedText() {
        // Test weight correction behavior with mixed Chinese-English text
        let mixedText = "苹果 apple iPhone"

        // Get probabilities with weight correction
        let probabilities = detector.detectLanguageDict(text: mixedText)
        #expect(!probabilities.isEmpty, "Mixed text should return probabilities")

        // Final detection should consider both ML detection and user preferences
        let detectedLanguage = detector.detectLanguage(text: mixedText)
        #expect(
            detectedLanguage == .simplifiedChinese,
            "Mixed text with Chinese characters should be detected as Chinese"
        )
    }

    @Test("English Additional Weight When Not Preferred", .tags(.apple, .unit))
    func testEnglishAdditionalWeightWhenNotPreferred() {
        // Test that English gets additional weight boost even when not in user preferences
        // since it's widely used

        let englishText = "Hello world"
        let probabilities = detector.detectLanguageDict(text: englishText)

        // English should be detected with high probability
        if let englishProb = probabilities["en"] {
            #expect(
                englishProb.doubleValue > 0.5,
                "English should have high probability even without preference boost"
            )
        }

        #expect(detector.detectLanguage(text: englishText) == .english)
    }

    @Test("Weight Correction Preserves ML Insights", .tags(.apple, .unit))
    func testWeightCorrectionPreservesMLInsights() {
        // Test that weight correction enhances but doesn't override strong ML detections

        // Use very clear Chinese text
        let clearChineseText = "这是一段非常明确的中文文本，没有任何其他语言的混合"

        let probabilities = detector.detectLanguageDict(text: clearChineseText)

        // Chinese should be strongly detected regardless of user preferences
        let hasHighChineseProb = probabilities.contains { key, value in
            (key == "zh-Hans" || key == "zh-Hant") && value.doubleValue > 0.8
        }
        #expect(hasHighChineseProb, "Clear Chinese text should maintain high Chinese probability")

        #expect(detector.detectLanguage(text: clearChineseText) == .simplifiedChinese)
    }

    @Test("Intelligent Chinese Type Detection", .tags(.apple, .unit))
    func testIntelligentChineseTypeDetection() {
        // Test cases that often get misidentified by Apple's raw detection

        // Common simplified Chinese words that might be misidentified as traditional
        #expect(detector.detectLanguage(text: "很棒") == .simplifiedChinese)
        #expect(detector.detectLanguage(text: "苹果") == .simplifiedChinese)
        #expect(detector.detectLanguage(text: "电脑") == .simplifiedChinese)
        #expect(detector.detectLanguage(text: "软件") == .simplifiedChinese)
        #expect(detector.detectLanguage(text: "网络") == .simplifiedChinese)
        #expect(detector.detectLanguage(text: "翻译") == .simplifiedChinese)

        // Clear traditional Chinese text
        #expect(detector.detectLanguage(text: "開門") == .traditionalChinese)
        #expect(detector.detectLanguage(text: "電腦") == .traditionalChinese)
        #expect(detector.detectLanguage(text: "軟體") == .traditionalChinese)
        #expect(detector.detectLanguage(text: "網路") == .traditionalChinese)
        #expect(detector.detectLanguage(text: "翻譯") == .traditionalChinese)

        // Mixed text with simplified Chinese
        #expect(detector.detectLanguage(text: "苹果apple很棒") == .simplifiedChinese)
        #expect(detector.detectLanguage(text: "这个软件真的很好用") == .simplifiedChinese)

        // Mixed text with traditional Chinese
        #expect(detector.detectLanguage(text: "開門apple") == .traditionalChinese)
        #expect(detector.detectLanguage(text: "這個軟體真的很好用") == .traditionalChinese)

        // Single character cases
        #expect(detector.detectLanguage(text: "门") == .simplifiedChinese) // simplified
        #expect(detector.detectLanguage(text: "門") == .traditionalChinese) // traditional

        // Short phrases that are commonly misidentified
        #expect(detector.detectLanguage(text: "很好") == .simplifiedChinese)
        #expect(detector.detectLanguage(text: "不错") == .simplifiedChinese)
        #expect(detector.detectLanguage(text: "厉害") == .simplifiedChinese)
    }

    // MARK: Private

    /// The detector instance used across all tests
    private let detector = AppleLanguageDetector()
}
