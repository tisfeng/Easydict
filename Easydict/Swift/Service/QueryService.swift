//
//  QueryService.swift
//  Easydict
//
//  Created by tisfeng on 2025/03/09.
//  Copyright © 2025 izual. All rights reserved.
//

import AppKit
import Foundation

@objc(EZQueryService)
@objcMembers
open class QueryService: NSObject {
    // MARK: Lifecycle

    required public override init() {
        super.init()
    }

    // MARK: Open

    // MARK: - Public properties

    open dynamic var uuid: String = ""
    open dynamic var queryModel: EZQueryModel!

    open dynamic var enabled: Bool = true

    open dynamic var queryType: EZQueryTextType = []
    open dynamic var windowType: EZWindowType = .main

    open dynamic var autoCopyTranslatedTextBlock: ((EZQueryResult, Error?) -> ())?

    open dynamic var result: EZQueryResult! {
        didSet {
            guard let result else { return }

            result.service = self
            result.serviceTypeWithUniqueIdentifier = serviceTypeWithUniqueIdentifier()
            result.queryModel = queryModel
            resultDidUpdate(result)
        }
    }

    open dynamic var enabledQuery: Bool {
        get { storedEnabledQuery }
        set {
            storedEnabledQuery = newValue
            EZLocalStorage.shared().setEnabledQuery(
                newValue,
                serviceType: serviceType(),
                serviceId: uuid,
                windowType: windowType
            )
        }
    }

    open dynamic var enabledAutoQuery: Bool {
        get {
            if serviceUsageStatus() == .alwaysOff {
                return false
            }

            if Configuration.shared.intelligentQueryModeForWindowType(windowType) {
                guard let model = queryModel else { return false }
                let queryType = model.queryText.queryType(
                    withLanguage: model.queryFromLanguage,
                    maxWordCount: 1
                )

                return intelligentQueryTextType().contains(queryType)
            }

            return true
        }
        set { storedEnabledAutoQuery = newValue }
    }

    open dynamic var audioPlayer: EZAudioPlayer! {
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
    open dynamic func languages() -> [Language] {
        buildLanguageCachesIfNeeded()
        return cachedLanguages ?? []
    }

    /// Language enum to string code, nil if unsupported.
    @objc(languageCodeForLanguage:)
    open dynamic func languageCode(forLanguage language: Language) -> String? {
        buildLanguageCachesIfNeeded()
        return languageDictionary?.object(forKey: language) as? String
    }

    /// String code to language enum, returns `.auto` if unsupported.
    @objc(languageEnumFromCode:)
    open dynamic func languageEnum(fromCode langString: String) -> Language {
        buildLanguageCachesIfNeeded()
        return languageFromStringDict?[langString] ?? .auto
    }

    /// Index of the language in the supported list, returns 0 if missing.
    @objc(indexForLanguage:)
    open dynamic func index(forLanguage lang: Language) -> Int {
        buildLanguageCachesIfNeeded()
        return languageIndexDict?[lang]?.intValue ?? 0
    }

    /// Preprocess a query. Returns true if handled (no further request needed).
    @objc(prehandleQueryText:from:to:completion:)
    open dynamic func prehandleQueryText(
        _ text: String,
        from: Language,
        to: Language,
        completion: @escaping (EZQueryResult, Error?) -> ()
    )
        -> Bool {
        if queryModel == nil {
            let model = EZQueryModel()
            model.userSourceLanguage = from
            model.userTargetLanguage = to
            queryModel = model
        }
        queryModel.inputText = text

        if result == nil {
            result = EZQueryResult()
        }

        result.queryText = text
        result.from = from
        result.to = to

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
                result.translatedResults = [translatedText]
                completion(result, nil)
                return true
            }
        }

        guard let fromLanguage = languageCode(forLanguage: from),
              let toLanguage = languageCode(forLanguage: to)
        else {
            completion(result, QueryError.unsupportedLanguageError(service: self))
            return true
        }

        _ = fromLanguage
        _ = toLanguage

        // Free quota check for services requiring private API key.
        if needPrivateAPIKey(),
           !hasPrivateAPIKey(),
           !EZLocalStorage.shared().hasFreeQuotaLeft(self) {
            let error = QueryError.error(
                type: .api,
                message: nil,
                errorDataMessage: NSLocalizedString("insufficient_quota_prompt", comment: "")
            )
            result.promptURL = link()
            completion(result, error)
            return true
        }

