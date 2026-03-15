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
    /// Get final result text, remove redundant content, like tag and qoutes.
    func getFinalResultText(_ text: String) -> String {
        var resultText = text.trim()

        // Remove last </s>, fix Groq model mixtral-8x7b-32768
        let stopFlag = "</s>"
        if !queryModel.queryText.hasSuffix(stopFlag), resultText.hasSuffix(stopFlag) {
            resultText = String(resultText.dropLast(stopFlag.count)).trim()
        }

        // Since it is more difficult to accurately remove redundant quotes in streaming, we wait until the end of the request to remove the quotes
        resultText = resultText.tryToRemoveQuotes().trim()

        return resultText
    }

    /// Throttle update result text, avoid update UI too frequently.
    func throttleUpdateResultText(
        _ textStream: AsyncThrowingStream<String, Error>,
        queryType: EZQueryTextType,
        error: Error?,
        interval: TimeInterval = 0.3,
        completion: @escaping (QueryResult) -> ()
    ) async throws {
        for try await text in textStream._throttle(for: .seconds(interval)) {
            updateResultText(text, queryType: queryType, error: error, completion: completion)
        }
    }

    func updateResultText(
        _ resultText: String?,
        queryType: EZQueryTextType,
        error: Error?,
        completion: @escaping (QueryResult) -> ()
    ) {
        // Acquire the lock before accessing/modifying the shared 'result' state
        updateResultLock.lock()
        defer { updateResultLock.unlock() }

        if result.isStreamFinished {
            cancelStream()

            var queryError: QueryError?

            if let error {
                let nsError = error as NSError
                if nsError.domain == NSURLErrorDomain, nsError.code == NSURLErrorCancelled {
                    // Do not throw error if user cancelled request.
                } else if shouldIgnoreCompletionError(error, resultText: resultText) {
                    logInfo("Ignore stream completion error with existing content: \(error)")
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

        var finalText = resultText?.trim() ?? ""

        if hideThinkTagContent {
            finalText = finalText.filterThinkTagContent().trim()
        }

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

        func completeWithResult(_ result: QueryResult, error: Error?) {
            result.error = .queryError(from: error)
            completion(result)
        }
    }

    private func shouldIgnoreCompletionError(_ error: Error, resultText: String?) -> Bool {
        guard let resultText else {
            return false
        }

        let trimmedText = resultText.trim()
        guard !trimmedText.isEmpty else {
            return false
        }

        let contentLength = trimmedText.count
        let minContentLengthToSuppressError = 8
        guard contentLength >= minContentLengthToSuppressError else {
            logInfo(
                "Do not ignore stream completion error due to insufficient content. " +
                    "Content length: \(contentLength), error: \(error)"
            )
            return false
        }

        // This error can be wrapped by different layers, so we collect a compact context string
        // from the error itself, NSError metadata, and nested underlying errors.
        let lowercasedErrorContext = errorContextString(error).lowercased()

        let isContentTypeError =
            lowercasedErrorContext.contains("incorrectcontenttype(")
            || lowercasedErrorContext.contains("incorrect content-type:")
            || lowercasedErrorContext.contains("unacceptable content-type:")
        let isTextPlainMIME = lowercasedErrorContext.contains("text/plain")
        let shouldSuppress = isContentTypeError && isTextPlainMIME

        if shouldSuppress {
            logInfo(
                "Ignore stream completion error with existing content due to content-type mismatch. " +
                    "Content length: \(contentLength), error: \(error)"
            )
        }

        return shouldSuppress
    }

    private func errorContextString(_ error: Error) -> String {
        var parts = Set<String>()

        func collect(_ currentError: Error, depth: Int) {
            guard depth <= 2 else {
                return
            }

            let nsError = currentError as NSError
            parts.insert(String(describing: currentError))
            parts.insert(nsError.localizedDescription)

            if let failureReason = nsError.localizedFailureReason {
                parts.insert(failureReason)
            }

            if let recoverySuggestion = nsError.localizedRecoverySuggestion {
                parts.insert(recoverySuggestion)
            }

            if let debugDescription = nsError.userInfo[NSDebugDescriptionErrorKey] as? String {
                parts.insert(debugDescription)
            }

            if let responseData = nsError.userInfo["com.alamofire.serialization.response.error.data"] as? Data,
               let responseText = String(data: responseData, encoding: .utf8)
            {
                parts.insert(responseText)
            }

            if let underlyingError = nsError.userInfo[NSUnderlyingErrorKey] as? Error {
                collect(underlyingError, depth: depth + 1)
            }
        }

        collect(error, depth: 0)
        return parts.joined(separator: " | ")
    }
}
