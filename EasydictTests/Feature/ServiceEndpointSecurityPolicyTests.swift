//
//  ServiceEndpointSecurityPolicyTests.swift
//  EasydictTests
//
//  Created by Eric Pan on 2026/8/26.
//  Copyright © 2026 izual. All rights reserved.
//

import Defaults
import Foundation
import Testing

@testable import Easydict

// MARK: - ServiceEndpointSecurityPolicyTests

/// Verifies the shared service endpoint boundary without resolving hostnames or contacting a server.
@Suite("Service Endpoint Security Policy", .serialized, .tags(.unit))
struct ServiceEndpointSecurityPolicyTests {
    // MARK: Internal

    @Test(
        "Allows HTTPS and exact HTTP loopback hosts",
        arguments: [
            "https://api.example.com/v1/chat/completions",
            "HTTPS://API.EXAMPLE.COM/v1",
            "https://localhost:8443",
            "http://localhost:11434",
            "HTTP://LOCALHOST:11434/api/tags",
            "http://127.0.0.1:11434",
            "http://[::1]:11434/v1",
            "  https://api.example.com/v1  ",
        ]
    )
    func allowsSecureAndExactLoopbackEndpoints(_ endpoint: String) throws {
        #expect(ServiceEndpointSecurityPolicy.allows(endpoint))
        let url = try ServiceEndpointSecurityPolicy.validatedURL(endpoint)
        #expect(url.scheme?.lowercased() == endpoint.trim().prefix { $0 != ":" }.lowercased())
    }

