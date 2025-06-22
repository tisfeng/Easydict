//
//  AppleService.swift
//  Easydict
//
//  Created by tisfeng on 2024/10/9.
//  Copyright © 2024 izual. All rights reserved.
//

import AVFoundation
import Foundation
import NaturalLanguage
import Translation
import Vision

// MARK: - AppleService

@objc(EZAppleService)
public class AppleService: QueryService {
    // MARK: Public

    /// Service type identification
    @objc
    public override func serviceType() -> ServiceType {
        .apple
    }

    /// Service name
    @objc
    public override func name() -> String {
        NSLocalizedString("apple_translate", comment: "")
    }

    /// Supported languages dictionary
    @objc
    public override func supportLanguagesDictionary() -> MMOrderedDictionary<AnyObject, AnyObject> {
        languageMapper.supportedLanguages.toMMOrderedDictionary()
    }

    public override func detectText(_ text: String, completion: @escaping (Language, (any Error)?) -> ()) {
        let language = detectText(text, printLog: true)
        completion(language, nil)
    }

    public override func translate(
        _ text: String,
        from: Language,
        to: Language,
        completion: @escaping (EZQueryResult, (any Error)?) -> ()
    ) {
        Task {
            do {
                let result = try await translateAsync(
                    text: text,
                    from: from,
                    to: to
                )
                await MainActor.run {
                    completion(result, nil)
                }
            } catch {
                await MainActor.run {
                    completion(self.result, error)
                }
            }
        }
    }

    @objc
    public override func ocr(_ queryModel: EZQueryModel, completion: @escaping (EZOCRResult?, Error?) -> ()) {
        let image = queryModel.ocrImage ?? NSImage()
        let language = queryModel.queryFromLanguage
        let autoDetect = language == .auto

        ocrService.performOCR(
            image: image,
            language: language,
            autoDetect: autoDetect,
            completion: completion
        )
    }

    /// Async version for Swift usage
    public func ocrAsync(cgImage: CGImage) async throws -> String {
        try await ocrService.ocrAsync(cgImage: cgImage)
    }

    /// Async translation method
    public func translateAsync(
        text: String,
        from sourceLanguage: Language,
        to targetLanguage: Language
    ) async throws
        -> EZQueryResult {
        // Use macOS 15+ API to translate if available
        if #available(macOS 15.0, *), Configuration.shared.enableAppleOfflineTranslation {
            let service = await getTranslationService()
            if let service = service as? TranslationService {
                let translatedText = try await service.translate(
                    text: text,
                    sourceLanguage: sourceLanguage,
                    targetLanguage: targetLanguage
                )

                let result = EZQueryResult()
                result.translatedResults = [translatedText]
                return result
            }
        }

        // Fallback to AppleScript-based translation
        return try await translateWithAppleScript(
            text: text,
            from: sourceLanguage,
            to: targetLanguage
        )
    }

    /// Language detection
    @objc
    public func detectLanguage(
        text: String,
        completion: @escaping (Language, Error?) -> ()
    ) {
        let detectedLanguage = languageDetector.detectLanguage(text: text)
        completion(detectedLanguage, nil)
    }

    /// Text-to-speech functionality
    @objc
    public func playAudio(
        text: String,
        language: Language,
        completion: @escaping (Error?) -> ()
    )
        -> NSSpeechSynthesizer? {
        speechService.playAudio(text: text, language: language, completion: completion)
    }

    @objc
    public func detectText(
        _ text: String,
        printLog: Bool = false
    )
        -> Language {
        let detectedLanguage = languageDetector.detectLanguage(text: text, printLog: printLog)
        return detectedLanguage
    }

    @objc
    public func detectText(
        _ text: String
    )
        -> Language {
        detectText(text, printLog: false)
    }

    /// Play text audio using system speech synthesizer
    @objc
    public func playTextAudio(
        _ text: String,
        textLanguage: Language
    )
        -> NSSpeechSynthesizer? {
        speechService.playAudio(text: text, language: textLanguage) { _ in }
    }

    /// Convert NLLanguage to Language enum
    @objc
    public func languageEnum(fromAppleLanguage appleLanguage: NLLanguage) -> Language {
        languageDetector.languageEnumFromAppleLanguage(appleLanguage)
    }

    /// Convert Language enum to NLLanguage
    @objc
    public func appleLanguage(fromLanguageEnum language: Language) -> NLLanguage {
        languageMapperToNLLanguage(language)
    }

    // MARK: Internal

    @objc static let shared = AppleService()

    var supportedLanguages = [Locale.Language]()

    @available(macOS 15.0, *)
    func prepareSupportedLanguages() async {
        supportedLanguages = await LanguageAvailability().supportedLanguages

        supportedLanguages.sort {
            $0.languageCode!.identifier < $1.languageCode!.identifier
        }

        for language in supportedLanguages {
            print("\(language.languageCode!.identifier)_\(language.region!)")
        }
    }

    // MARK: Private

    private let ocrService = AppleOCRService()
    private let languageMapper = AppleLanguageMapper()
    private let languageDetector = AppleLanguageDetector()
    private let speechService = AppleSpeechService()

    private var translationService: Any? // Use Any to avoid compile-time type checking

    /// Convert Language enum to NLLanguage
    private func languageMapperToNLLanguage(_ language: Language) -> NLLanguage {
        switch language {
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
        default: return .english
        }
    }

    @MainActor
    private func getTranslationService() -> Any? {
        if #available(macOS 15.0, *) {
            if translationService == nil {
                let window = NSApplication.shared.windows.first
                let service = TranslationService(attachedWindow: window)
                service.enableTranslateSameLanguage = true
                translationService = service
            }
            return translationService
        } else {
            return nil
        }
    }

    /// Fallback translation using AppleScript
    private func translateWithAppleScript(
        text: String,
        from sourceLanguage: Language,
        to targetLanguage: Language
    ) async throws
        -> EZQueryResult {
        let parameters = [
            "text": text,
            "from": languageMapper.appleLanguageCode(for: sourceLanguage),
            "to": languageMapper.appleLanguageCode(for: targetLanguage),
        ]

        let text = try await AppleScriptTask.runTranslateShortcut(parameters: parameters) ?? ""
        result.translatedResults = [text]
        return result
    }
}

