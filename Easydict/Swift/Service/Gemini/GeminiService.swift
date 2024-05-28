//
//  GeminiService.swift
//  Easydict
//
//  Created by Jerry on 2024-01-02.
//  Copyright © 2024 izual. All rights reserved.
//

import Defaults
import Foundation
import GoogleGenerativeAI

@objc(EZGeminiService)
public final class GeminiService: LLMStreamService {
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

    override public func translate(
        _ text: String,
        from: Language,
        to: Language,
        completion: @escaping (EZQueryResult, Error?) -> ()
    ) {
        Task {
            do {
                result.from = from
                result.to = to
                result.isStreamFinished = false
                let translationPrompt = translationPrompt(text: text, from: from, to: to)
                let prompt = LLMStreamService.translationSystemPrompt +
                    "\n" + translationPrompt
                let model = GenerativeModel(
                    name: model,
                    apiKey: apiKey,
                    safetySettings: [
                        harassmentBlockNone,
                        hateSpeechBlockNone,
                        sexuallyExplicitBlockNone,
                        dangerousContentBlockNone,
                    ]
                )

                var resultString = ""

                // Gemini Docs: https://github.com/google/generative-ai-swift

                let outputContentStream = model.generateContentStream(prompt)
                for try await outputContent in outputContentStream {
                    guard let line = outputContent.text else {
                        return
                    }
                    if !result.isStreamFinished {
                        resultString += line

                        result.translatedResults = [resultString]
                        await MainActor.run {
                            throttler.throttle { [unowned self] in
                                completion(result, nil)
                            }
                        }
                    }
                }

                result.isStreamFinished = true
                result.translatedResults = [getFinalResultText(text: resultString)]
                completion(result, nil)
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

    // MARK: Internal

    // https://ai.google.dev/available_regions
    override var unsupportedLanguages: [Language] {
        [
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
    }

    // easydict://writeKeyValue?EZGeminiAPIKey=xxx
    override var apiKey: String {
        Defaults[.geminiAPIKey] ?? ""
    }

    override var availableModels: [String] {
        Defaults[.geminiVaildModels]
    }

    override var model: String {
        get {
            Defaults[.geminiModel]
        }
        set {
            // easydict://writeKeyValue?EZGeminiModelKey=gemini-1.5-flash
            Defaults[.geminiModel] = newValue
        }
    }

    // MARK: Private

    // Set Gemini safety level to BLOCK_NONE
    private let harassmentBlockNone = SafetySetting(harmCategory: .harassment, threshold: .blockNone)
    private let hateSpeechBlockNone = SafetySetting(harmCategory: .hateSpeech, threshold: .blockNone)
    private let sexuallyExplicitBlockNone = SafetySetting(harmCategory: .sexuallyExplicit, threshold: .blockNone)
    private let dangerousContentBlockNone = SafetySetting(harmCategory: .dangerousContent, threshold: .blockNone)
}
