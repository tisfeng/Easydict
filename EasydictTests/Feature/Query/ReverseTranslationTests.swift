//
//  ReverseTranslationTests.swift
//  EasydictTests
//
//  Created by tisfeng on 2026/9/5.
//

import AppKit
import Testing

@testable import Easydict

// MARK: - ReverseTranslationTests

/// Exercises the real controller and language cell without starting a query window
/// or contacting translation services. Captures the cell's query callback and
/// restores the language preferences that the production toggle updates.
@MainActor
@Suite("Reverse Translation", .serialized, .tags(.unit))
struct ReverseTranslationTests {
    // MARK: Internal

    @Test("Auto source reverses to the detected language, not an Auto target")
    func detectedSource() throws {
        try withFixture { controller, model, service in
            model.detectedLanguage = .japanese
            #expect(model.queryFromLanguage == .japanese)
            #expect(model.queryTargetLanguage == .simplifiedChinese)

            controller.perform(NSSelectorFromString("toggleTranslationLanguages"))

            #expect(model.inputText == "你好")
            #expect(model.userSourceLanguage == .simplifiedChinese)
            #expect(model.userTargetLanguage == .japanese)
            #expect(model.queryTargetLanguage == .japanese)
            #expect(model.ocrImage == nil)
            #expect(model.actionType == .inputQuery)
            #expect(service.result.translatedText == "你好")
        }
    }

    @Test("Explicit languages still reverse with completed stream output")
    func explicitSource() throws {
        try withFixture { controller, model, service in
            model.userSourceLanguage = .english
            service.streaming = true
            service.result.isStreamFinished = true

            controller.perform(NSSelectorFromString("toggleTranslationLanguages"))

            #expect(model.inputText == "你好")
            #expect(model.userSourceLanguage == .simplifiedChinese)
            #expect(model.userTargetLanguage == .english)
        }
    }

    @Test(
        "Unavailable results preserve the original text and language-only swap",
        arguments: ["empty", "loading", "streaming", "error", "stale"]
    )
    func unavailableResult(state: String) throws {
        try withFixture { controller, model, service in
            switch state {
            case "empty": service.result.translatedResults = []
            case "loading": service.result.isLoading = true
            case "streaming":
                service.streaming = true
                service.result.isStreamFinished = false
            case "error": service.result.error = QueryError(type: .api)
            case "stale": service.result.queryText = "a different query"
            default: Issue.record("Unknown result state")
            }

            controller.perform(NSSelectorFromString("toggleTranslationLanguages"))

            #expect(model.inputText == "こんにちは")
            #expect(model.userSourceLanguage == .simplifiedChinese)
            #expect(model.userTargetLanguage == .auto)
            #expect(model.ocrImage != nil)
            #expect(model.actionType == .ocrQuery)
        }
    }

    @Test("Equal effective languages do not replace the input")
    func equalEffectiveLanguages() throws {
        try withFixture { controller, model, _ in
            model.detectedLanguage = .simplifiedChinese

            controller.perform(NSSelectorFromString("toggleTranslationLanguages"))

            #expect(model.inputText == "こんにちは")
            #expect(model.userSourceLanguage == .simplifiedChinese)
            #expect(model.userTargetLanguage == .auto)
            #expect(model.ocrImage != nil)
        }
    }

    @Test("Auto to Auto retains the existing no-op behavior")
    func bothAutomatic() throws {
        try withFixture { controller, model, _ in
            model.userTargetLanguage = .auto

            controller.perform(NSSelectorFromString("toggleTranslationLanguages"))

            #expect(model.inputText == "こんにちは")
            #expect(model.userSourceLanguage == .auto)
            #expect(model.userTargetLanguage == .auto)
            #expect(model.ocrImage != nil)
        }
    }

    // MARK: Private

    /// KVC supplies existing private collaborators without adding production hooks.
    /// The inherited nib initializer avoids unrelated window and service setup.
    private func withFixture(
        _ body: (NSViewController, QueryModel, ReverseTranslationService) throws -> ()
    ) throws {
        let config = MyConfiguration.shared
        let savedFrom = config.fromLanguage
        let savedTo = config.toLanguage
        defer {
            config.fromLanguage = savedFrom
            config.toLanguage = savedTo
        }

        let controllerType = try #require(NSClassFromString("EZBaseQueryViewController") as? NSViewController.Type)
        let cellType = try #require(NSClassFromString("EZSelectLanguageCell") as? NSView.Type)
        let controller = controllerType.init(nibName: nil, bundle: nil)
        let cell = cellType.init(frame: .zero)
        let model = QueryModel()
        model.userSourceLanguage = .auto
        model.userTargetLanguage = .simplifiedChinese
        controller.setValue(model, forKey: "queryModel")
        controller.setValue("こんにちは", forKey: "inputText")
        model.detectedLanguage = .japanese
        model.actionType = .ocrQuery
        model.ocrImage = NSImage(size: NSSize(width: 1, height: 1))
        cell.setValue(model, forKey: "queryModel")
        let query: @convention(block) (NSString, NSString) -> () = { from, to in
            model.userSourceLanguage = Language(rawValue: from as String)
            model.userTargetLanguage = Language(rawValue: to as String)
        }
        cell.setValue(query, forKey: "enterActionBlock")
        controller.setValue(cell, forKey: "selectLanguageCell")

        let service = ReverseTranslationService()
        service.queryModel = model
        service.result = QueryResult()
        service.result.queryText = model.queryText
        service.result.translatedResults = ["你好"]
        controller.setValue(service, forKey: "firstService")
        try body(controller, model, service)
    }
}

// MARK: - ReverseTranslationService

/// Supplies completed or streaming results without invoking a provider.
private final class ReverseTranslationService: QueryService {
    var streaming = false

    override func serviceType() -> ServiceType { .apple }

    override func isStream() -> Bool { streaming }
}
