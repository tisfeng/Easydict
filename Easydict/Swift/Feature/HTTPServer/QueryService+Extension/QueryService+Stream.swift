//
//  QueryService+Stream.swift
//  Easydict
//
//  Created by tisfeng on 2024/7/27.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation
import Vapor

extension QueryService {
    func streamTranslateText(request: TranslationRequest) async throws -> AsyncThrowingStream<String, Error> {
        let streamResults = try await streamTranslate(request: request)
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    for try await result in streamResults {
                        if result.isStreamFinished {
                            continuation.finish()
                            break
                        }
                        continuation.yield(result.translatedText ?? "")
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    func streamTranslate(request: TranslationRequest) async throws -> AsyncThrowingStream<EZQueryResult, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    while true {
                        let result = try await translate(request: request)
                        continuation.yield(result)
                        if result.isStreamFinished {
                            break
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
