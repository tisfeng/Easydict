//
//  GrammarAnalysisService.swift
//  Easydict
//
//  Created by Yi Miao on 2026/7/6.
//

import Defaults
import Foundation
import SwiftUI

// MARK: - GrammarAnalysisService

/// Provides a dedicated grammar-analysis card for query pages.
/// The service keeps impact low by reusing the existing AI service card flow,
/// while internally applying a local filter and a cheap-model gate before the
/// full grammar analysis request.
@objc(EZGrammarAnalysisService)
final class GrammarAnalysisService: AIToolService {
    // MARK: Lifecycle

    required init() {
        self.isSeedingBuiltInModels = true
        super.init()
        self.isSeedingBuiltInModels = false
        migrateLegacyProviderConfigurationIfNeeded()
        migrateLegacyCustomConfigurationIfNeeded()
    }

    // MARK: Internal

    static let openAIOfficialEndpoint = "https://api.openai.com/v1/chat/completions"
    static let openAIDefaultModels = ["gpt-4o-mini"]
    static let deepSeekOfficialEndpoint = "https://api.deepseek.com/v1/chat/completions"
    static let deepSeekDefaultModels = DeepSeekModel.allCases.map(\.rawValue)

    override var canFetchRemoteModels: Bool {
        credentialSource.usesPrivateKey
    }

    override var defaultModel: String {
        ZhipuModel.glm_4_5_flash.rawValue
    }

    override var defaultEndpoint: String {
        if credentialSource == .builtIn {
            return builtInAIEndpoint
        }

        return providerDefaultEndpoint
    }

    override var modelKey: Defaults.Key<String> {
        if credentialSource.usesPrivateKey {
            return userCredentialStringDefaultsKey(.model, defaultValue: providerDefaultModel)
        }
        return stringDefaultsKey(.model, defaultValue: defaultModel)
    }

    override var supportedModelsKey: Defaults.Key<String> {
        if credentialSource.usesPrivateKey {
            return userCredentialStringDefaultsKey(
                .supportedModels,
                defaultValue: providerSupportedModels
            )
        }
        return stringDefaultsKey(
            .supportedModels,
            defaultValue: supportedModels(from: defaultModels)
        )
    }

    override var validModelsKey: Defaults.Key<[String]> {
        if credentialSource.usesPrivateKey {
            return userCredentialDefaultsKey(.validModels, defaultValue: providerDefaultModels)
        }
        return serviceDefaultsKey(.validModels, defaultValue: defaultModels)
    }

    override var supportedModels: String {
        get {
            if credentialSource.usesPrivateKey {
                return Defaults[userCredentialStringDefaultsKey(
                    .supportedModels,
                    defaultValue: providerSupportedModels
                )]
            }
            return Defaults[builtInSupportedModelsStorageKey]
        }
        set {
            if isSeedingBuiltInModels {
                Defaults[builtInSupportedModelsStorageKey] = newValue
                Defaults[builtInValidModelsStorageKey] = validModels(from: newValue)
                return
            }

            if credentialSource.usesPrivateKey {
                let customKey = userCredentialStringDefaultsKey(
                    .supportedModels,
                    defaultValue: providerSupportedModels
                )
                let customValidModelsKey = userCredentialDefaultsKey(
                    .validModels,
                    defaultValue: providerDefaultModels
                )
                Defaults[customKey] = newValue
                Defaults[customValidModelsKey] = validModels(from: newValue)
            } else {
                Defaults[builtInSupportedModelsStorageKey] = newValue
                Defaults[builtInValidModelsStorageKey] = validModels(from: newValue)
            }
        }
    }

    override var apiKey: String {
        credentialSource == .builtIn ? builtInAIAPIKey : Defaults[apiKeyKey]
    }

    override var apiKeyKey: Defaults.Key<String> {
        userCredentialStringDefaultsKey(.apiKey)
    }

