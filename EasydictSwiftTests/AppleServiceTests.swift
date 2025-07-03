//
//  AppleServiceTests.swift
//  EasydictSwiftTests
//
//  Created by AI Assistant on 2025/7/3.
//  Copyright © 2024 izual. All rights reserved.
//

import Testing
import Translation

@testable import Easydict

/// Tests for Apple translation and language services
@Suite("Apple Services", .tags(.apple, .integration))
struct AppleServiceTests {
    @available(macOS 15.0, *)
    @Test("Apple Service Language Availability", .tags(.apple))
    func testLanguageAvailability() async {
        let apple = AppleService()
        await apple.prepareSupportedLanguages()
    }

    @MainActor
    @available(macOS 15.0, *)
    @Test("Apple Offline Translation", .tags(.apple, .integration))
    func testAppleOfflineTranslation() async throws {
        let translationService = TranslationService(
            configuration: .init(
                source: .init(languageCode: .english),
                target: .init(languageCode: .chinese)
            )
        )

        #expect(
            try await translationService.translate(text: "Hello, world!").targetText == "你好，世界！"
        )
        #expect(try await translationService.translate(text: "good").targetText == "利益")

        let response = try await translationService.translate(
            text: "你好",
            sourceLanguage: .init(languageCode: .chinese),
            targetLanguage: .init(languageCode: .english)
        )
        print(response)
        #expect(response.targetText == "Hello")
    }
}
