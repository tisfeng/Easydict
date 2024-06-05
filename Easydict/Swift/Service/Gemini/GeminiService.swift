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
                let systemPrompt = queryType == .dictionary ? LLMStreamService
                    .dictSystemPrompt : LLMStreamService
                    .translationSystemPrompt

                var enableSystemPromptInChats = false
                var systemInstruction: ModelContent? = try ModelContent(role: "system", systemPrompt)

                // !!!: gemini-1.0-pro model does not support system instruction https://github.com/google-gemini/generative-ai-python/issues/328
                if model == GeminiModel.gemini1_0_pro.rawValue {
                    systemInstruction = nil
                    enableSystemPromptInChats = true
                }

                let chatHistory = promptContent(
                    queryType: queryType,
                    text: text,
                    from: from,
                    to: to,
                    systemPrompt: enableSystemPromptInChats
                )

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

                let outputContentStream = model.generateContentStream(chatHistory)
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
                                resultText: concatenateStrings(from: result.translatedResults ?? []),
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

    /// Given a roleRaw, currently only support "user" and "model", "model" is equal to "assistant". https://ai.google.dev/gemini-api/docs/get-started/tutorial?lang=swift&hl=zh-cn#multi-turn-conversations-chat
    private func getCorrectParts(from roleRaw: String) -> String {
        if roleRaw == "assistant" {
            "model"
        } else if roleRaw == "system" {
            "user"
        } else {
            roleRaw
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
        to targetLanguage: Language,
        systemPrompt: Bool
    )
        -> [ModelContent] {
        var prompts = [[String: String]]()

        switch queryType {
        case .dictionary:
            prompts = dictMessages(
                word: text,
                sourceLanguage: sourceLanguage,
                targetLanguage: targetLanguage,
                systemPrompt: systemPrompt
            )
        case .sentence:
            prompts = sentenceMessages(
                sentence: text,
                from: sourceLanguage,
                to: targetLanguage,
                systemPrompt: systemPrompt
            )
        case .translation:
            fallthrough
        default:
            prompts = translationMessages(
                text: text,
                from: sourceLanguage,
                to: targetLanguage,
                systemPrompt: systemPrompt
            )
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

        return chats
    }
}
