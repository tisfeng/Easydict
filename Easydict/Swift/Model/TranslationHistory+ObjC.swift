//
//  TranslationHistory+ObjC.swift
//  Easydict
//
//  Created by Ryan on 2026/01/10.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

// MARK: - TranslationHistoryManager + Objective-C Bridge

extension TranslationHistoryManager {
    /// Objective-C bridge method to save translation history.
    /// - Parameters:
    ///   - queryText: Original query text.
    ///   - translatedText: Translated text.
    ///   - fromLanguage: Source language raw value.
    ///   - toLanguage: Target language raw value.
    ///   - serviceType: Service type identifier.
    @objc(saveTranslationHistoryWithQueryText:translatedText:fromLanguage:toLanguage:serviceType:)
    static func saveTranslationHistory(
        queryText: String,
        translatedText: String,
        fromLanguage: String,
        toLanguage: String,
        serviceType: String
    ) {
        Task { @MainActor in
            let fromLang = Language(rawValue: fromLanguage)
            let toLang = Language(rawValue: toLanguage)
            shared.addHistory(
                queryText: queryText,
                translatedText: translatedText,
                fromLanguage: fromLang,
                toLanguage: toLang,
                serviceType: serviceType
            )
        }
    }
}
