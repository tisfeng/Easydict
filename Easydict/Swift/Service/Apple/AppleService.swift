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
    var supportedLanguages = [Locale.Language]()

    @available(macOS 15.0, *)
    func prepareSupportedLanguages() async {
        supportedLanguages = await LanguageAvailability().supportedLanguages // zh_CN, zh_TW, ja_JP

        supportedLanguages.sort {
            $0.languageCode!.identifier < $1.languageCode!.identifier
        }

        for language in supportedLanguages {
            print("\(language.languageCode!.identifier)_\(language.region!)")
        }

        /**
         ar_AE
         de_DE
         en_GB
         en_US
         es_ES
         fr_FR
         hi_IN
         id_ID
         it_IT
         ja_JP
         ko_KR
         nl_NL
         pl_PL
         pt_BR
         ru_RU
         th_TH
         tr_TR
         uk_UA
         vi_VN
         zh_TW
         zh_CN
         */
    }
}

func systemLanguages() {
    for language in Locale.Language.systemLanguages {
        // zh, zh, zh-Hans-CN 中文 (中国大陆)
        // zh, zh-TW, zh-Hant-TW 中文 (台湾)
        print(language)
    }
}

func availableIdentifiers() {
    let availableIdentifiers = Locale.availableIdentifiers
    var availableLanguages = [Locale.Language]()

    for identifier in availableIdentifiers {
        let locale = Locale(identifier: identifier)
        let language = locale.language

        if Locale.Language.systemLanguages.contains(language) {
            availableLanguages.append(language)

            // locale identifier: zh_Hans, zh, zh-Hans-CN
            // locale identifier: zh_Hant, zh-TW, zh-Hant-TW
            print(
                "locale identifier: \(identifier), \(locale.language.minimalIdentifier), \(locale.language.maximalIdentifier)"
            )

            // zh, Hant, HK
            print(
                "\(language.languageCode?.identifier ?? "nil"), \(language.script?.identifier ?? "nil"), \(language.region?.identifier ?? "nil")\n"
            )
        }
    }

    print(availableLanguages)
}

// MARK: - Locale.Language + CustomStringConvertible

extension Locale.Language: @retroactive CustomStringConvertible {
    public var description: String {
        let currentLocal = Locale.current // Locale.current.identifier = "zh_CN"
        let locale = Locale(identifier: maximalIdentifier)

        if let languageCode = languageCode {
            let identifier = languageCode.identifier
            let localizedName = currentLocal.localizedString(forIdentifier: identifier) ?? ""
            let region =
                currentLocal.localizedString(forRegionCode: locale.region?.identifier ?? "") ?? ""
            return
                "\(identifier) \(minimalIdentifier) \(maximalIdentifier) \(localizedName) (\(region))"
        }
        return "\(languageCode?.identifier ?? "nil") maximalIdentifier: \(maximalIdentifier)"
    }
}
