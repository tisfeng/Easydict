//
//  CookieManager.swift
//  Easydict
//
//  Created by tisfeng on 2025/1/1.
//  Copyright © 2025 izual. All rights reserved.
//

import Alamofire
import Foundation

// MARK: - CookieManager

/// Manager for handling cookie-related operations
@objc(EZCookieManager)
final class CookieManager: NSObject {
    // MARK: Lifecycle

    private override init() {
        let configuration = URLSessionConfiguration.default
        configuration.headers = .default
        self.session = Session(configuration: configuration)
        super.init()
    }

    // MARK: Internal

    @objc static let shared = CookieManager()

    /// Request cookie of URL
    /// - Parameters:
    ///   - url: The URL to request cookie from
    ///   - cookieName: The name of the cookie to retrieve
    ///   - completion: Completion handler with cookie string
    @objc
    func requestCookie(ofURL url: String, cookieName: String, completion: @escaping (String?) -> ()) {
        guard let url = URL(string: url) else {
            completion(nil)
            return
        }

        session.request(url, method: .get)
            .response { response in
                switch response.result {
                case .success:
                    if let cookies = HTTPCookieStorage.shared.cookies(for: url) {
                        for cookie in cookies where cookie.name == cookieName {
                            let cookieString =
                                "\(cookie.name)=\(cookie.value); domain=\(cookie.domain); expires=\(cookie.expiresDate?.description ?? "")"
                            completion(cookieString)
                            return
                        }
                    }
                    completion(nil)

                case let .failure(error):
                    print("Request cookie error: \(error)")
                    completion(nil)
                }
            }
    }

    /// Request cookie using async/await
    /// - Parameters:
    ///   - url: The URL to request cookie from
    ///   - cookieName: The name of the cookie to retrieve
    /// - Returns: Cookie string if found, nil otherwise
    func requestCookie(ofURL url: String, cookieName: String) async -> String? {
        await withCheckedContinuation { continuation in
            requestCookie(ofURL: url, cookieName: cookieName) { cookie in
                continuation.resume(returning: cookie)
            }
        }
    }

    // MARK: Private

    private let session: Session
}
