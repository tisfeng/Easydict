//
//  String+Removing.swift
//  Easydict
//
//  Created by tisfeng on 2025/7/5.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

// MARK: - String Extensions for Removing Characters

/// Extension providing utility methods for removing specific types of characters from strings
///
/// These methods are particularly useful for text preprocessing in language detection scenarios,
/// where you need to isolate specific character types for analysis.
extension String {
    /// Remove all non-letter characters from the string
    ///
    /// Filters the string to keep only Unicode letter characters, removing all
    /// whitespace, punctuation, symbols, numbers, and other non-alphabetic characters.
    ///
    /// This method is primarily used for text preprocessing in language detection scenarios,
    /// particularly for preparing text for simplified Chinese detection by isolating only
    /// alphabetic characters (letters). Uses Swift's efficient Character.isLetter property
    /// for optimal performance.
    ///
    /// - Returns: String containing only Unicode letter characters
    ///
    /// **Example:**
    /// ```swift
    /// "Hello, 世界! 123 café@#$".removingNonLetters() // Returns: "Hello世界café"
    /// "test@#$%456".removingNonLetters()              // Returns: "test"
    /// "café-123".removingNonLetters()                 // Returns: "café"
    /// ```
    func removingNonLetters() -> String {
        filter { $0.isLetter }
    }

    /// Remove whitespace and newline characters from the string
    ///
    /// Eliminates all Unicode whitespace characters including spaces, tabs, newlines,
    /// and other whitespace variants defined in CharacterSet.whitespacesAndNewlines.
    ///
    /// - Returns: String with all whitespace and newline characters removed
    ///
    /// **Example:**
    /// ```swift
    /// "hello world\n\ttest".removingWhitespaceAndNewlines() // Returns: "helloworldtest"
    /// "  spaced  text  ".removingWhitespaceAndNewlines()   // Returns: "spacedtext"
    /// ```
    func removingWhitespaceAndNewlines() -> String {
        components(separatedBy: .whitespacesAndNewlines).joined()
    }

    /// Remove punctuation characters from the string
    ///
    /// Eliminates all Unicode punctuation characters (General Category P*) including:
    /// - connectorPunctuation: _, ‿, ⁀...
    /// - dashPunctuation: -, –, —, ―...
    /// - openPunctuation: (, [, {, ⟨...
    /// - closePunctuation: ), ], }, ⟩...
    /// - initialPunctuation: ", ', «...
    /// - finalPunctuation: ", ', »...
    /// - otherPunctuation: !, ?, ., ;, :, ¡, ¿...
    ///
    /// - Returns: String with all punctuation characters removed
    ///
    /// **Example:**
    /// ```swift
    /// "hello, world!".removingPunctuationCharacters() // Returns: "hello world"
    /// "test(123).txt".removingPunctuationCharacters() // Returns: "test123txt"
    /// ```
    func removingPunctuationCharacters() -> String {
        components(separatedBy: .punctuationCharacters).joined()
    }

    /// Remove symbol characters from the string
    ///
    /// Eliminates all Unicode symbol characters (General Category S*) including:
    /// - **mathSymbol**: +, =, ÷, ×, √, ∑, ∫, ∞, ∂, ∇...
    /// - **currencySymbol**: $, €, ¥, £, ₹, ¢, ₽, ₿...
    /// - **modifierSymbol**: ^, `, ´, ¨, ¯, ˆ, ˜, ˚, ˙...
    /// - **otherSymbol**: ©, ®, ™, ‰, ¶, §, ♠, ♥, ♦, ♣...
    ///
    /// Note: This does not remove punctuation characters, only symbols.
    /// See: https://unicode.org/reports/tr44/#General_Category_Values
    ///
    /// - Returns: String with all symbol characters removed
    ///
    /// **Example:**
    /// ```swift
    /// "test@#$%".removingSymbols()     // Returns: "test"
    /// "price$100€50".removingSymbols() // Returns: "price10050"
    /// "math: 2+2=4".removingSymbols()  // Returns: "math: 224"
    /// ```
    func removingSymbols() -> String {
        components(separatedBy: .symbols).joined()
    }

