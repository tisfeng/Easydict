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

        // Match and replace only the API suffix; escaped separators may be part of a gateway route.
        var path = components.percentEncodedPath
        while path.last == "/" {
            path.removeLast()
        }
        let lowered = path.lowercased()
        let chatSuffix = "/chat/completions"
        let responsesSuffix = "/responses"

        switch apiType {
        case .responses:
            if lowered.hasSuffix(chatSuffix) {
                path = path.dropLast(chatSuffix.count) + responsesSuffix
            } else if lowered.hasSuffix(responsesSuffix) {
                return endpoint
            } else if path.isEmpty {
                path = "/v1" + responsesSuffix
            } else if isBareBase(path) {
                path += responsesSuffix
            } else {
                return endpoint
            }
        case .chat:
            guard lowered.hasSuffix(responsesSuffix) else {
                return endpoint
            }
            path = path.dropLast(responsesSuffix.count) + chatSuffix
        }

        components.percentEncodedPath = path
        return components.url ?? endpoint
    }

    // MARK: Private

    /// A non-empty bare base ends with an API version such as `v1`.
    private func isBareBase(_ path: String) -> Bool {
        guard let last = path.split(separator: "/").last else {
            return false
        }
        return isVersionSegment(last.lowercased())
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
}
