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
        let queryType = queryType(text: text, from: from, to: to)

        Task {
            do {
                result.isStreamFinished = false

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

                let chatQueryParam = ChatQueryParam(
                    text: text,
                    sourceLanguage: from,
                    targetLanguage: to,
                    queryType: queryType,
                    enableSystemPrompt: enableSystemPromptInChats
                )

                let chatHistory = serviceChatModels(chatQueryParam)

                guard let chatHistory = chatHistory as? [ModelContent] else { return }

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

                var resultText = ""

                // Gemini Docs: https://github.com/google/generative-ai-swift

                let outputContentStream = model.generateContentStream(chatHistory)
                for try await outputContent in outputContentStream {
                    guard let line = outputContent.text else {
                        return
                    }
                    resultText += line
                    updateResultText(resultText, queryType: queryType, error: nil, completion: completion)
                }

                resultText = getFinalResultText(resultText)
                updateResultText(resultText, queryType: queryType, error: nil, completion: completion)
                result.isStreamFinished = true

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

                updateResultText(nil, queryType: queryType, error: ezError, completion: completion)
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

    override func serviceChatModels(_ chatQuery: ChatQueryParam) -> [Any] {
        let chatMessageDicts = chatMessageDicts(chatQuery)

        var chats: [ModelContent] = []
        for prompt in chatMessageDicts {
            if let openAIRole = prompt["role"],
               let parts = prompt["content"] {
                let role = getGeminiRole(from: openAIRole)
                let chat = ModelContent(role: role, parts: parts)
                chats.append(chat)
            }
        }

        return chats
    }

    // MARK: Private

    // Set Gemini safety level to BLOCK_NONE
    private let harassmentBlockNone = SafetySetting(harmCategory: .harassment, threshold: .blockNone)
    private let hateSpeechBlockNone = SafetySetting(harmCategory: .hateSpeech, threshold: .blockNone)
    private let sexuallyExplicitBlockNone = SafetySetting(harmCategory: .sexuallyExplicit, threshold: .blockNone)
    private let dangerousContentBlockNone = SafetySetting(harmCategory: .dangerousContent, threshold: .blockNone)

    /// Given a roleRaw, currently only support "user" and "model", "model" is equal to "assistant". https://ai.google.dev/gemini-api/docs/get-started/tutorial?lang=swift&hl=zh-cn#multi-turn-conversations-chat
    private func getGeminiRole(from openAIRole: String) -> String {
        if openAIRole == "assistant" {
            "model"
        } else if openAIRole == "system" {
            "user"
        } else {
            openAIRole
        }
    }
}