    @Test(
        "Rejects remote HTTP, loopback aliases, and unsupported schemes",
        arguments: [
            "http://api.example.com/v1",
            "http://localhost.example.com/v1",
            "http://example.localhost/v1",
            "http://localhost./v1",
            "http://127.0.0.2/v1",
            "http://127.1/v1",
            "http://2130706433/v1",
            "http://0x7f000001/v1",
            "http://[::ffff:127.0.0.1]/v1",
            "http://service.local/v1",
            "http://192.168.1.10/v1",
            "http://10.0.0.1/v1",
            "ftp://api.example.com/resource",
            "file:///tmp/service",
            "custom://api.example.com/v1",
            "api.example.com/v1",
            "https:///missing-host",
            "not a url",
            "",
        ]
    )
    func rejectsDisallowedEndpoints(_ endpoint: String) {
        #expect(!ServiceEndpointSecurityPolicy.allows(endpoint))
        #expect(throws: ServiceEndpointSecurityError.self) {
            try ServiceEndpointSecurityPolicy.validatedURL(endpoint)
        }
    }

    @Test("Uses the parsed host instead of user information")
    func rejectsLoopbackTextUsedAsUserInformation() {
        let endpoint = "http://localhost@api.example.com/v1"

        #expect(!ServiceEndpointSecurityPolicy.allows(endpoint))
    }

    @Test(
        "Rejects every HTTPS userinfo form",
        arguments: [
            "https://user@api.example.com/v1",
            "https://user" + ":password@api.example.com/v1",
            "https://us%65r" + ":p%40ssword@api.example.com/v1",
        ]
    )
    func rejectsHTTPSUserInfo(_ endpoint: String) {
        #expect(!ServiceEndpointSecurityPolicy.allows(endpoint))
        #expect(throws: ServiceEndpointSecurityError.self) {
            try ServiceEndpointSecurityPolicy.validatedURL(endpoint)
        }
    }

    @Test("URL convenience property uses the shared policy")
    func urlConveniencePropertyUsesSharedPolicy() throws {
        let secureURL = try #require(URL(string: "https://api.example.com/v1"))
        let loopbackURL = try #require(URL(string: "http://[::1]:11434/v1"))
        let insecureURL = try #require(URL(string: "http://api.example.com/v1"))

        #expect(secureURL.isAllowedServiceEndpoint)
        #expect(loopbackURL.isAllowedServiceEndpoint)
        #expect(!insecureURL.isAllowedServiceEndpoint)
    }

    @Test("Allows redirects only within the original origin")
    func allowsOnlySameOriginRedirects() throws {
        let allowedPairs = [
            ("https://api.example.com/v1/start", "https://api.example.com/v1/final"),
            ("https://api.example.com/v1/start", "https://api.example.com:443/v2/final"),
            ("https://api.example.com:443/v1/start", "https://API.EXAMPLE.COM/v2/final"),
            ("http://localhost/v1/start", "http://localhost:80/v2/final"),
            ("http://127.0.0.1:11434/v1/start", "http://127.0.0.1:11434/v2/final"),
            ("http://[::1]:11434/v1/start", "http://[::1]:11434/v2/final"),
        ]
        let rejectedPairs = [
            ("https://api.example.com/v1", "http://api.example.com/v2"),
            ("https://api.example.com/v1", "https://other.example.com/v2"),
            ("https://api.example.com/v1", "https://api.example.com:8443/v2"),
            ("http://localhost:11434/v1", "https://localhost:11434/v2"),
            ("http://localhost:11434/v1", "http://api.example.com/v2"),
            ("http://localhost:11434/v1", "https://api.example.com/v2"),
            ("http://127.0.0.1:11434/v1", "http://localhost:11434/v2"),
        ]

        for (original, redirected) in allowedPairs {
            let originalURL = try #require(URL(string: original))
            let redirectedURL = try #require(URL(string: redirected))
            #expect(ServiceEndpointSecurityPolicy.allowsRedirect(from: originalURL, to: redirectedURL))
        }
        for (original, redirected) in rejectedPairs {
            let originalURL = try #require(URL(string: original))
            let redirectedURL = try #require(URL(string: redirected))
            #expect(!ServiceEndpointSecurityPolicy.allowsRedirect(from: originalURL, to: redirectedURL))
        }
    }

    @Test("Rejects HTTPS userinfo before data or byte transports start")
    func rejectsHTTPSUserInfoAtRequestBoundary() async throws {
        let endpoint = "https://user" + ":password@localhost:65534/v1"
        let sanitizedEndpoint = "https://localhost:65534/v1"
        let url = try #require(URL(string: endpoint))
        #expect(URLProtocol.registerClass(EndpointProbeURLProtocol.self))
        defer { URLProtocol.unregisterClass(EndpointProbeURLProtocol.self) }

        EndpointProbeURLProtocol.configure(matching: [endpoint, sanitizedEndpoint])
        var dataError: Error?
        do {
            _ = try await ServiceEndpointRequestSecurity.data(
                for: credentialBearingRequest(url: url),
                originalURL: url
            )
        } catch {
            dataError = error
        }
        #expect(dataError is ServiceEndpointSecurityError)
        #expect(EndpointProbeURLProtocol.requestCount == 0)

        EndpointProbeURLProtocol.configure(matching: [endpoint, sanitizedEndpoint])
        var bytesError: Error?
        do {
            _ = try await ServiceEndpointRequestSecurity.bytes(
                for: credentialBearingRequest(url: url),
                originalURL: url
            )
        } catch {
            bytesError = error
        }
        #expect(bytesError is ServiceEndpointSecurityError)
        #expect(EndpointProbeURLProtocol.requestCount == 0)
    }

    @Test("Stops unsafe 307 and 308 redirects before a credential-bearing second request")
    func blocksUnsafeRedirectRequests() async throws {
        let originalURL = try #require(URL(string: "http://localhost:65532/v1/start"))
        let targets = [
            (307, "http://api.redirect-target.invalid/capture"),
            (308, "https://api.redirect-target.invalid/capture"),
        ]
        #expect(URLProtocol.registerClass(EndpointProbeURLProtocol.self))
        defer { URLProtocol.unregisterClass(EndpointProbeURLProtocol.self) }

        for (statusCode, target) in targets {
            let targetURL = try #require(URL(string: target))
            EndpointProbeURLProtocol.configureRedirect(
                from: originalURL,
                to: targetURL,
                statusCode: statusCode,
                targetBody: Data("must-not-be-returned".utf8)
            )
            var request = credentialBearingRequest(url: originalURL)
            request.setValue("status-\(statusCode)", forHTTPHeaderField: "X-Redirect-Test")

            let requestTask = Task {
                try await ServiceEndpointRequestSecurity.data(
                    for: request,
                    originalURL: originalURL
                )
            }
            let redirectIssued = await EndpointProbeURLProtocol.waitForRedirect(from: originalURL)
            let targetReached = await EndpointProbeURLProtocol.waitForRequest(to: targetURL)
            requestTask.cancel()
            _ = await requestTask.result

            #expect(redirectIssued)
            #expect(!targetReached)
            #expect(EndpointProbeURLProtocol.requests(for: originalURL).count == 1)
            #expect(EndpointProbeURLProtocol.requests(for: targetURL).isEmpty)
            #expect(EndpointProbeURLProtocol.requestCount == 1)
        }
    }

    @Test("Continues a same-origin redirect through the restricted URLSession")
    func followsSameOriginRedirectRequest() async throws {
        let originalURL = try #require(URL(string: "http://localhost:65533/v1/start"))
        let targetURL = try #require(URL(string: "http://localhost:65533/v1/final"))
        let expectedBody = Data("same-origin-redirect-complete".utf8)
        EndpointProbeURLProtocol.configureRedirect(
            from: originalURL,
            to: targetURL,
            statusCode: 307,
            targetBody: expectedBody
        )
        #expect(URLProtocol.registerClass(EndpointProbeURLProtocol.self))
        defer { URLProtocol.unregisterClass(EndpointProbeURLProtocol.self) }

        let (data, response) = try await ServiceEndpointRequestSecurity.data(
            for: credentialBearingRequest(url: originalURL),
            originalURL: originalURL
        )

        #expect(data == expectedBody)
        #expect((response as? HTTPURLResponse)?.statusCode == 200)
        #expect(EndpointProbeURLProtocol.requests(for: originalURL).count == 1)
        let redirectedRequest = try #require(EndpointProbeURLProtocol.requests(for: targetURL).first)
        #expect(EndpointProbeURLProtocol.requestCount == 2)
        #expect(redirectedRequest.httpMethod == "POST")
        #expect(EndpointProbeURLProtocol.body(for: targetURL) == Data("body-canary".utf8))
        #expect(redirectedRequest.value(forHTTPHeaderField: "Authorization") == "Bearer credential-canary")
        #expect(redirectedRequest.value(forHTTPHeaderField: "api-key") == "credential-canary")
    }

    @Test("Rejects one remote HTTP input across UI, scheme, restore, and request sinks")
    func rejectsRemoteHTTPAcrossEveryBoundary() async throws {
        let uuid = UUID().uuidString
        let endpoint = "http://api.endpoint-policy.invalid/v1/chat/completions"
        let endpointKey = "EZ\(ServiceType.customOpenAI.rawValue)EndPoint_\(uuid)_Key"
        let service = CustomOpenAIService()
        service.uuid = uuid
        service.result = QueryResult()
        defer { resetServiceDefaults(service) }

        EndpointProbeURLProtocol.configure(
            matching: [
                endpoint,
                "http://api.endpoint-policy.invalid/v1/models",
                "http://api.endpoint-policy.invalid/v1/deepl",
            ]
        )
        #expect(URLProtocol.registerClass(EndpointProbeURLProtocol.self))
        defer { URLProtocol.unregisterClass(EndpointProbeURLProtocol.self) }

        let uiValidation = ServiceEndpointSecurityPolicy.allows(endpoint)
        let schemeResult = writeEndpointViaScheme(key: endpointKey, value: endpoint)
        let restore = try prepareEndpointRestore(key: endpointKey, value: endpoint)

        #expect(!uiValidation)
        #expect(!schemeResult.isSuccess)
        #expect(UserDefaults.standard.object(forKey: endpointKey) == nil)
        #expect(restore.preview.skippedUnsafeEndpointCount == 1)
        #expect(restore.resolvedItems.isEmpty)

        // Simulate a value persisted by an older build. Endpoint validation must win over the
        // missing-credential check, and no transport may be created.
        Defaults[service.endpointKey] = endpoint
        Defaults.reset(service.apiKeyKey)
        let requestError = await terminalError(
            from: service.contentStreamTranslate(
                "hello",
                from: .english,
                to: .simplifiedChinese
            )
        )
        let queryError = try #require(requestError as? QueryError)
        #expect(queryError.type == .parameter)

        Defaults[service.apiKeyKey] = "fake-api-key-for-endpoint-policy-test"
        var remoteModelsError: Error?
        do {
            _ = try await service.fetchRemoteModelIDs()
        } catch {
            remoteModelsError = error
        }
        #expect((remoteModelsError as? QueryError)?.type == .parameter)

        let deepLDefaults = snapshotDefaults(keys: [
            "EZDeepLAuthKey",
            "EZDeepLTranslateEndPointKey",
            "EZDeepLTranslationAPIKey",
        ])
        defer { restoreDefaults(deepLDefaults) }
        Defaults[.deepLAuth] = "fake-deepl-key-for-endpoint-policy-test"
        Defaults[.deepLTranslateEndPointKey] = "http://api.endpoint-policy.invalid/v1/deepl"
        Defaults[.deepLTranslation] = .authKeyOnly
        let deepLService = DeepLService()
        deepLService.result = QueryResult()
        let deepLError: Error? = await withCheckedContinuation { continuation in
            deepLService.deepLTranslate(
                "hello",
                from: .english,
                to: .simplifiedChinese
            ) { _, error in
                continuation.resume(returning: error)
            }
        }
        #expect((deepLError as? QueryError)?.type == .parameter)
        #expect(EndpointProbeURLProtocol.requestCount == 0)
    }

    @Test("Allows localhost through UI, restore, and requests while scheme rejects automation")
    func allowsLocalhostAtTrustedBoundaries() async throws {
        let uuid = UUID().uuidString
        let endpoint = "http://localhost:65531/v1/chat/completions"
        let existingEndpoint = "https://existing.endpoint.example/v1/chat/completions"
        let endpointKey = "EZ\(ServiceType.customOpenAI.rawValue)EndPoint_\(uuid)_Key"
        let service = CustomOpenAIService()
        service.uuid = uuid
        service.result = QueryResult()
        defer { resetServiceDefaults(service) }
        Defaults[service.endpointKey] = existingEndpoint

        EndpointProbeURLProtocol.configure(matching: [endpoint])
        #expect(URLProtocol.registerClass(EndpointProbeURLProtocol.self))
        defer { URLProtocol.unregisterClass(EndpointProbeURLProtocol.self) }

        let uiValidation = ServiceEndpointSecurityPolicy.allows(endpoint)
        let schemeResult = writeEndpointViaScheme(key: endpointKey, value: endpoint)
        let restore = try prepareEndpointRestore(key: endpointKey, value: endpoint)

        #expect(uiValidation)
        #expect(!schemeResult.isSuccess)
        #expect(UserDefaults.standard.string(forKey: endpointKey) == existingEndpoint)
        #expect(restore.preview.skippedUnsafeEndpointCount == 0)
        #expect(restore.resolvedItems.map(\.entry.userDefaultsKey) == [endpointKey])

        Defaults[service.endpointKey] = endpoint
        Defaults[service.apiKeyKey] = "fake-api-key-for-endpoint-policy-test"
        service.enableStreaming = false
        service.supportedModels = "endpoint-policy-test-model"
        service.model = "endpoint-policy-test-model"

        let requestError = await terminalError(
            from: service.contentStreamTranslate(
                "hello",
                from: .english,
                to: .simplifiedChinese
            )
        )

        #expect(requestError != nil)
        #expect(EndpointProbeURLProtocol.requestCount == 1)
        let request = try #require(EndpointProbeURLProtocol.lastRequest)
        #expect(request.url?.absoluteString == endpoint)
        #expect(request.httpMethod == "POST")
    }

    // MARK: Private

    // MARK: - Helpers

    private struct SchemeResult {
        let isSuccess: Bool
    }

    private struct DefaultsSnapshot {
        let values: [String: Any]
        let absentKeys: Set<String>
    }

    private func writeEndpointViaScheme(key: String, value: String) -> SchemeResult {
        var components = URLComponents()
        components.scheme = "easydict"
        components.host = "writeKeyValue"
        components.queryItems = [.init(name: key, value: value)]

        var result = SchemeResult(isSuccess: false)
        EZSchemeParserTestBridge.openURLScheme(components.string ?? "") { isSuccess, _, _ in
            result = SchemeResult(isSuccess: isSuccess)
        }
        return result
    }

    private func prepareEndpointRestore(
        key: String,
        value: String
    ) throws
        -> PreparedConfigurationRestore {
        let metadata = ConfigurationBackupApplicationMetadata(
            bundleIdentifier: "com.example.easydict-endpoint-policy-tests",
            version: "1.0",
            build: "100"
        )
        let source = ConfigurationBackupService(
            domainStore: EndpointPolicyDomainStore(domain: [key: value]),
            metadata: metadata
        )
        let encrypted = try source.exportData(
            password: "correct horse battery staple",
            confirmation: "correct horse battery staple"
        )
        let destination = ConfigurationBackupService(
            domainStore: EndpointPolicyDomainStore(domain: [:]),
            metadata: metadata
        )
        return try destination.prepareRestore(
            data: encrypted,
            password: "correct horse battery staple"
        )
    }

    private func terminalError(
        from stream: AsyncThrowingStream<String, any Error>
    ) async
        -> Error? {
        do {
            for try await _ in stream {}
            return nil
        } catch {
            return error
        }
    }

    private func credentialBearingRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = Data("body-canary".utf8)
        request.setValue("Bearer credential-canary", forHTTPHeaderField: "Authorization")
        request.setValue("credential-canary", forHTTPHeaderField: "api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return request
    }

    private func resetServiceDefaults(_ service: CustomOpenAIService) {
        Defaults.reset(service.endpointKey)
        Defaults.reset(service.apiKeyKey)
        Defaults.reset(service.enableStreamingKey)
        Defaults.reset(service.supportedModelsKey)
        Defaults.reset(service.validModelsKey)
        Defaults.reset(service.modelKey)
    }

    private func snapshotDefaults(keys: [String]) -> DefaultsSnapshot {
        var values = [String: Any]()
        var absentKeys = Set<String>()
        for key in keys {
            if let value = UserDefaults.standard.object(forKey: key) {
                values[key] = value
            } else {
                absentKeys.insert(key)
            }
        }
        return DefaultsSnapshot(values: values, absentKeys: absentKeys)
    }

    private func restoreDefaults(_ snapshot: DefaultsSnapshot) {
        for key in snapshot.absentKeys {
            UserDefaults.standard.removeObject(forKey: key)
        }
        for (key, value) in snapshot.values {
            UserDefaults.standard.set(value, forKey: key)
        }
    }
}

