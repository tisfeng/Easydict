//
//  CookieManager.swift
//  Easydict
//
//  Created by tisfeng on 2025/1/1.
//  Copyright © 2025 izual. All rights reserved.
//

import Alamofire
import Foundation

/// A utility class for managing HTTP cookies
@objc(EZCookieManager)
final class CookieManager: NSObject {
    // MARK: Lifecycle

    private override init() {
        let configuration = URLSessionConfiguration.default
        configuration.httpCookieStorage = HTTPCookieStorage.shared
        configuration.httpCookieAcceptPolicy = .always

        self.session = Session(configuration: configuration)
        super.init()
    }

    // MARK: Internal

    @objc static let shared = CookieManager()

    /// Request a specific cookie from a URL
    /// - Parameters:
    ///   - url: The URL to request the cookie from
    ///   - name: The name of the cookie to retrieve
    /// - Returns: The value of the requested cookie, if found
    /// - Throws: Network, validation, or parameter errors
    @objc
    func requestCookie(ofURL url: String, name: String) async throws -> String? {
        logInfo("Requesting cookie \(name) from \(url)")

        let cookies = try await requestCookies(ofURL: url)

        if let cookie = cookies?.first(where: { $0.name == name }) {
            let cookieString = "\(cookie.name)=\(cookie.value); domain=\(cookie.domain);"

            if let expiresDate = cookie.expiresDate {
                return "\(cookieString) expiresDate=\(expiresDate);"
            }
            return cookieString
        }

        return nil
    }

    // MARK: Private

    private let session: Session

    /// Request all cookies from a URL
    /// - Parameter url: The URL to request cookies from
    /// - Returns: Array of cookies if successful
    /// - Throws: Network or validation errors
    private func requestCookies(ofURL url: String) async throws -> [HTTPCookie]? {
        guard let url = URL(string: url) else {
            logError("Invalid URL: \(url)")
            throw QueryError(type: .parameter, message: "Invalid URL")
        }

        _ = try await session.request(url)
            .validate()
            .serializingString()
            .value

        return HTTPCookieStorage.shared.cookies(for: url)
    }
}
