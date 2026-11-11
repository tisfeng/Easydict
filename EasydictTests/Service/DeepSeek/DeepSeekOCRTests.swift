//
//  DeepSeekOCRTests.swift
//  EasydictTests
//
//  Copyright © 2026 izual. All rights reserved.
//

import AppKit
import Defaults
import Foundation
import Testing
import XCTest

@testable import Easydict

// MARK: - DeepSeekOCRTests

@Suite("DeepSeek OCR", .tags(.unit))
struct DeepSeekOCRTests {
    // MARK: Internal

    @Test("Image requests preserve the image, endpoint, key, and reasoning settings")
    func imageRequest() throws {
        let fixture = Fixture()
        defer { fixture.cleanUp() }
        let service = fixture.service
        Defaults[service.reasoningEffortDefaultsKey] = .high
        let image = "data:image/png;base64,aW1hZ2U="
        let request = try service.imageRecognitionRequest(image, prompt: #"Keep \(\frac{1}{2}\) unchanged"#)
        let body = try requestBody(request)
        #expect(request.url?.absoluteString == "https://deepseek.invalid/v1/chat/completions")
        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer test-key")
        #expect(body["model"] as? String == "deepseek-flash")
        #expect(body["stream"] as? Bool == false)
        #expect((body["thinking"] as? [String: String])?["type"] == "enabled")
        #expect(body["reasoning_effort"] as? String == "high")
        let messages = try #require(body["messages"] as? [[String: Any]])
        #expect(messages.count == 1)
        #expect(messages[0]["role"] as? String == "user")
        let parts = try #require(messages[0]["content"] as? [[String: Any]])
        #expect(parts.count == 2)
        #expect(parts[0]["type"] as? String == "text")
        #expect(parts[0]["text"] as? String == #"Keep \(\frac{1}{2}\) unchanged"#)
        #expect(parts[1]["type"] as? String == "image_url")
        #expect((parts[1]["image_url"] as? [String: String])?["url"] == image)
    }

    @Test("Reasoning off omits the reasoning effort override")
    func reasoningOff() throws {
        let fixture = Fixture()
        defer { fixture.cleanUp() }
        let request = try fixture.service.imageRecognitionRequest("data:image/png;base64,aQ==", prompt: "Read")
        let body = try requestBody(request)
        #expect((body["thinking"] as? [String: String])?["type"] == "disabled")
        #expect(body["reasoning_effort"] == nil)
    }

    @Test("Text-only V4 Pro is rejected before a request is sent")
    func textOnlyModel() throws {
        let fixture = Fixture()
        defer { fixture.cleanUp() }
        fixture.service.model = "deepseek-v4-pro"
        #expect(throws: QueryError.self) {
            try fixture.service.imageRecognitionRequest("data:image/png;base64,aQ==", prompt: "Read")
        }
        do {
            _ = try fixture.service.imageRecognitionRequest("data:image/png;base64,aQ==", prompt: "Read")
            Issue.record("Expected the image model validation to fail")
        } catch let error as QueryError {
            #expect(error.type == .parameter)
            #expect(error.message?.contains("deepseek-flash") == true)
        }
    }

    @Test("Missing credentials fail before building an image request")
    func missingKey() throws {
        let fixture = Fixture()
        defer { fixture.cleanUp() }
        Defaults[fixture.service.apiKeyKey] = ""
        do {
            _ = try fixture.service.imageRecognitionRequest("data:image/png;base64,aQ==", prompt: "Read")
            Issue.record("Expected missing API key validation to fail")
        } catch let error as QueryError {
            #expect(error.type == .missingSecretKey)
        }
    }

    @Test("The official legacy Flash aliases retain image support", arguments: [
        "deepseek-v4-flash", "deepseek-v4-flash-vision-exp",
    ])
    func legacyFlashModel(model: String) throws {
        let fixture = Fixture()
        defer { fixture.cleanUp() }
        fixture.service.supportedModels = "deepseek-flash, " + model
        fixture.service.model = model
        let request = try fixture.service.imageRecognitionRequest("data:image/png;base64,aQ==", prompt: "Read")
        let body = try requestBody(request)
        #expect(body["model"] as? String == model)
    }

    // MARK: Private

    private struct Fixture {
        // MARK: Lifecycle

        init() {
            let service = DeepSeekService()
            service.uuid = UUID().uuidString
            Defaults[service.apiKeyKey] = "test-key"
            Defaults[service.endpointKey] = "https://deepseek.invalid/v1/chat/completions"
            Defaults[service.reasoningEffortDefaultsKey] = .off
            service.supportedModels = "deepseek-flash, deepseek-v4-pro"
            service.model = "deepseek-flash"
            self.service = service
        }

        // MARK: Internal

        let service: DeepSeekService

        func cleanUp() {
            Defaults.reset(
                service.apiKeyKey,
                service.endpointKey,
                service.reasoningEffortDefaultsKey,
                service.supportedModelsKey,
                service.validModelsKey,
                service.modelKey
            )
        }
    }

    private func requestBody(_ request: URLRequest) throws -> [String: Any] {
        let data = try #require(request.httpBody)
        return try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }
}

// MARK: - DeepSeekFormulaImageTests

/// Real-provider validation is selected explicitly through the DeepSeekOCR test plan.
final class DeepSeekFormulaImageTests: XCTestCase {
    func testRecognizesFormulaImage() async throws {
        let service = DeepSeekService()
        try XCTSkipIf(service.apiKey.isEmpty, "Configure a DeepSeek API key before running this test plan")
        let image = try NSImage.loadTestImage(named: "ocr-en-formula.png")
        let response = try await service.ocr(image, from: .english, to: .auto)
        let result = try XCTUnwrap(response)
        let text = result.mergedText
        let compact = text.filter { !$0.isWhitespace && $0 != "{" && $0 != "}" }
        XCTAssertTrue(text.contains("EDLUNA-4736"))
        XCTAssertTrue(text.contains(#"\("#) || text.contains("$"))
        XCTAssertTrue(text.contains(#"\["#) || text.contains("$$"))
        XCTAssertTrue(compact.contains("p_7=53"))
        XCTAssertTrue(compact.contains("R_8="))
        XCTAssertTrue(compact.contains("frac"))
        XCTAssertTrue(compact.contains("x_j^2+1"))
        XCTAssertTrue(compact.contains(#"\sqrt(n+3)"#) || compact.contains(#"\sqrtn+3"#))
    }
}
