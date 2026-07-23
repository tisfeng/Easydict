//
//  YandexServiceTests.swift
//  EasydictTests
//
//  Created by Emil Batmanov on 2026/07/23.
//

import Alamofire
import Foundation
import Testing

@testable import Easydict

// MARK: - YandexURLProtocolStub

/// Intercepts Yandex requests at the URL loading boundary and returns a
/// deterministic response.
private final class YandexURLProtocolStub: URLProtocol {
    nonisolated(unsafe) static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override static func canInit(with _: URLRequest) -> Bool {
        true
    }

    override static func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    /// Executes the stubbed response or error at the URL loading boundary.
    override func startLoading() {
        guard let handler = Self.handler else {
            Issue.record("Yandex URL protocol handler was not configured")
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

// MARK: - YandexServiceTests

/// Verifies Yandex translation behavior through the public query-service seam.
@Suite("Yandex Service", .serialized, .tags(.unit))
struct YandexServiceTests {
    /// Verifies the direct unofficial Yandex request and response contract.
    @Test("Translates English to Russian through direct Yandex")
    func translatesEnglishToRussianThroughDirectYandex() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [YandexURLProtocolStub.self]
        let session = Session(configuration: configuration)
        let baseURL = try #require(URL(string: "https://translate.yandex.net"))

        YandexURLProtocolStub.handler = { request in
            let components = try #require(URLComponents(url: request.url!, resolvingAgainstBaseURL: false))

            #expect(request.httpMethod == "POST")
            #expect(components.path == "/api/v1/tr.json/translate")
            #expect(components.queryItems?.first { $0.name == "lang" }?.value == "en-ru")
            #expect(components.queryItems?.first { $0.name == "text" }?.value == "Hello")
            #expect(components.queryItems?.first { $0.name == "srv" }?.value == "android")
            let sid = components.queryItems?.first { $0.name == "sid" }?.value
            #expect(sid?.isEmpty == false)
            #expect(sid?.hasSuffix("-0-0") == true)

            let response = try #require(
                HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )
            )
            let data = Data(#"{"code":200,"lang":"en-ru","text":["Привет"]}"#.utf8)
            return (response, data)
        }
        defer {
            YandexURLProtocolStub.handler = nil
        }

        let service = YandexService(session: session, baseURL: baseURL)
        _ = service.resetServiceResult()

        let result = try await service.translate("Hello", from: .english, to: .russian)

        #expect(result.translatedText == "Привет")
    }

    /// Verifies that Yandex server failures preserve their response body in a
    /// service error.
    @Test("Maps Yandex server failures to QueryError")
    func mapsYandexServerFailuresToQueryError() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [YandexURLProtocolStub.self]
        let session = Session(configuration: configuration)
        let baseURL = try #require(URL(string: "https://translate.yandex.net"))
        let responseBody = "Source language code invalid"

        YandexURLProtocolStub.handler = { request in
            let response = try #require(
                HTTPURLResponse(
                    url: request.url!,
                    statusCode: 500,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "text/plain"]
                )
            )
            return (response, Data(responseBody.utf8))
        }
        defer {
            YandexURLProtocolStub.handler = nil
        }

        let service = YandexService(session: session, baseURL: baseURL)
        _ = service.resetServiceResult()

        do {
            _ = try await service.translate("Hello", from: .english, to: .russian)
            Issue.record("Expected Yandex HTTP 500 response to throw QueryError")
        } catch let error as QueryError {
            #expect(error.type == .api)
            #expect(error.errorDataMessage == responseBody)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }
}
