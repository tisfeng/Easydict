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

    @objc
    public override func serviceType() -> ServiceType {
        .apple
    }

    @objc
    public override func name() -> String {
        NSLocalizedString("apple_translate", comment: "")
    }

    /// Supported languages dictionary
    @objc
    public override func supportLanguagesDictionary() -> MMOrderedDictionary {
        languageMapper.supportedLanguages.toMMOrderedDictionary()
    }

    /// Detect language using Apple's language detection.
    @nonobjc
    public override func detectText(_ text: String) async throws -> Language {
        let language = detectTextSync(text)
        return language
    }

    /// Detect language for Objective-C callers without spinning up a Task.
    @objc
    public override func detectText(
        _ text: String,
        completion: @escaping (Language, Error?) -> ()
    ) {
        completion(detectTextSync(text), nil)
    }

    /// Translate text using Apple translation services.
    public override func translate(
        _ text: String,
        from: Language,
        to: Language
    ) async throws
        -> QueryResult {
        try await translateAsync(text: text, from: from, to: to)
    }

    /// Perform OCR using Apple's Vision-based engine.
    public override func ocr(
        _ image: NSImage,
        from: Language,
        to: Language
    ) async throws
        -> EZOCRResult? {
        _ = to
        return try await withCheckedThrowingContinuation { continuation in
            ocrEnginee.recognizeText(
                image: image,
                language: from
            ) { result, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: result)
                }
            }
        }
    }

    public override func autoConvertTraditionalChinese() -> Bool {
        // Since Apple system translation not support zh-hans <--> zh-hant, so we need to convert it manually.
        true
    }

    /// Async translation method
    public func translateAsync(
        text: String,
        from sourceLanguage: Language,
        to targetLanguage: Language
    ) async throws
        -> QueryResult {
        // Use macOS 15+ API to translate if available
        if #available(macOS 15.0, *), Configuration.shared.enableAppleOfflineTranslation {
            let service = await getTranslationService()
            if let service = service as? AppleTranslation {
                let translatedText = try await service.translate(
                    text: text,
                    sourceLanguage: sourceLanguage,
                    targetLanguage: targetLanguage
                )

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

    @objc
    public func detectTextSync(_ text: String) -> Language {
        languageDetector.detectLanguage(text: text)
    }

    /// Play text audio using system speech synthesizer
    @objc
    public func playTextAudio(_ text: String, textLanguage: Language) -> NSSpeechSynthesizer? {
        speechService.playAudio(text: text, language: textLanguage) { _ in }
    }

    /// Convert NLLanguage to Language enum
    @objc
    public func languageEnum(fromAppleLanguage appleLanguage: NLLanguage) -> Language {
        languageMapper.languageEnum(from: appleLanguage)
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

    private let ocrEnginee = AppleOCREngine()
    private let languageMapper = AppleLanguageMapper.shared
    private let languageDetector = AppleLanguageDetector(enableDebugLog: true)
    private let speechService = AppleSpeechService()

    private var translationService: Any? // Use Any to avoid compile-time type checking

    @MainActor
    private func getTranslationService() -> Any? {
        if #available(macOS 15.0, *) {
            if translationService == nil {
                let window = NSApplication.shared.windows.first
                let service = AppleTranslation(attachedWindow: window)
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
        -> QueryResult {
        guard let fromLanguage = languageMapper.supportedLanguages[sourceLanguage],
              let toLanguage = languageMapper.supportedLanguages[targetLanguage]
        else {
            throw QueryError(
                type: .parameter, message: "Unsupported language for Apple Translation"
            )
        }

        let parameters = [
            "text": text,
            "from": fromLanguage,
            "to": toLanguage,
        ]

        let text = try await AppleScriptTask.runTranslateShortcut(parameters: parameters) ?? ""
        result.translatedResults = [text]
        return result
    }
}

// Only extend TranslationService when it's available
@available(macOS 15.0, *)
extension AppleTranslation {
    /// Translate text from source language to target language, used for objc.
    public func translate(
        text: String,
        sourceLanguage: Language,
        targetLanguage: Language
    ) async throws
        -> String {
        let mapper = AppleLanguageMapper.shared

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

// MARK: - Locale.Language + @retroactive CustomStringConvertible

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
