//
//  BingDictValidationTests.swift
//  EasydictTests
//
//  Created by wanzaiqidao on 2026/11/17.
//

@testable import Easydict
import Foundation
import Testing

// MARK: - BingDictValidationTests

@Suite("Bing Dict Validation", .tags(.integration), .timeLimit(.minutes(1)))
struct BingDictValidationTests {
    @Test("Validates an anonymous English lookup")
    func validateService() async throws {
        let result = await BingDictService().validate()

        #expect(
            result.error == nil,
            "Bing Dict validation failed: \(result.error?.localizedDescription ?? "unknown error")"
        )
        #expect(result.wordResult != nil)
    }
}
