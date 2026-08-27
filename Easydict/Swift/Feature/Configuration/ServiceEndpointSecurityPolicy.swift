//
//  ServiceEndpointSecurityPolicy.swift
//  Easydict
//
//  Created by Eric Pan on 2026/8/26.
//  Copyright © 2026 izual. All rights reserved.
//

import Alamofire
import Foundation

// MARK: - ServiceEndpointSecurityPolicy

/// Applies the transport boundary shared by settings, URL schemes, backup restore, and requests.
///
/// HTTPS endpoints may target any host. Plain HTTP is restricted to exact, literal loopback
/// hosts and is never approved through DNS resolution, preventing aliases and DNS rebinding from
/// widening the exception.
enum ServiceEndpointSecurityPolicy {
    // MARK: Internal

    static func allows(_ rawValue: String) -> Bool {
        guard let components = URLComponents(string: rawValue.trim()),
              let scheme = components.scheme?.lowercased(),
              let host = components.host,
              !host.isEmpty,
              components.user == nil,
              components.password == nil,
              components.url != nil
        else {
            return false
        }

        switch scheme {
        case "https":
            return true
        case "http":
            return loopbackHosts.contains(normalizedHost(host))
        default:
            return false
        }
    }

    static func validatedURL(_ rawValue: String) throws -> URL {
        let rawValue = rawValue.trim()
        guard allows(rawValue), let url = URL(string: rawValue) else {
            throw ServiceEndpointSecurityError.disallowedEndpoint
        }
        return url
    }

    /// Redirects are new network destinations, so they must satisfy the endpoint policy too.
    /// They are additionally restricted to the original origin because credential-bearing
    /// headers are provider-specific and must never cross a scheme, host, or port boundary.
    static func allowsRedirect(from originalURL: URL, to redirectedURL: URL) -> Bool {
        guard allows(originalURL.absoluteString), allows(redirectedURL.absoluteString) else {
            return false
        }
        return origin(of: originalURL) == origin(of: redirectedURL)
    }

    // MARK: Private

    private struct Origin: Equatable {
        let scheme: String
        let host: String
        let port: Int?
    }

    private static let loopbackHosts = Set(["localhost", "127.0.0.1", "::1"])

    private static func origin(of url: URL) -> Origin? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let scheme = components.scheme?.lowercased(),
              let host = components.host,
              !host.isEmpty
        else {
            return nil
        }

        let defaultPort: Int?
        switch scheme {
        case "http":
            defaultPort = 80
        case "https":
            defaultPort = 443
        default:
            defaultPort = nil
        }

        return Origin(
            scheme: scheme,
            host: normalizedHost(host),
            port: components.port ?? defaultPort
        )
    }

    private static func normalizedHost(_ host: String) -> String {
        let host = host.lowercased()
        guard host.hasPrefix("["), host.hasSuffix("]") else { return host }
        return String(host.dropFirst().dropLast())
    }
}

// MARK: - ServiceEndpointRequestSecurity

/// Creates network transports which fail closed when a service endpoint redirects outside its
/// original origin. A per-task delegate keeps the shared session's normal protocol and cache
/// behavior while ensuring every service request receives the redirect boundary.
enum ServiceEndpointRequestSecurity {
    static func data(
        for request: URLRequest,
        originalURL: URL
    ) async throws
        -> (Data, URLResponse) {
        guard let requestURL = request.url,
              ServiceEndpointSecurityPolicy.allowsRedirect(
                  from: originalURL,
                  to: requestURL
              )
        else {
            throw ServiceEndpointSecurityError.disallowedEndpoint
        }
        return try await URLSession.shared.data(
            for: request,
            delegate: ServiceEndpointRedirectDelegate(originalURL: originalURL)
        )
    }

    static func bytes(
        for request: URLRequest,
        originalURL: URL
    ) async throws
        -> (URLSession.AsyncBytes, URLResponse) {
        guard let requestURL = request.url,
              ServiceEndpointSecurityPolicy.allowsRedirect(
                  from: originalURL,
                  to: requestURL
              )
        else {
            throw ServiceEndpointSecurityError.disallowedEndpoint
        }
        return try await URLSession.shared.bytes(
            for: request,
            delegate: ServiceEndpointRedirectDelegate(originalURL: originalURL)
        )
    }

    static func alamofireRedirector(for originalURL: URL) -> Redirector {
        .modify { _, request, _ in
            guard let redirectedURL = request.url,
                  ServiceEndpointSecurityPolicy.allowsRedirect(
                      from: originalURL,
                      to: redirectedURL
                  )
            else {
                return nil
            }
            return request
        }
    }
}

// MARK: - ServiceEndpointRedirectDelegate

private final class ServiceEndpointRedirectDelegate: NSObject, URLSessionTaskDelegate,
    @unchecked Sendable {
    // MARK: Lifecycle

    init(originalURL: URL) {
        self.originalURL = originalURL
    }

    // MARK: Internal

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping (URLRequest?) -> ()
    ) {
        guard let redirectedURL = request.url,
              ServiceEndpointSecurityPolicy.allowsRedirect(
                  from: originalURL,
                  to: redirectedURL
              )
        else {
            completionHandler(nil)
            return
        }
        completionHandler(request)
    }

    // MARK: Private

    private let originalURL: URL
}

// MARK: - ServiceEndpointSecurityError

enum ServiceEndpointSecurityError: LocalizedError {
    case disallowedEndpoint

    // MARK: Internal

    var errorDescription: String? {
        String(localized: "network.endpoint.insecure_remote")
    }
}
