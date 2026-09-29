//
//  DeepLServiceTests.swift
//  EasydictTests
//
//  Created by tisfeng on 2026/8/15.
//

import Foundation
import Testing

@testable import Easydict

// MARK: - DeepLServiceTests

/// Verifies the DeepL service behavior and response contracts.
@Suite("DeepL Service")
struct DeepLServiceTests {
    /// Exercises the same configured DeepL service path used by service validation.
    @Test("Validates DeepL service through a real translation", .tags(.integration))
    func validatesDeepLService() async {
        let result = await DeepLService().validate()

        #expect(
            result.error == nil,
            "DeepL service validation failed: \(result.error?.localizedDescription ?? "unknown error")"
        )
        #expect(result.translatedText?.isEmpty == false)
    }

    /// Ensures the oneshot response remains compatible with the official API response shape.
    @Test("Decodes oneshot translation response", .tags(.unit))
    func decodesOneshotTranslationResponse() throws {
        let data = Data(#"{"translations":[{"detected_source_language":"EN","text":"你好"}]}"#.utf8)
        let response = try JSONDecoder().decode(DeepLOfficialResponse.self, from: data)

        #expect(response.translations?.first?.detectedSourceLanguage == "EN")
        #expect(response.translations?.first?.text == "你好")
    }

    /// Ensures official API response formatting is preserved after parsing.
    @Test("Preserves official response whitespace", .tags(.unit))
    func preservesOfficialResponseWhitespace() throws {
        let response: [String: Any] = [
            "translations": [["text": "\n  Hello\n"]],
        ]

        let translatedResults = try #require(DeepLService().parseOfficialResponse(response))

        #expect(translatedResults == ["", "  Hello", ""])
    }
}
