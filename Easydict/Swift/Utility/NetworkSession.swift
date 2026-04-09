//
//  NetworkSession.swift
//  Easydict
//
//  Created by tisfeng on 2026/4/9.
//  Copyright © 2026 izual. All rights reserved.
//

import Alamofire
import Combine
import Defaults
import Foundation

// MARK: - NetworkSession

/// Manages the app-wide Alamofire Session, supporting an optional user-configured HTTP/SOCKS proxy.
///
/// When `Defaults[.httpProxyURL]` is non-empty the session is configured with
/// the parsed proxy dictionary; otherwise the system default session is used.
final class NetworkSession {
    // MARK: Lifecycle

    private init() {
        setupSessionObserver()
    }

    // MARK: Internal

    static let shared = NetworkSession()

    /// Current Alamofire Session. Updated automatically when the proxy setting changes.
    private(set) var session: Alamofire.Session = .default

    // MARK: Private

    private var cancellables: Set<AnyCancellable> = []

    /// Creates an Alamofire Session configured with the given proxy URL string.
    ///
    /// Returns `Session.default` when the URL is empty or cannot be parsed.
    private static func makeSession(proxyURL: String) -> Alamofire.Session {
        let trimmed = proxyURL.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty,
              let proxyDict = proxyDictionary(for: trimmed)
        else {
            return .default
        }
        let config = URLSessionConfiguration.default
        config.connectionProxyDictionary = proxyDict
        return Alamofire.Session(configuration: config)
    }

    /// Parses a proxy URL string into a `connectionProxyDictionary` for `URLSessionConfiguration`.
    ///
    /// Supported formats:
    /// - `http://host:port`  — HTTP proxy (also used for HTTPS via CONNECT tunnel)
    /// - `socks5://host:port` — SOCKS5 proxy
    /// - `host:port`         — treated as HTTP proxy
    private static func proxyDictionary(for proxyURL: String) -> [AnyHashable: Any]? {
        var urlString = proxyURL
        if !urlString.contains("://") {
            urlString = "http://" + urlString
        }

        guard let url = URL(string: urlString),
              let host = url.host,
              let port = url.port,
              !host.isEmpty
        else {
            return nil
        }

        var dict: [AnyHashable: Any] = [:]
        let scheme = url.scheme ?? "http"

        if scheme == "socks5" || scheme == "socks" {
            dict[kCFNetworkProxiesSOCKSEnable as String] = true
            dict[kCFNetworkProxiesSOCKSProxy as String] = host
            dict[kCFNetworkProxiesSOCKSPort as String] = port
        } else {
            // HTTP proxy — handles plain HTTP and HTTPS (via CONNECT tunnel)
            dict[kCFNetworkProxiesHTTPEnable as String] = true
            dict[kCFNetworkProxiesHTTPProxy as String] = host
            dict[kCFNetworkProxiesHTTPPort as String] = port
            dict[kCFNetworkProxiesHTTPSEnable as String] = true
            dict[kCFNetworkProxiesHTTPSProxy as String] = host
            dict[kCFNetworkProxiesHTTPSPort as String] = port
        }

        return dict
    }

    private func setupSessionObserver() {
        Defaults.publisher(.httpProxyURL, options: [.initial])
            .sink { [weak self] change in
                self?.session = NetworkSession.makeSession(proxyURL: change.newValue)
            }
            .store(in: &cancellables)
    }
}

// MARK: - Global accessor

/// A proxy-aware Alamofire Session for making HTTP requests throughout the app.
///
/// Use `EAF` instead of Alamofire's global `AF` so that requests automatically
/// route through the user-configured local HTTP/SOCKS proxy when one is set.
var EAF: Alamofire.Session { NetworkSession.shared.session }
