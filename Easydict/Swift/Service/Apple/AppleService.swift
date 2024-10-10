//
//  AppleService.swift
//  Easydict
//
//  Created by tisfeng on 2024/10/9.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation
import Testing
import Translation

// MARK: - AppleService

public class AppleService: QueryService {
    //    public override func translate(_ text: String, from: Language, to: Language) async throws
    //        -> EZQueryResult {
    //        // use TranslationSession to translate
    //        // Docs https://developer.apple.com/documentation/translation/translationsession
    //    }

    @available(macOS 15.0, *)
    func translate() {
        let configuration = TranslationSession.Configuration()

//        TranslationSession(configuration).translate("")
    }
}

// log all Locale.Language

func printAllAvailableLanguages() {
    for language in Locale.Language.systemLanguages {
        let currentLocal = Locale.current
        let locale = Locale(identifier: language.maximalIdentifier)

        if let languageCode = language.languageCode {
            print(
                "languageCode identifier: \(languageCode.identifier), \(language.minimalIdentifier), \(language.maximalIdentifier) "
            )
        }

        let localizedName =
            currentLocal.localizedString(forLanguageCode: language.maximalIdentifier) ?? ""
        let region =
            currentLocal.localizedString(forRegionCode: locale.region?.identifier ?? "") ?? ""
        print("localizedName: \(localizedName), region: \(region)\n")
    }

    let availableIdentifiers = Locale.availableIdentifiers

    for identifier in availableIdentifiers {
        let locale = Locale(identifier: identifier)
        let language = locale.language

        if Locale.Language.systemLanguages.contains(language) {
            print(
                "locale identifier: \(identifier), \(locale.language.minimalIdentifier), \(locale.language.maximalIdentifier)"
            )

            print(" \(language.languageCode), \(language.script), \(language.region)\n")
        }
    }
}

@available(macOS 15.0, *)
func prepareSupportedLanguages() {
    Task { @MainActor in
        let supportedLanguages = await LanguageAvailability().supportedLanguages // zh_CN, zh_TW, ja_JP
        for language in supportedLanguages {
            print("language: \(language.languageCode!.identifier)_\(language.region!)")
        }
    }
}

extension Locale.Language {
    var description: String {
        languageCode?.identifier ?? ""
    }
}