    override var apiKeyPlaceholder: String {
        switch credentialSource {
        case .builtIn:
            super.apiKeyPlaceholder
        case .userKey:
            String(localized: "grammar.analysis.credential_source.openai_key.title")
        case .deepSeekKey:
            String(localized: "grammar.analysis.credential_source.deepseek_key.title")
        }
    }

    override var endpoint: String {
        if credentialSource == .builtIn {
            return builtInAIEndpoint
        }

        let storedEndpoint = Defaults[endpointKey]
        return storedEndpoint.isEmpty ? providerDefaultEndpoint : storedEndpoint
    }

    override var endpointKey: Defaults.Key<String> {
        userCredentialStringDefaultsKey(.endpoint, defaultValue: providerDefaultEndpoint)
    }

    override var recommendedEndpoint: String? {
        guard credentialSource.usesPrivateKey else {
            return nil
        }

        return switch provider {
        case .openAI:
            Self.openAIOfficialEndpoint
        case .deepSeek:
            Self.deepSeekOfficialEndpoint
        case .customOpenAICompatible:
            nil
        }
    }

    override var remoteModelsEndpoint: String? {
        guard credentialSource.usesPrivateKey else {
            return nil
        }

        return switch provider {
        case .deepSeek:
            "https://api.deepseek.com/models"
        case .customOpenAICompatible, .openAI:
            nil
        }
    }

    override var remoteModelFetchRequiresEndpoint: Bool {
        guard credentialSource.usesPrivateKey else {
            return false
        }

        return provider != .deepSeek
    }

    override var observeKeys: [Defaults.Key<String>] {
        if credentialSource.usesPrivateKey {
            [apiKeyKey, endpointKey, supportedModelsKey]
        } else {
            [supportedModelsKey]
        }
    }

    override var serviceUsageStatusKey: Defaults.Key<ServiceUsageStatus> {
        serviceDefaultsKey(.serviceUsageStatus, defaultValue: .alwaysOn)
    }

    override var usesStreamingTransport: Bool {
        false
    }

    var analysisModeKey: Defaults.Key<GrammarAnalysisMode> {
        serviceDefaultsKey(.grammarAnalysisMode, defaultValue: .general)
    }

    var analysisMode: GrammarAnalysisMode {
        canUseIELTSMode ? Defaults[analysisModeKey] : .general
    }

    var canUseIELTSMode: Bool {
        EZLanguageManager.shared().containsEnglishInPreferredTwoLanguages()
    }

    var credentialSourceKey: Defaults.Key<GrammarAnalysisCredentialSource> {
        serviceDefaultsKey(.grammarAnalysisCredentialSource, defaultValue: .builtIn)
    }

    var credentialSource: GrammarAnalysisCredentialSource {
        Defaults[credentialSourceKey]
    }

    var providerKey: Defaults.Key<GrammarAnalysisProvider> {
        serviceDefaultsKey(.grammarAnalysisProvider, defaultValue: .openAI)
    }

    var provider: GrammarAnalysisProvider {
        switch credentialSource {
        case .builtIn:
            Defaults[providerKey]
        case .userKey:
            Defaults[providerKey] == .deepSeek ? .openAI : Defaults[providerKey]
        case .deepSeekKey:
            .deepSeek
        }
    }

    override func name() -> String {
        NSLocalizedString("grammar_analysis_service", comment: "")
    }

    override func serviceType() -> ServiceType {
        .grammarAnalysis
    }

    override func configurationListItems() -> Any {
        GrammarAnalysisConfigurationView(service: self)
    }

    override func apiKeyRequirement() -> ServiceAPIKeyRequirement {
        credentialSource == .builtIn ? .builtIn : .userProvided
    }

    override func hasPrivateAPIKey() -> Bool {
        credentialSource.usesPrivateKey && !Defaults[apiKeyKey].isEmpty
    }

    override func cancelStream() {
        currentTask?.cancel()
        currentTask = nil
        currentTaskID = nil
    }

