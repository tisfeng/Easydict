//
//  StreamService+UpdateResult.swift
//  Easydict
//
//  Created by tisfeng on 2025/1/18.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation
import RegexBuilder

extension StreamService {
    /// Throttle update result text, avoid update UI too frequently.
    func throttleUpdateResultText(
        _ textStream: AsyncThrowingStream<String, Error>,
        queryType: EZQueryTextType,
        error: Error?,
        interval: TimeInterval = 0.2,
        completion: @escaping (EZQueryResult) -> ()
    ) async throws {
        for try await text in textStream._throttle(for: .seconds(interval)) {
            updateResultText(text, queryType: queryType, error: error, completion: completion)
        }
    }

    func updateResultText(
        _ resultText: String?,
        queryType: EZQueryTextType,
        error: Error?,
        completion: @escaping (EZQueryResult) -> ()
    ) {
        if result.isStreamFinished {
            cancelStream()

            var queryError: QueryError?

            if let error {
                let nsError = error as NSError
                if nsError.domain == NSURLErrorDomain, nsError.code == NSURLErrorCancelled {
                    // Do not throw error if user cancelled request.
                } else {
                    queryError = .queryError(from: error)
                }
            } else if resultText?.isEmpty ?? true {
                // If error is nil but result text is also empty, we should report error.
                queryError = .init(type: .noResult)
            }

            completeWithResult(result, error: queryError)
            return
        }

        // If error is not nil, means stream is finished.
        result.isStreamFinished = error != nil

        let finalText = resultText?.filterThinkTagContent().trim() ?? ""

        let updateCompletion = { [weak result] in
            guard let result else { return }

            result.translatedResults = [finalText]
            completeWithResult(result, error: error)
        }

        switch queryType {
        case .dictionary:
            if error != nil {
                result.showBigWord = false
                result.translateResultsTopInset = 0
                updateCompletion()
                return
            }

            result.showBigWord = true
            result.translateResultsTopInset = 6
            updateCompletion()

        default:
            updateCompletion()
        }

        func completeWithResult(_ result: EZQueryResult, error: Error?) {
            result.error = .queryError(from: error)
            completion(result)
        }
    }
}
