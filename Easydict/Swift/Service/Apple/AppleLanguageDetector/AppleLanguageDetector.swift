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

@objc
public class AppleLanguageDetector: NSObject {
    // MARK: Public

    /// Detect language of text
    @objc
    public func detectLanguage(text: String) -> Language {
        detectLanguage(text: text, printLog: false)
    }

    /// Detect language with logging option
    @objc
    public func detectLanguage(text: String, printLog: Bool) -> Language {
        if text.isEmpty {
            return .english
        }

        let languageProbabilityDict = detectLanguageDict(text: text, printLog: printLog)
        let mostConfidentLanguage = getMostConfidentLanguage(
            languageProbabilityDict,
            text: text,
            printLog: printLog
        )

        return mostConfidentLanguage
    }

    /// Detect language and return probability dictionary
    @objc
    public func detectLanguageDict(text: String, printLog: Bool) -> [String: NSNumber] {
        let trimmedText = String(text.prefix(100))

        let startTime = CFAbsoluteTimeGetCurrent()

        let recognizer = NLLanguageRecognizer()
        recognizer.languageConstraints = designatedLanguages
        recognizer.languageHints = customLanguageHints
        recognizer.processString(trimmedText)

        let languageProbabilityDict = recognizer.languageHypotheses(withMaximum: 5)
        let dominantLanguage = recognizer.dominantLanguage

        let endTime = CFAbsoluteTimeGetCurrent()

        if printLog {
            // Format language probabilities for better readability
            let formattedProbabilities =
                languageProbabilityDict
                    .sorted { $0.value > $1.value } // Sort by probability descending
                    .map { "\($0.key.rawValue): \(String(format: "%.3f", $0.value))" }
                    .joined(separator: "\n")

            print("Language probabilities: \n\(formattedProbabilities)\n")
            print("Dominant language: \(dominantLanguage?.rawValue ?? "nil")")
            print("Detection cost: \(String(format: "%.1f", (endTime - startTime) * 1000)) ms")
        }

        // Convert to String keys for Objective-C compatibility
        var result: [String: NSNumber] = [:]
        for (key, value) in languageProbabilityDict {
            result[key.rawValue] = NSNumber(value: value)
        }

        return result
    }

    /// Convert NLLanguage to Language enum - exposed for external use
    @objc
    public func languageEnumFromAppleLanguage(_ appleLanguage: NLLanguage?) -> Language {
        guard let appleLanguage = appleLanguage else { return .auto }

        switch appleLanguage {
        case .english: return .english
        case .simplifiedChinese: return .simplifiedChinese
        case .traditionalChinese: return .traditionalChinese
        case .japanese: return .japanese
        case .korean: return .korean
        case .french: return .french
        case .spanish: return .spanish
        case .portuguese: return .portuguese
        case .italian: return .italian
        case .german: return .german
        case .russian: return .russian
        case .arabic: return .arabic
        case .thai: return .thai
        case .polish: return .polish
        case .turkish: return .turkish
        case .indonesian: return .indonesian
        case .vietnamese: return .vietnamese
        case .dutch: return .dutch
        case .ukrainian: return .ukrainian
        case .hindi: return .hindi
        default: return .auto
        }
    }

    // MARK: Private

    private var designatedLanguages: [NLLanguage] {
        [
            .english, .simplifiedChinese, .traditionalChinese,
            .japanese, .korean, .french, .spanish, .portuguese,
            .italian, .german, .russian, .arabic, .thai,
            .polish, .turkish, .indonesian, .vietnamese,
            .dutch, .ukrainian, .hindi,
        ]
    }

    private var customLanguageHints: [NLLanguage: Double] {
        [
            .english: 2.0,
            .simplifiedChinese: 2.0,
            .traditionalChinese: 0.6,
            .japanese: 0.25,
            .korean: 0.2,
            .french: 0.15,
            .italian: 0.1,
            .spanish: 0.1,
            .german: 0.05,
            .portuguese: 0.05,
            .dutch: 0.01,
            .czech: 0.01,
        ]
    }

    private func getMostConfidentLanguage(
        _ languageProbabilities: [String: NSNumber],
        text: String,
        printLog: Bool
    )
        -> Language {
        // Find the language with highest probability
        let sortedLanguages = languageProbabilities.sorted {
            $0.value.doubleValue > $1.value.doubleValue
        }

        guard let mostConfident = sortedLanguages.first else {
            return .english
        }

        // Convert NLLanguage to Language
        let nlLanguage = NLLanguage(rawValue: mostConfident.key)
        let language = languageEnumFromAppleLanguage(nlLanguage)

        if printLog {
            print("Detected language: \(language)")
        }

        return language
    }
}