// MARK: - AppleLanguageMapper

@objc
public class AppleLanguageMapper: NSObject {
    // MARK: Public

    @objc
    public var supportedLanguages: [Language: String] {
        languageMap
    }

    @objc
    public func appleLanguageCode(for language: Language) -> String {
        languageMap[language] ?? "en_US"
    }

    @objc
    public func language(for appleLanguageCode: String) -> Language {
        for (key, value) in languageMap where value == appleLanguageCode {
            return key
        }
        return .english
    }

    /// Convert Language to BCP-47 language code for Translation API
    @objc
    public func languageCode(for language: Language) -> String {
        switch language {
        case .auto: return "und"
        case .simplifiedChinese: return "zh-Hans"
        case .traditionalChinese: return "zh-Hant"
        case .english: return "en"
        case .japanese: return "ja"
        case .korean: return "ko"
        case .french: return "fr"
        case .spanish: return "es"
        case .portuguese: return "pt"
        case .italian: return "it"
        case .german: return "de"
        case .russian: return "ru"
        case .arabic: return "ar"
        case .thai: return "th"
        case .polish: return "pl"
        case .turkish: return "tr"
        case .indonesian: return "id"
        case .vietnamese: return "vi"
        case .dutch: return "nl"
        case .ukrainian: return "uk"
        case .hindi: return "hi"
        default: return "en"
        }
    }

    // MARK: Private

    private let languageMap: [Language: String] = [
        .auto: "auto",
        .simplifiedChinese: "zh_CN",
        .traditionalChinese: "zh_TW",
        .english: "en_US",
        .japanese: "ja_JP",
        .korean: "ko_KR",
        .french: "fr_FR",
        .spanish: "es_ES",
        .portuguese: "pt_BR",
        .italian: "it_IT",
        .german: "de_DE",
        .russian: "ru_RU",
        .arabic: "ar_AE",
        .thai: "th_TH",
        .polish: "pl_PL",
        .turkish: "tr_TR",
        .indonesian: "id_ID",
        .vietnamese: "vi_VN",
        .dutch: "nl_NL",
        .ukrainian: "uk_UA",
        .hindi: "hi_IN",
    ]
}

// Only extend TranslationService when it's available
@available(macOS 15.0, *)
extension TranslationService {
    /// Translate text from source language to target language, used for objc.
    public func translate(
        text: String,
        sourceLanguage: Language,
        targetLanguage: Language
    ) async throws
        -> String {
        let mapper = AppleLanguageMapper()

        // Convert Language to Locale.Language using BCP-47 codes
        let sourceLocaleLanguage = Locale.Language(
            identifier: mapper.languageCode(for: sourceLanguage)
        )
        let targetLocaleLanguage = Locale.Language(
            identifier: mapper.languageCode(for: targetLanguage)
        )

        let response = try await translate(
            text: text,
            sourceLanguage: sourceLocaleLanguage,
            targetLanguage: targetLocaleLanguage
        )

        return response.targetText
    }
}

extension NLLanguage {
    var localeLanguage: Locale.Language {
        .init(identifier: rawValue)
    }
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
