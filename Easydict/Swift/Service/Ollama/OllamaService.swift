//
//  OllamaService.swift
//  Easydict
//
//  Created by tisfeng on 2024/7/5.
//  Copyright © 2024 izual. All rights reserved.
//

import Alamofire
import Defaults
import Foundation

// MARK: - OllamaService

@objc(EZOllamaService)
class OllamaService: BaseOpenAIService {
    // MARK: Lifecycle

    required init() {
        super.init()

        Task {
            let models = try await localModels()
            self.ollamaModels = models.models.map(\.name)
            logInfo("ollama models: \(ollamaModels)")
        }
    }

    // MARK: Public

    public override func name() -> String {
        NSLocalizedString("ollama_translate", comment: "")
    }

    public override func serviceType() -> ServiceType {
        .ollama
    }

    // MARK: Internal

    override var defaultEndpoint: String {
        "http://localhost:11434/v1/chat/completions"
    }

    override var defaultModels: [String] {
        ollamaModels
    }

    override var observeKeys: [Defaults.Key<String>] {
        [supportedModelsKey]
    }

    override func apiKeyRequirement() -> ServiceAPIKeyRequirement {
        .none
    }

    override func configurationListItems() -> Any {
        StreamConfigurationView(
            service: self,
            showAPIKeySection: false
        )
    }

    // MARK: Private

    private var ollamaModels = [""]

    /// Get Ollama modles https://github.com/ollama/ollama/blob/main/docs/api.md#list-local-models
    private func localModels() async throws -> OllamaModels {
        // endpoint is http://localhost:11434/v1/chat/completions, we need url http://localhost:11434/api/tags
        let endpointURL = URL(string: endpoint)
        guard let endpointURL, let trueBaseURL = endpointURL.rootURL else {
            throw QueryError(
                type: .parameter, message: "`\(serviceType().rawValue)` endpoint is invalid"
            )
        }

        let modelsURL = trueBaseURL.appendingPathComponent("api/tags")
        let dataTask = AF.request(modelsURL).serializingDecodable(OllamaModels.self)
        return try await dataTask.value
    }
}

// MARK: - OllamaRephraseService

@objc(EZOllamaRephraseService)
class OllamaRephraseService: OllamaService {
    override var isSentenceEnabledByDefault: Bool {
        false
    }

    override var isDictionaryEnabledByDefault: Bool {
        false
    }

    override func name() -> String {
        NSLocalizedString("ollama_rephrase", comment: "")
    }

    override func serviceType() -> ServiceType {
        .ollamaRephrase
    }

    override func configurationListItems() -> Any {
        StreamConfigurationView(
            service: self,
            showAPIKeySection: false,
            showTranslationToggle: false,
            showSentenceToggle: false,
            showDictionaryToggle: false
        )
    }

    override func chatMessageDicts(_ chatQuery: ChatQueryParam) -> [ChatMessage] {
        if enableCustomPrompt {
            return super.chatMessageDicts(chatQuery)
        }

        // Default Rephrase Prompts
        let (text, sourceLanguage, _, _, _) = chatQuery.unpack()
        let prompt = "Rephrase the following \(sourceLanguage.queryLanguageName) text to make it more natural and fluent: \"\"\"\(text)\"\"\""

        let systemPrompt = "You are a writing assistant. Your task is to rephrase the provided text to improve its flow, vocabulary, and overall quality while keeping the original meaning intact. Only return the rephrased text."

        return [
            .init(role: .system, content: systemPrompt),
            .init(role: .user, content: prompt),
        ]
    }
}
