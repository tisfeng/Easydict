//
//  QueryService+Extension.swift
//  Easydict
//
//  Created by tisfeng on 2024/7/22.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation

extension QueryService {
    /// Translate request, if source language is auto or nil, will detect source language first.
    func translate(request: TranslationRequest) async throws -> EZQueryResult {
        queryType = request.queryType

        let text = request.text
        var from = Language.auto
        let to = Language.language(fromCode: request.targetLanguage)

        if let sourceLanguage = request.sourceLanguage {
            from = Language.language(fromCode: sourceLanguage)
        }

        return try await translate(text, from: from, to: to, enablePrehandle: true)
    }

    func translate(
        _ text: String,
        from: Language,
        to: Language,
        enablePrehandle: Bool
    ) async throws
        -> EZQueryResult {
        var sourceLanguage = from
        if from == .auto {
            let queryModel = try await EZDetectManager().detectText(text)
            sourceLanguage = queryModel.detectedLanguage
        }

        if enablePrehandle {
            let (prehandled, result) = try await prehandleQueryText(
                text: text, from: sourceLanguage, to: to
            )
            if prehandled {
                logInfo("prehandled query text: \(text.prefix200)")
                return result
            }
        }

        return try await translate(text, from: sourceLanguage, to: to)
    }

    func prehandleQueryText(
        text: String,
        from: Language,
        to: Language
    ) async throws
        -> (Bool, EZQueryResult) {
        try await withCheckedThrowingContinuation { continuation in
            let isHandled = self.prehandleQueryText(text, from: from, to: to) { result, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: (true, result))
                }
            }

            if !isHandled {
                continuation.resume(returning: (false, EZQueryResult()))
            }
        }
    }
}
