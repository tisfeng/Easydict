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

/// Gemini Docs: https://ai.google.dev/gemini-api/docs/get-started/tutorial?lang=swift
@objc(EZGeminiService)
public final class GeminiService: StreamService {
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

    public override func configurationListItems() -> Any {
        StreamConfigurationView(
            service: self,
            showEndpointSection: false,
            showCustomPromptSection: true
        )
    }

    // MARK: Internal

    override var defaultModels: [String] {
        GeminiModel.allCases.map(\.rawValue)
    }

    override var defaultModel: String {
        GeminiModel.gemini_2_0_flash.rawValue
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

    override func contentStreamTranslate(
        _ text: String,
        from: Language,
        to: Language
    )
        -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            if let currentTask, currentTask.isCancelled == false {
                currentTask.cancel()
            }

            let queryType = queryType(text: text, from: from, to: to)

            currentTask = Task {
                do {
                    let systemPrompt =
                        queryType == .dictionary
                            ? StreamService.dictSystemPrompt
                            : StreamService.translationSystemPrompt

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

                    let config = GenerationConfig(temperature: Float(temperature))
                    let geminiModel = GenerativeModel(
                        name: model,
                        apiKey: apiKey,
                        generationConfig: config,
                        safetySettings: blockNoneSettings,
                        systemInstruction: systemInstruction
                    )

                    let outputContentStream = geminiModel.generateContentStream(chatHistory)
                    for try await outputContent in outputContentStream {
                        try Task.checkCancellation()
                        guard let text = outputContent.text else { continue }

                        continuation.yield(text)
                    }
                    continuation.finish()
                } catch is CancellationError {
                    logInfo("Gemini task was cancelled.")
                    continuation.finish()
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

                    continuation.finish(throwing: queryError)
                }
            }
        }
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
    // Docs: https://ai.google.dev/gemini-api/docs/models

    // RPM: Requests per minute, TPM: Tokens per minute
    // RPD: Requests per day, TPD: Tokens per day

    case gemini_2_5_pro_exp_03_25 = "gemini-2.5-pro-exp-03-25" // Exp 5 RPM, 1,000,000 TPM, 25 RPD

    case gemini_2_0_flash = "gemini-2.0-flash" // Free 15 RPM, 1,000,000 TPM, 1500 RPD
    case gemini_2_0_flash_lite = "gemini-2.0-flash-lite" // Free 30 RPM, 1,000,000 TPM, 1500 RPD
    case gemini_2_0_flash_exp = "gemini-2.0-flash-exp" // Exp 10 RPM, 1,000,000 TPM, 1500 RPD
    case gemini_2_0_pro_exp = "gemini-2.0-pro-exp" // Exp 2 RPM, 1,000,000 TPM, 50 RPD

    case gemini_1_5_flash = "gemini-1.5-flash" // Free 15 RPM, 1,000,000 TPM, 1500 RPD
}

// swiftlint:enable identifier_name
