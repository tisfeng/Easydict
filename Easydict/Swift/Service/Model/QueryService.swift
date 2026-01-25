//
//  QueryService.swift
//  Easydict
//
//  Created by tisfeng on 2025/03/09.
//  Copyright © 2025 izual. All rights reserved.
//

import AppKit
import Foundation

// MARK: - ServiceAPIKeyRequirement

public enum ServiceAPIKeyRequirement {
    case none
    case builtIn
    case userProvided

    // MARK: Internal

    /// Whether this service requires an API key for requests.
    var requiresKeyForRequest: Bool {
        self != .none
    }

    /// Whether this service needs the user to provide an API key.
    var needsUserProvidedKey: Bool {
        self == .userProvided
    }
}

// MARK: - QueryService

@objc(EZQueryService)
@objcMembers
open class QueryService: NSObject {
    // MARK: Lifecycle

    required public override init() {
        self.queryModel = QueryModel()
        super.init()
    }

    // MARK: Open

    open var uuid: String = ""
    open var enabled: Bool = true

    open var queryType: EZQueryTextType = []
    open var windowType: EZWindowType = .main

    open var autoCopyTranslatedTextBlock: ((QueryResult, Error?) -> ())?

    open var queryModel: QueryModel {
        didSet {
            result?.queryModel = queryModel
        }
    }

    open var result: QueryResult! {
        didSet {
            guard let result else { return }

            result.service = self
            result.serviceTypeWithUniqueIdentifier = serviceTypeWithUniqueIdentifier()
            result.queryModel = queryModel
            resultDidUpdate(result)
        }
    }

    open var enabledQuery: Bool {
        get { storedEnabledQuery }
        set {
            storedEnabledQuery = newValue
            LocalStorage.shared().setEnabledQuery(
                newValue,
                serviceType: serviceType(),
                serviceId: uuid,
                windowType: windowType
            )
        }
    }

    open var enabledAutoQuery: Bool {
        get {
            if serviceUsageStatus() == .alwaysOff {
                return false
            }

            if MyConfiguration.shared.intelligentQueryModeForWindowType(windowType) {
                let queryType = queryModel.queryText.queryType(
                    withLanguage: queryModel.queryFromLanguage,
                    maxWordCount: 1
                )

                return intelligentQueryTextType().contains(queryType)
            }

            return true
        }
        set { storedEnabledAutoQuery = newValue }
    }

    open var audioPlayer: EZAudioPlayer! {
        get {
            if storedAudioPlayer == nil {
                let player = EZAudioPlayer()
                player.service = self
                storedAudioPlayer = player
            }
            return storedAudioPlayer
        }
        set { storedAudioPlayer = newValue }
    }

    // MARK: - MJExtension

    /// Avoid MJExtension retain cycle.
    open class func mj_ignoredPropertyNames() -> [String] {
        ["result"]
    }

    // MARK: - Public API

    /// Supported languages.
    open func languages() -> [Language] {
        buildLanguageCachesIfNeeded()
        return cachedLanguages ?? []
    }

    /// Language enum to string code, nil if unsupported.
    @objc(languageCodeForLanguage:)
    open func languageCode(forLanguage language: Language) -> String? {
        buildLanguageCachesIfNeeded()
        return languageDictionary?.object(forKey: language) as? String
    }

    /// String code to language enum, returns `.auto` if unsupported.
    @objc(languageEnumFromCode:)
    open func languageEnum(fromCode langString: String) -> Language {
        buildLanguageCachesIfNeeded()
        return languageFromStringDict?[langString] ?? .auto
    }

    /// Index of the language in the supported list, returns 0 if missing.
    @objc(indexForLanguage:)
    open func index(forLanguage lang: Language) -> Int {
        buildLanguageCachesIfNeeded()
        return languageIndexDict?[lang]?.intValue ?? 0
    }

    /// Preprocess a query and return the result when handled.
    @nonobjc
    open func prehandleQueryText(
        _ text: String,
        from: Language,
        to: Language
    ) async throws
        -> (Bool, QueryResult) {
        let outcome = prehandleQueryTextOutcome(text, from: from, to: to)
        if outcome.handled {
            if let error = outcome.error {
                throw error
            }
            return (true, outcome.result)
        }
        return (false, outcome.result)
    }

