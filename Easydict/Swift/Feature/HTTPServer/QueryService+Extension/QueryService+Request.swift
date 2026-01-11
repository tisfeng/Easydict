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
    func translate(request: TranslationRequest) async throws -> QueryResult {
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
        -> QueryResult {
        var sourceLanguage = from
        if from == .auto {
            let queryModel = try await DetectManager().detectText(text)
            sourceLanguage = queryModel.detectedLanguage
        }

        if enablePrehandle {
            let (prehandled, result) = try await prehandleQueryText(
                text,
                from: sourceLanguage,
                to: to
            )
            if prehandled {
                logInfo("prehandled query text: \(text.prefix200)")
                return result
            }
        }

        return try await translate(text, from: sourceLanguage, to: to)
    }
}
