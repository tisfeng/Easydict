//
//  MWDictValidationTests.swift
//  EasydictTests
//
//  Created by wanzaiqidao on 2026/11/17.
//

@testable import Easydict
import Foundation
import Testing

// MARK: - MWDictValidationTests

@Suite("Merriam-Webster Validation", .tags(.integration), .timeLimit(.minutes(1)))
struct MWDictValidationTests {
    @Test("Validates the configured Collegiate key with an English lookup")
    func validateService() async throws {
        let service = MWDictService()
        try #require(
            service.hasPrivateAPIKey(),
            "Configure a Merriam-Webster Collegiate API key before running this validation"
        )

        let result = await service.validate()

        #expect(
            result.error == nil,
            "Merriam-Webster validation failed: \(result.error?.localizedDescription ?? "unknown error")"
        )
        #expect(result.wordResult != nil)
    }
}
