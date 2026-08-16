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

/// Verifies the request and response contracts used by DeepL's oneshot endpoint without network access.
@Suite("DeepL Protocol", .tags(.unit))
struct DeepLServiceTests {
    // MARK: Internal

    /// Ensures automatic source detection omits the unsupported `source_lang: auto` field.
    @Test("Encodes oneshot request with automatic source detection")
    func encodesOneshotRequestWithAutomaticSourceDetection() throws {
        let request = makeRequest(sourceLang: nil)
        let object = try #require(try JSONSerialization
            .jsonObject(with: JSONEncoder().encode(request)) as? [String: Any])

        #expect(object["text"] as? [String] == ["test"])
        #expect(object["target_lang"] as? String == "zh-Hans")
        #expect(object["source_lang"] == nil)
        #expect(object["usage_type"] as? String == "translate")

        let appInformation = try #require(object["app_information"] as? [String: Any])
        #expect(appInformation["os"] as? String == "iOS")
        #expect(appInformation["os_version"] as? String == "26.0")
        #expect(appInformation["app_version"] as? String == "26.42")
        #expect(appInformation["app_build"] as? String == "5443737")
        #expect(appInformation["instance_id"] as? String == "test-instance")
    }

    /// Ensures the oneshot response remains compatible with the official API response shape.
    @Test("Decodes oneshot translation response")
    func decodesOneshotTranslationResponse() throws {
        let data = Data(#"{"translations":[{"detected_source_language":"EN","text":"你好"}]}"#.utf8)
        let response = try JSONDecoder().decode(DeepLOfficialResponse.self, from: data)

        #expect(response.translations?.first?.detectedSourceLanguage == "EN")
        #expect(response.translations?.first?.text == "你好")
    }

    /// Ensures official API response formatting is preserved after parsing.
    @Test("Preserves official response whitespace")
    func preservesOfficialResponseWhitespace() throws {
        let response: [String: Any] = [
            "translations": [["text": "\n  Hello\n"]],
        ]

        let translatedResults = try #require(DeepLService().parseOfficialResponse(response))

        #expect(translatedResults == ["", "  Hello", ""])
    }

    // MARK: Private

    /// Builds a deterministic request fixture matching the new DeepL protocol.
    private func makeRequest(sourceLang: String?) -> DeepLWebTranslateRequest {
        DeepLWebTranslateRequest(
            text: ["test"],
            targetLang: "zh-Hans",
            sourceLang: sourceLang,
            usageType: "translate",
            appInformation: DeepLAppInformation(
                os: "iOS",
                osVersion: "26.0",
                appVersion: "26.42",
                appBuild: "5443737",
                instanceID: "test-instance"
            )
        )
    }
}
