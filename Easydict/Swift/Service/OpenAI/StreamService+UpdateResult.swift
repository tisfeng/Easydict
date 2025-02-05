//
//  StreamService+UpdateResult.swift
//  Easydict
//
//  Created by tisfeng on 2025/1/18.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

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

            result.error = queryError
            completion(result)
            return
        }

        var translatedTexts: [String]?
        if let resultText {
            translatedTexts = [resultText.trim()]
        }

        // Make a local copy of result to avoid potential retain cycles
        let localResult = result

        // If error is not nil, means stream is finished.
        localResult.isStreamFinished = error != nil

        /**
         This code may crash

         SIGABRT
         Object 0x600002932840 of class __BridgingBufferStorage deallocated with non-zero retain count 2. This object's deinit, or something called from it, may have created a strong reference to self which outlived deinit, resulting in a dangling reference.
          >
         KERN_INVALID_ADDRESS at 0xfffffffffffffff0.
         */
        localResult.translatedResults = translatedTexts

        let updateCompletion = {
            localResult.error = .queryError(from: error)
            completion(localResult)
        }

        switch queryType {
        case .dictionary:
            if error != nil {
                localResult.showBigWord = false
                localResult.translateResultsTopInset = 0
                updateCompletion()
                return
            }

            localResult.showBigWord = true
            localResult.translateResultsTopInset = 6
            updateCompletion()

        default:
            updateCompletion()
        }
    }
}