    /// Get TTS language code.
    /// - Parameters:
    ///   - language: Text language.
    ///   - accent: English accent, such as en-US, en-GB.
    open func getTTSLanguageCode(_ language: Language, accent: String?) -> String {
        var currentLanguage = language
        if currentLanguage == .classicalChinese {
            currentLanguage = .simplifiedChinese
        }

        return languageCode(forLanguage: currentLanguage) ?? ""
    }

    @discardableResult
    open func resetServiceResult() -> QueryResult {
        let currentResult = result ?? QueryResult()
        currentResult.reset()

        let enabledReplaceTypes: [ActionType] = [
            ActionType.autoSelectQuery,
            ActionType.shortcutQuery,
            ActionType.invokeQuery,
        ]

        let actionType = queryModel.actionType
        if enabledReplaceTypes.contains(actionType) {
            currentResult.showReplaceButton = EventMonitor.shared.isSelectedTextEditable
        } else {
            currentResult.showReplaceButton = false
        }

        result = currentResult
        return currentResult
    }

    /// Starts a query using async/await and returns the final result.
    ///
    /// - NOTE: This function only returns the final result. For incremental results, use `startQueryStream(_:)`.
    open func startQuery(_ queryModel: QueryModel) async throws -> QueryResult {
        self.queryModel = queryModel

        let queryText = queryModel.queryText
        let fromLanguage = queryModel.queryFromLanguage
        let targetLanguage = queryModel.queryTargetLanguage

        let (handled, prehandleResult) = try await prehandleQueryText(
            queryText,
            from: fromLanguage,
            to: targetLanguage
        )
        if handled {
            return prehandleResult
        }

        return try await translate(queryText, from: fromLanguage, to: targetLanguage)
    }

    /// Starts a query and reports incremental results on the main thread.
    ///
    /// - NOTE: The completionHandler will be called many time for stream service.
    open func startQueryStream(
        _ queryModel: QueryModel,
        completionHandler: @escaping (QueryResult, Error?) -> ()
    ) {
        let task = Task { [weak self] in
            guard let self else { return }

            var didYieldError = false

            do {
                for try await result in startQueryStream(queryModel) {
                    if result.error != nil {
                        didYieldError = true
                    }
                    await MainActor.run {
                        completionHandler(result, result.error)
                    }
                }
            } catch {
                if !didYieldError {
                    let errorResult = ensureResult()
                    if errorResult.error == nil {
                        errorResult.error = QueryError.queryError(from: error)
                    }
                    await MainActor.run {
                        completionHandler(errorResult, errorResult.error)
                    }
                }
            }
        }

        let serviceType = serviceTypeWithUniqueIdentifier()
        queryModel.setStop({ [weak self] in
            task.cancel()
            self?.cancelStream()
        }, serviceType: serviceType)
    }

