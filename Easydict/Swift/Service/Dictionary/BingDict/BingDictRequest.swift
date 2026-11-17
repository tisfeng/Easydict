//
//  BingDictRequest.swift
//  Easydict
//
//  Created by wanzaiqidao on 2026/11/04.
//  Copyright © 2026 izual. All rights reserved.
//

import Alamofire
import Foundation

// MARK: - BingDictRequest

/// Anonymous Bing dictionary page request.
///
/// The dict page `https://cn.bing.com/dict/search?q={word}` is server-rendered
/// and reachable without cookies or tokens; only a browser-like User-Agent is
/// required. The session is ephemeral (no cookie storage, no cache) so the
/// service never reuses another service's Bing session.
enum BingDictRequest {
    // MARK: Internal

    static let baseURLString = "https://cn.bing.com/dict/search"

    /// Fetch the server-rendered dict page HTML for a word.
    static func fetchPage(
        for word: String,
        timeout: TimeInterval = 30
    ) async throws
        -> String {
        guard let url = URL(string: "\(baseURLString)?q=\(DictionarySupport.percentEncodedQueryValue(word))") else {
            throw QueryError.error(
                type: .api,
                message: String(
                    format: String(localized: "service.bing_dict.error.invalid_url %@"),
                    word
                )
            )
        }

        let response = await session.request(
            url,
            headers: [
                "User-Agent": AppConstants.userAgent,
                "Accept": "text/html",
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
                    format: String(localized: "service.bing_dict.error.request_failed %@"),
                    error.localizedDescription
                )
            )
        }

        if let httpResponse = response.response, !(200 ..< 300).contains(httpResponse.statusCode) {
            throw QueryError.error(
                type: .api,
                message: String(
                    format: String(localized: "service.dictionary.error.http_status %ld"),
                    httpResponse.statusCode
                )
            )
        }

        guard let data = response.data,
              let html = String(data: data, encoding: .utf8),
              !html.isEmpty
        else {
            throw QueryError.error(
                type: .api,
                message: String(localized: "service.bing_dict.error.empty_page")
            )
        }
        return html
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
