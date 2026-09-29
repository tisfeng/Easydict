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

    /// Accepts the current DeepL app version from Apple's lookup response.
    @Test("Parses DeepL App Store version", .tags(.unit))
    func parsesDeepLAppStoreVersion() {
        let data = Data(
            """
            {
                "resultCount": 1,
                "results": [{
                    "trackId": 1552407475,
                    "bundleId": "com.linguee.DeepLMobileTranslator",
                    "artistName": "DeepL SE",
                    "version": "26.52"
                }]
            }
            """.utf8
        )

        #expect(DeepLAppStoreVersionParser.version(from: data) == "26.52")
    }

    /// Rejects a version response for a different App Store application.
    @Test("Rejects unrelated App Store version", .tags(.unit))
    func rejectsUnrelatedAppStoreVersion() {
        let data = Data(
            """
            {
                "resultCount": 1,
                "results": [{
                    "trackId": 1,
                    "bundleId": "com.example.other",
                    "artistName": "Other",
                    "version": "26.52"
                }]
            }
            """.utf8
        )

        #expect(DeepLAppStoreVersionParser.version(from: data) == nil)
    }

    /// Rejects malformed versions before placing them in request headers or bodies.
    @Test("Rejects malformed App Store version", .tags(.unit))
    func rejectsMalformedAppStoreVersion() {
        #expect(DeepLAppStoreVersionParser.isValidVersion("26.52"))
        #expect(DeepLAppStoreVersionParser.isValidVersion("26.52.1"))
        #expect(!DeepLAppStoreVersionParser.isValidVersion("26/52"))
        #expect(!DeepLAppStoreVersionParser.isValidVersion("26.52\r\nInjected: true"))
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
