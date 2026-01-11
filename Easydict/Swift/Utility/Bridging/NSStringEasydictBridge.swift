//
//  NSStringEasydictBridge.swift
//  Easydict
//
//  Created by GitHub Copilot on 2025/02/17.
//

import Foundation

@objcMembers
final class NSStringEasydictBridge: NSObject {
    // MARK: Internal

    static func removeAlphabet(_ string: NSString) -> NSString {
        (string as String).removingAlphabet() as NSString
    }

    static func removingNonLetters(_ string: NSString) -> NSString {
        (string as String).removingNonLetters() as NSString
    }

    static func wordCount(_ string: NSString) -> Int {
        (string as String).wordCount
    }

    static func firstWord(_ string: NSString) -> NSString {
        (string as String).firstWord as NSString
    }

    static func lastWord(_ string: NSString) -> NSString {
        (string as String).lastWord as NSString
    }

    static func isEnglishWordWithMaxWordLength(_ string: NSString, maxLength: Int) -> Bool {
        (string as String).isEnglishWordWithMaxLength(maxLength)
    }

    static func isSpelledCorrectly(_ string: NSString) -> Bool {
        (string as String).isSpelledCorrectly
    }

    static func isSpelledCorrectly(_ string: NSString, language: String?) -> Bool {
        (string as String).isSpelledCorrectly(language: language)
    }

    static func shouldQueryDictionary(
        _ string: NSString,
        languageIdentifier: NSString?,
        maxWordCount: Int
    )
        -> Bool {
        let language = makeLanguage(from: languageIdentifier)
        return (string as String).shouldQueryDictionary(
            withLanguage: language, maxWordCount: maxWordCount
        )
    }

    static func shouldQuerySentence(_ string: NSString, languageIdentifier: NSString?) -> Bool {
        let language = makeLanguage(from: languageIdentifier)
        return (string as String).shouldQuerySentence(withLanguage: language)
    }

    // MARK: Private

    private static func makeLanguage(from identifier: NSString?) -> Language {
        guard let identifier else { return .auto }
        return Language(rawValue: identifier as String)
    }
}