    /// Remove numeric digits from the string
    ///
    /// Eliminates all Unicode decimal digit characters (0-9 and their equivalents
    /// in other writing systems) as defined by CharacterSet.decimalDigits.
    ///
    /// This includes:
    /// - ASCII digits: 0, 1, 2, 3, 4, 5, 6, 7, 8, 9
    /// - Arabic-Indic digits: ٠, ١, ٢, ٣, ٤, ٥, ٦, ٧, ٨, ٩
    /// - Extended Arabic-Indic digits: ۰, ۱, ۲, ۳, ۴, ۵, ۶, ۷, ۸, ۹
    /// - Devanagari digits: ०, १, २, ३, ४, ५, ६, ७, ८, ९
    /// - And other Unicode decimal digit characters
    ///
    /// - Returns: String with all numeric characters removed
    ///
    /// **Example:**
    /// ```swift
    /// "hello123world".removingNumbers() // Returns: "helloworld"
    /// "test456.txt".removingNumbers()   // Returns: "test.txt"
    /// "room101".removingNumbers()       // Returns: "room"
    /// ```
    func removingNumbers() -> String {
        components(separatedBy: .decimalDigits).joined()
    }

    // MARK: - NSString+EZUtils Text Cleaning Methods

    /// Remove all non-normal characters (combination of multiple removal methods)
    func removingNonNormalCharacters() -> String {
        removingWhitespaceAndNewlineCharacters()
            .removingPunctuationCharacters()
            .removingSymbolCharacterSet()
            .removingNumbers()
            .removingNonBaseCharacterSet()
    }

    /// Remove whitespace and newline characters
    func removingWhitespaceAndNewlineCharacters() -> String {
        removingWhitespaceAndNewlines()
    }

    /// Remove punctuation characters (enhanced version with Chinese punctuation)
    func removingPunctuationCharacters2() -> String {
        let chinesePunctuationChars = "，。《》？"
        let enhancedPunctuationSet = CharacterSet.punctuationCharacters
            .union(CharacterSet(charactersIn: chinesePunctuationChars))
        return components(separatedBy: enhancedPunctuationSet).joined()
    }

    /// Remove symbol characters
    func removingSymbolCharacterSet() -> String {
        components(separatedBy: .symbols).joined()
    }

    /// Remove control characters
    func removingControlCharacterSet() -> String {
        components(separatedBy: .controlCharacters).joined()
    }

    /// Remove illegal characters
    func removingIllegalCharacterSet() -> String {
        components(separatedBy: .illegalCharacters).joined()
    }

    /// Remove non-base characters
    func removingNonBaseCharacterSet() -> String {
        components(separatedBy: CharacterSet.nonBaseCharacters).joined()
    }

    /// Remove alphabet characters (a-z, A-Z)
    func removingAlphabet() -> String {
        let alphabetSet = CharacterSet(
            charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")
        return components(separatedBy: alphabetSet).joined()
    }

    /// Remove alphabet characters using regex
    func removingAlphabet2() -> String {
        let pattern = "[a-zA-Z]"
        return replacingOccurrences(of: pattern, with: "", options: .regularExpression)
    }

    /// Remove all letters
    func removingLetters() -> String {
        components(separatedBy: .letters).joined()
    }

    /// Remove alphabet and numbers
    func removingAlphabetAndNumbers() -> String {
        components(separatedBy: .alphanumerics).joined()
    }
}

// MARK: - NSString Bridges

@objc
extension NSString {
    func removeAlphabet() -> NSString {
        (self as String).removingAlphabet() as NSString
    }

    func removeNonNormalCharacters() -> NSString {
        (self as String).removingNonNormalCharacters() as NSString
    }

    func removingNonLetters() -> NSString {
        (self as String).removingNonLetters() as NSString
    }
}
