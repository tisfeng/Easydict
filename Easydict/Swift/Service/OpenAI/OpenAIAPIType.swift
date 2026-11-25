//
//  OpenAIAPIType.swift
//  Easydict
//
//  Created by tisfeng on 2026/11/25.
//  Copyright © 2026 izual. All rights reserved.
//

import Defaults
import Foundation
import SwiftUI

// MARK: - OpenAIAPIType

/// Wire format for an OpenAI-compatible custom service.
///
/// `chat` keeps the existing Chat Completions request. `responses` sends `input`
/// to the Responses API. The choice is independent of the model name because a
/// gateway can expose either format for the same model identifier.
enum OpenAIAPIType: String, CaseIterable, Defaults.Serializable {
    case chat
    case responses
}

// MARK: - EnumLocalizedStringConvertible

extension OpenAIAPIType: EnumLocalizedStringConvertible {
    var title: LocalizedStringKey {
        switch self {
        case .chat:
            "service.openai_api_type.chat"
        case .responses:
            "service.openai_api_type.responses"
        }
    }
}

// MARK: - OpenAIEndpointAdapter

/// Rewrites a custom OpenAI endpoint when its path uses a known wire-format suffix.
///
/// Unrecognized full paths stay untouched, and Chat Completions does not gain a suffix
/// merely because the stored value is a bare base URL. That preserves existing endpoints
/// such as `https://host/api/chat`.
struct OpenAIEndpointAdapter {
    // MARK: Internal

    /// Returns the URL that should receive a request for `apiType`.
    func requestURL(endpoint: URL, apiType: OpenAIAPIType) -> URL {
        guard var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false) else {
            return endpoint
        }

        let parts = pathParts(components.path)
        let lowered = parts.map { $0.lowercased() }
        var updated = parts

        switch apiType {
        case .responses:
            if lowered.suffix(2).elementsEqual(["chat", "completions"]) {
                updated.removeLast(2)
                updated.append("responses")
            } else if lowered.last == "responses" {
                return endpoint
            } else if isBareBase(parts) {
                if parts.isEmpty {
                    updated = ["v1", "responses"]
                } else {
                    updated.append("responses")
                }
            } else {
                return endpoint
            }
        case .chat:
            guard lowered.last == "responses" else {
                return endpoint
            }
            updated.removeLast()
            updated.append(contentsOf: ["chat", "completions"])
        }

        components.path = "/" + updated.joined(separator: "/")
        return components.url ?? endpoint
    }

    // MARK: Private

    /// A bare base is an origin, or a path whose last segment is an API version such as `v1`.
    private func isBareBase(_ parts: [String]) -> Bool {
        guard let last = parts.last?.lowercased() else {
            return true
        }
        return isVersionSegment(last)
    }

    /// Matches `v1`, `v2`, and version labels such as `v1beta` without treating `v` alone as a version.
    private func isVersionSegment(_ segment: String) -> Bool {
        guard segment.count > 1, segment.first == "v" else {
            return false
        }
        let version = segment.dropFirst()
        guard let first = version.first, first.isNumber else {
            return false
        }
        return version.allSatisfy { $0.isNumber || $0.isLetter }
    }

    private func pathParts(_ path: String) -> [String] {
        path.split(separator: "/", omittingEmptySubsequences: true).map(String.init)
    }
}
