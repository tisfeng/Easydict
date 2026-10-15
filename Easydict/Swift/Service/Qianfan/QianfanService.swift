//
//  QianfanService.swift
//  Easydict
//
//  Copyright © 2026 izual. All rights reserved.
//

import Alamofire
import Defaults
import Foundation

// MARK: - QianfanService

/// Uses Baidu Qianfan's OpenAI-compatible Chat V2 API.
@objc(EZQianfanService)
class QianfanService: OpenAIService {
    // MARK: Public

    public override func name() -> String {
        NSLocalizedString("qianfan_translate", comment: "The name of Baidu Qianfan Translate")
    }

    public override func serviceType() -> ServiceType {
        .qianfan
    }

    public override func link() -> String? {
        "https://cloud.baidu.com/doc/qianfan-api/s/3m7of64lb"
    }

    // MARK: Internal

    override var defaultModels: [String] {
        QianfanModel.allCases.map(\.rawValue)
    }

    override var defaultModel: String {
        QianfanModel.ernie_4_5_turbo_128k.rawValue
    }

    override var observeKeys: [Defaults.Key<String>] {
        [apiKeyKey, supportedModelsKey]
    }

    override var defaultEndpoint: String {
        "https://qianfan.baidubce.com/v2/chat/completions"
    }

    override var remoteModelsEndpoint: String? {
        "https://qianfan.baidubce.com/v2/models"
    }

    override func fetchRemoteModelIDs() async throws -> [String] {
        guard !apiKey.trim().isEmpty else {
            throw QueryError(type: .missingSecretKey, message: "API key is empty")
        }

        guard let endpoint = remoteModelsEndpoint,
              let url = URL(string: endpoint),
              url.isValid
        else {
            throw QueryError(type: .parameter, message: "Qianfan models endpoint is invalid")
        }

        let data = try await fetchRemoteModelData(
            url: url,
            headers: [
                .authorization(bearerToken: apiKey),
                .accept("application/json"),
            ]
        )

        guard let response = try? JSONDecoder().decode(QianfanModelListResponse.self, from: data) else {
            throw QueryError(type: .api, message: "Invalid Qianfan models response")
        }

        return normalizedRemoteModelIDs(
            response.data
                .filter { $0.type == "chat" }
                .map(\.id)
        )
    }
}

// MARK: - QianfanModel

private enum QianfanModel: String, CaseIterable {
    // Model IDs from https://cloud.baidu.com/doc/qianfan/s/rmh4stp0j
    case ernie_5_1 = "ernie-5.1"
    case ernie_5_0 = "ernie-5.0"
    case ernie_4_5_turbo_128k = "ernie-4.5-turbo-128k"
}

// MARK: - QianfanModelListResponse

private struct QianfanModelListResponse: Decodable {
    struct Model: Decodable {
        let id: String
        let type: String
    }

    let data: [Model]
}
