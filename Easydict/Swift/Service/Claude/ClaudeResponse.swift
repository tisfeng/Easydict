//
//  ClaudeResponse.swift
//  Easydict
//
//  Created by zkbkb on 2026/4/1.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation

// MARK: - ClaudeStreamDelta

/// Represents a `content_block_delta` SSE event from the Anthropic Messages API.
/// Contains incremental text content during streaming.
struct ClaudeStreamDelta: Codable {
    // MARK: - DeltaContent

    struct DeltaContent: Codable {
        let type: String
        let text: String?
    }

    let type: String
    let index: Int?
    let delta: DeltaContent?
}

// MARK: - ClaudeStreamError

/// Represents an `error` SSE event from the Anthropic Messages API.
struct ClaudeStreamError: Codable {
    // MARK: - ErrorDetail

    struct ErrorDetail: Codable {
        let type: String
        let message: String
    }

    let type: String
    let error: ErrorDetail
}
