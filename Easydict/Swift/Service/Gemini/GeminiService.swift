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

                let chatHistory = serviceChatMessageModels(chatQueryParam)
                guard let chatHistory = chatHistory as? [ModelContent] else { return }

                let model = GenerativeModel(
                    name: model,
                    apiKey: apiKey,
                    safetySettings: blockNoneSettings,
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
        for prompt in chatMessageDicts(chatQuery) {
            if let openAIRole = prompt["role"],
               let parts = prompt["content"] {
                let role = getGeminiRole(from: openAIRole)
                let chat = ModelContent(role: role, parts: parts)
                chatModels.append(chat)
            }
        }
        return chatModels
    }

    // MARK: Private

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
    // Docs: https://ai.google.dev/gemini-api/docs/models/gemini

    // RPM: Requests per minute, TPM: Tokens per minute
    // RPD: Requests per day, TPD: Tokens per day
    case gemini1_5_flash = "gemini-1.5-flash" // Free 15 RPM/100million TPM, 1500 RPD/ n/a TPD  (1048k context length)
    case gemini1_5_pro = "gemini-1.5-pro" // Free 2 RPM/32,000 TPM, 50 RPD/46,080,000 TPD (1048k context length)
    case gemini1_0_pro = "gemini-1.0-pro" // Free 15 RPM/32,000 TPM, 1,500 RPD/46,080,000 TPD (n/a context length)
}

// swiftlint:enable identifier_name
