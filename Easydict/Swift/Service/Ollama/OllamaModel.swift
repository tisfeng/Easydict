//
//  OllamaModel.swift
//  Easydict
//
//  Created by tisfeng on 2024/7/7.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation

// MARK: - OllamaModels

// Ollama docs https://github.com/ollama/ollama/blob/main/docs/api.md#list-local-models
struct OllamaModels: Codable {
    let models: [OllamaModel]
}

// MARK: - OllamaModel

struct OllamaModel: Codable {
    enum CodingKeys: String, CodingKey {
        case name, model
        case modifiedAt = "modified_at"
        case size, digest, details
    }

    let name, model, modifiedAt: String
    let size: Int
    let digest: String
    let details: OllamaModelDetails
}

// MARK: - OllamaModelDetails

struct OllamaModelDetails: Codable {
    enum CodingKeys: String, CodingKey {
        case parentModel = "parent_model"
        case format, family, families
        case parameterSize = "parameter_size"
        case quantizationLevel = "quantization_level"
    }

    let parentModel, format, family: String
    let families: [String]?
    let parameterSize, quantizationLevel: String
}
