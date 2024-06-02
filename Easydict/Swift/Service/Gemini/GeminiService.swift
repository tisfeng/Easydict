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

// MARK: - GeminiService

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
                result.isStreamFinished = false

                let queryType = queryType(text: text, from: from, to: to)
                let translationPrompt = promptContent(queryType: queryType, text: text, from: from, to: to)
                let systemInstruction = LLMStreamService.translationSystemPrompt
                let model = GenerativeModel(
                    name: model,
                    apiKey: apiKey,
                    safetySettings: [
                        harassmentBlockNone,
                        hateSpeechBlockNone,
                        sexuallyExplicitBlockNone,
                        dangerousContentBlockNone,
                    ],
                    systemInstruction: systemInstruction
                )

                var resultString = ""

                // Gemini Docs: https://github.com/google/generative-ai-swift

                let outputContentStream = model.generateContentStream(translationPrompt)
                for try await outputContent in outputContentStream {
                    guard let line = outputContent.text else {
                        return
                    }
                    if !result.isStreamFinished {
                        resultString += line

                        result.translatedResults = [resultString]
                        await MainActor.run {
                            handleResult(
                                queryType: queryType,
                                resultString: concatenateStrings(from: result.translatedResults ?? []),
                                error: nil,
                                completion: completion
                            )
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
        Defaults[.geminiValidModels]
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

    /// Given a roleRaw, replace "assistant" with "model"
    private func getCorrectParts(from roleRaw: String) -> String {
        if roleRaw.lowercased() == "assistant" {
            "model"
        } else {
            roleRaw
        }
    }

    private func handleResult(
        queryType: EZQueryTextType,
        resultString: String?,
        error: Error?,
        completion: @escaping (EZQueryResult, Error?) -> ()
    ) {
        var normalResults: [String]?
        if let resultString {
            normalResults = [resultString.trim()]
        }

        result.isStreamFinished = error != nil
        result.translatedResults = normalResults
        let updateCompletion = {
            self.throttler.throttle { [unowned self] in
                completion(result, error)
            }
        }

        switch queryType {
        case .sentence, .translation:
            updateCompletion()

        case .dictionary:
            if error != nil {
                result.showBigWord = false
                result.translateResultsTopInset = 0
                updateCompletion()
                return
            }

            result.showBigWord = true
            result.queryText = queryModel.queryText
            result.translateResultsTopInset = 6
            updateCompletion()

        default:
            updateCompletion()
        }
    }

    private func concatenateStrings(from array: [String]) -> String {
        array.joined()
    }
}

extension GeminiService {
    func promptContent(
        queryType: EZQueryTextType,
        text: String,
        from sourceLanguage: Language,
        to targetLanguage: Language
    )
        -> [ModelContent] {
        var prompts = [[String: String]]()

        switch queryType {
        case .dictionary:
            prompts = dictMessages(word: text, sourceLanguage: sourceLanguage, targetLanguage: targetLanguage)
        case .sentence:
            prompts = sentenceMessages(sentence: text, from: sourceLanguage, to: targetLanguage)
        case .translation:
            fallthrough
        default:
            prompts = translationMessages(text: text, from: sourceLanguage, to: targetLanguage)
        }

        var chats: [ModelContent] = []
        for prompt in prompts {
            if let roleRaw = prompt["role"],
               let parts = prompt["content"] {
                let role = getCorrectParts(from: roleRaw)
                let chat = ModelContent(role: role, parts: parts)
                chats.append(chat)
            }
        }
        guard !chats.isEmpty else {
            return chats
        }
        // removing first element in [ModelContent] since it's system instruction
        chats.removeFirst()
        return chats
    }
}
