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

// TODO: add a LLM stream service base class, make both OpenAI and Gemini inherit from it.
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

    public override func isStream() -> Bool {
        true
    }

    override public func translate(
        _ text: String,
        from: Language,
        to: Language,
        completion: @escaping (EZQueryResult, Error?) -> ()
    ) {
        Task {
            do {
                let translationPrompt = translationPrompt(text: text, from: from, to: to)
                let prompt = QueryService.translationSystemPrompt +
                    "\n" + translationPrompt
//                logInfo("gemini prompt: \(prompt)")
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

                // Gemini Docs: https://github.com/google/generative-ai-swift
                if #available(macOS 12.0, *) {
                    result.isStreamFinished = false

                    var resultString = ""
                    let outputContentStream = model.generateContentStream(prompt)

                    for try await outputContent in outputContentStream {
                        guard let line = outputContent.text else {
                            return
                        }
                        if !result.isStreamFinished {
                            resultString += line
                            result.translatedResults = [resultString]
                            await MainActor.run {
                                completion(result, nil)
                            }
                        }
                    }
                    result.isStreamFinished = true
                    completion(result, nil)
                } else {
                    // Gemini does not support stream in macOS 12.0-
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
                result.isStreamFinished = true

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

    // easydict://writeKeyValue?EZGeminiAPIKey=xxx
    private var apiKey: String {
        Defaults[.geminiAPIKey] ?? ""
    }
}

// swiftlint:enable all
