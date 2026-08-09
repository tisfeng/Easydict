//
//  GrammarAnalysisService+Support.swift
//  Easydict
//
//  Created by Yi Miao on 2026/7/7.
//

import Defaults
import Foundation

extension GrammarAnalysisService {
    var preferredGateModels: [String] {
        [
            ZhipuModel.glm_4_flash_250414.rawValue,
            ZhipuModel.glm_4_5_flash.rawValue,
            GroqModel.llama3_1_8b_instant.rawValue,
        ]
    }

    var providerDefaultEndpoint: String {
        switch provider {
        case .openAI:
            Self.openAIOfficialEndpoint
        case .deepSeek:
            Self.deepSeekOfficialEndpoint
        case .customOpenAICompatible:
            ""
        }
    }

    var providerDefaultModels: [String] {
        switch provider {
        case .openAI:
            Self.openAIDefaultModels
        case .deepSeek:
            Self.deepSeekDefaultModels
        case .customOpenAICompatible:
            []
        }
    }

    var providerDefaultModel: String {
        providerDefaultModels.first ?? ""
    }

    var providerSupportedModels: String {
        supportedModels(from: providerDefaultModels)
    }

    var gateModel: String {
        preferredGateModels.first(where: { validModels.contains($0) }) ?? model
    }

    var activeProviderConfigurationID: String {
        providerConfigurationID(provider)
    }

    var legacyUserCredentialConfigurationID: String {
        uuid.isEmpty ? "user_key" : "\(uuid)_user_key"
    }

    var builtInSupportedModelsStorageKey: Defaults.Key<String> {
        stringDefaultsKey(
            .supportedModels,
            defaultValue: supportedModels(from: defaultModels)
        )
    }

    var builtInValidModelsStorageKey: Defaults.Key<[String]> {
        serviceDefaultsKey(.validModels, defaultValue: defaultModels)
    }

    func providerConfigurationID(_ provider: GrammarAnalysisProvider) -> String {
        let baseID = uuid.isEmpty ? "user_key" : "\(uuid)_user_key"
        return "\(baseID)_\(provider.rawValue)"
    }

    func shouldSkipForLocalHeuristics(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return true }

        if trimmed.isEnglishWord || trimmed.isChineseWord || trimmed.wordCount <= 1 {
            return true
        }

        if trimmed.contains("://") || trimmed.hasPrefix("www.") {
            return true
        }

        if trimmed.range(
            of: #"^screenshot\s+\d{4}-\d{2}-\d{2}\s+at\s+.+"#,
            options: [.regularExpression, .caseInsensitive]
        ) != nil {
            return true
        }

        if trimmed.range(
            of: #"\.(png|jpg|jpeg|gif|heic|webp|pdf|txt|docx?|pages|key|zip)$"#,
            options: [.regularExpression, .caseInsensitive]
        ) != nil {
            return true
        }

        if trimmed.contains("/") || trimmed.contains("\\"), trimmed.wordCount <= 3 {
            return true
        }