    /// Starts a query using async stream and yields incremental results.
    open func startQueryStream(_ queryModel: QueryModel)
        -> AsyncThrowingStream<QueryResult, Error> {
        AsyncThrowingStream { [weak self] continuation in
            Task {
                guard let self else {
                    continuation.finish()
                    return
                }

                self.queryModel = queryModel

                let queryText = queryModel.queryText
                let fromLanguage = queryModel.queryFromLanguage
                let targetLanguage = queryModel.queryTargetLanguage

                var didYieldError = false

                do {
                    let (handled, prehandleResult) = try await self.prehandleQueryText(
                        queryText,
                        from: fromLanguage,
                        to: targetLanguage
                    )
                    if handled {
                        continuation.yield(prehandleResult)
                        continuation.finish()
                        return
                    }

                    for try await result in self.translateStream(
                        queryText,
                        from: fromLanguage,
                        to: targetLanguage
                    ) {
                        if result.error != nil {
                            didYieldError = true
                        }
                        continuation.yield(result)
                    }

                    continuation.finish()
                } catch {
                    if !didYieldError {
                        let errorResult = self.ensureResult()
                        if errorResult.error == nil {
                            errorResult.error = QueryError.queryError(from: error)
                        }
                        continuation.yield(errorResult)
                    }
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    open func configurationListItems() -> Any? {
        nil
    }

    /// Cancels the current streaming request if supported.
    open func cancelStream() {}

    // MARK: - Overridable hooks

    /// Invoked when `result` is set to allow subclasses to customize side effects.
    open func resultDidUpdate(_ result: QueryResult) {}

    // MARK: - Required subclass overrides

    open func serviceType() -> ServiceType {
        fatalError("You must override \(#function) in a subclass.")
    }

    open func serviceTypeWithUniqueIdentifier() -> String {
        serviceType().rawValue
    }

    open func name() -> String {
        fatalError("You must override \(#function) in a subclass.")
    }

    open func link() -> String? {
        nil
    }

    /// Word direct link. If nil, fallback to `link`.
    open func wordLink(_ queryModel: QueryModel) -> String? {
        link()
    }

    open func supportLanguagesDictionary() -> MMOrderedDictionary {
        fatalError("You must override \(#function) in a subclass.")
    }

    /// Translate text and return the final result.
    @nonobjc
    open func translate(
        _ text: String,
        from: Language,
        to: Language
    ) async throws
        -> QueryResult {
        fatalError("You must override \(#function) in a subclass.")
    }

    /// Translate text and return an async stream of results.
    @nonobjc
    open func translateStream(
        _ text: String,
        from: Language,
        to: Language
    )
        -> AsyncThrowingStream<QueryResult, Error> {
        AsyncThrowingStream { [weak self] continuation in
            Task {
                guard let self else {
                    continuation.finish()
                    return
                }

                do {
                    let result = try await self.translate(text, from: from, to: to)
                    continuation.yield(result)
                    continuation.finish()
                } catch {
                    let errorResult = self.ensureResult()
                    if errorResult.error == nil {
                        errorResult.error = QueryError.queryError(from: error)
                    }
                    continuation.yield(errorResult)
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    // MARK: - Optional subclass overrides

    open func autoConvertTraditionalChinese() -> Bool {
        false
    }

    open func serviceUsageStatus() -> EZServiceUsageStatus {
        .default
    }

    open func supportedQueryType() -> EZQueryTextType {
        [.translation, .sentence]
    }

    open func intelligentQueryTextType() -> EZQueryTextType {
        [.translation, .sentence]
    }

    open func hasPrivateAPIKey() -> Bool {
        false
    }

    open func apiKeyRequirement() -> ServiceAPIKeyRequirement {
        .userProvided
    }

    open func totalFreeQueryCharacterCount() -> Int {
        100 * 10_000
    }

    open func isStream() -> Bool {
        false
    }

    open func isDuplicatable() -> Bool {
        false
    }

    open func isDeletable(_ windowType: EZWindowType) -> Bool {
        true
    }

    /// Detect the language of the given text.
    @nonobjc
    open func detectText(_ text: String) async throws -> Language {
        fatalError("You must override \(#function) in a subclass.")
    }

    /// Detect the language of the given text using completion callbacks.
    open func detectText(
        _ text: String,
        completionHandler: @escaping (Language, Error?) -> ()
    ) {
        Task { [weak self] in
            guard let self else { return }
            do {
                let language = try await detectText(text)
                await MainActor.run {
                    completionHandler(language, nil)
                }
            } catch {
                await MainActor.run {
                    completionHandler(.auto, error)
                }
            }
        }
    }

    /// Generate audio for the given text with an optional accent.
    open func textToAudio(
        _ text: String,
        fromLanguage: Language,
        accent: String? = nil
    ) async throws
        -> String? {
        try await audioPlayer.defaultTTSService.textToAudio(text, fromLanguage: fromLanguage, accent: accent)
    }

    /// Perform OCR for the given image.
    open func ocr(
        _ image: NSImage,
        from: Language,
        to: Language
    ) async throws
        -> EZOCRResult? {
        fatalError("You must override \(#function) in a subclass.")
    }

    /// Perform OCR for the given query model.
    open func ocr(_ queryModel: QueryModel) async throws -> EZOCRResult? {
        guard let image = queryModel.ocrImage else {
            throw QueryError.error(type: .parameter, message: "Image is nil")
        }
        return try await ocr(
            image,
            from: queryModel.queryFromLanguage,
            to: queryModel.queryTargetLanguage
        )
    }

    /// Perform OCR and translation with an intermediate OCR callback.
    open func ocrAndTranslate(
        _ image: NSImage,
        from: Language,
        to: Language,
        ocrSuccess: @escaping (EZOCRResult, Bool) -> ()
    ) async throws
        -> (EZOCRResult?, QueryResult?) {
        fatalError("You must override \(#function) in a subclass.")
    }

    // MARK: Private

    private var storedEnabledQuery: Bool = true

    private var storedEnabledAutoQuery: Bool = true

    private var storedAudioPlayer: EZAudioPlayer?

    // MARK: - Language caches

    private var languageDictionary: MMOrderedDictionary?
    private var cachedLanguages: [Language]?
    private var languageFromStringDict: [String: Language]?
    private var languageIndexDict: [Language: NSNumber]?

    private func buildLanguageCachesIfNeeded() {
        if languageDictionary == nil {
            languageDictionary = supportLanguagesDictionary()
        }

        if cachedLanguages == nil {
            cachedLanguages = languageDictionary?.allKeys().compactMap { $0 as? Language }
        }

        if languageFromStringDict == nil, let dict = languageDictionary {
            var map: [String: Language] = [:]
            for language in cachedLanguages ?? [] {
                if let code = dict.object(forKey: language) as? String {
                    map[code] = language
                }
            }
            languageFromStringDict = map
        }

        if languageIndexDict == nil, let languages = cachedLanguages {
            var indexMap: [Language: NSNumber] = [:]
            for (index, language) in languages.enumerated() {
                indexMap[language] = NSNumber(value: index)
            }
            languageIndexDict = indexMap
        }
    }

    /// Builds and returns a consistent query result for prehandle checks.
    private func prehandleQueryTextOutcome(
        _ text: String,
        from: Language,
        to: Language
    )
        -> (handled: Bool, result: QueryResult, error: Error?) {
        queryModel.inputText = text

        if result == nil {
            result = QueryResult()
        }

        let currentResult = result ?? QueryResult()
        result = currentResult

        currentResult.queryText = text
        currentResult.from = from
        currentResult.to = to
        currentResult.error = nil

        // Chinese conversion prehandle.
        let languages = [from, to]
        if autoConvertTraditionalChinese(),
           EZLanguageManager.shared().onlyContainsChineseLanguages(languages) {
            var translatedText: String?
            if to == .simplifiedChinese {
                translatedText = text.toSimplifiedChinese()
            } else if to == .traditionalChinese {
                translatedText = text.toTraditionalChinese()
            }

            if let translatedText {
                currentResult.translatedResults = [translatedText]
                return (true, currentResult, nil)
            }
        }

        guard let fromLanguage = languageCode(forLanguage: from),
              let toLanguage = languageCode(forLanguage: to)
        else {
            let error = QueryError.unsupportedLanguageError(service: self)
            currentResult.error = error
            return (true, currentResult, error)
        }

        _ = fromLanguage
        _ = toLanguage

        // Free quota check for services requiring private API key.
        if apiKeyRequirement().needsUserProvidedKey,
           !hasPrivateAPIKey(),
           !LocalStorage.shared().hasFreeQuotaLeft(self) {
            let error = QueryError.error(
                type: .api,
                message: nil,
                errorDataMessage: NSLocalizedString("insufficient_quota_prompt", comment: "")
            )
            currentResult.promptURL = link()
            currentResult.error = error
            return (true, currentResult, error)
        }

        return (false, currentResult, nil)
    }

    /// Ensure that `result` is non-nil and return it.
    private func ensureResult() -> QueryResult {
        if let result {
            return result
        }
        let newResult = QueryResult()
        result = newResult
        return newResult
    }
}
