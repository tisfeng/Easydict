//
//  QueryService+Extension.swift
//  Easydict
//
//  Created by tisfeng on 2024/7/22.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation

extension QueryService {
    func translate(request: TranslationRequest) async throws -> EZQueryResult {
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
            let (prehandled, result) = try await prehandleQueryText(text: text, from: sourceLanguage, to: to)
            if prehandled {
                logInfo("prehandled query text: \(text.truncated())")
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
            var prehandled = false
            self.prehandleQueryText(text, from: from, to: to) { result, error in
                prehandled = true

                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: (prehandled, result))
                }
            }

            if !prehandled {
                continuation.resume(returning: (prehandled, result))
            }
        }
    }
}