        return false
    }

    /// Get TTS language code.
    /// - Parameters:
    ///   - language: Text language.
    ///   - accent: English accent, such as en-US, en-GB.
    open dynamic func getTTSLanguageCode(_ language: Language, accent: String?) -> String {
        var currentLanguage = language
        if currentLanguage == .classicalChinese {
            currentLanguage = .simplifiedChinese
        }

        return languageCode(forLanguage: currentLanguage) ?? ""
    }

    @discardableResult
    open dynamic func resetServiceResult() -> EZQueryResult {
        let currentResult = result ?? EZQueryResult()
        currentResult.reset()

        let enabledReplaceTypes: [ActionType] = [
            ActionType.autoSelectQuery,
            ActionType.shortcutQuery,
            ActionType.invokeQuery,
        ]

        if let actionType = queryModel?.actionType,
           enabledReplaceTypes.contains(actionType) {
            currentResult.showReplaceButton = EZEventMonitor.shared().isSelectedTextEditable
        } else {
            currentResult.showReplaceButton = false
        }

        result = currentResult
        return currentResult
    }

    open dynamic func startQuery(
        _ queryModel: EZQueryModel,
        completion: @escaping (EZQueryResult, Error?) -> ()
    ) {
        self.queryModel = queryModel

        let queryText = queryModel.queryText
        let fromLanguage = queryModel.queryFromLanguage
        let targetLanguage = queryModel.queryTargetLanguage

        if prehandleQueryText(queryText, from: fromLanguage, to: targetLanguage, completion: completion) {
            return
        }

        translate(queryText, from: fromLanguage, to: targetLanguage, completion: completion)
    }

    open dynamic func configurationListItems() -> Any? {
        nil
    }

    // MARK: - Overridable hooks

    /// Invoked when `result` is set to allow subclasses to customize side effects.
    open func resultDidUpdate(_ result: EZQueryResult) {}

    // MARK: - Required subclass overrides

    open dynamic func serviceType() -> ServiceType {
        fatalError("You must override \(#function) in a subclass.")
    }

    open dynamic func serviceTypeWithUniqueIdentifier() -> String {
        serviceType().rawValue
    }

    open dynamic func name() -> String {
        fatalError("You must override \(#function) in a subclass.")
    }

    open dynamic func link() -> String? {
        nil
    }

    /// Word direct link. If nil, fallback to `link`.
    open dynamic func wordLink(_ queryModel: EZQueryModel) -> String? {
        link()
    }

    open dynamic func supportLanguagesDictionary() -> MMOrderedDictionary {
        fatalError("You must override \(#function) in a subclass.")
    }

    open dynamic func translate(
        _ text: String,
        from: Language,
        to: Language,
        completion: @escaping (EZQueryResult, Error?) -> ()
    ) {
        fatalError("You must override \(#function) in a subclass.")
    }

    // MARK: - Optional subclass overrides

    open dynamic func autoConvertTraditionalChinese() -> Bool {
        false
    }

    open dynamic func serviceUsageStatus() -> EZServiceUsageStatus {
        .default
    }

    open dynamic func supportedQueryType() -> EZQueryTextType {
        [.translation, .sentence]
    }

    open dynamic func intelligentQueryTextType() -> EZQueryTextType {
        [.translation, .sentence]
    }

    open dynamic func hasPrivateAPIKey() -> Bool {
        false
    }

    open dynamic func needPrivateAPIKey() -> Bool {
        false
    }

    open dynamic func totalFreeQueryCharacterCount() -> Int {
        100 * 10_000
    }

    open dynamic func isStream() -> Bool {
        false
    }

    open dynamic func isDuplicatable() -> Bool {
        false
    }

    open dynamic func isDeletable(_ windowType: EZWindowType) -> Bool {
        true
    }

    open dynamic func detectText(
        _ text: String,
        completion: @escaping (Language, Error?) -> ()
    ) {
        fatalError("You must override \(#function) in a subclass.")
    }

    open dynamic func textToAudio(
        _ text: String,
        fromLanguage: Language,
        completion: @escaping (String?, Error?) -> ()
    ) {
        audioPlayer.defaultTTSService.textToAudio(
            text,
            fromLanguage: fromLanguage,
            completion: completion
        )
    }

    open dynamic func textToAudio(
        _ text: String,
        fromLanguage: Language,
        accent: String?,
        completion: @escaping (String?, Error?) -> ()
    ) {
        textToAudio(text, fromLanguage: fromLanguage, completion: completion)
    }

    open dynamic func ocr(
        _ image: NSImage,
        from: Language,
        to: Language,
        completion: @escaping (EZOCRResult?, Error?) -> ()
    ) {
        fatalError("You must override \(#function) in a subclass.")
    }

    open dynamic func ocr(_ queryModel: EZQueryModel, completion: @escaping (EZOCRResult?, Error?) -> ()) {
        guard let image = queryModel.ocrImage else {
            completion(nil, QueryError.error(type: .parameter, message: "Image is nil"))
            return
        }
        ocr(image, from: queryModel.queryFromLanguage, to: queryModel.queryTargetLanguage, completion: completion)
    }

    open dynamic func ocrAndTranslate(
        _ image: NSImage,
        from: Language,
        to: Language,
        ocrSuccess: @escaping (EZOCRResult, Bool) -> (),
        completion: @escaping (EZOCRResult?, EZQueryResult?, Error?) -> ()
    ) {
        fatalError("You must override \(#function) in a subclass.")
    }

    // MARK: Internal

    /// Async wrapper for completion-based translate API.
    func translate(
        _ text: String,
        from: Language,
        to: Language
    ) async throws
        -> EZQueryResult {
        try await withCheckedThrowingContinuation { continuation in
            self.translate(text, from: from, to: to) { result, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: result)
                }
            }
        }
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
}
