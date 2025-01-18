//
//  QueryService+Stream.swift
//  Easydict
//
//  Created by tisfeng on 2024/7/27.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation
import OpenAI
import Vapor

extension LLMStreamService {
    func streamTranslateText(request: TranslationRequest) async throws -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let chatStreamResults = try await streamTranslate(request: request)
                    for try await result in chatStreamResults {
                        let content = result.choices.first?.delta.content ?? ""
                        continuation.yield(content)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
