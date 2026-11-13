//
//  MWDictRequest.swift
//  Easydict
//
//  Created by wanzaiqidao on 2026/11/09.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation

// MARK: - MWDictRequest

/// Merriam-Webster Collegiate API request.
///
/// The dictionary website itself sits behind a Cloudflare bot challenge, so the
/// app uses the official API (`dictionaryapi.com`), which serves the same
/// Collegiate content as JSON and requires a free user key.
enum MWDictRequest {
    // MARK: Internal

    static let baseURLString = "https://dictionaryapi.com/api/v3/references/collegiate/json"

    /// Fetch the raw JSON for a word.
    static func fetchEntryJSON(
        for word: String,
        apiKey: String,
        timeout: TimeInterval = 30,
        reference: String = "collegiate"
    ) async throws
        -> Data {
        let encodedWord = DictionarySupport.percentEncodedQueryValue(word)
        let encodedKey = DictionarySupport.percentEncodedQueryValue(apiKey)
        guard let url =
            URL(
                string: "https://dictionaryapi.com/api/v3/references/\(reference)/json/\(encodedWord)?key=\(encodedKey)"
            )
        else {
            throw QueryError.error(
                type: .api,
                message: "Merriam-Webster URL is invalid: \(word)"
            )
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.timeoutInterval = timeout
        urlRequest.setValue(AppConstants.userAgent, forHTTPHeaderField: "User-Agent")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        urlRequest.httpShouldHandleCookies = false

        do {
            let (data, response) = try await session.data(for: urlRequest)
            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200 ..< 300:
                    break
                case 401, 403:
                    throw QueryError.error(
                        type: .api,
                        message: "Merriam-Webster API key is invalid or expired"
                    )
                default:
                    throw QueryError.error(
                        type: .api,
                        message: "Merriam-Webster HTTP \(httpResponse.statusCode)"
                    )
                }
            }
            guard !data.isEmpty else {
                throw QueryError.error(
                    type: .api,
                    message: "Merriam-Webster response is empty"
                )
            }
            return data
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as URLError where error.code == .cancelled {
            throw CancellationError()
        } catch let error as QueryError {
            throw error
        } catch {
            throw QueryError.error(
                type: .api,
                message: "Merriam-Webster request failed: \(error.localizedDescription)"
            )
        }
    }

    // MARK: Private

    private static let session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpCookieStorage = nil
        configuration.httpShouldSetCookies = false
        configuration.urlCache = nil
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: configuration)
    }()
}
