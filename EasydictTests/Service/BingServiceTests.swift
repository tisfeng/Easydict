//
//  BingServiceTests.swift
//  EasydictTests
//
//  Created by tisfeng on 2026/4/12.
//

import Alamofire
@testable import Easydict
import Foundation
import Testing

// MARK: - BingRequestStub

private final class BingRequestStub: BingRequest {
    var translations: [BingTranslateCompletion] = []

    override func translateText(
        text _: String,
        from _: String,
        to _: String,
        completionHandler completion: @escaping BingTranslateCompletion
    ) {
        translations.append(completion)
    }
}

// MARK: - BingServiceTests

@MainActor
@Suite("Bing Service", .tags(.unit), .timeLimit(.minutes(1)))
struct BingServiceTests {
    // MARK: Internal

    @Test("Cancels non-dictionary translate when lookup is cancelled")
    func cancelsNonDictionaryTranslateWhenLookupIsCancelled() throws {
        let request = BingRequestStub()
        let service = makeService(request: request)
        var completionResult: QueryResult?
        var completionError: Error?

        service.bingTranslate("hello", useDictQuery: false, from: .english, to: .simplifiedChinese) { result, error in
            completionResult = result
            completionError = error
        }
        request.translations[0](try makeTranslateData("你好"), nil, nil, CancellationError())

        #expect(completionError is CancellationError)
        #expect(completionResult?.translatedText == nil)
        #expect(service.result.translatedText == nil)
        #expect(service.result.error == nil)
    }

    @Test("Keeps translated result when lookup fails without cancellation")
    func keepsTranslatedResultWhenLookupFailsWithoutCancellation() throws {
        let request = BingRequestStub()
        let service = makeService(request: request)
        var completionResult: QueryResult?
        var completionError: Error?

        service.bingTranslate("hello", useDictQuery: false, from: .english, to: .simplifiedChinese) { result, error in
            completionResult = result
            completionError = error
        }
        request.translations[0](try makeTranslateData("你好"), nil, nil, QueryError(type: .api, message: "lookup failed"))

        #expect(completionError == nil)
        #expect(completionResult?.translatedText == "你好")
    }

    @Test("Overlapping network queries each complete once and the last succeeds")
    func overlappingNetworkQueries() async throws {
        let (request, session, host, channel) = makeNetworkRequest()
        defer {
            session.session.invalidateAndCancel()
            BingURLProtocol.removeChannel(for: host)
        }
        var incoming = channel.requests.makeAsyncIterator()
        var completions: [Int] = []
        let results = AsyncStream<(Int, Data?, Error?)>.makeStream()
        defer { results.continuation.finish() }
        let expected = try makeTranslateData("最后结果")

        for index in 0 ..< 3 {
            request.translateText(text: "query \(index)", from: "en", to: "zh-Hans") { data, _, error, _ in
                completions.append(index)
                results.continuation.yield((index, data, error))
            }
            let first = try #require(await incoming.next())
            let second = try #require(await incoming.next())
            if index == 2 {
                for endpoint in [first, second] {
                    #expect(["/ttranslatev3", "/tlookupv3"].contains(endpoint.request.url?.path ?? ""))
                    endpoint.respond(with: endpoint.request.url?.path == "/ttranslatev3" ? expected : Data("[]".utf8))
                }
            }
        }

        var finished = results.stream.makeAsyncIterator()
        for _ in 0 ..< 3 {
            let (index, data, error) = try #require(await finished.next())
            if index == 2 {
                #expect(error == nil)
                #expect(data == expected)
            } else {
                #expect(error is CancellationError)
            }
        }
        #expect(completions.sorted() == [0, 1, 2])
    }

    // MARK: Private

    private func makeService(request: BingRequest) -> BingService {
        let service = BingService()
        service.bingRequest = request
        let result = QueryResult()
        result.from = .english
        result.to = .simplifiedChinese
        result.queryText = "hello"
        service.result = result
        return service
    }

    private func makeTranslateData(_ translatedText: String) throws -> Data {
        try JSONSerialization.data(withJSONObject: [[
            "detectedLanguage": ["language": "en", "score": 1.0],
            "translations": [["text": translatedText, "to": "zh-Hans"]],
        ]])
    }

    private func makeNetworkRequest() -> (BingRequest, Session, String, BingRequestChannel) {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [BingURLProtocol.self]
        let session = Session(configuration: configuration)
        let request = BingRequest(session: session)
        let host = "\(UUID().uuidString.lowercased()).test"
        let channel = BingRequestChannel()
        BingURLProtocol.addChannel(channel, for: host)
        request.bingConfig.host = host
        request.bingConfig.key = String(Int64(Date().timeIntervalSince1970 * 1000))
        request.bingConfig.token = "test-token"
        request.bingConfig.IG = "test-ig"
        request.bingConfig.IID = "test-iid"
        request.bingConfig.expirationInterval = "3600000"
        return (request, session, host, channel)
    }
}

// MARK: - BingRequestChannel

private final class BingRequestChannel {
    // MARK: Lifecycle

    init() {
        let stream = AsyncStream<BingURLProtocol>.makeStream()
        self.requests = stream.stream
        self.continuation = stream.continuation
    }

    // MARK: Internal

    let requests: AsyncStream<BingURLProtocol>
    let continuation: AsyncStream<BingURLProtocol>.Continuation
}

// MARK: - BingURLProtocol

private final class BingURLProtocol: URLProtocol, @unchecked Sendable {
    // MARK: Internal

    override class func canInit(with _: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.channelLock.lock()
        let channel = Self.channels[request.url?.host ?? ""]
        Self.channelLock.unlock()
        guard let channel else {
            client?.urlProtocol(self, didFailWithError: URLError(.unsupportedURL))
            return
        }
        channel.continuation.yield(self)
    }

    override func stopLoading() {}

    static func addChannel(_ channel: BingRequestChannel, for host: String) {
        channelLock.lock()
        defer { channelLock.unlock() }
        channels[host] = channel
    }

    static func removeChannel(for host: String) {
        channelLock.lock()
        defer { channelLock.unlock() }
        channels.removeValue(forKey: host)?.continuation.finish()
    }

    func respond(with data: Data) {
        guard let url = request.url,
              let response = HTTPURLResponse(
                  url: url,
                  statusCode: 200,
                  httpVersion: nil,
                  headerFields: ["Content-Type": "application/json"]
              )
        else { return }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    // MARK: Private

    private static let channelLock = NSLock()
    private static var channels: [String: BingRequestChannel] = [:]
}
