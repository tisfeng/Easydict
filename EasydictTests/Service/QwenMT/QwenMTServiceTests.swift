//
//  QwenMTServiceTests.swift
//  EasydictTests
//
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation
import Testing

@testable import Easydict

// MARK: - QwenMTServiceTests

@Suite("QwenMTService", .serialized)
struct QwenMTServiceTests {
    @Test("registers a translation-only service with the official endpoint")
    func serviceContract() {
        let service = QwenMTService()

        #expect(service.serviceType() == .qwenMT)
        #expect(service.apiKeyRequirement() == .userProvided)
        #expect(service.supportedQueryType() == .translation)
        #expect(service.defaultModel == "qwen-mt-flash")
        #expect(service.defaultModels == ["qwen-mt-flash", "qwen-mt-plus", "qwen-mt-lite"])
        #expect(service.defaultEndpoint == "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions")
        #expect(!service.supportsOCR())
        #expect(!service.canFetchRemoteModels)
        #expect(service.preservesResponseContent)
        #expect(QueryServiceFactory.shared.service(withTypeId: "QwenMT") is QwenMTService)
        #expect(QueryServiceFactory.shared.metadata(withTypeId: "QwenMT")?.apiKeyRequirement == .userProvided)
    }

    @Test("encodes only the original user text and translation options")
    func translationPayload() throws {
        let service = QwenMTService()
        let text = "Translate this literally:\n\"Hello, world!\""
        let request = try service.translationRequest(
            text: text, from: .auto, to: .traditionalChinese, model: "qwen-mt-flash"
        )
        let data = try JSONEncoder().encode(request)
        let json = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let messages = try #require(json["messages"] as? [[String: String]])
        let options = try #require(json["translation_options"] as? [String: String])

        #expect(Set(json.keys) == ["model", "messages", "stream", "translation_options"])
        #expect(messages == [["role": "user", "content": text]])
        #expect(options == ["source_lang": "auto", "target_lang": "zh_tw"])
        #expect(json["stream"] as? Bool == true)
    }

    @Test(
        "selects incremental streaming only for Flash and Lite",
        arguments: [
            ("qwen-mt-flash", true),
            ("qwen-mt-lite", true),
            ("qwen-mt-plus", false),
        ]
    )
    func streamingMode(model: String, expected: Bool) throws {
        let request = try QwenMTService().translationRequest(
            text: "Hello", from: .english, to: .simplifiedChinese, model: model
        )
        #expect(request.stream == expected)
    }

    @Test("maps Chinese variants, Hebrew, and Norwegian to provider language codes")
    func languageMapping() throws {
        let service = QwenMTService()
        #expect(service.languageCode(forLanguage: .simplifiedChinese) == "zh")
        #expect(service.languageCode(forLanguage: .traditionalChinese) == "zh_tw")
        #expect(service.languageCode(forLanguage: .hebrew) == "he")
        #expect(service.languageCode(forLanguage: .norwegian) == "nb")
        #expect(service.languageCode(forLanguage: .brazilianPortuguese) == "pt")

        #expect(throws: QueryError.self) {
            try service.translationRequest(
                text: "Hello", from: .english, to: .auto, model: "qwen-mt-flash"
            )
        }
        #expect(throws: QueryError.self) {
            try service.translationRequest(
                text: "Hello", from: .english, to: .mongolian, model: "qwen-mt-plus"
            )
        }
        #expect(throws: QueryError.self) {
            try service.translationRequest(
                text: "Hello", from: .english, to: .norwegian, model: "qwen-mt-lite"
            )
        }
        #expect(service.translationLanguageCode(for: .norwegian, model: "qwen-mt-flash") == "nb")
    }

    @Test(
        "translates into the requested Chinese variant using locally configured credentials",
        .tags(.integration, .requiresLocalEnvironment),
        .enabled(
            if: !QwenMTService().apiKey.trim().isEmpty,
            "Configure a Qwen-MT API key in Easydict on this Mac before running this test"
        ),
        arguments: [
            ("qwen-mt-flash", Language.simplifiedChinese),
            ("qwen-mt-plus", Language.simplifiedChinese),
            ("qwen-mt-lite", Language.simplifiedChinese),
            ("qwen-mt-flash", Language.traditionalChinese),
        ]
    )
    func translatesWithConfiguredCredentials(model: String, target: Language) async throws {
        let service = QwenMTService()
        let originalModel = service.model
        defer { service.model = originalModel }
        service.model = model
        #expect(service.model == model)

        let query = QueryModel()
        query.inputText = "The world is changing."
        query.userSourceLanguage = .english
        query.userTargetLanguage = target
        let result = try await service.startQuery(query)

        #expect(result.error == nil)
        let translatedText = try #require(result.translatedText)
        #expect(translatedText.contains("世界"))
        #expect(translatedText.contains(target == .traditionalChinese ? "變" : "变"))
    }

    @Test(
        "preserves quotes and think markup from actual provider responses",
        .tags(.integration, .requiresLocalEnvironment),
        .enabled(
            if: !QwenMTService().apiKey.trim().isEmpty,
            "Configure a Qwen-MT API key in Easydict on this Mac before running this test"
        ),
        arguments: ["qwen-mt-lite", "qwen-mt-plus"],
        ["\"The world is changing.\"", "<think>The world is changing.</think>"]
    )
    func preservesProviderResponse(model: String, input: String) async throws {
        let service = QwenMTService()
        let originalModel = service.model
        defer { service.model = originalModel }
        service.model = model
        service.hideThinkTagContent = true
        service.resetServiceResult().isStreamFinished = false

        var providerText = ""
        for try await content in service.contentStreamTranslate(
            input, from: .english, to: .simplifiedChinese
        ) {
            providerText += content
            service.updateResultText(providerText, queryType: .translation, error: nil) { result in
                #expect(result.error == nil)
                #expect(result.translatedText == providerText)
            }
        }

        #expect(providerText.contains("世界"))
        #expect(providerText.contains("变"))
        if input.hasPrefix("<think>") {
            #expect(providerText.hasPrefix("<think>"))
            #expect(providerText.hasSuffix("</think>"))
        } else {
            #expect(providerText.hasPrefix("\"") || providerText.hasPrefix("“"))
            #expect(providerText.hasSuffix("\"") || providerText.hasSuffix("”"))
        }

        let finalText = service.getFinalResultText(providerText)
        #expect(finalText == providerText)
        service.updateResultText(
            finalText, queryType: .translation, error: nil, markStreamFinished: true
        ) { result in
            #expect(result.error == nil)
            #expect(result.isStreamFinished)
            #expect(result.translatedText == providerText)
        }
    }
}
