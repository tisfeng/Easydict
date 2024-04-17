//
//  GeminiService.swift
//  Easydict
//
//  Created by Jerry on 2024-01-02.
//  Copyright © 2024 izual. All rights reserved.
//

// swiftlint:disable all

import Defaults
import Foundation
import GoogleGenerativeAI

@objc(EZGeminiService)
public final class GeminiService: QueryService {
    // MARK: Public

    override public func serviceType() -> ServiceType {
        .gemini
    }

    override public func link() -> String? {
        "https://gemini.google.com/"
    }

    override public func name() -> String {
        NSLocalizedString("gemini_translate", comment: "The name of Gemini Translate")
    }

    override public func supportLanguagesDictionary() -> MMOrderedDictionary<AnyObject, AnyObject> {
        // TODO: Replace MMOrderedDictionary.
        let orderedDict = MMOrderedDictionary<AnyObject, AnyObject>()
        for language in EZLanguageManager.shared().allLanguages {
            let value = language.rawValue
            if !GeminiService.unsupportedLanguages.contains(language) {
                orderedDict.setObject(value as NSString, forKey: language.rawValue as NSString)
            }
        }

        return orderedDict
    }

    override public func translate(
        _ text: String,
        from: Language,
        to: Language,
        completion: @escaping (EZQueryResult, Error?) -> ()
    ) {
        Task {
            do {
                let prompt = GeminiService
                    .translationPrompt + "Translate the following \(from.rawValue) text into \(to.rawValue): \(text)"
                print("gemini prompt: \(prompt)")
                let model = GenerativeModel(
                    name: "gemini-pro",
                    apiKey: apiKey,
                    safetySettings: [
                        GeminiService.harassmentSafety,
                        GeminiService.hateSpeechSafety,
                        GeminiService.sexuallyExplicitSafety,
                        GeminiService.dangerousContentSafety,
                    ]
                )

                if #available(macOS 12.0, *) {
                    var resultString = ""
                    let outputContentStream = model.generateContentStream(prompt)

                    // stream response
                    for try await outputContent in outputContentStream {
                        guard let line = outputContent.text else {
                            return
                        }

                        resultString += line
                        result.translatedResults = [resultString]
                        await MainActor.run {
                            completion(result, nil)
                        }
                    }

                } else {
                    let outputContent = try await model.generateContent(prompt)
                    guard let resultString = outputContent.text else {
                        return
                    }

                    result.translatedResults = [resultString]
                    await MainActor.run {
                        completion(result, nil)
                    }
                }
            } catch {
                /**
                 https://github.com/google/generative-ai-swift/issues/89

                 String(describing: error)

                 "internalError(underlying: GoogleGenerativeAI.RPCError(httpResponseCode: 400, message: \"API key not valid. Please pass a valid API key.\", status: GoogleGenerativeAI.RPCStatus.invalidArgument))"
                 */
                let ezError = EZError(nsError: error)
                let errorString = String(describing: error)
                let errorMessage = errorString.extract(withPattern: "message: \"([^\"]*)\"") ?? errorString
                ezError?.errorDataMessage = errorMessage
                await MainActor.run {
                    completion(result, ezError)
                }
            }
        }
    }

    // MARK: Private

    // https://ai.google.dev/available_regions
    private static let unsupportedLanguages: [Language] = [
        .persian,
        .filipino,
        .khmer,
        .lao,
        .malay,
        .mongolian,
        .burmese,
        .telugu,
        .tamil,
        .urdu,
    ]

    // Set Gemini safety level to BLOCK_NONE
    private static let harassmentSafety = SafetySetting(harmCategory: .harassment, threshold: .blockNone)
    private static let hateSpeechSafety = SafetySetting(harmCategory: .hateSpeech, threshold: .blockNone)
    private static let sexuallyExplicitSafety = SafetySetting(harmCategory: .sexuallyExplicit, threshold: .blockNone)
    private static let dangerousContentSafety = SafetySetting(harmCategory: .dangerousContent, threshold: .blockNone)

    private static let translationPrompt =
        "You are a translation expert proficient in various languages that can only translate text and cannot interpret it. You are able to accurately understand the meaning of proper nouns, idioms, metaphors, allusions or other obscure words in sentences and translate them into appropriate words by combining the context and language environment. The result of the translation should be natural and fluent, you can only return the translated text, do not show additional information and notes."

    // easydict://writeKeyValue?EZGeminiAPIKey=xxx
    private var apiKey: String {
        Defaults[.geminiAPIKey] ?? ""
    }
}

// swiftlint:enable all