    override func supportedQueryType() -> EZQueryTextType {
        [.translation, .sentence]
    }

    override func intelligentQueryTextType() -> EZQueryTextType {
        [.translation, .sentence]
    }

    override func isStream() -> Bool {
        true
    }

    override func translateStream(
        _ text: String,
        from: Language,
        to: Language
    )
        -> AsyncThrowingStream<QueryResult, Error> {
        let activeResult = result ?? QueryResult()
        let activeGeneration = resultGeneration
        if result == nil {
            result = activeResult
        }

        activeResult.translatedResults = nil
        activeResult.wordResult = nil
        activeResult.error = nil
        activeResult.raw = nil
        activeResult.promptTitle = nil
        activeResult.promptURL = nil
        activeResult.htmlString = nil
        activeResult.htmlStrings = nil
        activeResult.innerTexts = nil
        activeResult.validationMessage = nil
        activeResult.translateResultsTopInset = 0
        activeResult.markdownRenderingOverride = true
        activeResult.copiedText = nil
        activeResult.webViewManager.reset()
        activeResult.queryText = text
        activeResult.from = from
        activeResult.to = to
        activeResult.isShowing = true
        activeResult.isLoading = true
        activeResult.isStreamFinished = false

        return AsyncThrowingStream { [weak self] continuation in
            guard let self else {
                continuation.finish()
                return
            }

            let taskID = UUID()
            let task = Task {
                defer {
                    // `resetServiceResult()` reuses the same result object across generations.
                    // Only the active generation should finalize the shared loading flags.
                    if self.resultGeneration == activeGeneration {
                        activeResult.isLoading = false
                        activeResult.isStreamFinished = true
                    }
                    if self.currentTaskID == taskID {
                        self.currentTask = nil
                        self.currentTaskID = nil
                    }
                }

                do {
                    let answerLanguage = self.analysisAnswerLanguage(targetLanguage: to)

                    if self.shouldSkipForModeEligibility(sourceLanguage: from) {
                        guard self.resultGeneration == activeGeneration else {
                            continuation.finish()
                            return
                        }
                        activeResult.translatedResults = [
                            self.ieltsLanguageSkipMessage(answerLanguage: answerLanguage)
                        ]
                        self.completeFinalResultState(activeResult)
                        continuation.yield(activeResult)
                        continuation.finish()
                        return
                    }

                    if self.shouldSkipForLocalHeuristics(text) {
                        guard self.resultGeneration == activeGeneration else {
                            continuation.finish()
                            return
                        }
                        activeResult.translatedResults = [self.skipMessage(answerLanguage: answerLanguage)]
                        self.completeFinalResultState(activeResult)
                        continuation.yield(activeResult)
                        continuation.finish()
                        return
                    }

                    let decision = try await self.fetchGateDecision(for: text)
                    if !decision.shouldAnalyze,
                       !self.looksClearlyAnalyzableNaturalLanguage(text) {
                        guard self.resultGeneration == activeGeneration else {
                            continuation.finish()
                            return
                        }
                        activeResult.translatedResults = [self.skipMessage(answerLanguage: answerLanguage)]
                        self.completeFinalResultState(activeResult)
                        continuation.yield(activeResult)
                        continuation.finish()
                        return
                    }

                    guard self.resultGeneration == activeGeneration else {
                        continuation.finish()
                        return
                    }
                    let analysis = try await self.fetchGrammarAnalysis(
                        for: text,
                        sourceLanguage: from,
                        targetLanguage: to
                    )
                    guard self.resultGeneration == activeGeneration else {
                        continuation.finish()
                        return
                    }
                    activeResult.translatedResults = [analysis]
                    self.completeFinalResultState(activeResult)
                    continuation.yield(activeResult)
                    continuation.finish()
                } catch is CancellationError {
                    continuation.finish()
                } catch {
                    guard self.resultGeneration == activeGeneration else {
                        continuation.finish()
                        return
                    }
                    activeResult.error = QueryError.queryError(from: error)
                    self.completeFinalResultState(activeResult)
                    continuation.yield(activeResult)
                    continuation.finish(throwing: error)
                }
            }

            currentTask = task
            currentTaskID = taskID
            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }

    override func validate() async -> QueryResult {
        resetServiceResult()

        let text = analysisMode == .ielts
            ? Self.ieltsValidationSampleText
            : Self.generalValidationSampleText
        var latestResult = result ?? QueryResult()

        do {
            for try await result in translateStream(
                text,
                from: .english,
                to: .simplifiedChinese
            ) {
                latestResult = result
            }
        } catch {
            latestResult = result ?? latestResult
            if latestResult.error == nil {
                latestResult.error = QueryError.queryError(from: error)
            }
        }

        return latestResult
    }

    func normalizeAnalysisModeIfNeeded() {
        guard !canUseIELTSMode, Defaults[analysisModeKey] == .ielts else {
            return
        }

        Defaults[analysisModeKey] = .general
    }

    // MARK: Private

    private static let generalValidationSampleText =
        "The report that I submitted yesterday still needs a few small revisions."

    private static let ieltsValidationSampleText =
        "Although the plan changed twice, we still finished the work on time."

    private var isSeedingBuiltInModels = false

    private var currentTask: Task<(), Never>?

    private var currentTaskID: UUID?

    private let providerConfigurationMigrationKey = Defaults.Key<Bool>(
        "EZGrammarAnalysisProviderConfigurationMigrationV1Key",
        default: false
    )

    private let customConfigurationCleanupKey = Defaults.Key<Bool>(
        "EZGrammarAnalysisCustomConfigurationCleanupV2Key",
        default: false
    )

    private func migrateLegacyProviderConfigurationIfNeeded() {
        guard !Defaults[providerConfigurationMigrationKey] else { return }

        let legacyEndpointKey = legacyUserCredentialStringDefaultsKey(.endpoint, defaultValue: "")
        let legacyModelsKey = legacyUserCredentialStringDefaultsKey(.supportedModels, defaultValue: "")
        let legacyModelKey = legacyUserCredentialStringDefaultsKey(.model, defaultValue: "")
        let legacyValidModelsKey = legacyUserCredentialDefaultsKey(.validModels, defaultValue: [String]())
        let legacyAPIKeyKey = legacyUserCredentialStringDefaultsKey(.apiKey, defaultValue: "")

        let legacyEndpoint = Defaults[legacyEndpointKey].trim()
        let legacySupportedModels = Defaults[legacyModelsKey].trim()
        let legacyModel = Defaults[legacyModelKey].trim()
        let legacyValidModels = Defaults[legacyValidModelsKey]
        let legacyAPIKey = Defaults[legacyAPIKeyKey].trim()

        let legacyDefaultModels = supportedModels(from: defaultModels)
        let legacyDefaultModelSet = Set(defaultModels)
        let matchesLegacyModel = legacyModel.isEmpty || legacyDefaultModelSet.contains(legacyModel)

        let matchesLegacySeed = legacyAPIKey.isEmpty &&
            legacyEndpoint == builtInAIEndpoint &&
            legacySupportedModels == legacyDefaultModels &&
            legacyValidModels == defaultModels &&
            matchesLegacyModel

        let hasLegacyContent = !legacyEndpoint.isEmpty ||
            !legacySupportedModels.isEmpty ||
            !legacyModel.isEmpty ||
            !legacyValidModels.isEmpty ||
            !legacyAPIKey.isEmpty

        guard hasLegacyContent, !matchesLegacySeed else {
            Defaults[providerConfigurationMigrationKey] = true
            return
        }

        let targetProvider = migratedProvider(for: legacyEndpoint)

        let targetProviderDefaultModels = providerDefaultModels(for: targetProvider)
        let parsedLegacySupportedModels = validModels(from: legacySupportedModels)
        let migratedValidModels: [String]
        if !legacyValidModels.isEmpty {
            migratedValidModels = legacyValidModels
        } else if !parsedLegacySupportedModels.isEmpty {
            migratedValidModels = parsedLegacySupportedModels
        } else {
            migratedValidModels = targetProviderDefaultModels
        }
        let migratedSupportedModels = !parsedLegacySupportedModels.isEmpty
            ? legacySupportedModels
            : supportedModels(from: migratedValidModels)
        let migratedModel = !legacyModel.isEmpty
            ? legacyModel
            : migratedValidModels.first ?? ""

        Defaults[userCredentialStringDefaultsKey(.apiKey, provider: targetProvider)] = legacyAPIKey
        Defaults[userCredentialStringDefaultsKey(
            .endpoint,
            provider: targetProvider,
            defaultValue: targetProvider == .openAI ? Self.openAIOfficialEndpoint : ""
        )] = legacyEndpoint
        Defaults[userCredentialStringDefaultsKey(
            .supportedModels,
            provider: targetProvider,
            defaultValue: providerSupportedModels(from: targetProvider)
        )] = migratedSupportedModels
        Defaults[userCredentialDefaultsKey(
            .validModels,
            provider: targetProvider,
            defaultValue: targetProviderDefaultModels
        )] = migratedValidModels
        Defaults[userCredentialStringDefaultsKey(
            .model,
            provider: targetProvider,
            defaultValue: targetProviderDefaultModels.first ?? ""
        )] = migratedModel

        Defaults[providerKey] = targetProvider
        if targetProvider == .deepSeek, Defaults[credentialSourceKey] == .userKey {
            Defaults[credentialSourceKey] = .deepSeekKey
        }

        Defaults[legacyEndpointKey] = ""
        Defaults[legacyModelsKey] = ""
        Defaults[legacyModelKey] = ""
        Defaults[legacyValidModelsKey] = []
        Defaults[legacyAPIKeyKey] = ""
        Defaults[providerConfigurationMigrationKey] = true
    }

    private func migrateLegacyCustomConfigurationIfNeeded() {
        guard !Defaults[customConfigurationCleanupKey] else { return }

        let legacyEndpointKey = legacyUserCredentialStringDefaultsKey(.endpoint, defaultValue: "")
        let legacyModelsKey = legacyUserCredentialStringDefaultsKey(.supportedModels, defaultValue: "")
        let legacyModelKey = legacyUserCredentialStringDefaultsKey(.model, defaultValue: "")
        let legacyValidModelsKey = legacyUserCredentialDefaultsKey(.validModels, defaultValue: [String]())
        let legacyAPIKeyKey = legacyUserCredentialStringDefaultsKey(.apiKey, defaultValue: "")

        let storedEndpoint = Defaults[legacyEndpointKey]
        let storedModels = Defaults[legacyModelsKey]
        let storedModel = Defaults[legacyModelKey]
        let storedAPIKey = Defaults[legacyAPIKeyKey]
        let storedValidModels = Defaults[legacyValidModelsKey]
        let legacyDefaultModels = supportedModels(from: defaultModels)
        let legacyDefaultModelSet = Set(defaultModels)
        let matchesLegacyModel = storedModel.isEmpty || legacyDefaultModelSet.contains(storedModel)

        let matchesLegacySeed = storedAPIKey.isEmpty &&
            storedEndpoint == builtInAIEndpoint &&
            storedModels == legacyDefaultModels &&
            storedValidModels == defaultModels &&
            matchesLegacyModel

        if matchesLegacySeed {
            Defaults[legacyEndpointKey] = ""
            Defaults[legacyModelsKey] = ""
            Defaults[legacyModelKey] = ""
            Defaults[legacyValidModelsKey] = []
        }

        Defaults[customConfigurationCleanupKey] = true
    }
}
