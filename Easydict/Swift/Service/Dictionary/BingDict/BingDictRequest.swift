//
//  BingDictRequest.swift
//  Easydict
//
//  Created by wanzaiqidao on 2026/11/04.
//  Copyright © 2026 izual. All rights reserved.
//

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
        guard let url = URL(string: "\(baseURLString)?q=\(percentEncodedQueryValue(word))") else {
            throw QueryError.error(
                type: .api,
                message: "Bing dictionary URL is invalid: \(word)"
            )
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.timeoutInterval = timeout
        urlRequest.setValue(AppConstants.userAgent, forHTTPHeaderField: "User-Agent")
        urlRequest.setValue("text/html", forHTTPHeaderField: "Accept")
        urlRequest.httpShouldHandleCookies = false

        do {
            let (data, response) = try await session.data(for: urlRequest)
            if let httpResponse = response as? HTTPURLResponse,
               !(200 ..< 300).contains(httpResponse.statusCode) {
                throw QueryError.error(
                    type: .api,
                    message: "Bing dictionary HTTP \(httpResponse.statusCode)"
                )
            }
            guard let html = String(data: data, encoding: .utf8), !html.isEmpty else {
                throw QueryError.error(
                    type: .api,
                    message: "Bing dictionary page data is empty"
                )
            }
            return html
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as URLError where error.code == .cancelled {
            throw CancellationError()
        } catch let error as QueryError {
            throw error
        } catch {
            throw QueryError.error(
                type: .api,
                message: "Bing dictionary request failed: \(error.localizedDescription)"
            )
        }
    }

    /// Percent-encode a query value so reserved characters (`+`, `&`, `=`, `#`)
    /// reach Bing literally instead of changing the query.
    static func percentEncodedQueryValue(_ text: String) -> String {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        return text.addingPercentEncoding(withAllowedCharacters: allowed) ?? text
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
