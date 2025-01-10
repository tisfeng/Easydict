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

    public override func serviceType() -> ServiceType {
        .gemini
    }

    public override func link() -> String? {
        "https://gemini.google.com/"
    }

    public override func name() -> String {
        NSLocalizedString("gemini_translate", comment: "The name of Gemini Translate")
    }

    public override func translate(
        _ text: String,
        from: Language,
        to: Language,
        completion: @escaping (EZQueryResult, Error?) -> ()
    ) {
        if model.isEmpty {
            let emptyModelError = QueryError(type: .parameter, message: "model is empty")
            completion(result, emptyModelError)
            return
        }

        performTranslationTask(text: text, from: from, to: to, completion: completion)
    }

    public override func configurationListItems() -> Any {
        StreamConfigurationView(
            service: self,
            showEndpointSection: false
        )
    }

    // MARK: Internal

    override var defaultModels: [String] {
        GeminiModel.allCases.map(\.rawValue)
    }

    override var defaultModel: String {
        GeminiModel.gemini_1_5_pro.rawValue
    }

    override var observeKeys: [Defaults.Key<String>] {
        [apiKeyKey, supportedModelsKey]
    }

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

    override func serviceChatMessageModels(_ chatQuery: ChatQueryParam) -> [Any] {
        var chatModels: [ModelContent] = []
        for message in chatMessageDicts(chatQuery) {
            let openAIRole = message.role.rawValue
            let parts = message.content

            let role = getGeminiRole(from: openAIRole)
            let chat = ModelContent(role: role, parts: parts)
            chatModels.append(chat)
        }
        return chatModels
    }

    override func cancelStream() {
        currentTask?.cancel()
    }

    // MARK: Private

    private var currentTask: Task<(), Never>?

    // Set Gemini safety level to BLOCK_NONE
    private let blockNoneSettings = [
        SafetySetting(harmCategory: .harassment, threshold: .blockNone),
        SafetySetting(harmCategory: .hateSpeech, threshold: .blockNone),
        SafetySetting(harmCategory: .sexuallyExplicit, threshold: .blockNone),
        SafetySetting(harmCategory: .dangerousContent, threshold: .blockNone),
    ]

    private func performTranslationTask(
        text: String,
        from: Language,
        to: Language,
        completion: @escaping (EZQueryResult, Error?) -> ()
    ) {
        if let currentTask, currentTask.isCancelled == false {
            currentTask.cancel()
        }

        let queryType = queryType(text: text, from: from, to: to)

        // Gemini Docs: https://github.com/google/generative-ai-swift

        currentTask = Task {
            do {
                result.isStreamFinished = false

                let systemPrompt =
                    queryType == .dictionary
                        ? LLMStreamService
                        .dictSystemPrompt
                        : LLMStreamService
                        .translationSystemPrompt

                var enableSystemPromptInChats = false
                var systemInstruction: ModelContent? = try ModelContent(
                    role: "system", systemPrompt
                )

                // !!!: gemini-1.0-pro model does not support system instruction https://github.com/google-gemini/generative-ai-python/issues/328
                if model == "gemini-1.0-pro" {
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

                let chatHistory = serviceChatMessageModels(chatQueryParam)
                guard let chatHistory = chatHistory as? [ModelContent] else { return }

                let model = GenerativeModel(
                    name: model,
                    apiKey: apiKey,
                    safetySettings: blockNoneSettings,
                    systemInstruction: systemInstruction
                )

                var resultText = ""

                let outputContentStream = model.generateContentStream(chatHistory)
                for try await outputContent in outputContentStream {
                    try Task.checkCancellation()
                    guard let line = outputContent.text else {
                        return
                    }
                    resultText += line
                    updateResultText(
                        resultText, queryType: queryType, error: nil, completion: completion
                    )
                }

                resultText = getFinalResultText(resultText)
                updateResultText(
                    resultText, queryType: queryType, error: nil, completion: completion
                )
                result.isStreamFinished = true

            } catch is CancellationError {
                // Task was cancelled.
                log("Gemini task was cancelled.")
            } catch {
                /**
                 https://github.com/google/generative-ai-swift/issues/89

                 String(describing: error)

                 "internalError(underlying: GoogleGenerativeAI.RPCError(httpResponseCode: 400, message: \"API key not valid. Please pass a valid API key.\", status: GoogleGenerativeAI.RPCStatus.invalidArgument))"
                 */

                let errorString = String(describing: error)
                let errorMessage =
                    errorString.extract(withPattern: "message: \"([^\"]*)\"") ?? errorString
                let queryError = QueryError(type: .api, errorDataMessage: errorMessage)

                updateResultText(nil, queryType: queryType, error: queryError, completion: completion)
            }
        }
    }

    /// Get gemini role, currently only support "user" and "model", "model" is equal to OpenAI "assistant". https://ai.google.dev/gemini-api/docs/get-started/tutorial?lang=swift&hl=zh-cn#multi-turn-conversations-chat
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

// MARK: - GeminiModel

// swiftlint:disable identifier_name
enum GeminiModel: String, CaseIterable {
    // Docs: https://ai.google.dev/gemini-api/docs/models/gemini

    // RPM: Requests per minute, TPM: Tokens per minute
    // RPD: Requests per day, TPD: Tokens per day
    case gemini_1_5_flash = "gemini-1.5-flash" // Free 15 RPM/100million TPM, 1500 RPD/ n/a TPD  (1048k context length)
    case gemini_1_5_pro = "gemini-1.5-pro" // Free 2 RPM/32,000 TPM, 50 RPD/46,080,000 TPD (1048k context length)
    case gemini_1_5_pro_exp_0801 = "gemini-1.5-pro-exp-0801" // Experimental
}

// swiftlint:enable identifier_name