// MARK: - EndpointPolicyDomainStore

private final class EndpointPolicyDomainStore: ConfigurationDomainStoring {
    // MARK: Lifecycle

    init(domain: [String: Any]) {
        self.domain = domain
    }

    // MARK: Internal

    private(set) var domain: [String: Any]

    func persistentDomain() -> [String: Any] {
        domain
    }

    func setPersistentDomain(_ domain: [String: Any]) {
        self.domain = domain
    }
}

// MARK: - EndpointProbeURLProtocol

/// A global probe restricted to exact test-only URLs, so unrelated test traffic is untouched.
private final class EndpointProbeURLProtocol: URLProtocol, @unchecked Sendable {
    // MARK: Internal

    static var requestCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return requests.count
    }

    static var lastRequest: URLRequest? {
        lock.lock()
        defer { lock.unlock() }
        return requests.last
    }

    override static func canInit(with request: URLRequest) -> Bool {
        guard let url = request.url?.absoluteString else { return false }
        lock.lock()
        defer { lock.unlock() }
        return matchingURLs.contains(url)
    }

    override static func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        Self.lock.lock()
        Self.requests.append(request)
        let redirect = request.url.flatMap { Self.redirects[$0.absoluteString] }
        let responseBody = request.url.flatMap { Self.responseBodies[$0.absoluteString] }
        if redirect != nil, let requestURL = request.url {
            Self.issuedRedirectURLs.insert(requestURL.absoluteString)
        }
        Self.lock.unlock()

        if let redirect,
           let redirectResponse = HTTPURLResponse(
               url: request.url ?? redirect.targetURL,
               statusCode: redirect.statusCode,
               httpVersion: "HTTP/1.1",
               headerFields: ["Location": redirect.targetURL.absoluteString]
           ) {
            var redirectedRequest = request
            redirectedRequest.url = redirect.targetURL
            client?.urlProtocol(
                self,
                wasRedirectedTo: redirectedRequest,
                redirectResponse: redirectResponse
            )
            return
        }

        if let requestURL = request.url,
           let requestBody = Self.readBody(from: request) {
            Self.lock.lock()
            Self.requestBodies[requestURL.absoluteString] = requestBody
            Self.lock.unlock()
        }

        guard let url = request.url,
              let response = HTTPURLResponse(
                  url: url,
                  statusCode: responseBody == nil ? 503 : 200,
                  httpVersion: "HTTP/1.1",
                  headerFields: ["Content-Type": "application/json"]
              )
        else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(
            self,
            didLoad: responseBody ?? Data(#"{"error":{"message":"endpoint policy stub"}}"#.utf8)
        )
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

    static func requests(for url: URL) -> [URLRequest] {
        lock.lock()
        defer { lock.unlock() }
        return requests.filter { $0.url == url }
    }

    static func body(for url: URL) -> Data? {
        lock.lock()
        defer { lock.unlock() }
        return requestBodies[url.absoluteString]
    }

    /// Waits for the redirect callback without waiting for the deliberately suspended source load.
    static func waitForRedirect(from url: URL) async -> Bool {
        await waitUntil {
            lock.lock()
            defer { lock.unlock() }
            return issuedRedirectURLs.contains(url.absoluteString)
        }
    }

    /// Leaves a bounded grace period for a forbidden target request to expose a policy bypass.
    static func waitForRequest(to url: URL) async -> Bool {
        await waitUntil(attempts: 50) {
            lock.lock()
            defer { lock.unlock() }
            return requests.contains { $0.url == url }
        }
    }

    static func configure(matching urls: Set<String>) {
        lock.lock()
        matchingURLs = urls
        requests = []
        redirects = [:]
        responseBodies = [:]
        requestBodies = [:]
        issuedRedirectURLs = []
        lock.unlock()
    }

    static func configureRedirect(
        from originalURL: URL,
        to targetURL: URL,
        statusCode: Int,
        targetBody: Data
    ) {
        lock.lock()
        matchingURLs = [originalURL.absoluteString, targetURL.absoluteString]
        requests = []
        redirects = [
            originalURL.absoluteString: .init(
                statusCode: statusCode,
                targetURL: targetURL
            ),
        ]
        responseBodies = [targetURL.absoluteString: targetBody]
        requestBodies = [:]
        issuedRedirectURLs = []
        lock.unlock()
    }

    // MARK: Private

    private struct Redirect {
        let statusCode: Int
        let targetURL: URL
    }

    private static let lock = NSLock()
    nonisolated(unsafe) private static var matchingURLs = Set<String>()
    nonisolated(unsafe) private static var requests = [URLRequest]()
    nonisolated(unsafe) private static var redirects = [String: Redirect]()
    nonisolated(unsafe) private static var responseBodies = [String: Data]()
    nonisolated(unsafe) private static var requestBodies = [String: Data]()
    nonisolated(unsafe) private static var issuedRedirectURLs = Set<String>()

    private static func readBody(from request: URLRequest) -> Data? {
        if let body = request.httpBody {
            return body
        }
        guard let stream = request.httpBodyStream else {
            return nil
        }

        stream.open()
        defer { stream.close() }

        var body = Data()
        var buffer = [UInt8](repeating: 0, count: 4_096)
        while true {
            let count = stream.read(&buffer, maxLength: buffer.count)
            switch count {
            case let count where count > 0:
                body.append(contentsOf: buffer.prefix(count))
            case 0:
                return body
            default:
                return nil
            }
        }
    }

    private static func waitUntil(
        attempts: Int = 100,
        predicate: @escaping @Sendable () -> Bool
    ) async
        -> Bool {
        for _ in 0 ..< attempts {
            if predicate() {
                return true
            }
            try? await Task<Never, Never>.sleep(nanoseconds: 10_000_000)
        }
        return predicate()
    }
}
