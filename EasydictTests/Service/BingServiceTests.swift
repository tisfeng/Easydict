//
//  BingServiceTests.swift
//  EasydictTests
//
//  Created by tisfeng on 2026/4/12.
//

import Foundation
import Testing

@testable import Easydict

// MARK: - BingRequestStub

/// Supplies deterministic translate callback values so Bing service aggregation can be tested
/// without network traffic. The stub only overrides the standard translate endpoint because these
/// tests intentionally exercise the non-dictionary branch.
private final class BingRequestStub: BingRequest {
    // MARK: Lifecycle

    /// Creates a stub that immediately completes `translateText` with the provided callback values.
    init(
        translateData: Data?,
        lookupData: Data?,
        translateError: Error?,
        lookupError: Error?
    ) {
        self.translateData = translateData
        self.lookupData = lookupData
        self.translateError = translateError
        self.lookupError = lookupError
        super.init()
    }

    // MARK: Internal

    /// Returns the preconfigured callback payload without performing any network request.
    override func translateText(
        text _: String,
        from _: String,
        to _: String,
        completionHandler completion: @escaping BingTranslateCompletion
    ) {
        completion(translateData, lookupData, translateError, lookupError)
    }

    // MARK: Private

    private let translateData: Data?
    private let lookupData: Data?
    private let translateError: Error?
    private let lookupError: Error?
}

// MARK: - BingServiceTests

/// Verifies the service-layer aggregation rules for Bing translate callbacks. These tests focus on
/// how successful translate payloads are combined with lookup follow-up outcomes so cancellation
/// does not leak stale UI results while non-fatal lookup failures still preserve translated text.
@Suite("Bing Service", .tags(.unit))
struct BingServiceTests {
    // MARK: Internal

    /// Verifies that a cancelled lookup turns the whole non-dictionary query into cancellation.
    @Test("Cancels non-dictionary translate when lookup is cancelled", .tags(.unit))
    func cancelsNonDictionaryTranslateWhenLookupIsCancelled() throws {
        let translateData = try makeTranslateData(translatedText: "你好")
        let service = makeService(
            request: BingRequestStub(
                translateData: translateData,
                lookupData: nil,
                translateError: nil,
                lookupError: CancellationError()
            )
        )

        var completionResult: QueryResult?
        var completionError: (any Error)?

        service.bingTranslate("hello", useDictQuery: false, from: .english, to: .simplifiedChinese) { result, error in
            completionResult = result
            completionError = error
        }

        #expect(completionError is CancellationError)
        #expect(completionResult?.translatedText == nil)
    }

    /// Verifies that a normal lookup failure does not discard an already successful translation.
    @Test("Keeps translated result when lookup fails without cancellation", .tags(.unit))
    func keepsTranslatedResultWhenLookupFailsWithoutCancellation() throws {
        let translateData = try makeTranslateData(translatedText: "你好")
        let service = makeService(
            request: BingRequestStub(
                translateData: translateData,
                lookupData: nil,
                translateError: nil,
                lookupError: QueryError(type: .api, message: "lookup failed")
            )
        )

        var completionResult: QueryResult?
        var completionError: (any Error)?

        service.bingTranslate("hello", useDictQuery: false, from: .english, to: .simplifiedChinese) { result, error in
            completionResult = result
            completionError = error
        }

        if let completionError {
            Issue.record("Expected translated result without completion error, got: \(completionError)")
        }
        #expect(completionResult?.translatedText == "你好")
    }

    // MARK: Private

    /// Creates a Bing service with a stubbed request dependency and initialized result state.
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

    /// Builds the minimal successful Bing translate payload required by the service parser.
    private func makeTranslateData(translatedText: String) throws -> Data {
        let payload: [[String: Any]] = [
            [
                "detectedLanguage": [
                    "language": "en",
                    "score": 1.0,
                ],
                "translations": [
                    [
                        "text": translatedText,
                        "to": "zh-Hans",
                    ],
                ],
            ],
        ]

        return try JSONSerialization.data(withJSONObject: payload)
    }
}
