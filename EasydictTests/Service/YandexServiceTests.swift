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

// MARK: - MozhiURLProtocolStub

/// Intercepts Mozhi requests at the URL loading boundary and returns a
/// deterministic response.
private final class MozhiURLProtocolStub: URLProtocol {
    nonisolated(unsafe) static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with _: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = Self.handler else {
            Issue.record("Mozhi URL protocol handler was not configured")
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
    /// Verifies the current Mozhi/Crow request and response contract end to
    /// end.
    @Test("Translates English to Russian through Mozhi Yandex")
    func translatesEnglishToRussianThroughMozhiYandex() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MozhiURLProtocolStub.self]
        let session = Session(configuration: configuration)
        let baseURL = try #require(URL(string: "https://mozhi.example"))

        MozhiURLProtocolStub.handler = { request in
            let components = try #require(URLComponents(url: request.url!, resolvingAgainstBaseURL: false))

            #expect(request.httpMethod == "GET")
            #expect(components.path == "/api/translate")
            #expect(components.queryItems?.first { $0.name == "engine" }?.value == "yandex")
            #expect(components.queryItems?.first { $0.name == "from" }?.value == "en")
            #expect(components.queryItems?.first { $0.name == "to" }?.value == "ru")
            #expect(components.queryItems?.first { $0.name == "text" }?.value == "Hello")

            let response = try #require(
                HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )
            )
            let data = Data(
                #"{"engine":"yandex","detected":"en","translated-text":"Привет"}"#.utf8
            )
            return (response, data)
        }
        defer {
            MozhiURLProtocolStub.handler = nil
        }

        let service = YandexService(session: session, baseURL: baseURL)
        _ = service.resetServiceResult()

        let result = try await service.translate("Hello", from: .english, to: .russian)

        #expect(result.translatedText == "Привет")
    }

    /// Verifies that Mozhi server failures preserve their response body in a
    /// service error.
    @Test("Maps Mozhi server failures to QueryError")
    func mapsMozhiServerFailuresToQueryError() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MozhiURLProtocolStub.self]
        let session = Session(configuration: configuration)
        let baseURL = try #require(URL(string: "https://mozhi.example"))
        let responseBody = "Source language code invalid"

        MozhiURLProtocolStub.handler = { request in
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
            MozhiURLProtocolStub.handler = nil
        }

        let service = YandexService(session: session, baseURL: baseURL)
        _ = service.resetServiceResult()

        do {
            _ = try await service.translate("Hello", from: .english, to: .russian)
            Issue.record("Expected Mozhi HTTP 500 response to throw QueryError")
        } catch let error as QueryError {
            #expect(error.type == .api)
            #expect(error.errorDataMessage == responseBody)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }
}
