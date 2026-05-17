//
//  GitHubService.swift
//  Easydict
//
//  Created by tisfeng on 2025/4/17.
//  Copyright © 2025 izual. All rights reserved.
//

import Alamofire
import Defaults
import Foundation

// MARK: - GitHubService

@objc(EZGitHubService)
class GitHubService: OpenAIService {
    // MARK: Public

    public override func name() -> String {
        NSLocalizedString("github_models", comment: "")
    }

    public override func serviceType() -> ServiceType {
        .gitHub
    }

    public override func link() -> String? {
        "https://github.com/marketplace/models"
    }

    // MARK: Internal

    override var defaultModels: [String] {
        GitHubModel.allCases.map(\.rawValue)
    }

    override var defaultModel: String {
        GitHubModel.gpt_4_1.rawValue
    }

    override var observeKeys: [Defaults.Key<String>] {
        [apiKeyKey, supportedModelsKey]
    }

    override var defaultEndpoint: String {
        "https://models.github.ai/inference/chat/completions"
    }

    override var remoteModelsEndpoint: String? {
        "https://models.github.ai/catalog/models"
    }

    override func fetchRemoteModelIDs() async throws -> [String] {
        guard !apiKey.trim().isEmpty else {
            throw QueryError(type: .missingSecretKey, message: "GitHub Models token is empty")
        }

        let data = try await fetchRemoteModelData(
            url: try remoteModelsURL(),
            headers: [
                .authorization(bearerToken: apiKey),
                .accept("application/vnd.github+json"),
                HTTPHeader(name: "X-GitHub-Api-Version", value: "2026-03-10"),
            ]
        )

        guard let models = try? JSONDecoder().decode([GitHubCatalogModel].self, from: data) else {
            throw QueryError(type: .api, message: "Invalid models response")
        }
        return normalizedRemoteModelIDs(models.filter(\.supportsTextGeneration).map(\.id))
    }

    override func remoteModelLookupID(_ modelID: String) -> String {
        let modelID = super.remoteModelLookupID(modelID)
        guard let separatorIndex = modelID.firstIndex(of: "/") else {
            return modelID
        }
        return String(modelID[modelID.index(after: separatorIndex)...])
    }

    override func remoteModelGroupName(_ modelID: String) -> String? {
        let modelID = modelID.trim()
        guard let separatorIndex = modelID.firstIndex(of: "/") else {
            return nil
        }
        return String(modelID[..<separatorIndex])
    }

    // MARK: Private

    private func remoteModelsURL() throws -> URL {
        guard let remoteModelsEndpoint,
              let url = URL(string: remoteModelsEndpoint), url.isValid
        else {
            throw QueryError(type: .parameter, message: "Endpoint is invalid")
        }
        return url
    }
}

// MARK: - GitHubCatalogModel

private struct GitHubCatalogModel: Decodable {
    // MARK: Internal

    let id: String
    let supportedInputModalities: [String]?
    let supportedOutputModalities: [String]?

    var supportsTextGeneration: Bool {
        let supportsTextInput = supportedInputModalities?.contains("text") ?? true
        let supportsTextOutput = supportedOutputModalities?.contains("text") ?? true
        return supportsTextInput && supportsTextOutput
    }

    // MARK: Private

    private enum CodingKeys: String, CodingKey {
        case id
        case supportedInputModalities = "supported_input_modalities"
        case supportedOutputModalities = "supported_output_modalities"
    }
}

// MARK: - GitHubModel

enum GitHubModel: String, CaseIterable {
    // Models: https://github.com/marketplace?type=models
    // Rate limit: https://docs.github.com/zh/github-models/prototyping-with-ai-models#rate-limits

    case gpt_4_1 = "gpt-4.1" // Rate limit tier: High: 10 RPM | 50 RPD
    case gpt_4_1_mini = "gpt-4.1-mini" // Low: 15 RPM | 150 RPD
    case gpt_4_1_nano = "gpt-4.1-nano" // Low

    case gpt_4o = "gpt-4o" // Hight: 10 RPM | 50 RPD
    case gpt_4o_mini = "gpt-4o-mini" // Low: 15 RPM | 150 RPD

    /**
     o-series models are not good for translation, since they are expensive and slow,
     and can only use temperature 1.0 which is not consistent with the other models.

     case o3 // Custom:  1 RPM | 8 RPD
     case o4_mini = "o4-mini" // Custom:  2 RPM | 12 RPD

     case gpt_5 = "gpt-5" // Custom:  1 RPM | 8 RPD
     case gpt_5_mini = "gpt-5-mini" // Custom:  2 RPM | 12 RPD
     case gpt_5_nano = "gpt-5-nano"  // Custom:  2 RPM | 12 RPD
     */

    case deepseek_v3_0324 = "deepseek-v3-0324" // High
}
