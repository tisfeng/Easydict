//
//  StreamService+Request.swift
//  Easydict
//
//  Created by tisfeng on 2024/7/27.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation
import OpenAI

extension StreamService {
    /// Stream translation content only
    func contentStreamTranslate(request: TranslationRequest) async throws
        -> AsyncThrowingStream<String, Error> {
        let chatStream = try await streamTranslate(request: request)

        return AsyncThrowingStream<String, Error> { continuation in
            Task {
                do {
                    for try await chatResult in chatStream {
                        if let content = chatResult.content {
                            continuation.yield(content)
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    func streamTranslate(request: TranslationRequest) async throws
        -> AsyncThrowingStream<ChatStreamResult, Error> {
        queryType = request.queryType

        let text = request.text
        var from = Language.auto
        let to = Language.language(fromCode: request.targetLanguage)

        if let sourceLanguage = request.sourceLanguage {
            from = Language.language(fromCode: sourceLanguage)
        }

        if from == .auto {
            let queryModel = try await EZDetectManager().detectText(text)
            from = queryModel.detectedLanguage
        }

        let (prehandled, result) = try await prehandleQueryText(text, from: from, to: to)
        if prehandled {
            logInfo("prehandled query text: \(text.prefix200)")
            if let error = result.error {
                throw error
            }
        }

        return chatStreamTranslate(text, from: from, to: to)
    }
}
