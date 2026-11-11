//
//  OCRTranslationRoutingTests.swift
//  EasydictTests
//
//  Copyright © 2026 izual. All rights reserved.
//

import Testing

@testable import Easydict

/// Checks routing decisions without sending a request or installing test credentials.
@Suite("Combined OCR service identity", .tags(.unit))
struct OCRTranslationRoutingTests {
    @Test("Two views of the same configured service agree")
    func sameConfiguration() {
        let first = DeepSeekService()
        let second = DeepSeekService()
        #expect(first.canCombineOCR(with: second) == first.supportsOCRAndTranslation())
        let codex = CodexCLIService()
        #expect(codex.canCombineOCR(with: CodexCLIService()) == codex.supportsOCRAndTranslation())
    }

    @MainActor
    @Test("Explicit dictionary or sentence modes retain their existing text-query paths")
    func specializedQueryModes() {
        let service = DeepSeekService()
        service.queryType = .sentence
        #expect(!service.supportsOCRAndTranslation())
        service.queryType = .dictionary
        #expect(!service.supportsOCRAndTranslation())
    }

    @MainActor
    @Test("User input transformations retain the normal text-translation path")
    func transformedInput() async {
        let service = DeepSeekService()
        service.queryType = .translation
        let model = QueryModel()
        await Task.yield()
        model.inputText = "A source paragraph with deliberately retained trailing whitespace.  "
        #expect(model.queryText != model.inputText)
        #expect(!service.canReuseOCRTranslation(for: model))
    }

    @Test("Different providers or configured instances never merge")
    func distinctConfiguration() {
        let first = DeepSeekService()
        let other = DeepSeekService()
        other.uuid = "unconfigured-identity-test"
        #expect(!first.canCombineOCR(with: other))
        #expect(!first.canCombineOCR(with: CodexCLIService()))
        #expect(!first.canCombineOCR(with: AppleService.shared))
        #expect(!AppleService.shared.supportsOCRAndTranslation())
    }
}