        let letters = CharacterSet.letters
        let decimalDigits = CharacterSet.decimalDigits
        let meaningfulScalars = trimmed.unicodeScalars.filter {
            letters.contains($0) || decimalDigits.contains($0)
        }
        return meaningfulScalars.count <= 1
    }

    func looksClearlyAnalyzableNaturalLanguage(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 12 else {
            return false
        }

        let hasSentenceEnding = trimmed.hasEndPunctuationSuffix
        let hasClauseSeparator = trimmed.range(
            of: #"[,，;；:：]"#,
            options: .regularExpression
        ) != nil
        let hasChineseText = trimmed.range(
            of: #"\p{Han}"#,
            options: .regularExpression
        ) != nil
        let hasLongWordSequence = trimmed.wordCount >= 6

        return hasSentenceEnding ||
            hasClauseSeparator ||
            hasLongWordSequence ||
            (hasChineseText && trimmed.count >= 20)
    }

    func analysisAnswerLanguage(targetLanguage: Language) -> Language {
        targetLanguage
    }

    func shouldSkipForModeEligibility(sourceLanguage: Language) -> Bool {
        guard analysisMode == .ielts else {
            return false
        }

        return sourceLanguage != .english
    }

    func completeFinalResultState(_ result: QueryResult) {
        result.isLoading = false
        result.isStreamFinished = true
    }

    func skipMessage(answerLanguage: Language) -> String {
        localizedAnswerString(
            forKey: "grammar.analysis.skipped",
            answerLanguage: answerLanguage
        )
    }

    func ieltsLanguageSkipMessage(answerLanguage: Language) -> String {
        localizedAnswerString(
            forKey: "grammar.analysis.ielts.english_only",
            answerLanguage: answerLanguage
        )
    }

    func localizedAnswerString(forKey key: String, answerLanguage: Language) -> String {
        let availableLocalizations = Bundle.main.localizations.filter { $0 != "Base" }
        let preferredLocalizations = answerStringFallbackLocalizations(for: answerLanguage)
        let resolvedLocalization = Bundle.preferredLocalizations(
            from: availableLocalizations,
            forPreferences: preferredLocalizations
        ).first

        guard let resolvedLocalization,
              let bundlePath = Bundle.main.path(
                  forResource: resolvedLocalization,
                  ofType: "lproj"
              ),
              let bundle = Bundle(path: bundlePath)
        else {
            return Bundle.main.localizedString(forKey: key, value: nil, table: nil)
        }

        let localizedValue = bundle.localizedString(
            forKey: key,
            value: nil,
            table: nil
        )
        return localizedValue == key
            ? Bundle.main.localizedString(forKey: key, value: nil, table: nil)
            : localizedValue
    }

    func answerStringFallbackLocalizations(for answerLanguage: Language) -> [String] {
        switch answerLanguage {
        case .classicalChinese, .simplifiedChinese:
            return ["zh-Hans", "zh"]
        case .traditionalChinese:
            return ["zh-Hant", "zh-Hans", "zh"]
        case .english:
            return ["en"]
        case .japanese:
            return ["ja"]
        case .catalan:
            return ["ca", "es"]
        case .spanish:
            return ["es"]
        case .slovak:
            return ["sk"]
        default:
            let normalizedCode = answerLanguage.code
            let baseCode = normalizedCode.components(separatedBy: "-").first ?? normalizedCode
            return [normalizedCode, baseCode, "en"]
        }
    }

    func userCredentialStringDefaultsKey(
        _ key: ServiceConfigurationKey,
        provider: GrammarAnalysisProvider? = nil,
        defaultValue: String = ""
    )
        -> Defaults.Key<String> {
        serivceConfigurationKey(
            key,
            serviceType: serviceType(),
            id: provider.map(providerConfigurationID) ?? activeProviderConfigurationID,
            defaultValue: defaultValue
        )
    }

    func legacyUserCredentialStringDefaultsKey(
        _ key: ServiceConfigurationKey,
        defaultValue: String = ""
    )
        -> Defaults.Key<String> {
        serivceConfigurationKey(
            key,
            serviceType: serviceType(),
            id: legacyUserCredentialConfigurationID,
            defaultValue: defaultValue
        )
    }

    func userCredentialDefaultsKey<T: _DefaultsSerializable>(
        _ key: ServiceConfigurationKey,
        provider: GrammarAnalysisProvider? = nil,
        defaultValue: T
    )
        -> Defaults.Key<T> {
        serivceConfigurationKey(
            key,
            serviceType: serviceType(),
            id: provider.map(providerConfigurationID) ?? activeProviderConfigurationID,
            defaultValue: defaultValue
        )
    }

    func legacyUserCredentialDefaultsKey<T: _DefaultsSerializable>(
        _ key: ServiceConfigurationKey,
        defaultValue: T
    )
        -> Defaults.Key<T> {
        serivceConfigurationKey(
            key,
            serviceType: serviceType(),
            id: legacyUserCredentialConfigurationID,
            defaultValue: defaultValue
        )
    }

    func providerSupportedModels(from provider: GrammarAnalysisProvider) -> String {
        supportedModels(from: providerDefaultModels(for: provider))
    }

    func providerDefaultModels(for provider: GrammarAnalysisProvider) -> [String] {
        switch provider {
        case .openAI:
            Self.openAIDefaultModels
        case .deepSeek:
            Self.deepSeekDefaultModels
        case .customOpenAICompatible:
            []
        }
    }

    func migratedProvider(for endpoint: String) -> GrammarAnalysisProvider {
        let normalizedEndpoint = endpoint
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        if normalizedEndpoint.contains("api.deepseek.com") {
            return .deepSeek
        }
        if normalizedEndpoint.isEmpty ||
            normalizedEndpoint == Self.openAIOfficialEndpoint {
            return .openAI
        }
        return .customOpenAICompatible
    }
}
