//
//  DoubaoResponse.swift
//  Easydict
//
//  Created by Liaoworking on 2025/9/30.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation

// MARK: - DoubaoResponse

struct DoubaoResponse: Codable {
    enum CodingKeys: String, CodingKey {
        case output, usage, id, model, object, status, caching, store, error
        case createdAt = "created_at"
    }

    let output: [DoubaoOutput]?
    let usage: DoubaoUsage?
    let createdAt: Int?
    let id: String?
    let model: String?
    let object: String?
    let status: String?
    let caching: DoubaoCache?
    let store: Bool?
    let error: DoubaoError?
}

// MARK: - DoubaoOutput

struct DoubaoOutput: Codable {
    let type: String?
    let role: String?
    let content: [DoubaoContent]?
    let status: String?
    let id: String?
}

// MARK: - DoubaoContent

struct DoubaoContent: Codable {
    let type: String?
    let text: String?
}

// MARK: - DoubaoUsage

struct DoubaoUsage: Codable {
    enum CodingKeys: String, CodingKey {
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
        case totalTokens = "total_tokens"
        case inputTokensDetails = "input_tokens_details"
        case outputTokensDetails = "output_tokens_details"
    }

    let inputTokens: Int?
    let outputTokens: Int?
    let totalTokens: Int?
    let inputTokensDetails: DoubaoTokensDetails?
    let outputTokensDetails: DoubaoTokensDetails?
}

// MARK: - DoubaoTokensDetails

struct DoubaoTokensDetails: Codable {
    enum CodingKeys: String, CodingKey {
        case cachedTokens = "cached_tokens"
        case reasoningTokens = "reasoning_tokens"
    }

    let cachedTokens: Int?
    let reasoningTokens: Int?
}

// MARK: - DoubaoCache

struct DoubaoCache: Codable {
    let type: String?
}

// MARK: - DoubaoError

struct DoubaoError: Codable {
    let code: String?
    let message: String?
    let param: String?
    let type: String?
}
