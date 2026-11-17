//
//  MWDictRequest.swift
//  Easydict
//
//  Created by wanzaiqidao on 2026/11/09.
//  Copyright © 2026 izual. All rights reserved.
//

import Alamofire
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
                message: String(
                    format: String(localized: "service.mw_dict.error.invalid_url %@"),
                    word
                )
            )
        }

        let response = await session.request(
            url,
            headers: [
                "User-Agent": AppConstants.userAgent,
                "Accept": "application/json",
            ]
        ) { $0.timeoutInterval = timeout }
            .serializingData(automaticallyCancelling: true)
            .response

        if let error = response.error {
            if DictionarySupport.isCancellation(error) {
                throw CancellationError()
            }
            throw QueryError.error(
                type: .api,
                message: String(
                    format: String(localized: "service.mw_dict.error.request_failed %@"),
                    error.localizedDescription
                )
            )
        }

        if let httpResponse = response.response {
            switch httpResponse.statusCode {
            case 200 ..< 300:
                break
            case 401, 403:
                throw QueryError.error(
                    type: .api,
                    message: String(localized: "service.mw_dict.error.invalid_key")
                )
            default:
                throw QueryError.error(
                    type: .api,
                    message: String(
                        format: String(localized: "service.dictionary.error.http_status %ld"),
                        httpResponse.statusCode
                    )
                )
            }
        }

        guard let data = response.data, !data.isEmpty else {
            throw QueryError.error(
                type: .api,
                message: String(localized: "service.mw_dict.error.empty_response")
            )
        }

        // An invalid key or an unsubscribed reference is reported as a plain
        // text body with a 2xx status, not as a JSON array.
        let body = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard body.hasPrefix("[") else {
            if body.localizedCaseInsensitiveContains("api key") {
                throw QueryError.error(
                    type: .api,
                    message: String(localized: "service.mw_dict.error.invalid_key")
                )
            }
            throw QueryError.error(
                type: .api,
                message: String(
                    format: String(localized: "service.mw_dict.error.request_failed %@"),
                    body
                )
            )
        }

        return data
    }

    // MARK: Private

    private static let session: Session = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpCookieStorage = nil
        configuration.httpShouldSetCookies = false
        configuration.urlCache = nil
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        return Session(configuration: configuration)
    }()
}
