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
